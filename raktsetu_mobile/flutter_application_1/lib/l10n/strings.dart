// lib/l10n/strings.dart
// Centralised strings — English + Marathi
// Usage: AppStrings.of(context).appName

class AppStrings {
  final String languageCode;
  const AppStrings(this.languageCode);

  static AppStrings of(context) => const AppStrings('en'); // wired to locale in main.dart

  bool get isMarathi => languageCode == 'mr';

  String get appName          => isMarathi ? 'रक्तसेतू'        : 'RaktSetu';
  String get tagline          => isMarathi ? 'रक्त वेळेत, जीव वाचवा' : 'Right blood. Right time.';

  // Role selection
  String get chooseRole       => isMarathi ? 'तुमची भूमिका निवडा' : 'Choose your role';
  String get roleDoctor       => isMarathi ? 'डॉक्टर / रुग्णालय' : 'Doctor / Hospital';
  String get roleBloodBank    => isMarathi ? 'रक्तपेढी' : 'Blood Bank';
  String get roleFamily       => isMarathi ? 'रुग्णाचे कुटुंब' : "Patient's Family";
  String get roleDoctorSub    => isMarathi ? 'रक्त तातडीने मागवा' : 'Request blood urgently';
  String get roleBloodBankSub => isMarathi ? 'स्टॉक अपडेट करा, मागणी पूर्ण करा' : 'Update stock, fulfill requests';
  String get roleFamilySub    => isMarathi ? 'रक्त कुठे आहे ते ट्रॅक करा' : 'Track blood delivery live';

  // Common
  String get continueBtn      => isMarathi ? 'पुढे'     : 'Continue';
  String get confirmBtn       => isMarathi ? 'पुष्टी करा'  : 'Confirm';
  String get cancelBtn        => isMarathi ? 'रद्द करा'   : 'Cancel';
  String get backBtn          => isMarathi ? 'मागे'      : 'Back';
  String get loading          => isMarathi ? 'लोड होत आहे...' : 'Loading...';
  String get retry            => isMarathi ? 'पुन्हा प्रयत्न करा' : 'Try again';
  String get units            => isMarathi ? 'युनिट्स'   : 'units';
  String get minutes          => isMarathi ? 'मिनिटे'    : 'mins';
  String get km               => isMarathi ? 'किमी'      : 'km';

  // Doctor flow
  String get raiseRequest     => isMarathi ? 'रक्त मागणी करा' : 'Request Blood';
  String get bloodType        => isMarathi ? 'रक्त प्रकार'   : 'Blood Type';
  String get unitsNeeded      => isMarathi ? 'किती युनिट्स?' : 'Units needed';
  String get findingBlood     => isMarathi ? 'रक्त शोधत आहे...' : 'Finding blood...';
  String get matchesFound     => isMarathi ? 'जवळची रक्तपेढी' : 'Nearest Blood Banks';
  String get selectBank       => isMarathi ? 'रक्तपेढी निवडा' : 'Select blood bank';
  String get requestSent      => isMarathi ? 'मागणी पाठवली' : 'Request sent';
  String get awaitingConfirm  => isMarathi ? 'रक्तपेढीच्या पुष्टीची वाट आहे' : 'Awaiting blood bank confirmation';
  String get noMatches        => isMarathi ? 'सध्या उपलब्ध नाही' : 'No matches found right now';

  // Blood bank flow
  String get pendingRequests  => isMarathi ? 'प्रलंबित मागण्या' : 'Pending Requests';
  String get myInventory      => isMarathi ? 'माझा स्टॉक' : 'My Inventory';
  String get updateStock      => isMarathi ? 'स्टॉक अपडेट करा' : 'Update Stock';
  String get acceptRequest    => isMarathi ? 'स्वीकारा'  : 'Accept';
  String get rejectRequest    => isMarathi ? 'नाकारा'    : 'Reject';
  String get dispatched       => isMarathi ? 'पाठवले'    : 'Dispatched';
  String get markDispatched   => isMarathi ? 'पाठवल्याचे चिन्हांकित करा' : 'Mark as dispatched';
  String get stockSaved       => isMarathi ? 'स्टॉक जतन झाला' : 'Stock saved';

  // Family flow
  String get trackDelivery    => isMarathi ? 'डिलिव्हरी ट्रॅक करा' : 'Track Delivery';
  String get enterRequestId   => isMarathi ? 'मागणी आयडी प्रविष्ट करा' : 'Enter Request ID';
  String get bloodOnTheWay    => isMarathi ? 'रक्त येत आहे!' : 'Blood is on the way!';
  String get eta              => isMarathi ? 'अंदाजे वेळ'  : 'Estimated arrival';
  String get bloodSecured     => isMarathi ? 'रक्त मिळाले' : 'Blood secured';
  String get waitingDispatch  => isMarathi ? 'रक्तपेढी तयारी करत आहे' : 'Blood bank is preparing';
}