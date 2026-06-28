import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this._locale);
  final Locale _locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('fr'),
    Locale('ar'),
    Locale('en'),
  ];

  bool get isArabic => _locale.languageCode == 'ar';

  Map<String, String> get _m {
    switch (_locale.languageCode) {
      case 'ar':
        return _ar;
      case 'fr':
        return _fr;
      default:
        return _en;
    }
  }

  String _t(String k) => _m[k] ?? _en[k] ?? k;

  // ── Global ──────────────────────────────────────────────────────────────────
  String get appName => _t('appName');
  String get appNameAr => 'سهلي';
  String get continueBtn => _t('continueBtn');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get submit => _t('submit');
  String get back => _t('back');
  String get next => _t('next');
  String get loading => _t('loading');
  String get viewAll => _t('viewAll');

  // ── Language screen ─────────────────────────────────────────────────────────
  String get chooseLanguage => _t('chooseLanguage');
  String get languageHint => _t('languageHint');

  // ── Home screen ─────────────────────────────────────────────────────────────
  String get homeGreeting => _t('homeGreeting');
  String get homeSubtitle => _t('homeSubtitle');
  String get reportsNearby => _t('reportsNearby');
  String get reportNow => _t('reportNow');
  String get reportNowSub => _t('reportNowSub');
  String get recentActivity => _t('recentActivity');
  String get noReports => _t('noReports');
  String get totalLabel => _t('totalLabel');
  String get activeLabel => _t('activeLabel');
  String get resolvedLabel => _t('resolvedLabel');
  String get quickReport => _t('quickReport');

  // ── Bottom nav ───────────────────────────────────────────────────────────────
  String get navHome => _t('navHome');
  String get navMyReports => _t('navMyReports');
  String get navAlerts => _t('navAlerts');
  String get navProfile => _t('navProfile');

  // ── Categories ───────────────────────────────────────────────────────────────
  String get catInfrastructure => _t('catInfrastructure');
  String get catInfrastructureSub => _t('catInfrastructureSub');
  String get catLighting => _t('catLighting');
  String get catLightingSub => _t('catLightingSub');
  String get catWaste => _t('catWaste');
  String get catWasteSub => _t('catWasteSub');
  String get catEnvironment => _t('catEnvironment');
  String get catEnvironmentSub => _t('catEnvironmentSub');
  String get catWater => _t('catWater');
  String get catWaterSub => _t('catWaterSub');
  String get catTransport => _t('catTransport');
  String get catTransportSub => _t('catTransportSub');
  String get catSafety => _t('catSafety');
  String get catSafetySub => _t('catSafetySub');

  // ── Report wizard ─────────────────────────────────────────────────────────────
  String get newReport => _t('newReport');
  String get whatReporting => _t('whatReporting');
  String get chooseCategoryHint => _t('chooseCategoryHint');
  String get nextPhoto => _t('nextPhoto');
  String get addPhoto => _t('addPhoto');
  String get addPhotoHint => _t('addPhotoHint');
  String get takePhoto => _t('takePhoto');
  String get fromGallery => _t('fromGallery');
  String get pinLocation => _t('pinLocation');
  String get pinLocationHint => _t('pinLocationHint');
  String get useMyLocation => _t('useMyLocation');
  String get describeIssue => _t('describeIssue');
  String get descriptionHint => _t('descriptionHint');
  String get descriptionTip => _t('descriptionTip');
  String get reviewReport => _t('reviewReport');
  String get reviewReportHint => _t('reviewReportHint');
  String get submitReport => _t('submitReport');
  String get reviewCategory => _t('reviewCategory');
  String get reviewPhoto => _t('reviewPhoto');
  String get reviewLocation => _t('reviewLocation');
  String get reviewDescription => _t('reviewDescription');
  String get confirmTitle => _t('confirmTitle');
  String get confirmSubtitle => _t('confirmSubtitle');
  String get trackStatus => _t('trackStatus');
  String get backToHome => _t('backToHome');

  // ── My Reports ────────────────────────────────────────────────────────────────
  String get myReports => _t('myReports');
  String get filterAll => _t('filterAll');
  String get filterActive => _t('filterActive');
  String get filterResolved => _t('filterResolved');
  String get filterClosed => _t('filterClosed');
  String get noReportsFound => _t('noReportsFound');

  // ── Profile ───────────────────────────────────────────────────────────────────
  String get profile => _t('profile');
  String get recentActivitySection => _t('recentActivitySection');
  String get viewAllReports => _t('viewAllReports');
  String get notifications => _t('notifications');
  String get language => _t('language');
  String get privacyPolicy => _t('privacyPolicy');
  String get helpSupport => _t('helpSupport');
  String get signOut => _t('signOut');

  // ── Onboarding ────────────────────────────────────────────────────────────────
  String get onboardingSkip => _t('onboardingSkip');
  String get onboardingNext => _t('onboardingNext');
  String get onboardingStart => _t('onboardingStart');
  String get ob1Title => _t('ob1Title');
  String get ob1Sub => _t('ob1Sub');
  String get ob2Title => _t('ob2Title');
  String get ob2Sub => _t('ob2Sub');
  String get ob3Title => _t('ob3Title');
  String get ob3Sub => _t('ob3Sub');

  // ── Emergency numbers screen ───────────────────────────────────────────────────
  String get navEmergency => _t('navEmergency');
  String get emergencyTitle => _t('emergencyTitle');
  String get emergencySubtitle => _t('emergencySubtitle');
  String get emergencyAvail => _t('emergencyAvail');
  String get callBtn => _t('callBtn');
  String get callDialogCancel => _t('callDialogCancel');
  String get emergencyCatSOS => _t('emergencyCatSOS');
  String get emergencyCatMedical => _t('emergencyCatMedical');
  String get emergencyCatSocial => _t('emergencyCatSocial');
  String get emergencyCatServices => _t('emergencyCatServices');
  // service names
  String get svcPolice => _t('svcPolice');
  String get svcGardeNationale => _t('svcGardeNationale');
  String get svcSamu => _t('svcSamu');
  String get svcPompiers => _t('svcPompiers');
  String get svcAntiPoison => _t('svcAntiPoison');
  String get svcSosFemmes => _t('svcSosFemmes');
  String get svcEnfance => _t('svcEnfance');
  String get svcSteg => _t('svcSteg');
  String get svcSonede => _t('svcSonede');
  String get svcPoliceMunicipale => _t('svcPoliceMunicipale');
  String get svcNumeroUnique => _t('svcNumeroUnique');
  // service descriptions
  String get svcPoliceDesc => _t('svcPoliceDesc');
  String get svcGardeDesc => _t('svcGardeDesc');
  String get svcSamuDesc => _t('svcSamuDesc');
  String get svcPompiersDesc => _t('svcPompiersDesc');
  String get svcAntiPoisonDesc => _t('svcAntiPoisonDesc');
  String get svcSosFemmesDesc => _t('svcSosFemmesDesc');
  String get svcEnfanceDesc => _t('svcEnfanceDesc');
  String get svcStegDesc => _t('svcStegDesc');
  String get svcSonedeDesc => _t('svcSonedeDesc');
  String get svcPoliceMunicipaleDesc => _t('svcPoliceMunicipaleDesc');
  String get svcNumeroUniqueDesc => _t('svcNumeroUniqueDesc');

  // ── Community / Tunisia dashboard ─────────────────────────────────────────────
  String get communityTitle => _t('communityTitle');
  String get communitySub => _t('communitySub');
  String get liveLabel => _t('liveLabel');
  String get reportsSuffix => _t('reportsSuffix');
  String get resolvedLabel2 => _t('resolvedLabel2');
  String get activeLabel2 => _t('activeLabel2');
  String get tapToReport => _t('tapToReport');

  // ── Notifications ─────────────────────────────────────────────────────────────
  String get notificationsTitle => _t('notificationsTitle');
  String get noNotifications => _t('noNotifications');

  // ── Status ─────────────────────────────────────────────────────────────────────
  String get statusSubmitted => _t('statusSubmitted');
  String get statusReceived => _t('statusReceived');
  String get statusUnderReview => _t('statusUnderReview');
  String get statusInProgress => _t('statusInProgress');
  String get statusResolved => _t('statusResolved');
  String get statusRejected => _t('statusRejected');

  // ── Login ─────────────────────────────────────────────────────────────────────
  String get welcomeBack => _t('welcomeBack');
  String get loginSubtitle => _t('loginSubtitle');
  String get tabPhoneOtp => _t('tabPhoneOtp');
  String get tabEmail => _t('tabEmail');
  String get phoneNumber => _t('phoneNumber');
  String get phoneHint => _t('phoneHint');
  String get enterOtp => _t('enterOtp');
  String get sendOtp => _t('sendOtp');
  String get emailAddress => _t('emailAddress');
  String get password => _t('password');
  String get skipForNow => _t('skipForNow');

  // ── Photo screen ──────────────────────────────────────────────────────────────
  String get tapToTakePhoto => _t('tapToTakePhoto');
  String get orChooseGallery => _t('orChooseGallery');
  String get gallery => _t('gallery');
  String get camera => _t('camera');
  String get nextConfirmLocation => _t('nextConfirmLocation');
  String get skipPhoto => _t('skipPhoto');

  // ── Location screen ───────────────────────────────────────────────────────────
  String get tapMapHint => _t('tapMapHint');
  String get confirmLocation => _t('confirmLocation');

  // ── Description screen ────────────────────────────────────────────────────────
  String get describeIssueSub => _t('describeIssueSub');
  String get descriptionPlaceholder => _t('descriptionPlaceholder');
  String atLeastNChars(int n) => _t('atLeastNChars').replaceAll('{n}', '$n');
  String get tipRoadDamage => _t('tipRoadDamage');
  String get tipFlooding => _t('tipFlooding');
  String get tipBrokenLamp => _t('tipBrokenLamp');
  String get tipTrashOverflow => _t('tipTrashOverflow');
  String get tipNoise => _t('tipNoise');
  String get nextReviewReport => _t('nextReviewReport');

  // ── Review screen ─────────────────────────────────────────────────────────────
  String get edit => _t('edit');
  String get noCategory => _t('noCategory');
  String get photoAttached => _t('photoAttached');
  String get noPhoto => _t('noPhoto');
  String get noDescription => _t('noDescription');
  String get submitDisclaimer => _t('submitDisclaimer');
  String get signInToSubmit => _t('signInToSubmit');
  String get signInReadySub => _t('signInReadySub');
  String get signInAndSubmit => _t('signInAndSubmit');

  // ── Confirmation screen ───────────────────────────────────────────────────────
  String get reportSubmitted => _t('reportSubmitted');
  String get reportSubmittedSub => _t('reportSubmittedSub');
  String get trackingCodeLabel => _t('trackingCodeLabel');
  String get copied => _t('copied');
  String get copyCode => _t('copyCode');
  String get confirmStep1 => _t('confirmStep1');
  String get confirmStep2 => _t('confirmStep2');
  String get confirmStep3 => _t('confirmStep3');
  String get trackMyReport => _t('trackMyReport');

  // ── Report detail ─────────────────────────────────────────────────────────────
  String get reportNotFound => _t('reportNotFound');
  String get retry => _t('retry');
  String get statusTimeline => _t('statusTimeline');
  String get reportFallback => _t('reportFallback');
}

