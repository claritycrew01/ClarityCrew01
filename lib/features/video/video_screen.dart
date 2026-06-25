import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class VideoContent {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String subject;
  final String chapter;
  final List<String> keyPoints;
  final List<String> chapters;

  const VideoContent({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.subject,
    required this.chapter,
    required this.keyPoints,
    required this.chapters,
  });
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  int _currentVideoIndex = 0;
  bool _isWatched = false;

  final _videos = [
    VideoContent(
      id: 'vid_algebra_1',
      title: 'Solving Linear Equations Visually',
      description:
          'Watch step-by-step solutions to linear equations using a balance scale approach.',
      duration: '4:30',
      subject: 'Algebra',
      chapter: 'Linear Equations',
      keyPoints: [
        'Isolate the variable by undoing operations in reverse order',
        'Whatever you do to one side, do to the other',
        'Check your answer by plugging it back into the original equation',
        'Use inverse operations: addition undoes subtraction, division undoes multiplication',
      ],
      chapters: [
        '0:00 — What is a linear equation?',
        '0:45 — The balance scale method',
        '1:30 — Example 1: 2x + 5 = 13',
        '2:15 — Example 2: 3x - 7 = 2x + 5',
        '3:00 — Equations with fractions',
        '3:45 — Checking your answer',
      ],
    ),
    VideoContent(
      id: 'vid_bio_1',
      title: 'Cell Organelles: A Tour Inside the Cell',
      description:
          'Explore the internal structure of animal and plant cells through detailed diagrams.',
      duration: '5:00',
      subject: 'Biology',
      chapter: 'Cell Biology',
      keyPoints: [
        'The nucleus contains DNA and controls the cell',
        'Mitochondria produce ATP energy through cellular respiration',
        'Ribosomes build proteins from amino acids',
        'The cell membrane regulates what enters and exits',
        'Plant cells have cell walls and chloroplasts that animal cells lack',
      ],
      chapters: [
        '0:00 — Overview of cell types',
        '0:40 — The nucleus and DNA',
        '1:20 — Mitochondria: power plant',
        '2:00 — Ribosomes and protein synthesis',
        '2:40 — Endoplasmic Reticulum and Golgi',
        '3:20 — Cell membrane structure',
        '4:00 — Plant vs animal cells',
        '4:30 — Summary diagram',
      ],
    ),
  ];

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
              _buildVideoHeader(video),
              const SizedBox(height: 20),
              _buildVideoDetails(video),
              const SizedBox(height: 20),
              _buildChapterList(video.chapters),
              const SizedBox(height: 20),
              _buildKeyPoints(video),
              const SizedBox(height: 20),
              if (_isWatched) _buildWatchedBadge(),
              const SizedBox(height: 24),
              _buildNavButtons(video),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoHeader(VideoContent video) {
    return Semantics(
      label: 'Video: ${video.title}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.sereneBlue.withValues(alpha: 0.2),
              AppColors.softPurple.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sereneBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 32,
                    color: AppColors.sereneBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${video.subject} · ${video.chapter}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    video.duration,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.subtitles_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${video.chapters.length} chapters',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDetails(VideoContent video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sereneBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                video.subject,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.sereneBlue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.softPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                video.chapter,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.softPurple,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChapterList(List<String> chapters) {
    return Container(
      width: double.infinity,
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
            'Video Chapters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...chapters.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 18, color: AppColors.sereneBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKeyPoints(VideoContent video) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.calmTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.calmTeal.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 20, color: AppColors.calmTeal),
              const SizedBox(width: 8),
              Text(
                'Key Takeaways',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...video.keyPoints.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.calmTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: AppColors.calmTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              label: _isWatched ? 'Watched' : 'Mark as watched',
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _isWatched = !_isWatched);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isWatched
                          ? 'Marked as watched'
                          : 'Marked as not watched'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: Icon(
                  _isWatched ? Icons.check_circle : Icons.check_circle_outline,
                  color: _isWatched ? AppColors.success : null,
                ),
                label: Text(_isWatched ? 'Watched' : 'Mark as Watched'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isWatched ? AppColors.success : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Text(
            'You watched this video',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons(VideoContent video) {
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
                    _isWatched = false;
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
                    _isWatched = false;
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
