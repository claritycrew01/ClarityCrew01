import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme/colors.dart';
import '../../state/learner_state.dart';
import '../../state/app_state.dart';
import '../accessibility/accessibility_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  @override
  Widget build(BuildContext context) {
    final learnerState = context.watch<LearnerState>();
    final appState = context.watch<AppState>();
    final profile = learnerState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(context, profile),
              const SizedBox(height: 24),
              _buildPreferencesSection(context, appState),
              const SizedBox(height: 24),
              _buildAccessibilitySection(context),
              const SizedBox(height: 24),
              _buildAboutSection(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, dynamic profile) {
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.breakpointDesktop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Semantics(
                label: 'Your name: ${profile.name}',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: isDesktop ? 42 : 48,
                    height: isDesktop ? 42 : 48,
                    decoration: BoxDecoration(
                      color: AppColors.calmTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.calmTeal,
                      size: isDesktop ? 20 : 24,
                    ),
                  ),
                  title: Text(
                    profile.name.isNotEmpty ? profile.name : 'Set your name',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    profile.neurodivergentTraits.isEmpty
                        ? 'No traits selected'
                        : profile.neurodivergentTraits.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _showEditNameDialog(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: appState.isDarkMode,
                onChanged: (value) => appState.setDarkMode(value),
                activeColor: AppColors.calmTeal,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound Effects'),
                subtitle: const Text('Play sounds for interactions'),
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  if (_hapticEnabled && !kIsWeb) {
                    HapticFeedback.lightImpact();
                  }
                },
                activeColor: AppColors.calmTeal,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Haptic Feedback'),
                subtitle: const Text('Vibrate on key actions'),
                value: _hapticEnabled,
                onChanged: (value) {
                  setState(() => _hapticEnabled = value);
                  if (value && !kIsWeb) {
                    HapticFeedback.mediumImpact();
                  }
                },
                activeColor: AppColors.calmTeal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.breakpointDesktop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accessibility',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: 'Open accessibility settings',
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AccessibilitySettingsScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: isDesktop ? 42 : 48,
                    height: isDesktop ? 42 : 48,
                    decoration: BoxDecoration(
                      color: AppColors.softPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.accessibility_new_rounded,
                      color: AppColors.softPurple,
                      size: isDesktop ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accessibility Settings',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Motion, visuals, font size, and more',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildAboutRow(context, 'Version', '1.0.0'),
              const Divider(height: 16),
              _buildAboutRow(context, 'Data', 'Stored locally only'),
              const Divider(height: 16),
              _buildAboutRow(context, 'AI Engine', 'Adaptive v1'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: context.read<LearnerState>().profile.name,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Your name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<LearnerState>().updateName(controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