// ═══════════════════════════════════════════════════════════════════════════════
// TRANSLATIONS
// ═══════════════════════════════════════════════════════════════════════════════

const _en = <String, String>{
  'appName': 'Sahali',
  'continueBtn': 'Continue',
  'cancel': 'Cancel',
  'save': 'Save',
  'submit': 'Submit',
  'back': 'Back',
  'next': 'Next',
  'loading': 'Loading…',
  'viewAll': 'View all',

  'chooseLanguage': 'Choose your\nlanguage',
  'languageHint': 'You can change this later in settings.',

  'homeGreeting': 'Hello,',
  'homeSubtitle': 'What needs fixing today?',
  'reportsNearby': 'reports nearby',
  'reportNow': 'Report a Problem',
  'reportNowSub': 'Takes less than 2 minutes',
  'recentActivity': 'Recent Activity',
  'noReports': 'No reports yet',
  'totalLabel': 'Total',
  'activeLabel': 'Active',
  'resolvedLabel': 'Resolved',
  'quickReport': 'Quick Report',

  'navHome': 'Home',
  'navMyReports': 'Reports',
  'navAlerts': 'Alerts',
  'navProfile': 'Profile',

  'catInfrastructure': 'Infrastructure',
  'catInfrastructureSub': 'Roads, sidewalks, signs',
  'catLighting': 'Lighting',
  'catLightingSub': 'Streetlights, wiring',
  'catWaste': 'Waste',
  'catWasteSub': 'Garbage, illegal dumping',
  'catEnvironment': 'Environment',
  'catEnvironmentSub': 'Pollution, trees',
  'catWater': 'Water',
  'catWaterSub': 'Leaks, sewage',
  'catTransport': 'Transport',
  'catTransportSub': 'Bus stops, traffic',
  'catSafety': 'Safety',
  'catSafetySub': 'Hazards, unsafe buildings',

  'newReport': 'New Report',
  'whatReporting': 'What are you reporting?',
  'chooseCategoryHint': 'Choose the category that best matches.',
  'nextPhoto': 'Next — Take a photo',
  'addPhoto': 'Add a Photo',
  'addPhotoHint': 'A clear photo helps the team identify the issue faster.',
  'takePhoto': 'Take Photo',
  'fromGallery': 'From Gallery',
  'pinLocation': 'Pin the Location',
  'pinLocationHint': 'Drag the map or tap to place the pin.',
  'useMyLocation': 'Use my location',
  'describeIssue': 'Describe the Issue',
  'descriptionHint': 'Describe the problem clearly…',
  'descriptionTip': 'Provide specific details to help the team act faster.',
  'reviewReport': 'Review Your Report',
  'reviewReportHint': 'Make sure everything looks correct before submitting.',
  'submitReport': 'Submit Report',
  'reviewCategory': 'Category',
  'reviewPhoto': 'Photo',
  'reviewLocation': 'Location',
  'reviewDescription': 'Description',
  'confirmTitle': 'Report #',
  'confirmSubtitle': 'Your report has been submitted successfully.',
  'trackStatus': 'Track status',
  'backToHome': 'Back to home',

  'myReports': 'My Reports',
  'filterAll': 'All',
  'filterActive': 'Active',
  'filterResolved': 'Resolved',
  'filterClosed': 'Rejected',
  'noReportsFound': 'No reports found',

  'profile': 'Profile',
  'recentActivitySection': 'Recent activity',
  'viewAllReports': 'View all reports',
  'notifications': 'Notifications',
  'language': 'Language',
  'privacyPolicy': 'Privacy Policy',
  'helpSupport': 'Help & Support',
  'signOut': 'Sign Out',

  'navEmergency': 'SOS',
  'emergencyTitle': 'Emergency Numbers',
  'emergencySubtitle': 'Tunisia — 24/7 hotlines',
  'emergencyAvail': 'Available 24 h/24',
  'callBtn': 'Call',
  'callDialogCancel': 'Cancel',
  'emergencyCatSOS': 'Emergency Services',
  'emergencyCatMedical': 'Medical',
  'emergencyCatSocial': 'Social Support',
  'emergencyCatServices': 'Public Services',
  'svcPolice': 'Police Secours',
  'svcGardeNationale': 'Garde Nationale',
  'svcSamu': 'SAMU',
  'svcPompiers': 'Pompiers',
  'svcAntiPoison': 'Anti-Poison Center',
  'svcSosFemmes': 'SOS Femmes',
  'svcEnfance': 'Child Protection',
  'svcSteg': 'STEG',
  'svcSonede': 'SONEDE',
  'svcPoliceMunicipale': 'Municipal Police',
  'svcNumeroUnique': 'Unique Emergency Number',
  'svcPoliceDesc': 'Emergency police response',
  'svcGardeDesc': 'National Guard response',
  'svcSamuDesc': 'Medical emergency / ambulance',
  'svcPompiersDesc': 'Civil protection / fire',
  'svcAntiPoisonDesc': 'Poisoning & toxic emergencies',
  'svcSosFemmesDesc': 'Violence against women helpline',
  'svcEnfanceDesc': 'Child abuse & protection',
  'svcStegDesc': 'Electricity & gas emergency',
  'svcSonedeDesc': 'Water network emergency',
  'svcPoliceMunicipaleDesc': 'City police',
  'svcNumeroUniqueDesc': 'Single national emergency line',

  'communityTitle': 'Tunisia — Dashboard',
  'communitySub': 'National civic reports',
  'liveLabel': 'Live',
  'reportsSuffix': 'reports',
  'resolvedLabel2': 'resolved',
  'activeLabel2': 'active',
  'tapToReport': 'Tap to report an issue',

  'notificationsTitle': 'Notifications',
  'noNotifications': 'No notifications yet',

  'statusSubmitted': 'Submitted',
  'statusReceived': 'Received',
  'statusUnderReview': 'Under Review',
  'statusInProgress': 'In Progress',
  'statusResolved': 'Resolved',
  'statusRejected': 'Rejected',

  'onboardingSkip': 'Skip',
  'onboardingNext': 'Next',
  'onboardingStart': 'Get Started',
  'ob1Title': 'Report in seconds',
  'ob1Sub': 'A photo, a description — your report goes straight to the municipality.',
  'ob2Title': 'Track in real-time',
  'ob2Sub': 'Get notified at every step until your issue is fully resolved.',
  'ob3Title': 'Together for Tunisia',
  'ob3Sub': 'Thousands of Tunisians have already improved their neighborhoods with سهلي.',

  'welcomeBack': 'Welcome back',
  'loginSubtitle': 'Sign in to report issues in your city.',
  'tabPhoneOtp': 'Phone / OTP',
  'tabEmail': 'Email',
  'phoneNumber': 'Phone number',
  'phoneHint': '+216 XX XXX XXX',
  'enterOtp': 'Enter OTP code',
  'sendOtp': 'Send OTP',
  'emailAddress': 'Email address',
  'password': 'Password',
  'skipForNow': 'Skip for now',

  'tapToTakePhoto': 'Tap to take a photo',
  'orChooseGallery': 'or choose from gallery below',
  'gallery': 'Gallery',
  'camera': 'Camera',
  'nextConfirmLocation': 'Next — Confirm location',
  'skipPhoto': 'Skip photo',

  'tapMapHint': 'Tap on the map to pin the exact location of the issue.',
  'confirmLocation': 'Confirm location',

  'describeIssueSub': 'Give as much detail as possible — when it started, how serious it is.',
  'descriptionPlaceholder': 'e.g. There is a large pothole on the main road near the market, it has been there for two weeks and is causing traffic issues…',
  'atLeastNChars': 'At least {n} characters required',
  'tipRoadDamage': 'Road damage',
  'tipFlooding': 'Flooding',
  'tipBrokenLamp': 'Broken lamp',
  'tipTrashOverflow': 'Trash overflow',
  'tipNoise': 'Noise issue',
  'nextReviewReport': 'Next — Review your report',

  'edit': 'Edit',
  'noCategory': 'No category selected',
  'photoAttached': '1 photo attached',
  'noPhoto': 'No photo — tap Edit to add one',
  'noDescription': 'No description — tap Edit to add one',
  'submitDisclaimer': 'By submitting, you confirm this report is accurate. False reports may result in account suspension.',
  'signInToSubmit': 'Sign in to submit',
  'signInReadySub': 'Your report is ready — just sign in to send it.',
  'signInAndSubmit': 'Sign in & submit',

  'reportSubmitted': 'Report submitted!',
  'reportSubmittedSub': 'Your report has been received and will be reviewed by the municipality team.',
  'trackingCodeLabel': 'YOUR TRACKING CODE',
  'copied': 'Copied!',
  'copyCode': 'Copy code',
  'confirmStep1': 'Municipality receives and reviews your report',
  'confirmStep2': 'A team is assigned and begins work',
  'confirmStep3': 'You get notified at every status update',
  'trackMyReport': 'Track my report',

  'reportNotFound': 'Report not found',
  'retry': 'Retry',
  'statusTimeline': 'Status timeline',
  'reportFallback': 'Report',
};

