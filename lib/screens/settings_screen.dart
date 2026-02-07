import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/storage_helper.dart';
import '../theme/app_theme.dart';

/// Settings screen - configure game preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Game settings section
              // Appearance section
              _SectionHeader('Appearance'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Theme'),
                      subtitle: Text(
                        settings.darkMode == null
                            ? 'System default'
                            : (settings.darkMode! ? 'Dark' : 'Light'),
                      ),
                      trailing: PopupMenuButton<bool?>(
                        initialValue: settings.darkMode,
                        onSelected: (value) => settings.setDarkMode(value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: null,
                            child: Text('System default'),
                          ),
                          const PopupMenuItem(
                            value: false,
                            child: Text('Light'),
                          ),
                          const PopupMenuItem(value: true, child: Text('Dark')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Data section
              _SectionHeader('Data'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Clear Saved Players'),
                      subtitle: const Text('Remove all saved player names'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showClearConfirmation(
                        context,
                        'Clear Saved Players?',
                        'This will remove all saved player names.',
                        () async {
                          await StorageHelper.clearSavedPlayers();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saved players cleared'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Clear Player Records'),
                      subtitle: const Text('Remove all player statistics'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showClearConfirmation(
                        context,
                        'Clear Player Records?',
                        'This will permanently delete all player statistics.',
                        () async {
                          await StorageHelper.clearPlayerRecords();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Player records cleared'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // About section
              Center(
                child: Column(
                  children: [
                    Text(
                      'Stocks v1.0.0',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A push-your-luck dice game',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearConfirmation(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
