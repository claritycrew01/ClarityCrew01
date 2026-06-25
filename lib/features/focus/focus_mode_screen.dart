import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../state/session_state.dart';
import '../../state/app_state.dart';
import '../../state/learner_state.dart';
import '../../services/focus_support_service.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with SingleTickerProviderStateMixin {
  late FocusSupportService _focusService;
  StreamSubscription<FocusState>? _subscription;
  FocusState _focusState = FocusState(
    elapsedSeconds: 0,
    totalSeconds: 1500,
    isRunning: false,
    isBreak: false,
  );
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _focusService = context.read<AppState>().focusService;
    _subscription = _focusService.focusStateStream.listen((state) {
      if (mounted) setState(() => _focusState = state);
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _focusState.isRunning;
    final progress = _focusState.progress;
    final isBreak = _focusState.isBreak;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Sprint'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStatusBadge(isBreak, isRunning),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 280,
                      child: _buildTimerCircle(progress, isRunning),
                    ),
                    const SizedBox(height: 24),
                    _buildControls(context, isRunning, isBreak),
                    const SizedBox(height: 24),
                    _buildDurationSelector(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isBreak, bool isRunning) {
    String label;
    Color color;
    if (!isRunning) {
      label = 'Ready to focus';
      color = AppColors.calmTeal;
    } else if (isBreak) {
      label = 'Taking a break';
      color = AppColors.softGold;
    } else {
      label = 'Focus session';
      color = AppColors.sereneBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(double progress, bool isRunning) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isRunning ? 1.0 + (_pulseController.value * 0.02) : 1.0;
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth.clamp(200.0, 280.0);
            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      color: _focusState.isBreak
                          ? AppColors.softGold
                          : AppColors.calmTeal,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _focusState.formattedTime,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: size / 5,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _focusState.isBreak ? 'break time' : 'focus time',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, bool isRunning, bool isBreak) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isRunning)
          Semantics(
            button: true,
            label: 'Start focus session',
            child: FilledButton.icon(
              onPressed: () => _focusService.startFocus(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Focus'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: AppColors.calmTeal,
              ),
            ),
          )
        else ...[
          Semantics(
            button: true,
            label: isRunning ? 'Pause timer' : 'Resume timer',
            child: IconButton(
              onPressed: () {
                if (_focusState.isRunning) {
                  _focusService.pause();
                } else {
                  _focusService.resume();
                }
              },
              icon: Icon(
                isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.calmTeal.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            button: true,
            label: 'Stop focus session',
            child: IconButton(
              onPressed: () => _focusService.stop(),
              icon: const Icon(Icons.stop_rounded, size: 32),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.warmCoral.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          if (!_focusState.isBreak) ...[
            const SizedBox(width: 16),
            Semantics(
              button: true,
              label: 'Take a break',
              child: IconButton(
                onPressed: () => _focusService.startBreak(),
                icon: const Icon(Icons.coffee_rounded, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.softGold.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDurationSelector() {
    if (_focusState.isRunning) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          'Session duration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDurationOption(5),
              const SizedBox(width: 12),
              _buildDurationOption(15),
              const SizedBox(width: 12),
              _buildDurationOption(25, isDefault: true),
              const SizedBox(width: 12),
              _buildDurationOption(45),
              const SizedBox(width: 12),
              _buildDurationOption(60),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationOption(int minutes, {bool isDefault = false}) {
    final selected = _focusState.totalSeconds == minutes * 60;
    return Semantics(
      button: true,
      label: 'Set focus duration to $minutes minutes',
      child: GestureDetector(
        onTap: () => _focusService.adjustDuration(minutes * 60),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.calmTeal.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.calmTeal : Colors.grey.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$minutes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.calmTeal : null,
                    ),
              ),
              Text(
                'min',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