const _fr = <String, String>{
  'appName': 'Sahali',
  'continueBtn': 'Continuer',
  'cancel': 'Annuler',
  'save': 'Enregistrer',
  'submit': 'Soumettre',
  'back': 'Retour',
  'next': 'Suivant',
  'loading': 'Chargement…',
  'viewAll': 'Voir tout',

  'chooseLanguage': 'Choisissez votre\nlangue',
  'languageHint': 'Vous pouvez modifier cela plus tard dans les paramètres.',

  'homeGreeting': 'Bonjour,',
  'homeSubtitle': 'Qu\'est-ce qui nécessite une réparation ?',
  'reportsNearby': 'signalements à proximité',
  'reportNow': 'Signaler un problème',
  'reportNowSub': 'Moins de 2 minutes',
  'recentActivity': 'Activité récente',
  'noReports': 'Aucun signalement',
  'totalLabel': 'Total',
  'activeLabel': 'Actifs',
  'resolvedLabel': 'Résolus',
  'quickReport': 'Signalement rapide',

  'navHome': 'Accueil',
  'navMyReports': 'Rapports',
  'navAlerts': 'Alertes',
  'navProfile': 'Profil',

  'catInfrastructure': 'Infrastructure',
  'catInfrastructureSub': 'Routes, trottoirs, panneaux',
  'catLighting': 'Éclairage',
  'catLightingSub': 'Lampadaires, câblage',
  'catWaste': 'Déchets',
  'catWasteSub': 'Ordures, dépôts sauvages',
  'catEnvironment': 'Environnement',
  'catEnvironmentSub': 'Pollution, arbres',
  'catWater': 'Eau',
  'catWaterSub': 'Fuites, égouts',
  'catTransport': 'Transport',
  'catTransportSub': 'Arrêts de bus, circulation',
  'catSafety': 'Sécurité',
  'catSafetySub': 'Risques, bâtiments dangereux',

  'newReport': 'Nouveau signalement',
  'whatReporting': 'Que signalez-vous ?',
  'chooseCategoryHint': 'Choisissez la catégorie qui correspond le mieux.',
  'nextPhoto': 'Suivant — Prendre une photo',
  'addPhoto': 'Ajouter une photo',
  'addPhotoHint': 'Une photo claire aide l\'équipe à identifier le problème plus rapidement.',
  'takePhoto': 'Prendre une photo',
  'fromGallery': 'Depuis la galerie',
  'pinLocation': 'Épingler l\'emplacement',
  'pinLocationHint': 'Faites glisser la carte ou appuyez pour placer l\'épingle.',
  'useMyLocation': 'Utiliser ma position',
  'describeIssue': 'Décrire le problème',
  'descriptionHint': 'Décrivez le problème clairement…',
  'descriptionTip': 'Fournissez des détails précis pour aider l\'équipe à agir plus vite.',
  'reviewReport': 'Vérifier votre signalement',
  'reviewReportHint': 'Assurez-vous que tout est correct avant de soumettre.',
  'submitReport': 'Soumettre le signalement',
  'reviewCategory': 'Catégorie',
  'reviewPhoto': 'Photo',
  'reviewLocation': 'Emplacement',
  'reviewDescription': 'Description',
  'confirmTitle': 'Signalement n°',
  'confirmSubtitle': 'Votre signalement a été soumis avec succès.',
  'trackStatus': 'Suivre le statut',
  'backToHome': 'Retour à l\'accueil',

  'myReports': 'Mes signalements',
  'filterAll': 'Tous',
  'filterActive': 'Actifs',
  'filterResolved': 'Résolus',
  'filterClosed': 'Rejetés',
  'noReportsFound': 'Aucun signalement trouvé',

  'profile': 'Profil',
  'recentActivitySection': 'Activité récente',
  'viewAllReports': 'Voir tous les signalements',
  'notifications': 'Notifications',
  'language': 'Langue',
  'privacyPolicy': 'Politique de confidentialité',
  'helpSupport': 'Aide & Support',
  'signOut': 'Déconnexion',

  'navEmergency': 'SOS',
  'emergencyTitle': 'Numéros d\'urgence',
  'emergencySubtitle': 'Tunisie — Lignes d\'urgence 24h/24',
  'emergencyAvail': 'Disponible 24 h/24',
  'callBtn': 'Appeler',
  'callDialogCancel': 'Annuler',
  'emergencyCatSOS': 'Services d\'urgence',
  'emergencyCatMedical': 'Médical',
  'emergencyCatSocial': 'Soutien social',
  'emergencyCatServices': 'Services publics',
  'svcPolice': 'Police Secours',
  'svcGardeNationale': 'Garde Nationale',
  'svcSamu': 'SAMU',
  'svcPompiers': 'Pompiers',
  'svcAntiPoison': 'Centre Anti-Poison',
  'svcSosFemmes': 'SOS Femmes',
  'svcEnfance': 'Protection de l\'enfance',
  'svcSteg': 'STEG',
  'svcSonede': 'SONEDE',
  'svcPoliceMunicipale': 'Police Municipale',
  'svcNumeroUnique': 'Numéro unique d\'urgence',
  'svcPoliceDesc': 'Intervention d\'urgence policière',
  'svcGardeDesc': 'Intervention de la garde nationale',
  'svcSamuDesc': 'Urgence médicale / ambulance',
  'svcPompiersDesc': 'Protection civile / incendie',
  'svcAntiPoisonDesc': 'Intoxications et urgences toxiques',
  'svcSosFemmesDesc': 'Ligne d\'écoute violences femmes',
  'svcEnfanceDesc': 'Maltraitance et protection enfants',
  'svcStegDesc': 'Urgence électricité et gaz',
  'svcSonedeDesc': 'Urgence réseau d\'eau',
  'svcPoliceMunicipaleDesc': 'Police de la ville',
  'svcNumeroUniqueDesc': 'Ligne nationale unique d\'urgence',

  'communityTitle': 'Tunisie — Tableau de bord',
  'communitySub': 'Signalements citoyens nationaux',
  'liveLabel': 'Live',
  'reportsSuffix': 'signalements',
  'resolvedLabel2': 'résolus',
  'activeLabel2': 'actifs',
  'tapToReport': 'Appuyez pour signaler un problème',

  'notificationsTitle': 'Notifications',
  'noNotifications': 'Aucune notification',

  'statusSubmitted': 'Soumis',
  'statusReceived': 'Reçu',
  'statusUnderReview': 'En examen',
  'statusInProgress': 'En cours',
  'statusResolved': 'Résolu',
  'statusRejected': 'Rejeté',

  'onboardingSkip': 'Passer',
  'onboardingNext': 'Suivant',
  'onboardingStart': 'Commencer',
  'ob1Title': 'Signalez en quelques secondes',
  'ob1Sub': 'Une photo, une description — votre signalement est transmis instantanément à la municipalité.',
  'ob2Title': 'Suivez la résolution',
  'ob2Sub': 'Recevez des notifications à chaque étape jusqu\'à la résolution complète.',
  'ob3Title': 'Ensemble pour la Tunisie',
  'ob3Sub': 'Des milliers de Tunisiens ont déjà amélioré leur quartier grâce à سهلي.',

  'welcomeBack': 'Bon retour',
  'loginSubtitle': 'Connectez-vous pour signaler des problèmes dans votre ville.',
  'tabPhoneOtp': 'Téléphone / OTP',
  'tabEmail': 'E-mail',
  'phoneNumber': 'Numéro de téléphone',
  'phoneHint': '+216 XX XXX XXX',
  'enterOtp': 'Entrez le code OTP',
  'sendOtp': 'Envoyer OTP',
  'emailAddress': 'Adresse e-mail',
  'password': 'Mot de passe',
  'skipForNow': 'Passer pour l\'instant',

  'tapToTakePhoto': 'Appuyez pour prendre une photo',
  'orChooseGallery': 'ou choisissez dans la galerie ci-dessous',
  'gallery': 'Galerie',
  'camera': 'Caméra',
  'nextConfirmLocation': 'Suivant — Confirmer l\'emplacement',
  'skipPhoto': 'Passer la photo',

  'tapMapHint': 'Appuyez sur la carte pour épingler l\'emplacement exact du problème.',
  'confirmLocation': 'Confirmer l\'emplacement',

  'describeIssueSub': 'Donnez autant de détails que possible — quand ça a commencé, à quel point c\'est grave.',
  'descriptionPlaceholder': 'ex. Il y a un grand nid-de-poule sur la route principale près du marché, il est là depuis deux semaines et cause des problèmes de circulation…',
  'atLeastNChars': 'Au moins {n} caractères requis',
  'tipRoadDamage': 'Dégâts routiers',
  'tipFlooding': 'Inondation',
  'tipBrokenLamp': 'Lampe cassée',
  'tipTrashOverflow': 'Débordement de déchets',
  'tipNoise': 'Problème de bruit',
  'nextReviewReport': 'Suivant — Vérifier votre signalement',

  'edit': 'Modifier',
  'noCategory': 'Aucune catégorie sélectionnée',
  'photoAttached': '1 photo jointe',
  'noPhoto': 'Pas de photo — appuyez sur Modifier pour en ajouter une',
  'noDescription': 'Pas de description — appuyez sur Modifier pour en ajouter une',
  'submitDisclaimer': 'En soumettant, vous confirmez que ce signalement est exact. Les signalements abusifs peuvent entraîner la suspension du compte.',
  'signInToSubmit': 'Connexion pour soumettre',
  'signInReadySub': 'Votre signalement est prêt — connectez-vous pour l\'envoyer.',
  'signInAndSubmit': 'Connexion & soumettre',

  'reportSubmitted': 'Signalement soumis !',
  'reportSubmittedSub': 'Votre signalement a été reçu et sera examiné par l\'équipe municipale.',
  'trackingCodeLabel': 'VOTRE CODE DE SUIVI',
  'copied': 'Copié !',
  'copyCode': 'Copier le code',
  'confirmStep1': 'La municipalité reçoit et examine votre signalement',
  'confirmStep2': 'Une équipe est assignée et commence le travail',
  'confirmStep3': 'Vous êtes notifié à chaque mise à jour de statut',
  'trackMyReport': 'Suivre mon signalement',

  'reportNotFound': 'Signalement introuvable',
  'retry': 'Réessayer',
  'statusTimeline': 'Historique du statut',
  'reportFallback': 'Signalement',
};

