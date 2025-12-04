import 'package:flutter/material.dart';

/// App Localizations - Comprehensive translation support
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Comprehensive translations for driver app
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'app_name': 'Drivio',
      'welcome': 'Welcome',
      'settings': 'Settings',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',
      'save': 'Save',
      'cancel': 'Cancel',
      'ok': 'OK',
      'error': 'Error',
      'success': 'Success',
      'close': 'Close',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'remove': 'Remove',
      'yes': 'Yes',
      'no': 'No',

      // Navigation & Menu
      'home': 'Home',
      'inbox': 'Inbox',
      'refer_friends': 'Refer Friends',
      'opportunities': 'Opportunities',
      'earnings': 'Earnings',
      'services': 'Services',
      'wallet': 'Wallet',
      'account': 'Account',
      'help': 'Help',
      'learning_center': 'Learning Center',
      'log_out': 'Log out',
      'profile': 'Profile',

      // Driver Status
      'online': 'Online',
      'offline': 'Offline',
      'active': 'Active',
      'inactive': 'Inactive',
      'available': 'Available',
      'busy': 'Busy',
      'go_online': 'Go Online',
      'go_offline': 'Go Offline',
      'youre_online': "You're Online",
      'youre_offline': "You're Offline",

      // Trip & Ride
      'trip': 'Trip',
      'ride': 'Ride',
      'passenger': 'Passenger',
      'pickup': 'Pickup',
      'dropoff': 'Drop-off',
      'destination': 'Destination',
      'distance': 'Distance',
      'duration': 'Duration',
      'fare': 'Fare',
      'accept': 'Accept',
      'decline': 'Decline',
      'start_trip': 'Start Trip',
      'end_trip': 'End Trip',
      'cancel_trip': 'Cancel Trip',
      'navigate': 'Navigate',
      'arrived': 'Arrived',
      'complete': 'Complete',
      'ride_requests': 'Ride Requests',
      'new_ride_request': 'New Ride Request',
      'no_ride_requests': 'No ride requests available',

      // Earnings
      'total_earnings': 'Total Earnings',
      'today_earnings': "Today's Earnings",
      'this_week': 'This Week',
      'this_month': 'This Month',
      'cash': 'Cash',
      'bank_transfer': 'Bank Transfer',
      'other': 'Other',
      'points': 'Points',
      'payout': 'Payout',
      'balance': 'Balance',
      'withdraw': 'Withdraw',
      'payment_method': 'Payment Method',

      // Wallet
      'wallet_balance': 'Wallet Balance',
      'transaction_history': 'Transaction History',
      'add_funds': 'Add Funds',
      'link_payment': 'Link Payment Method',
      'payout_history': 'Payout History',

      // Account & Profile
      'personal_info': 'Personal Information',
      'vehicle_info': 'Vehicle Information',
      'documents': 'Documents',
      'payment_settings': 'Payment Settings',
      'preferences': 'Preferences',
      'name': 'Name',
      'email': 'Email',
      'phone': 'Phone',
      'address': 'Address',
      'city': 'City',
      'country': 'Country',

      // Vehicle
      'vehicle': 'Vehicle',
      'make': 'Make',
      'model': 'Model',
      'year': 'Year',
      'color': 'Color',
      'license_plate': 'License Plate',
      'vehicle_type': 'Vehicle Type',

      // Settings
      'app_settings': 'App Settings',
      'appearance': 'Appearance',
      'sound': 'Sound',
      'vibration': 'Vibration',
      'location_services': 'Location Services',
      'privacy': 'Privacy',
      'terms_of_service': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',
      'app_version': 'App Version',
      'push_notifications': 'Push Notifications',

      // Messages & Snackbars
      'language_changed': 'Language changed to',
      'dark_mode_enabled': 'Dark mode enabled',
      'light_mode_enabled': 'Light mode enabled',
      'failed_to_update': 'Failed to update',
      'trip_started': 'Trip started',
      'trip_ended': 'Trip ended',
      'trip_cancelled': 'Trip cancelled',
      'ride_accepted': 'Ride accepted',
      'ride_declined': 'Ride declined',
      'going_online': 'Going online...',
      'going_offline': 'Going offline...',
      'now_online': 'You are now online',
      'now_offline': 'You are now offline',
      'error_occurred': 'An error occurred',
      'please_try_again': 'Please try again',
      'no_internet': 'No internet connection',
      'location_permission_required': 'Location permission required',
      'enable_location': 'Please enable location services',

      // Dialogs
      'confirm_cancel_trip': 'Are you sure you want to cancel this trip?',
      'confirm_go_offline': 'Are you sure you want to go offline?',
      'confirm_logout': 'Are you sure you want to log out?',
      'select_language': 'Select Language',
      'select_payment_method': 'Select Payment Method',

      // Empty States
      'no_trips': 'No trips yet',
      'no_earnings': 'No earnings yet',
      'no_transactions': 'No transactions yet',
      'no_notifications': 'No notifications',

      // Referral
      'your_earnings': 'Your Earnings',
      'total_earned': 'Total Earned',
      'pending': 'Pending',
      'referrals': 'Referrals',
      'your_referral_code': 'Your Referral Code',
      'loading': 'Loading...',
      'copy_code': 'Copy code',
      'share_code': 'Share Code',
      'how_it_works': 'How It Works',
      'share_your_code': 'Share your code',
      'share_your_code_desc':
          'Send your referral code to friends via text, email, or social media.',
      'friend_signs_up': 'Friend signs up',
      'friend_signs_up_desc':
          'Your friend creates an account using your referral code.',
      'earn_rewards': 'Earn rewards',
      'earn_rewards_desc':
          'Get points when they sign up, and cash rewards as they complete rides!',
      'reward_milestones': 'Reward Milestones',
      'sign_up': 'Sign up',
      'first_ride': '1st ride',
      'rides': 'rides',
      'referral_history': 'Referral History',
      'no_referrals_yet': 'No referrals yet',
      'start_sharing': 'Start sharing your code!',
      'rides_completed': 'rides completed',
      'referral_code_copied': 'Referral code copied to clipboard!',
      'join_drivio_message': 'Join Drivio using my referral code:',
      'and_earn_rewards': 'and earn rewards! Download the app now.',
      'pending_signup': 'Pending signup',
    },
    'fr': {
      // Common
      'app_name': 'Drivio',
      'welcome': 'Bienvenue',
      'settings': 'Paramètres',
      'language': 'Langue',
      'dark_mode': 'Mode Sombre',
      'notifications': 'Notifications',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'ok': 'OK',
      'error': 'Erreur',
      'success': 'Succès',
      'close': 'Fermer',
      'confirm': 'Confirmer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'add': 'Ajouter',
      'remove': 'Retirer',
      'yes': 'Oui',
      'no': 'Non',

      // Navigation & Menu
      'home': 'Accueil',
      'inbox': 'Boîte de réception',
      'refer_friends': 'Parrainer des amis',
      'opportunities': 'Opportunités',
      'earnings': 'Gains',
      'services': 'Services',
      'wallet': 'Portefeuille',
      'account': 'Compte',
      'help': 'Aide',
      'learning_center': 'Centre d\'apprentissage',
      'log_out': 'Se déconnecter',
      'profile': 'Profil',

      // Driver Status
      'online': 'En ligne',
      'offline': 'Hors ligne',
      'active': 'Actif',
      'inactive': 'Inactif',
      'available': 'Disponible',
      'busy': 'Occupé',
      'go_online': 'Se mettre en ligne',
      'go_offline': 'Se mettre hors ligne',
      'youre_online': 'Vous êtes en ligne',
      'youre_offline': 'Vous êtes hors ligne',

      // Trip & Ride
      'trip': 'Course',
      'ride': 'Trajet',
      'passenger': 'Passager',
      'pickup': 'Prise en charge',
      'dropoff': 'Dépose',
      'destination': 'Destination',
      'distance': 'Distance',
      'duration': 'Durée',
      'fare': 'Tarif',
      'accept': 'Accepter',
      'decline': 'Refuser',
      'start_trip': 'Démarrer la course',
      'end_trip': 'Terminer la course',
      'cancel_trip': 'Annuler la course',
      'navigate': 'Naviguer',
      'arrived': 'Arrivé',
      'complete': 'Terminer',
      'ride_requests': 'Demandes de course',
      'new_ride_request': 'Nouvelle demande',
      'no_ride_requests': 'Aucune demande disponible',

      // Earnings
      'total_earnings': 'Gains totaux',
      'today_earnings': 'Gains d\'aujourd\'hui',
      'this_week': 'Cette semaine',
      'this_month': 'Ce mois',
      'cash': 'Espèces',
      'bank_transfer': 'Virement bancaire',
      'other': 'Autre',
      'points': 'Points',
      'payout': 'Paiement',
      'balance': 'Solde',
      'withdraw': 'Retirer',
      'payment_method': 'Méthode de paiement',

      // Wallet
      'wallet_balance': 'Solde du portefeuille',
      'transaction_history': 'Historique des transactions',
      'add_funds': 'Ajouter des fonds',
      'link_payment': 'Lier un moyen de paiement',
      'payout_history': 'Historique des paiements',

      // Account & Profile
      'personal_info': 'Informations personnelles',
      'vehicle_info': 'Informations du véhicule',
      'documents': 'Documents',
      'payment_settings': 'Paramètres de paiement',
      'preferences': 'Préférences',
      'name': 'Nom',
      'email': 'Email',
      'phone': 'Téléphone',
      'address': 'Adresse',
      'city': 'Ville',
      'country': 'Pays',

      // Vehicle
      'vehicle': 'Véhicule',
      'make': 'Marque',
      'model': 'Modèle',
      'year': 'Année',
      'color': 'Couleur',
      'license_plate': 'Plaque d\'immatriculation',
      'vehicle_type': 'Type de véhicule',

      // Settings
      'app_settings': 'Paramètres de l\'application',
      'appearance': 'Apparence',
      'sound': 'Son',
      'vibration': 'Vibration',
      'location_services': 'Services de localisation',
      'privacy': 'Confidentialité',
      'terms_of_service': 'Conditions d\'utilisation',
      'privacy_policy': 'Politique de confidentialité',
      'app_version': 'Version de l\'application',
      'push_notifications': 'Notifications push',

      // Messages & Snackbars
      'language_changed': 'Langue changée en',
      'dark_mode_enabled': 'Mode sombre activé',
      'light_mode_enabled': 'Mode clair activé',
      'failed_to_update': 'Échec de la mise à jour',
      'trip_started': 'Course démarrée',
      'trip_ended': 'Course terminée',
      'trip_cancelled': 'Course annulée',
      'ride_accepted': 'Course acceptée',
      'ride_declined': 'Course refusée',
      'going_online': 'Mise en ligne...',
      'going_offline': 'Mise hors ligne...',
      'now_online': 'Vous êtes maintenant en ligne',
      'now_offline': 'Vous êtes maintenant hors ligne',
      'error_occurred': 'Une erreur s\'est produite',
      'please_try_again': 'Veuillez réessayer',
      'no_internet': 'Pas de connexion Internet',
      'location_permission_required': 'Permission de localisation requise',
      'enable_location': 'Veuillez activer les services de localisation',

      // Dialogs
      'confirm_cancel_trip': 'Êtes-vous sûr de vouloir annuler cette course?',
      'confirm_go_offline': 'Êtes-vous sûr de vouloir vous mettre hors ligne?',
      'confirm_logout': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'select_language': 'Sélectionner la langue',
      'select_payment_method': 'Sélectionner le mode de paiement',

      // Empty States
      'no_trips': 'Aucune course',
      'no_earnings': 'Aucun gain',
      'no_transactions': 'Aucune transaction',
      'no_notifications': 'Aucune notification',

      // Referral
      'your_earnings': 'Vos gains',
      'total_earned': 'Total gagné',
      'pending': 'En attente',
      'referrals': 'Parrainages',
      'your_referral_code': 'Votre code de parrainage',
      'loading': 'Chargement...',
      'copy_code': 'Copier le code',
      'share_code': 'Partager le code',
      'how_it_works': 'Comment ça marche',
      'share_your_code': 'Partagez votre code',
      'share_your_code_desc':
          'Envoyez votre code de parrainage à vos amis par SMS, email ou réseaux sociaux.',
      'friend_signs_up': 'Votre ami s\'inscrit',
      'friend_signs_up_desc':
          'Votre ami crée un compte en utilisant votre code de parrainage.',
      'earn_rewards': 'Gagnez des récompenses',
      'earn_rewards_desc':
          'Obtenez des points lors de leur inscription et des récompenses en cash quand ils complètent des courses!',
      'reward_milestones': 'Paliers de récompenses',
      'sign_up': 'Inscription',
      'first_ride': '1ère course',
      'rides': 'courses',
      'referral_history': 'Historique des parrainages',
      'no_referrals_yet': 'Aucun parrainage',
      'start_sharing': 'Commencez à partager votre code!',
      'rides_completed': 'courses complétées',
      'referral_code_copied': 'Code de parrainage copié!',
      'join_drivio_message': 'Rejoignez Drivio avec mon code de parrainage:',
      'and_earn_rewards':
          'et gagnez des récompenses! Téléchargez l\'app maintenant.',
      'pending_signup': 'Inscription en attente',
    },
    'ar': {
      // Common
      'app_name': 'دريفيو',
      'welcome': 'مرحبا',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'dark_mode': 'الوضع الداكن',
      'notifications': 'الإشعارات',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'ok': 'موافق',
      'error': 'خطأ',
      'success': 'نجاح',
      'close': 'إغلاق',
      'confirm': 'تأكيد',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'remove': 'إزالة',
      'yes': 'نعم',
      'no': 'لا',

      // Navigation & Menu
      'home': 'الرئيسية',
      'inbox': 'البريد الوارد',
      'refer_friends': 'دعوة الأصدقاء',
      'opportunities': 'الفرص',
      'earnings': 'الأرباح',
      'services': 'الخدمات',
      'wallet': 'المحفظة',
      'account': 'الحساب',
      'help': 'المساعدة',
      'learning_center': 'مركز التعلم',
      'log_out': 'تسجيل الخروج',
      'profile': 'الملف الشخصي',

      // Driver Status
      'online': 'متصل',
      'offline': 'غير متصل',
      'active': 'نشط',
      'inactive': 'غير نشط',
      'available': 'متاح',
      'busy': 'مشغول',
      'go_online': 'الاتصال',
      'go_offline': 'قطع الاتصال',
      'youre_online': 'أنت متصل',
      'youre_offline': 'أنت غير متصل',

      // Trip & Ride
      'trip': 'رحلة',
      'ride': 'توصيلة',
      'passenger': 'راكب',
      'pickup': 'نقطة الانطلاق',
      'dropoff': 'نقطة الوصول',
      'destination': 'الوجهة',
      'distance': 'المسافة',
      'duration': 'المدة',
      'fare': 'الأجرة',
      'accept': 'قبول',
      'decline': 'رفض',
      'start_trip': 'بدء الرحلة',
      'end_trip': 'إنهاء الرحلة',
      'cancel_trip': 'إلغاء الرحلة',
      'navigate': 'التنقل',
      'arrived': 'وصلت',
      'complete': 'إكمال',
      'ride_requests': 'طلبات الرحلات',
      'new_ride_request': 'طلب رحلة جديد',
      'no_ride_requests': 'لا توجد طلبات متاحة',

      // Earnings
      'total_earnings': 'إجمالي الأرباح',
      'today_earnings': 'أرباح اليوم',
      'this_week': 'هذا الأسبوع',
      'this_month': 'هذا الشهر',
      'cash': 'نقدي',
      'bank_transfer': 'تحويل بنكي',
      'other': 'أخرى',
      'points': 'نقاط',
      'payout': 'دفع',
      'balance': 'الرصيد',
      'withdraw': 'سحب',
      'payment_method': 'طريقة الدفع',

      // Wallet
      'wallet_balance': 'رصيد المحفظة',
      'transaction_history': 'سجل المعاملات',
      'add_funds': 'إضافة أموال',
      'link_payment': 'ربط طريقة الدفع',
      'payout_history': 'سجل الدفعات',

      // Account & Profile
      'personal_info': 'المعلومات الشخصية',
      'vehicle_info': 'معلومات المركبة',
      'documents': 'المستندات',
      'payment_settings': 'إعدادات الدفع',
      'preferences': 'التفضيلات',
      'name': 'الاسم',
      'email': 'البريد الإلكتروني',
      'phone': 'الهاتف',
      'address': 'العنوان',
      'city': 'المدينة',
      'country': 'البلد',

      // Vehicle
      'vehicle': 'المركبة',
      'make': 'الصانع',
      'model': 'الطراز',
      'year': 'السنة',
      'color': 'اللون',
      'license_plate': 'لوحة الترخيص',
      'vehicle_type': 'نوع المركبة',

      // Settings
      'app_settings': 'إعدادات التطبيق',
      'appearance': 'المظهر',
      'sound': 'الصوت',
      'vibration': 'الاهتزاز',
      'location_services': 'خدمات الموقع',
      'privacy': 'الخصوصية',
      'terms_of_service': 'شروط الخدمة',
      'privacy_policy': 'سياسة الخصوصية',
      'app_version': 'إصدار التطبيق',
      'push_notifications': 'الإشعارات الفورية',

      // Messages & Snackbars
      'language_changed': 'تم تغيير اللغة إلى',
      'dark_mode_enabled': 'تم تفعيل الوضع الداكن',
      'light_mode_enabled': 'تم تفعيل الوضع الفاتح',
      'failed_to_update': 'فشل التحديث',
      'trip_started': 'بدأت الرحلة',
      'trip_ended': 'انتهت الرحلة',
      'trip_cancelled': 'تم إلغاء الرحلة',
      'ride_accepted': 'تم قبول الرحلة',
      'ride_declined': 'تم رفض الرحلة',
      'going_online': 'جاري الاتصال...',
      'going_offline': 'جاري قطع الاتصال...',
      'now_online': 'أنت الآن متصل',
      'now_offline': 'أنت الآن غير متصل',
      'error_occurred': 'حدث خطأ',
      'please_try_again': 'يرجى المحاولة مرة أخرى',
      'no_internet': 'لا يوجد اتصال بالإنترنت',
      'location_permission_required': 'مطلوب إذن الموقع',
      'enable_location': 'يرجى تفعيل خدمات الموقع',

      // Dialogs
      'confirm_cancel_trip': 'هل أنت متأكد من إلغاء هذه الرحلة؟',
      'confirm_go_offline': 'هل أنت متأكد من قطع الاتصال؟',
      'confirm_logout': 'هل أنت متأكد من تسجيل الخروج؟',
      'select_language': 'اختر اللغة',
      'select_payment_method': 'اختر طريقة الدفع',

      // Empty States
      'no_trips': 'لا توجد رحلات',
      'no_earnings': 'لا توجد أرباح',
      'no_transactions': 'لا توجد معاملات',
      'no_notifications': 'لا توجد إشعارات',

      // Referral
      'your_earnings': 'أرباحك',
      'total_earned': 'إجمالي المكتسب',
      'pending': 'قيد الانتظار',
      'referrals': 'الإحالات',
      'your_referral_code': 'كود الإحالة الخاص بك',
      'loading': 'جاري التحميل...',
      'copy_code': 'نسخ الكود',
      'share_code': 'مشاركة الكود',
      'how_it_works': 'كيف يعمل',
      'share_your_code': 'شارك الكود الخاص بك',
      'share_your_code_desc':
          'أرسل كود الإحالة الخاص بك إلى الأصدقاء عبر الرسائل النصية أو البريد الإلكتروني أو وسائل التواصل الاجتماعي.',
      'friend_signs_up': 'صديقك يسجل',
      'friend_signs_up_desc':
          'صديقك ينشئ حساباً باستخدام كود الإحالة الخاص بك.',
      'earn_rewards': 'اكسب المكافآت',
      'earn_rewards_desc':
          'احصل على نقاط عند تسجيلهم، ومكافآت نقدية عند إكمالهم للرحلات!',
      'reward_milestones': 'معالم المكافآت',
      'sign_up': 'التسجيل',
      'first_ride': 'الرحلة الأولى',
      'rides': 'رحلات',
      'referral_history': 'سجل الإحالات',
      'no_referrals_yet': 'لا توجد إحالات بعد',
      'start_sharing': 'ابدأ بمشاركة الكود الخاص بك!',
      'rides_completed': 'رحلات مكتملة',
      'referral_code_copied': 'تم نسخ كود الإحالة!',
      'join_drivio_message': 'انضم إلى دريفيو باستخدام كود الإحالة الخاص بي:',
      'and_earn_rewards': 'واكسب المكافآت! حمل التطبيق الآن.',
      'pending_signup': 'التسجيل قيد الانتظار',
    },
    'es': {
      // Common
      'app_name': 'Drivio',
      'welcome': 'Bienvenido',
      'settings': 'Configuración',
      'language': 'Idioma',
      'dark_mode': 'Modo Oscuro',
      'notifications': 'Notificaciones',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'ok': 'OK',
      'error': 'Error',
      'success': 'Éxito',
      'close': 'Cerrar',
      'confirm': 'Confirmar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Agregar',
      'remove': 'Quitar',
      'yes': 'Sí',
      'no': 'No',

      // Navigation & Menu
      'home': 'Inicio',
      'inbox': 'Bandeja de entrada',
      'refer_friends': 'Referir amigos',
      'opportunities': 'Oportunidades',
      'earnings': 'Ganancias',
      'services': 'Servicios',
      'wallet': 'Billetera',
      'account': 'Cuenta',
      'help': 'Ayuda',
      'learning_center': 'Centro de aprendizaje',
      'log_out': 'Cerrar sesión',
      'profile': 'Perfil',

      // Driver Status
      'online': 'En línea',
      'offline': 'Fuera de línea',
      'active': 'Activo',
      'inactive': 'Inactivo',
      'available': 'Disponible',
      'busy': 'Ocupado',
      'go_online': 'Conectarse',
      'go_offline': 'Desconectarse',
      'youre_online': 'Estás en línea',
      'youre_offline': 'Estás fuera de línea',

      // Trip & Ride
      'trip': 'Viaje',
      'ride': 'Carrera',
      'passenger': 'Pasajero',
      'pickup': 'Recogida',
      'dropoff': 'Destino',
      'destination': 'Destino',
      'distance': 'Distancia',
      'duration': 'Duración',
      'fare': 'Tarifa',
      'accept': 'Aceptar',
      'decline': 'Rechazar',
      'start_trip': 'Iniciar viaje',
      'end_trip': 'Finalizar viaje',
      'cancel_trip': 'Cancelar viaje',
      'navigate': 'Navegar',
      'arrived': 'Llegado',
      'complete': 'Completar',
      'ride_requests': 'Solicitudes de viaje',
      'new_ride_request': 'Nueva solicitud',
      'no_ride_requests': 'No hay solicitudes disponibles',

      // Earnings
      'total_earnings': 'Ganancias totales',
      'today_earnings': 'Ganancias de hoy',
      'this_week': 'Esta semana',
      'this_month': 'Este mes',
      'cash': 'Efectivo',
      'bank_transfer': 'Transferencia bancaria',
      'other': 'Otro',
      'points': 'Puntos',
      'payout': 'Pago',
      'balance': 'Saldo',
      'withdraw': 'Retirar',
      'payment_method': 'Método de pago',

      // Wallet
      'wallet_balance': 'Saldo de billetera',
      'transaction_history': 'Historial de transacciones',
      'add_funds': 'Agregar fondos',
      'link_payment': 'Vincular método de pago',
      'payout_history': 'Historial de pagos',

      // Account & Profile
      'personal_info': 'Información personal',
      'vehicle_info': 'Información del vehículo',
      'documents': 'Documentos',
      'payment_settings': 'Configuración de pago',
      'preferences': 'Preferencias',
      'name': 'Nombre',
      'email': 'Correo electrónico',
      'phone': 'Teléfono',
      'address': 'Dirección',
      'city': 'Ciudad',
      'country': 'País',

      // Vehicle
      'vehicle': 'Vehículo',
      'make': 'Marca',
      'model': 'Modelo',
      'year': 'Año',
      'color': 'Color',
      'license_plate': 'Matrícula',
      'vehicle_type': 'Tipo de vehículo',

      // Settings
      'app_settings': 'Configuración de la aplicación',
      'appearance': 'Apariencia',
      'sound': 'Sonido',
      'vibration': 'Vibración',
      'location_services': 'Servicios de ubicación',
      'privacy': 'Privacidad',
      'terms_of_service': 'Términos de servicio',
      'privacy_policy': 'Política de privacidad',
      'app_version': 'Versión de la aplicación',
      'push_notifications': 'Notificaciones push',

      // Messages & Snackbars
      'language_changed': 'Idioma cambiado a',
      'dark_mode_enabled': 'Modo oscuro activado',
      'light_mode_enabled': 'Modo claro activado',
      'failed_to_update': 'Error al actualizar',
      'trip_started': 'Viaje iniciado',
      'trip_ended': 'Viaje finalizado',
      'trip_cancelled': 'Viaje cancelado',
      'ride_accepted': 'Viaje aceptado',
      'ride_declined': 'Viaje rechazado',
      'going_online': 'Conectando...',
      'going_offline': 'Desconectando...',
      'now_online': 'Ahora estás en línea',
      'now_offline': 'Ahora estás fuera de línea',
      'error_occurred': 'Ocurrió un error',
      'please_try_again': 'Por favor, inténtalo de nuevo',
      'no_internet': 'Sin conexión a Internet',
      'location_permission_required': 'Permiso de ubicación requerido',
      'enable_location': 'Por favor, activa los servicios de ubicación',

      // Dialogs
      'confirm_cancel_trip':
          '¿Estás seguro de que quieres cancelar este viaje?',
      'confirm_go_offline': '¿Estás seguro de que quieres desconectarte?',
      'confirm_logout': '¿Estás seguro de que quieres cerrar sesión?',
      'select_language': 'Seleccionar idioma',
      'select_payment_method': 'Seleccionar método de pago',

      // Empty States
      'no_trips': 'No hay viajes',
      'no_earnings': 'No hay ganancias',
      'no_transactions': 'No hay transacciones',
      'no_notifications': 'No hay notificaciones',

      // Referral
      'your_earnings': 'Tus ganancias',
      'total_earned': 'Total ganado',
      'pending': 'Pendiente',
      'referrals': 'Referidos',
      'your_referral_code': 'Tu código de referido',
      'loading': 'Cargando...',
      'copy_code': 'Copiar código',
      'share_code': 'Compartir código',
      'how_it_works': 'Cómo funciona',
      'share_your_code': 'Comparte tu código',
      'share_your_code_desc':
          'Envía tu código de referido a amigos por mensaje, email o redes sociales.',
      'friend_signs_up': 'Tu amigo se registra',
      'friend_signs_up_desc':
          'Tu amigo crea una cuenta usando tu código de referido.',
      'earn_rewards': 'Gana recompensas',
      'earn_rewards_desc':
          '¡Obtén puntos cuando se registren y recompensas en efectivo cuando completen viajes!',
      'reward_milestones': 'Hitos de recompensas',
      'sign_up': 'Registro',
      'first_ride': '1er viaje',
      'rides': 'viajes',
      'referral_history': 'Historial de referidos',
      'no_referrals_yet': 'Aún no hay referidos',
      'start_sharing': '¡Comienza a compartir tu código!',
      'rides_completed': 'viajes completados',
      'referral_code_copied': '¡Código de referido copiado!',
      'join_drivio_message': 'Únete a Drivio usando mi código de referido:',
      'and_earn_rewards': 'y gana recompensas! Descarga la app ahora.',
      'pending_signup': 'Registro pendiente',
    },
    'de': {
      // Common
      'app_name': 'Drivio',
      'welcome': 'Willkommen',
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'dark_mode': 'Dunkler Modus',
      'notifications': 'Benachrichtigungen',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'ok': 'OK',
      'error': 'Fehler',
      'success': 'Erfolg',
      'close': 'Schließen',
      'confirm': 'Bestätigen',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'add': 'Hinzufügen',
      'remove': 'Entfernen',
      'yes': 'Ja',
      'no': 'Nein',

      // Navigation & Menu
      'home': 'Startseite',
      'inbox': 'Posteingang',
      'refer_friends': 'Freunde empfehlen',
      'opportunities': 'Möglichkeiten',
      'earnings': 'Einnahmen',
      'services': 'Dienstleistungen',
      'wallet': 'Geldbörse',
      'account': 'Konto',
      'help': 'Hilfe',
      'learning_center': 'Lernzentrum',
      'log_out': 'Abmelden',
      'profile': 'Profil',

      // Driver Status
      'online': 'Online',
      'offline': 'Offline',
      'active': 'Aktiv',
      'inactive': 'Inaktiv',
      'available': 'Verfügbar',
      'busy': 'Beschäftigt',
      'go_online': 'Online gehen',
      'go_offline': 'Offline gehen',
      'youre_online': 'Du bist online',
      'youre_offline': 'Du bist offline',

      // Trip & Ride
      'trip': 'Fahrt',
      'ride': 'Fahrt',
      'passenger': 'Fahrgast',
      'pickup': 'Abholung',
      'dropoff': 'Abgabe',
      'destination': 'Ziel',
      'distance': 'Entfernung',
      'duration': 'Dauer',
      'fare': 'Fahrpreis',
      'accept': 'Annehmen',
      'decline': 'Ablehnen',
      'start_trip': 'Fahrt starten',
      'end_trip': 'Fahrt beenden',
      'cancel_trip': 'Fahrt abbrechen',
      'navigate': 'Navigieren',
      'arrived': 'Angekommen',
      'complete': 'Abschließen',
      'ride_requests': 'Fahrtanfragen',
      'new_ride_request': 'Neue Anfrage',
      'no_ride_requests': 'Keine Anfragen verfügbar',

      // Earnings
      'total_earnings': 'Gesamteinnahmen',
      'today_earnings': 'Heutige Einnahmen',
      'this_week': 'Diese Woche',
      'this_month': 'Dieser Monat',
      'cash': 'Bargeld',
      'bank_transfer': 'Banküberweisung',
      'other': 'Andere',
      'points': 'Punkte',
      'payout': 'Auszahlung',
      'balance': 'Guthaben',
      'withdraw': 'Abheben',
      'payment_method': 'Zahlungsmethode',

      // Wallet
      'wallet_balance': 'Geldbörsen-Guthaben',
      'transaction_history': 'Transaktionsverlauf',
      'add_funds': 'Guthaben aufladen',
      'link_payment': 'Zahlungsmethode verknüpfen',
      'payout_history': 'Auszahlungsverlauf',

      // Account & Profile
      'personal_info': 'Persönliche Informationen',
      'vehicle_info': 'Fahrzeuginformationen',
      'documents': 'Dokumente',
      'payment_settings': 'Zahlungseinstellungen',
      'preferences': 'Einstellungen',
      'name': 'Name',
      'email': 'E-Mail',
      'phone': 'Telefon',
      'address': 'Adresse',
      'city': 'Stadt',
      'country': 'Land',

      // Vehicle
      'vehicle': 'Fahrzeug',
      'make': 'Hersteller',
      'model': 'Modell',
      'year': 'Jahr',
      'color': 'Farbe',
      'license_plate': 'Kennzeichen',
      'vehicle_type': 'Fahrzeugtyp',

      // Settings
      'app_settings': 'App-Einstellungen',
      'appearance': 'Erscheinungsbild',
      'sound': 'Ton',
      'vibration': 'Vibration',
      'location_services': 'Standortdienste',
      'privacy': 'Datenschutz',
      'terms_of_service': 'Nutzungsbedingungen',
      'privacy_policy': 'Datenschutzrichtlinie',
      'app_version': 'App-Version',
      'push_notifications': 'Push-Benachrichtigungen',

      // Messages & Snackbars
      'language_changed': 'Sprache geändert zu',
      'dark_mode_enabled': 'Dunkler Modus aktiviert',
      'light_mode_enabled': 'Heller Modus aktiviert',
      'failed_to_update': 'Aktualisierung fehlgeschlagen',
      'trip_started': 'Fahrt gestartet',
      'trip_ended': 'Fahrt beendet',
      'trip_cancelled': 'Fahrt abgebrochen',
      'ride_accepted': 'Fahrt angenommen',
      'ride_declined': 'Fahrt abgelehnt',
      'going_online': 'Gehe online...',
      'going_offline': 'Gehe offline...',
      'now_online': 'Du bist jetzt online',
      'now_offline': 'Du bist jetzt offline',
      'error_occurred': 'Ein Fehler ist aufgetreten',
      'please_try_again': 'Bitte versuche es erneut',
      'no_internet': 'Keine Internetverbindung',
      'location_permission_required': 'Standortberechtigung erforderlich',
      'enable_location': 'Bitte aktiviere Standortdienste',

      // Dialogs
      'confirm_cancel_trip':
          'Bist du sicher, dass du diese Fahrt abbrechen möchtest?',
      'confirm_go_offline': 'Bist du sicher, dass du offline gehen möchtest?',
      'confirm_logout': 'Bist du sicher, dass du dich abmelden möchtest?',
      'select_language': 'Sprache auswählen',
      'select_payment_method': 'Zahlungsmethode auswählen',

      // Empty States
      'no_trips': 'Keine Fahrten',
      'no_earnings': 'Keine Einnahmen',
      'no_transactions': 'Keine Transaktionen',
      'no_notifications': 'Keine Benachrichtigungen',

      // Referral
      'your_earnings': 'Deine Einnahmen',
      'total_earned': 'Gesamt verdient',
      'pending': 'Ausstehend',
      'referrals': 'Empfehlungen',
      'your_referral_code': 'Dein Empfehlungscode',
      'loading': 'Laden...',
      'copy_code': 'Code kopieren',
      'share_code': 'Code teilen',
      'how_it_works': 'So funktioniert es',
      'share_your_code': 'Teile deinen Code',
      'share_your_code_desc':
          'Sende deinen Empfehlungscode an Freunde per SMS, E-Mail oder soziale Medien.',
      'friend_signs_up': 'Freund meldet sich an',
      'friend_signs_up_desc':
          'Dein Freund erstellt ein Konto mit deinem Empfehlungscode.',
      'earn_rewards': 'Belohnungen verdienen',
      'earn_rewards_desc':
          'Erhalte Punkte bei ihrer Anmeldung und Geldprämien, wenn sie Fahrten abschließen!',
      'reward_milestones': 'Belohnungsmeilensteine',
      'sign_up': 'Anmeldung',
      'first_ride': '1. Fahrt',
      'rides': 'Fahrten',
      'referral_history': 'Empfehlungsverlauf',
      'no_referrals_yet': 'Noch keine Empfehlungen',
      'start_sharing': 'Beginne deinen Code zu teilen!',
      'rides_completed': 'Fahrten abgeschlossen',
      'referral_code_copied': 'Empfehlungscode kopiert!',
      'join_drivio_message': 'Tritt Drivio mit meinem Empfehlungscode bei:',
      'and_earn_rewards':
          'und verdiene Belohnungen! Lade die App jetzt herunter.',
      'pending_signup': 'Anmeldung ausstehend',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters for common translations
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get settings => translate('settings');
  String get language => translate('language');
  String get darkMode => translate('dark_mode');
  String get notifications => translate('notifications');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get ok => translate('ok');
  String get error => translate('error');
  String get success => translate('success');
  String get close => translate('close');
  String get confirm => translate('confirm');

  // Navigation
  String get home => translate('home');
  String get inbox => translate('inbox');
  String get referFriends => translate('refer_friends');
  String get opportunities => translate('opportunities');
  String get earnings => translate('earnings');
  String get services => translate('services');
  String get wallet => translate('wallet');
  String get account => translate('account');
  String get help => translate('help');
  String get learningCenter => translate('learning_center');
  String get logOut => translate('log_out');
  String get profile => translate('profile');

  // Driver Status
  String get online => translate('online');
  String get offline => translate('offline');
  String get goOnline => translate('go_online');
  String get goOffline => translate('go_offline');
  String get youreOnline => translate('youre_online');
  String get youreOffline => translate('youre_offline');

  // Trip
  String get trip => translate('trip');
  String get passenger => translate('passenger');
  String get pickup => translate('pickup');
  String get dropoff => translate('dropoff');
  String get destination => translate('destination');
  String get distance => translate('distance');
  String get duration => translate('duration');
  String get fare => translate('fare');
  String get accept => translate('accept');
  String get decline => translate('decline');
  String get startTrip => translate('start_trip');
  String get endTrip => translate('end_trip');
  String get cancelTrip => translate('cancel_trip');
  String get navigate => translate('navigate');
  String get complete => translate('complete');
  String get rideRequests => translate('ride_requests');
  String get newRideRequest => translate('new_ride_request');
  String get noRideRequests => translate('no_ride_requests');

  // Earnings
  String get totalEarnings => translate('total_earnings');
  String get todayEarnings => translate('today_earnings');
  String get thisWeek => translate('this_week');
  String get thisMonth => translate('this_month');
  String get cash => translate('cash');
  String get bankTransfer => translate('bank_transfer');
  String get points => translate('points');
  String get balance => translate('balance');

  // Messages
  String get languageChanged => translate('language_changed');
  String get darkModeEnabled => translate('dark_mode_enabled');
  String get lightModeEnabled => translate('light_mode_enabled');
  String get failedToUpdate => translate('failed_to_update');
  String get tripStarted => translate('trip_started');
  String get tripEnded => translate('trip_ended');
  String get tripCancelled => translate('trip_cancelled');
  String get rideAccepted => translate('ride_accepted');
  String get rideDeclined => translate('ride_declined');
  String get nowOnline => translate('now_online');
  String get nowOffline => translate('now_offline');
  String get errorOccurred => translate('error_occurred');
  String get pleaseTryAgain => translate('please_try_again');
}

/// Localization Delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ar', 'es', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
