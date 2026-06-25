import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/learner_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _pageController = PageController();
  int _currentPage = 0;
  String _selectedName = '';
  final Set<String> _selectedTraits = {};

  final _traits = [
    'adhd',
    'autism',
    'dyslexia',
    'dyscalculia',
    'dyspraxia',
    'anxiety',
    'sensory processing',
    'executive dysfunction',
  ];

  final _traitDescriptions = {
    'adhd': 'Easily distracted, hyperfocus, needs variety',
    'autism': 'Likes routine, literal thinking, sensory sensitivity',
    'dyslexia': 'Challenges with reading, benefits from visuals',
    'dyscalculia': 'Numbers can be tricky, prefers patterns',
    'dyspraxia': 'Coordination challenges, needs larger controls',
    'anxiety': 'Needs calm, predictable environment',
    'sensory processing': 'Sensitive to visual/audio overload',
    'executive dysfunction': 'Needs help starting and organizing',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    final learnerState = context.read<LearnerState>();
    await learnerState.completeOnboarding(
      _selectedName,
      _selectedTraits.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildTraitSelectionPage(),
                  _buildNamePage(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.calmTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: AppColors.calmTeal,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Welcome to ClarityCrew',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'A learning companion built for the way your mind works.\nNo pressure. No overwhelm. Just your pace, your path.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.calmBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.calmTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Everything adapts to you.\nWe will learn what works best together.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'What feels familiar?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Pick what resonates. This helps us tailor your experience.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _traits.length,
              itemBuilder: (context, index) {
                final trait = _traits[index];
                final selected = _selectedTraits.contains(trait);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedTraits.remove(trait);
                      } else {
                        _selectedTraits.add(trait);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.calmTeal.withValues(alpha: 0.15)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.calmTeal
                            : Colors.grey.withValues(alpha: 0.2),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          trait[0].toUpperCase() + trait.substring(1),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.calmTeal
                                    : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _traitDescriptions[trait] ?? '',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What should I call you?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Just a name so I can personalize things.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Your name',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => _selectedName = value,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text('Back'),
            ),
          const Spacer(),
          Semantics(
            button: true,
            label: _currentPage == 2 ? 'Start learning' : 'Continue',
            child: FilledButton(
              onPressed: _currentPage == 2 ? _finish : _nextPage,
              child: Text(_currentPage == 2 ? 'Start Learning' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