const _ar = <String, String>{
  'appName': 'سهلي',
  'continueBtn': 'متابعة',
  'cancel': 'إلغاء',
  'save': 'حفظ',
  'submit': 'إرسال',
  'back': 'رجوع',
  'next': 'التالي',
  'loading': 'جارٍ التحميل…',
  'viewAll': 'عرض الكل',

  'chooseLanguage': 'اختر لغتك',
  'languageHint': 'يمكنك تغيير هذا لاحقاً في الإعدادات.',

  'homeGreeting': 'أهلاً،',
  'homeSubtitle': 'ما الذي يحتاج إصلاحاً اليوم؟',
  'reportsNearby': 'تقارير قريبة',
  'reportNow': 'أبلّغ عن مشكلة',
  'reportNowSub': 'أقل من دقيقتين',
  'recentActivity': 'النشاط الأخير',
  'noReports': 'لا توجد تقارير بعد',
  'totalLabel': 'الإجمالي',
  'activeLabel': 'نشطة',
  'resolvedLabel': 'محلولة',
  'quickReport': 'تبليغ سريع',

  'navHome': 'الرئيسية',
  'navMyReports': 'تقاريري',
  'navAlerts': 'التنبيهات',
  'navProfile': 'ملفي',

  'catInfrastructure': 'البنية التحتية',
  'catInfrastructureSub': 'طرق، أرصفة، لافتات',
  'catLighting': 'الإضاءة',
  'catLightingSub': 'أعمدة الإنارة، الأسلاك',
  'catWaste': 'النفايات',
  'catWasteSub': 'قمامة، رمي عشوائي',
  'catEnvironment': 'البيئة',
  'catEnvironmentSub': 'تلوث، أشجار',
  'catWater': 'المياه',
  'catWaterSub': 'تسربات، صرف صحي',
  'catTransport': 'النقل',
  'catTransportSub': 'محطات الحافلات، المرور',
  'catSafety': 'السلامة',
  'catSafetySub': 'مخاطر، مبانٍ غير آمنة',

  'newReport': 'تقرير جديد',
  'whatReporting': 'عمَّ تريد الإبلاغ؟',
  'chooseCategoryHint': 'اختر الفئة الأنسب.',
  'nextPhoto': 'التالي — التقاط صورة',
  'addPhoto': 'أضف صورة',
  'addPhotoHint': 'الصورة الواضحة تساعد الفريق على تحديد المشكلة بسرعة.',
  'takePhoto': 'التقاط صورة',
  'fromGallery': 'من المعرض',
  'pinLocation': 'حدد الموقع',
  'pinLocationHint': 'اسحب الخريطة أو اضغط لتحديد الدبوس.',
  'useMyLocation': 'استخدام موقعي',
  'describeIssue': 'صف المشكلة',
  'descriptionHint': 'صف المشكلة بوضوح…',
  'descriptionTip': 'قدّم تفاصيل دقيقة لمساعدة الفريق على التصرف أسرع.',
  'reviewReport': 'مراجعة التقرير',
  'reviewReportHint': 'تأكد من صحة المعلومات قبل الإرسال.',
  'submitReport': 'إرسال التقرير',
  'reviewCategory': 'الفئة',
  'reviewPhoto': 'الصورة',
  'reviewLocation': 'الموقع',
  'reviewDescription': 'الوصف',
  'confirmTitle': 'التقرير رقم ',
  'confirmSubtitle': 'تم إرسال تقريرك بنجاح.',
  'trackStatus': 'تتبع الحالة',
  'backToHome': 'العودة للرئيسية',

  'myReports': 'تقاريري',
  'filterAll': 'الكل',
  'filterActive': 'نشطة',
  'filterResolved': 'محلولة',
  'filterClosed': 'مرفوضة',
  'noReportsFound': 'لا توجد تقارير',

  'profile': 'الملف الشخصي',
  'recentActivitySection': 'النشاط الأخير',
  'viewAllReports': 'عرض جميع التقارير',
  'notifications': 'الإشعارات',
  'language': 'اللغة',
  'privacyPolicy': 'سياسة الخصوصية',
  'helpSupport': 'المساعدة والدعم',
  'signOut': 'تسجيل الخروج',

  'navEmergency': 'SOS',
  'emergencyTitle': 'أرقام الطوارئ',
  'emergencySubtitle': 'تونس — خطوط الطوارئ 24/24',
  'emergencyAvail': 'متاح 24 ساعة',
  'callBtn': 'اتصال',
  'callDialogCancel': 'إلغاء',
  'emergencyCatSOS': 'خدمات الطوارئ',
  'emergencyCatMedical': 'طبي',
  'emergencyCatSocial': 'الدعم الاجتماعي',
  'emergencyCatServices': 'الخدمات العامة',
  'svcPolice': 'شرطة النجدة',
  'svcGardeNationale': 'الحرس الوطني',
  'svcSamu': 'سمو / الإسعاف',
  'svcPompiers': 'الحماية المدنية',
  'svcAntiPoison': 'مركز مكافحة السموم',
  'svcSosFemmes': 'SOS المرأة',
  'svcEnfance': 'حماية الطفولة',
  'svcSteg': 'الشركة التونسية للكهرباء والغاز',
  'svcSonede': 'الشركة الوطنية لاستغلال المياه',
  'svcPoliceMunicipale': 'الشرطة البلدية',
  'svcNumeroUnique': 'رقم الطوارئ الموحد',
  'svcPoliceDesc': 'تدخل الشرطة في حالات الطوارئ',
  'svcGardeDesc': 'تدخل الحرس الوطني',
  'svcSamuDesc': 'طوارئ طبية / سيارة إسعاف',
  'svcPompiersDesc': 'الحماية المدنية / الحرائق',
  'svcAntiPoisonDesc': 'حالات التسمم والسموم',
  'svcSosFemmesDesc': 'خط الاستماع للعنف ضد المرأة',
  'svcEnfanceDesc': 'إساءة وحماية الأطفال',
  'svcStegDesc': 'طوارئ الكهرباء والغاز',
  'svcSonedeDesc': 'طوارئ شبكة المياه',
  'svcPoliceMunicipaleDesc': 'شرطة المدينة',
  'svcNumeroUniqueDesc': 'الخط الوطني الموحد للطوارئ',

  'communityTitle': 'تونس — لوحة المتابعة',
  'communitySub': 'التقارير المدنية الوطنية',
  'liveLabel': 'مباشر',
  'reportsSuffix': 'تقرير',
  'resolvedLabel2': 'محلول',
  'activeLabel2': 'نشط',
  'tapToReport': 'اضغط للإبلاغ عن مشكلة',

  'notificationsTitle': 'الإشعارات',
  'noNotifications': 'لا توجد إشعارات',

  'statusSubmitted': 'مُقدَّم',
  'statusReceived': 'مستلم',
  'statusUnderReview': 'قيد المراجعة',
  'statusInProgress': 'قيد التنفيذ',
  'statusResolved': 'محلول',
  'statusRejected': 'مرفوض',

  'onboardingSkip': 'تخطي',
  'onboardingNext': 'التالي',
  'onboardingStart': 'ابدأ الآن',
  'ob1Title': 'أبلّغ في ثوانٍ',
  'ob1Sub': 'صورة وبضع كلمات — تقريرك يصل فوراً إلى البلدية.',
  'ob2Title': 'تتبع في الوقت الفعلي',
  'ob2Sub': 'احصل على إشعارات في كل خطوة حتى حل مشكلتك بالكامل.',
  'ob3Title': 'معاً من أجل تونس',
  'ob3Sub': 'آلاف التونسيين حسّنوا أحياءهم بالفعل بفضل سهلي.',

  'welcomeBack': 'مرحباً بعودتك',
  'loginSubtitle': 'سجّل دخولك للإبلاغ عن مشاكل في مدينتك.',
  'tabPhoneOtp': 'الهاتف / OTP',
  'tabEmail': 'البريد الإلكتروني',
  'phoneNumber': 'رقم الهاتف',
  'phoneHint': '+216 XX XXX XXX',
  'enterOtp': 'أدخل رمز OTP',
  'sendOtp': 'إرسال OTP',
  'emailAddress': 'عنوان البريد الإلكتروني',
  'password': 'كلمة المرور',
  'skipForNow': 'تخطي الآن',

  'tapToTakePhoto': 'اضغط للتقاط صورة',
  'orChooseGallery': 'أو اختر من المعرض أدناه',
  'gallery': 'المعرض',
  'camera': 'الكاميرا',
  'nextConfirmLocation': 'التالي — تأكيد الموقع',
  'skipPhoto': 'تخطي الصورة',

  'tapMapHint': 'اضغط على الخريطة لتثبيت الموقع الدقيق للمشكلة.',
  'confirmLocation': 'تأكيد الموقع',

  'describeIssueSub': 'قدّم أكبر قدر ممكن من التفاصيل — متى بدأ، ومدى خطورته.',
  'descriptionPlaceholder': 'مثال: يوجد حفرة كبيرة في الطريق الرئيسي بالقرب من السوق، وهي موجودة منذ أسبوعين وتسبب مشاكل في حركة المرور…',
  'atLeastNChars': 'مطلوب {n} حرفاً على الأقل',
  'tipRoadDamage': 'تلف الطريق',
  'tipFlooding': 'فيضان',
  'tipBrokenLamp': 'مصباح مكسور',
  'tipTrashOverflow': 'فيضان القمامة',
  'tipNoise': 'مشكلة ضوضاء',
  'nextReviewReport': 'التالي — مراجعة تقريرك',

  'edit': 'تعديل',
  'noCategory': 'لم يتم اختيار فئة',
  'photoAttached': 'صورة واحدة مرفقة',
  'noPhoto': 'لا توجد صورة — اضغط تعديل لإضافة واحدة',
  'noDescription': 'لا يوجد وصف — اضغط تعديل لإضافة واحد',
  'submitDisclaimer': 'بالإرسال، تؤكد أن هذا التقرير دقيق. قد تؤدي التقارير الكاذبة إلى تعليق الحساب.',
  'signInToSubmit': 'سجّل الدخول للإرسال',
  'signInReadySub': 'تقريرك جاهز — سجّل دخولك لإرساله.',
  'signInAndSubmit': 'تسجيل الدخول والإرسال',

  'reportSubmitted': 'تم إرسال التقرير!',
  'reportSubmittedSub': 'تم استلام تقريرك وسيتم مراجعته من قبل فريق البلدية.',
  'trackingCodeLabel': 'رمز التتبع الخاص بك',
  'copied': 'تم النسخ!',
  'copyCode': 'نسخ الرمز',
  'confirmStep1': 'تستلم البلدية تقريرك وتراجعه',
  'confirmStep2': 'يتم تعيين فريق ويبدأ العمل',
  'confirmStep3': 'تتلقى إشعاراً عند كل تحديث للحالة',
  'trackMyReport': 'تتبع تقريري',

  'reportNotFound': 'التقرير غير موجود',
  'retry': 'إعادة المحاولة',
  'statusTimeline': 'سجل الحالة',
  'reportFallback': 'تقرير',
};

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_) => false;
}
