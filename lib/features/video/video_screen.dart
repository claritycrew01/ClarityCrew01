import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/colors.dart';
import '../../models/video_content.dart';
import '../../persistence/video_progress_storage.dart';
import '../../services/content/content_repository.dart';

class VideoScreen extends StatefulWidget {
  final String? videoId;
  final String? lessonId;

  const VideoScreen({
    super.key,
    this.videoId,
    this.lessonId,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final _progressStorage = VideoProgressStorage();
  late List<VideoContent> _videos;
  VideoPlayerController? _controller;
  int _currentVideoIndex = 0;
  bool _isWatched = false;
  bool _isLoadingVideo = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _videos = ContentRepository.getAllVideos();
    _currentVideoIndex = _resolveInitialIndex();
    _loadVideo();
  }

  int _resolveInitialIndex() {
    if (_videos.isEmpty) return 0;
    if (widget.videoId != null) {
      final index = _videos.indexWhere((v) => v.id == widget.videoId);
      if (index >= 0) return index;
    }
    if (widget.lessonId != null) {
      final index =
          _videos.indexWhere((v) => v.linkedLessonId == widget.lessonId);
      if (index >= 0) return index;
    }
    return 0;
  }

  Future<void> _loadVideo() async {
    await _controller?.dispose();
    _controller = null;
    if (!mounted) return;

    setState(() {
      _isLoadingVideo = true;
      _loadError = null;
    });

    if (_videos.isEmpty) {
      setState(() => _isLoadingVideo = false);
      return;
    }

    _currentVideoIndex = _currentVideoIndex.clamp(0, _videos.length - 1);
    final video = _videos[_currentVideoIndex];
    final progress = await _progressStorage.loadForVideo(video.id);
    _isWatched = progress?['watched'] as bool? ?? false;

    try {
      final controller = _createVideoController(video);
      await controller.initialize();
      final positionMs = progress?['positionMs'] as int? ?? 0;
      if (positionMs > 0) {
        await controller.seekTo(Duration(milliseconds: positionMs));
      }
      controller.addListener(_handlePlaybackProgress);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isLoadingVideo = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingVideo = false;
        _loadError = 'Could not load ${video.title}.';
      });
    }
  }

  VideoPlayerController _createVideoController(VideoContent video) {
    if (video.assetPath.startsWith('http')) {
      return VideoPlayerController.networkUrl(Uri.parse(video.assetPath));
    }
    if (kIsWeb && video.assetPath.startsWith('assets/')) {
      return VideoPlayerController.networkUrl(
        Uri.parse(video.assetPath),
      );
    }
    return VideoPlayerController.asset(video.assetPath);
  }

  void _handlePlaybackProgress() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final video = _videos[_currentVideoIndex];
    final position = controller.value.position.inMilliseconds;
    _progressStorage.saveForVideo(
      video.id,
      watched: _isWatched,
      positionMs: position,
    );

    if (!_isWatched &&
        controller.value.duration.inMilliseconds > 0 &&
        position >= controller.value.duration.inMilliseconds * 0.9) {
      setState(() => _isWatched = true);
      _progressStorage.saveForVideo(video.id, watched: true, positionMs: position);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handlePlaybackProgress);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Watch & Learn'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'No videos available yet.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              _buildSubjectHeader(video),
              const SizedBox(height: 20),
              _buildVideoPlayer(video),
              const SizedBox(height: 20),
              _buildVideoHeader(video),
              const SizedBox(height: 20),
              _buildChapterList(video.chapters),
              const SizedBox(height: 20),
              _buildKeyPoints(video),
              const SizedBox(height: 20),
              if (_isWatched) _buildWatchedBadge(),
              const SizedBox(height: 24),
              _buildNavButtons(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(VideoContent video) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: _isLoadingVideo
              ? const Center(child: CircularProgressIndicator())
                      : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _loadVideo,
                              icon: const Icon(Icons.refresh, color: Colors.white70),
                              label: const Text('Retry',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _controller != null && _controller!.value.isInitialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller!),
                            _buildPlayOverlay(),
                          ],
                        )
                      : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildPlayOverlay() {
    final controller = _controller!;
    final isPlaying = controller.value.isPlaying;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        });
      },
      child: Container(
        color: isPlaying ? Colors.transparent : Colors.black26,
        child: isPlaying
            ? const SizedBox.expand()
            : const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 72,
              ),
      ),
    );
  }

  Widget _buildSubjectHeader(VideoContent video) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        const Spacer(),
        Text(
          '${_currentVideoIndex + 1} of ${_videos.length}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
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
            Text(
              video.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              video.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
                  const Icon(Icons.offline_pin_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    video.assetPath.startsWith('http') ? 'Online video' : 'Offline video',
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
          ...chapters.map(
            (chapter) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.play_circle_outline,
                      size: 18, color: AppColors.sereneBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      chapter,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                        style: const TextStyle(
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
                onPressed: () async {
                  final video = _videos[_currentVideoIndex];
                  setState(() => _isWatched = !_isWatched);
                  await _progressStorage.saveForVideo(
                    video.id,
                    watched: _isWatched,
                    positionMs:
                        _controller?.value.position.inMilliseconds ?? 0,
                  );
                  if (!mounted) return;
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
                    _isWatched = false;
                  });
                  _loadVideo();
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
                  _loadVideo();
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
