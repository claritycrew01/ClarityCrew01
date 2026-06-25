class VideoContent {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String subject;
  final String chapter;
  final List<String> keyPoints;
  final List<String> chapters;
  final String difficulty;
  final String source;

  const VideoContent({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.subject,
    required this.chapter,
    required this.keyPoints,
    required this.chapters,
    this.difficulty = 'beginner',
    this.source = 'Local media asset',
  });
}
