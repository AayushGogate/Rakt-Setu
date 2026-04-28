import json
import requests
import os
import math
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, firestore
from google.cloud.firestore import Client

# --- Global Initialization ---
_APP_INITIALIZED = False
_DB = None

def get_firestore_client():
    global _APP_INITIALIZED, _DB
    if not _APP_INITIALIZED:
        initialize_app()
        _APP_INITIALIZED = True
        # FIXED: Explicitly target 'default' to match your Firestore setup
        _DB = Client(project="raktsetu-prod", database="default")
    return _DB

BLOOD_TYPE_MAP = {
    "O+": "O_pos", "O_pos": "O_pos", "A+": "A_pos", "A_pos": "A_pos",
    "B+": "B_pos", "B_pos": "B_pos", "AB+": "AB_pos", "AB_pos": "AB_pos",
    "O-": "O_neg", "O_neg": "O_neg", "A-": "A_neg", "A_neg": "A_neg",
    "B-": "B_neg", "B_neg": "B_neg", "AB-": "AB_neg", "AB_neg": "AB_neg",
}

def _haversine_km(lat1, lng1, lat2, lng2):
    R = 6371
    d_lat, d_lng = math.radians(lat2 - lat1), math.radians(lng2 - lng1)
    a = (math.sin(d_lat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lng / 2)**2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

# --- 1. MATCHING ENGINE ---
@https_fn.on_request(memory=options.MemoryOption.GB_1, timeout_sec=120, cors=options.CorsOptions(cors_origins="*", cors_methods=["GET", "POST"]))
def find_matches(req: https_fn.Request) -> https_fn.Response:
    db = get_firestore_client()
    MAPS_API_KEY = "AIzaSyBVambLJ7UxEcB8a-cciYxpTaWilE08RCc"
    try:
        data = req.get_json()
        if not data: return https_fn.Response("No JSON", status=400)

        # Safe parameter extraction
        raw_type = data.get("bloodType") or data.get("blood_type", "O_pos")
        needed_type = BLOOD_TYPE_MAP.get(raw_type, "O_pos")
        u_lat = float(data.get("hospitalLat") or data.get("lat", 0))
        u_lng = float(data.get("hospitalLng") or data.get("lng", 0))
        units_needed = int(data.get("unitsNeeded", 1))

        # 1. Fetch & Filter
        all_banks = list(db.collection("inventory").stream())
        bank_list = []
        for doc in all_banks:
            d = doc.to_dict()
            bg = d.get("blood_groups", {})
            stock = bg.get(needed_type, {})
            available = int(stock.get("units", 0)) if isinstance(stock, dict) else 0
            loc = d.get("location")

            if available >= units_needed and loc:
                blat, blng = float(loc["lat"]), float(loc["lng"])
                bank_list.append({
                    "id": doc.id, "name": d.get("name", "Unknown"),
                    "units": available, "lat": blat, "lng": blng,
                    "km": _haversine_km(u_lat, u_lng, blat, blng)
                })

        if not bank_list:
            return https_fn.Response(json.dumps({"status": "no_match", "matches": []}), mimetype="application/json")

        # 2. Google Maps Distance
        dest_str = "|".join([f"{b['lat']},{b['lng']}" for b in bank_list])
        maps_url = f"https://maps.googleapis.com/maps/api/distancematrix/json?origins={u_lat},{u_lng}&destinations={dest_str}&key={MAPS_API_KEY}"
        
        final_results = []
        try:
            maps_res = requests.get(maps_url, timeout=8).json()
            if maps_res.get("status") == "OK":
                elements = maps_res["rows"][0]["elements"]
                for i, element in enumerate(elements):
                    if i < len(bank_list) and element.get("status") == "OK":
                        final_results.append({
                            "id": bank_list[i]["id"], "name": bank_list[i]["name"],
                            "travelTime": element["duration"]["text"],
                            "travelSeconds": element["duration"]["value"],
                            "distance": element["distance"]["text"]
                        })
        except: pass

        # 3. Fallback (If Maps failed or provided 0 results)
        if not final_results:
            for b in sorted(bank_list, key=lambda x: x["km"]):
                mins = max(1, round((b["km"] / 30) * 60))
                final_results.append({
                    "id": b["id"], "name": b["name"],
                    "travelTime": f"~{mins} mins", "travelSeconds": mins * 60,
                    "distance": f"{round(b['km'], 1)} km"
                })

        sorted_matches = sorted(final_results, key=lambda x: x["travelSeconds"])[:3]

        # 4. Log to 'requests' collection
        db.collection("requests").add({
            "bloodType": needed_type, "unitsNeeded": units_needed,
            "matchedBanks": [r["id"] for r in sorted_matches],
            "createdAt": firestore.SERVER_TIMESTAMP
        })

        return https_fn.Response(json.dumps({"status": "success", "matches": sorted_matches}), mimetype="application/json")
    except Exception as e:
        return https_fn.Response(json.dumps({"error": str(e)}), status=500)

# --- 2. SUPPORT FUNCTIONS ---
@https_fn.on_request(memory=256)
def register_bank(req: https_fn.Request) -> https_fn.Response:
    db = get_firestore_client()
    try:
        data = req.get_json()
        bank_id = data.get("bank_id", data.get("name", "unknown")).replace(" ", "_").lower()
        db.collection("inventory").document(bank_id).set({
            "name": data.get("name"),
            "location": {"lat": float(data.get("lat")), "lng": float(data.get("lng"))},
            "blood_groups": {bt: {"units": 0} for bt in BLOOD_TYPE_MAP.values()},
            "createdAt": firestore.SERVER_TIMESTAMP
        })
        return https_fn.Response(json.dumps({"status": "success", "bankId": bank_id}))
    except Exception as e: return https_fn.Response(str(e), status=500)

@https_fn.on_request(memory=256)
def update_stock(req: https_fn.Request) -> https_fn.Response:
    db = get_firestore_client()
    try:
        data = req.get_json()
        bank_id, units = data.get("bank_id"), int(data.get("units", 0))
        blood_type = BLOOD_TYPE_MAP.get(data.get("blood_type", "O_pos"), "O_pos")
        db.collection("inventory").document(bank_id).update({f"blood_groups.{blood_type}.units": units})
        return https_fn.Response(f"Updated {bank_id} successfully.")
    except Exception as e: return https_fn.Response(str(e), status=500)

@https_fn.on_request(cors=options.CorsOptions(cors_origins="*", cors_methods=["GET"]))
def get_demand_forecast(req: https_fn.Request) -> https_fn.Response:
    from google.cloud import bigquery as bq
    try:
        client = bq.Client(project="raktsetu-prod")
        query = "SELECT blood_type, DATE(forecast_timestamp) as d, ROUND(forecast_value) as v FROM ML.FORECAST(MODEL `raktsetu-prod.raktsetu.blood_demand_arima`, STRUCT(3 AS horizon))"
        rows = list(client.query(query).result())
        forecast = {}
        for r in rows:
            if r.blood_type not in forecast: forecast[r.blood_type] = []
            forecast[r.blood_type].append({"date": str(r.d), "val": int(r.v)})
        return https_fn.Response(json.dumps({"status": "live", "forecast": forecast}))
    except Exception as e: return https_fn.Response(json.dumps({"status": "error", "message": str(e)}))