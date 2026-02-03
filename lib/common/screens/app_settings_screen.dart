import 'package:flutter/material.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:drivio_app/common/providers/theme_provider.dart';
import 'package:drivio_app/common/providers/locale_provider.dart';
import 'package:drivio_app/common/l10n/app_localizations.dart';
import 'package:drivio_app/common/services/notification_service.dart';
import 'package:provider/provider.dart';

/// App Settings Screen
/// Allows users to configure app preferences including language, theme, notifications, etc.
class AppSettingsScreen extends StatefulWidget {
  final bool automaticallyImplyLeading;

  const AppSettingsScreen({super.key, this.automaticallyImplyLeading = true});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  // ... (existing state variables)
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _locationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Load notification settings
      final notificationsEnabled =
          await SharedPreferencesHelper().getValue<bool>(
            'notificationsEnabled',
          ) ??
          true;
      final soundEnabled =
          await SharedPreferencesHelper().getValue<bool>('soundEnabled') ??
          true;
      final vibrationEnabled =
          await SharedPreferencesHelper().getValue<bool>('vibrationEnabled') ??
          true;
      final locationEnabled =
          await SharedPreferencesHelper().getValue<bool>('locationEnabled') ??
          true;

      if (mounted) {
        setState(() {
          _notificationsEnabled = notificationsEnabled;
          _soundEnabled = soundEnabled;
          _vibrationEnabled = vibrationEnabled;
          _locationEnabled = locationEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLanguage(String languageCode) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final success = await localeProvider.setLocale(languageCode);

    if (mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${loc.languageChanged} ${LocaleProvider.supportedLanguages[languageCode]}'
                : loc.failedToUpdate,
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setTheme(value);

    if (mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? loc.darkModeEnabled : loc.lightModeEnabled),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    await SharedPreferencesHelper.setBool('notificationsEnabled', value);

    if (value) {
      // Enable notifications and apply current sound/vibration settings
      await NotificationService.enableNotifications();
      await NotificationService.updateNotificationSettings(
        soundEnabled: _soundEnabled,
        vibrationEnabled: _vibrationEnabled,
      );
    } else {
      // Disable all notifications
      await NotificationService.disableNotifications();
    }

    setState(() => _notificationsEnabled = value);
  }

  Future<void> _toggleSound(bool value) async {
    await SharedPreferencesHelper.setBool('soundEnabled', value);

    // Update notification channel with new sound setting
    await NotificationService.updateNotificationSettings(
      soundEnabled: value,
      vibrationEnabled: _vibrationEnabled,
    );

    setState(() => _soundEnabled = value);
  }

  Future<void> _toggleVibration(bool value) async {
    await SharedPreferencesHelper.setBool('vibrationEnabled', value);

    // Update notification channel with new vibration setting
    await NotificationService.updateNotificationSettings(
      soundEnabled: _soundEnabled,
      vibrationEnabled: value,
    );

    setState(() => _vibrationEnabled = value);
  }

  Future<void> _toggleLocation(bool value) async {
    await SharedPreferencesHelper.setBool('locationEnabled', value);
    setState(() => _locationEnabled = value);
  }

  void _showLanguageDialog() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLanguage = localeProvider.currentLocale.languageCode;
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(loc.translate('select_language')),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: LocaleProvider.supportedLanguages.length,
                itemBuilder: (context, index) {
                  final languageCode = LocaleProvider.supportedLanguages.keys
                      .elementAt(index);
                  final languageName =
                      LocaleProvider.supportedLanguages[languageCode]!;
                  final isSelected = currentLanguage == languageCode;

                  return ListTile(
                    title: Text(languageName),
                    trailing:
                        isSelected
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).primaryColor,
                            )
                            : null,
                    onTap: () {
                      _updateLanguage(languageCode);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.cancel),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          title: Text(AppLocalizations.of(context)!.settings),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        title: Text(AppLocalizations.of(context)!.settings),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Appearance Section
          _SectionHeader(
            title: AppLocalizations.of(context)!.translate('appearance'),
          ),
          _SettingsTile(
            icon: Icons.brightness_6,
            title: AppLocalizations.of(context)!.darkMode,
            subtitle: 'Switch between light and dark theme',
            trailing: Switch(
              value: Provider.of<ThemeProvider>(context).isDarkMode,
              onChanged: _toggleDarkMode,
            ),
          ),
          _SettingsTile(
            icon: Icons.language,
            title: AppLocalizations.of(context)!.language,
            subtitle: Provider.of<LocaleProvider>(context).currentLanguageName,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showLanguageDialog,
          ),

          const Divider(height: 32),

          // Notifications Section
          _SectionHeader(title: AppLocalizations.of(context)!.notifications),
          _SettingsTile(
            icon: Icons.notifications,
            title: AppLocalizations.of(
              context,
            )!.translate('push_notifications'),
            subtitle: 'Receive notifications for updates',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),
          _SettingsTile(
            icon: Icons.volume_up,
            title: AppLocalizations.of(context)!.translate('sound'),
            subtitle: 'Play sound for notifications',
            trailing: Switch(
              value: _soundEnabled,
              onChanged: _toggleSound,
              activeThumbColor: _notificationsEnabled ? null : Colors.grey,
            ),
            enabled: _notificationsEnabled,
          ),
          _SettingsTile(
            icon: Icons.vibration,
            title: AppLocalizations.of(context)!.translate('vibration'),
            subtitle: 'Vibrate for notifications',
            trailing: Switch(
              value: _vibrationEnabled,
              onChanged: _toggleVibration,
              activeThumbColor: _notificationsEnabled ? null : Colors.grey,
            ),
            enabled: _notificationsEnabled,
          ),

          const Divider(height: 32),

          // Privacy & Permissions Section
          _SectionHeader(
            title: AppLocalizations.of(context)!.translate('privacy'),
          ),
          _SettingsTile(
            icon: Icons.location_on,
            title: AppLocalizations.of(context)!.translate('location_services'),
            subtitle: 'Allow app to access your location',
            trailing: Switch(
              value: _locationEnabled,
              onChanged: _toggleLocation,
            ),
          ),

          const Divider(height: 32),

          // About Section
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: AppLocalizations.of(context)!.translate('app_version'),
            subtitle: '1.0.0',
            trailing: const SizedBox.shrink(),
          ),
          _SettingsTile(
            icon: Icons.description,
            title: AppLocalizations.of(context)!.translate('terms_of_service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to Terms of Service
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate('terms_of_service'),
                  ),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.privacy_tip,
            title: AppLocalizations.of(context)!.translate('privacy_policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to Privacy Policy
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate('privacy_policy'),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Settings Tile Widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      enabled: enabled,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              enabled
                  ? theme.primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? theme.primaryColor : Colors.grey,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? Colors.grey[600] : Colors.grey[400],
                ),
              )
              : null,
      trailing: trailing,
      onTap: enabled ? onTap : null,
    );
  }
}
