import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with SingleTickerProviderStateMixin {
  int _currentVideoIndex = 0;
  bool _isPlaying = false;
  double _progress = 0.0;
  late AnimationController _animController;

  final _videos = [
    _VideoContent(
      title: 'How Chunking Works',
      description: 'A visual explanation of chunking for better learning.',
      duration: '2:30',
      steps: [
        'Your brain processes information in groups',
        'Chunking reduces cognitive load',
        'Group related concepts together',
        'Take breaks between chunks',
      ],
    ),
    _VideoContent(
      title: 'Visual Learning Techniques',
      description: 'Discover how to use visuals to boost memory.',
      duration: '3:00',
      steps: [
        'Mind maps connect ideas visually',
        'Color coding helps categorization',
        'Sketchnotes engage creative thinking',
        'Diagrams simplify complex topics',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _videos[_currentVideoIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Learn'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVideoPlayer(video),
              const SizedBox(height: 20),
              _buildVideoInfo(video),
              const SizedBox(height: 20),
              _buildStepList(video.steps),
              const SizedBox(height: 24),
              _buildNavButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(_VideoContent video) {
    return Semantics(
      label: 'Video: ${video.title}',
      child: GestureDetector(
        onTap: () => setState(() => _isPlaying = !_isPlaying),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppColors.sereneBlue.withValues(alpha: 0.3),
                AppColors.softPurple.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlaying ? Icons.play_circle_fill : Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.duration,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    color: AppColors.calmTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo(_VideoContent video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          video.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildStepList(List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Takeaways',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.sereneBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: AppColors.sereneBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Mark video as watched',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _progress = 1.0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Marked as watched!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Mark as Watched'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Row(
      children: [
        if (_currentVideoIndex > 0)
          Expanded(
            child: Semantics(
              button: true,
              label: 'Previous video',
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentVideoIndex--;
                    _progress = 0.0;
                    _isPlaying = false;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Previous'),
              ),
            ),
          ),
        if (_currentVideoIndex > 0) const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            button: true,
            label: _currentVideoIndex < _videos.length - 1
                ? 'Next video'
                : 'Finish watching',
            child: FilledButton.icon(
              onPressed: () {
                if (_currentVideoIndex < _videos.length - 1) {
                  setState(() {
                    _currentVideoIndex++;
                    _progress = 0.0;
                    _isPlaying = false;
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              icon: Icon(_currentVideoIndex < _videos.length - 1
                  ? Icons.arrow_forward_rounded
                  : Icons.check_rounded),
              label: Text(_currentVideoIndex < _videos.length - 1
                  ? 'Next'
                  : 'Finish'),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoContent {
  final String title;
  final String description;
  final String duration;
  final List<String> steps;

  const _VideoContent({
    required this.title,
    required this.description,
    required this.duration,
    required this.steps,
  });
}
