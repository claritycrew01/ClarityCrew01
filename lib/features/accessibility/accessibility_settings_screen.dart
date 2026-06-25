import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../state/learner_state.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  bool _simplifiedText = false;

  @override
  Widget build(BuildContext context) {
    final learnerState = context.watch<LearnerState>();
    final profile = learnerState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Visual Settings'),
              const SizedBox(height: 12),
              _buildCard(context, [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce Motion'),
                  subtitle: const Text(
                    'Minimize animations and transitions',
                  ),
                  value: profile.prefersReducedMotion,
                  onChanged: (value) =>
                      learnerState.updateAccessibility(
                        reducedMotion: value,
                      ),
                  activeColor: AppColors.calmTeal,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce Visuals'),
                  subtitle: const Text(
                    'Simplify on-screen elements and decorations',
                  ),
                  value: profile.prefersReducedVisuals,
                  onChanged: (value) =>
                      learnerState.updateAccessibility(
                        reducedVisuals: value,
                      ),
                  activeColor: AppColors.calmTeal,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Font Size'),
              const SizedBox(height: 12),
              _buildCard(context, [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Font Size Multiplier'),
                          Text(
                            '${(profile.fontSizeMultiplier * 100).round()}%',
                            style: const TextStyle(
                              color: AppColors.calmTeal,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: profile.fontSizeMultiplier,
                        min: 0.8,
                        max: 2.0,
                        divisions: 12,
                        label:
                            '${(profile.fontSizeMultiplier * 100).round()}%',
                        onChanged: (value) =>
                            learnerState.updateAccessibility(
                              fontSizeMultiplier: value,
                            ),
                        activeColor: AppColors.calmTeal,
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Smaller',
                              style: TextStyle(color: AppColors.textSecondary)),
                          Text('Larger',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Reading Support'),
              const SizedBox(height: 12),
              _buildCard(context, [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Simplified Text'),
                  subtitle: const Text(
                    'Shorter sentences and simpler language',
                  ),
                  value: _simplifiedText,
                  onChanged: (value) {
                    setState(() => _simplifiedText = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'Text will be simplified'
                            : 'Using original text'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  activeColor: AppColors.calmTeal,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('High Contrast'),
                  subtitle: const Text(
                    'Increase contrast for better readability',
                  ),
                  value: profile.prefersHighContrast,
                  onChanged: (value) {
                    learnerState.updateAccessibility(highContrast: value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'High contrast mode enabled'
                            : 'High contrast mode disabled'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  activeColor: AppColors.calmTeal,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Line Spacing'),
                  subtitle: Text('Current: ${profile.lineSpacing}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          final newVal =
                              (profile.lineSpacing - 0.25).clamp(1.0, 3.0);
                          learnerState.updateAccessibility(lineSpacing: newVal);
                        },
                      ),
                      Text('${profile.lineSpacing}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          final newVal =
                              (profile.lineSpacing + 0.25).clamp(1.0, 3.0);
                          learnerState.updateAccessibility(lineSpacing: newVal);
                        },
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Accommodations'),
              const SizedBox(height: 12),
              _buildCard(context, [
                if (profile.neurodivergentTraits.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Select traits during onboarding to see personalized accommodations.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...profile.neurodivergentTraits.map((trait) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 18, color: AppColors.calmTeal),
                          const SizedBox(width: 8),
                          Text(
                            '${trait[0].toUpperCase()}${trait.substring(1)} support active',
                          ),
                        ],
                      ),
                    );
                  }),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(children: children),
    );
  }
}
