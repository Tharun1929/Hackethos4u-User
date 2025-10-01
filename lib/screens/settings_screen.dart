import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_themes.dart';
import '../utils/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/app_settings_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _emailUpdates = true;
  bool _pushNotifications = true;
  bool _courseReminders = true;
  bool _achievementNotifications = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final preferences =
              userData['preferences'] as Map<String, dynamic>? ?? {};
          final notificationSettings =
              userData['notificationSettings'] as Map<String, dynamic>? ?? {};

          setState(() {
            _notificationsEnabled = preferences['notifications'] ?? true;
            _soundEnabled = preferences['sound'] ?? true;
            _vibrationEnabled = preferences['vibration'] ?? true;
            _emailUpdates = notificationSettings['emailUpdates'] ?? true;
            _pushNotifications =
                notificationSettings['pushNotifications'] ?? true;
            _courseReminders = notificationSettings['courseReminders'] ?? true;
            _achievementNotifications =
                notificationSettings['achievementNotifications'] ?? true;
          });
        }
      }
    } catch (e) {
      // Error loading user settings: $e
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'preferences': {
            'notifications': _notificationsEnabled,
            'sound': _soundEnabled,
            'vibration': _vibrationEnabled,
          },
          'notificationSettings': {
            'emailUpdates': _emailUpdates,
            'pushNotifications': _pushNotifications,
            'courseReminders': _courseReminders,
            'achievementNotifications': _achievementNotifications,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update notification permissions
        if (_pushNotifications) {
          await _notificationService.initialize();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Error saving user settings: $e
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveUserSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Notifications'),
          const SizedBox(height: 16),

          // Notifications Toggle
          _buildSettingsCard(
            icon: Icons.notifications,
            title: 'Enable Notifications',
            subtitle: 'Receive push notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                  if (!value) {
                    _pushNotifications = false;
                    _courseReminders = false;
                    _achievementNotifications = false;
                  }
                });
              },
            ),
          ),

          if (_notificationsEnabled) ...[
            const SizedBox(height: 12),

            // Push Notifications
            _buildSettingsCard(
              icon: Icons.push_pin,
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              trailing: _buildCustomSwitch(
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 12),

            // Course Reminders
            _buildSettingsCard(
              icon: Icons.school,
              title: 'Course Reminders',
              subtitle: 'Get reminded about course deadlines',
              trailing: _buildCustomSwitch(
                value: _courseReminders,
                onChanged: (value) {
                  setState(() {
                    _courseReminders = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 12),

            // Achievement Notifications
            _buildSettingsCard(
              icon: Icons.emoji_events,
              title: 'Achievement Notifications',
              subtitle: 'Get notified about your achievements',
              trailing: _buildCustomSwitch(
                value: _achievementNotifications,
                onChanged: (value) {
                  setState(() {
                    _achievementNotifications = value;
                  });
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Sound Settings
          _buildSettingsCard(
            icon: Icons.volume_up,
            title: 'Sound Effects',
            subtitle: 'Play sounds for notifications',
            trailing: _buildCustomSwitch(
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // Vibration Settings
          _buildSettingsCard(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Vibrate for notifications',
            trailing: _buildCustomSwitch(
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // Email Updates
          _buildSettingsCard(
            icon: Icons.email,
            title: 'Email Updates',
            subtitle: 'Receive updates via email',
            trailing: _buildCustomSwitch(
              value: _emailUpdates,
              onChanged: (value) {
                setState(() {
                  _emailUpdates = value;
                });
              },
            ),
          ),

          const SizedBox(height: 32),

          _buildSectionHeader('Appearance'),
          const SizedBox(height: 16),

          // Theme Toggle
          _buildSettingsCard(
            icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            title: 'Dark Mode',
            subtitle: themeProvider.isDarkMode
                ? 'Dark theme enabled'
                : 'Light theme enabled',
            trailing: _buildCustomSwitch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                if (value) {
                  themeProvider.setThemeMode(ThemeMode.dark);
                } else {
                  themeProvider.setThemeMode(ThemeMode.light);
                }
              },
            ),
          ),

          const SizedBox(height: 12),

          // Theme Mode Selector
          _buildSettingsCard(
            icon: Icons.palette,
            title: 'Theme Mode',
            subtitle: _getThemeModeText(themeProvider.themeMode),
            onTap: () {
              _showThemeModeDialog(context, themeProvider);
            },
          ),

          const SizedBox(height: 32),

          _buildSectionHeader('Account'),
          const SizedBox(height: 16),

          // Profile
          _buildSettingsCard(
            icon: Icons.person,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              Navigator.pushNamed(context, '/editProfile');
            },
          ),

          const SizedBox(height: 12),

          // Invoices
          _buildSettingsCard(
            icon: Icons.receipt,
            title: 'My Invoices',
            subtitle: 'View your payment history and invoices',
            onTap: () {
              Navigator.pushNamed(context, '/invoices');
            },
          ),

          const SizedBox(height: 12),

          // Update Location
          _buildSettingsCard(
            icon: Icons.location_on,
            title: 'Update Location',
            subtitle: 'Add or change your location',
            onTap: _updateLocation,
          ),

          const SizedBox(height: 12),

          // Camera Test (permissions & capture)
          _buildSettingsCard(
            icon: Icons.camera_alt,
            title: 'Camera Test',
            subtitle: 'Open camera to verify permissions',
            onTap: _openCameraTest,
          ),

          const SizedBox(height: 12),

          // Privacy
          _buildSettingsCard(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              _showPrivacyPolicy(context);
            },
          ),

          const SizedBox(height: 12),

          // Terms
          _buildSettingsCard(
            icon: Icons.description,
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            onTap: () {
              _showTermsOfService(context);
            },
          ),

          const SizedBox(height: 12),

          // Data Export
          _buildSettingsCard(
            icon: Icons.download,
            title: 'Export Data',
            subtitle: 'Download your data',
            onTap: () {
              _exportUserData();
            },
          ),

          const SizedBox(height: 32),

          _buildSectionHeader('Support'),
          const SizedBox(height: 16),

          // Help Center
          _buildSettingsCard(
            icon: Icons.help,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () {
              _showHelpCenter(context);
            },
          ),

          const SizedBox(height: 12),

          // Contact Support
          _buildSettingsCard(
            icon: Icons.support_agent,
            title: 'Contact Support',
            subtitle: 'Get in touch with our team',
            onTap: () {
              _contactSupport(context);
            },
          ),

          const SizedBox(height: 12),

          // Feedback
          _buildSettingsCard(
            icon: Icons.feedback,
            title: 'Send Feedback',
            subtitle: 'Help us improve the app',
            onTap: () {
              _sendFeedback(context);
            },
          ),

          const SizedBox(height: 12),

          // Share App
          _buildSettingsCard(
            icon: Icons.share,
            title: 'Share App',
            subtitle: 'Invite friends to Hackethos4u',
            onTap: _shareApp,
          ),

          const SizedBox(height: 32),

          _buildSectionHeader('About'),
          const SizedBox(height: 16),

          // App Version
          _buildSettingsCard(
            icon: Icons.info,
            title: 'App Version',
            subtitle: 'Version 1.0.0',
            onTap: null,
          ),

          const SizedBox(height: 12),

          // Logout
          _buildSettingsCard(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () {
              _showLogoutDialog(context);
            },
            isDestructive: true,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 50,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: value
            ? theme.colorScheme.primary
            : theme.dividerColor.withOpacity(0.3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => onChanged(!value),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isDestructive ? Colors.red : theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDestructive
                              ? Colors.red
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing widget or arrow
                if (trailing != null)
                  trailing
                else if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'Follow system';
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
    }
  }

  Future<void> _updateLocation() async {
    final theme = Theme.of(context);
    final controller = _locationController..text = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Location'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'City, Country'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('user_profiles')
                      .doc(user.uid)
                      .set({
                    'location': text,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location updated')));
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: theme.colorScheme.error));
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCameraTest() async {
    try {
      final picker = ImagePicker();
      await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera opened successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _shareApp() async {
    try {
      const message =
          'I am learning on HACKETHOS4U! Join me: https://hackethos4u.com';
      await Share.share(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  void _showThemeModeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Follow System'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light Theme'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Theme'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your personal information when you use our app.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using our app, you agree to these terms of service. Please read them carefully before using the app.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // In a real app, this would export user data
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const Text(
          'Need help? Check our comprehensive help center for answers to common questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _contactSupport(BuildContext context) {
    final appSettings = Provider.of<AppSettingsService>(context, listen: false);
    final supportInfo = appSettings.getSupportInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${supportInfo['appName']} Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Get in touch with our support team for personalized assistance.'),
            const SizedBox(height: 16),
            _buildContactInfo('Email', supportInfo['email']!, Icons.email),
            const SizedBox(height: 8),
            _buildContactInfo('Phone', supportInfo['phone']!, Icons.phone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // You can add email/phone functionality here
              Navigator.pop(context);
            },
            child: const Text('Contact Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppThemes.primarySolid),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: AppThemes.textSecondary),
          ),
        ),
      ],
    );
  }

  void _sendFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text(
          'We value your feedback! Help us improve the app by sharing your thoughts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
