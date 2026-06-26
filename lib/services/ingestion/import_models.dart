class ImportJob {
  final String id;
  final String topicQuery;
  final String contentType;
  final String sourceSystem;
  final String? sourceId;
  final String status;
  final int retryCount;
  final int maxRetries;
  final String? errorMessage;
  final String? errorDetails;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> logEntries;

  const ImportJob({
    required this.id,
    required this.topicQuery,
    required this.contentType,
    this.sourceSystem = 'kolibri',
    this.sourceId,
    this.status = 'pending',
    this.retryCount = 0,
    this.maxRetries = 3,
    this.errorMessage,
    this.errorDetails,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.logEntries = const [],
  });

  ImportJob copyWith({
    String? id,
    String? topicQuery,
    String? contentType,
    String? sourceSystem,
    String? sourceId,
    String? status,
    int? retryCount,
    int? maxRetries,
    String? errorMessage,
    String? errorDetails,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? logEntries,
  }) {
    return ImportJob(
      id: id ?? this.id,
      topicQuery: topicQuery ?? this.topicQuery,
      contentType: contentType ?? this.contentType,
      sourceSystem: sourceSystem ?? this.sourceSystem,
      sourceId: sourceId ?? this.sourceId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      errorMessage: errorMessage ?? this.errorMessage,
      errorDetails: errorDetails ?? this.errorDetails,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      logEntries: logEntries ?? this.logEntries,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topicQuery': topicQuery,
        'contentType': contentType,
        'sourceSystem': sourceSystem,
        'sourceId': sourceId,
        'status': status,
        'retryCount': retryCount,
        'maxRetries': maxRetries,
        'errorMessage': errorMessage,
        'errorDetails': errorDetails,
        'createdAt': createdAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'logEntries': logEntries,
      };

  factory ImportJob.fromJson(Map<String, dynamic> json) {
    return ImportJob(
      id: json['id'] as String,
      topicQuery: json['topicQuery'] as String,
      contentType: json['contentType'] as String,
      sourceSystem: json['sourceSystem'] as String? ?? 'kolibri',
      sourceId: json['sourceId'] as String?,
      status: json['status'] as String? ?? 'pending',
      retryCount: json['retryCount'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
      errorMessage: json['errorMessage'] as String?,
      errorDetails: json['errorDetails'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      logEntries: (json['logEntries'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
    );
  }
}

class KolibriContentNode {
  final String id;
  final String title;
  final String description;
  final String kind;
  final String? author;
  final String? license;
  final String? language;
  final List<KolibriFile> files;
  final List<String> tags;
  final String? parentId;
  final num? durationSeconds;
  final String? thumbnailUrl;

  const KolibriContentNode({
    required this.id,
    required this.title,
    this.description = '',
    required this.kind,
    this.author,
    this.license,
    this.language,
    this.files = const [],
    this.tags = const [],
    this.parentId,
    this.durationSeconds,
    this.thumbnailUrl,
  });

  factory KolibriContentNode.fromJson(Map<String, dynamic> json) {
    return KolibriContentNode(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      author: json['author'] as String?,
      license: json['license_name'] as String? ?? json['license'] as String?,
      language: json['lang_code'] as String? ?? json['language'] as String?,
      files: (json['files'] as List<dynamic>?)
              ?.map((e) =>
                  KolibriFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      parentId: json['parent'] as String?,
      durationSeconds: json['duration'] as num?,
      thumbnailUrl: json['thumbnail'] as String?,
    );
  }

  String get bestVideoUrl {
    final mp4Files = files.where((f) =>
        f.extension == '.mp4' && f.downloadUrl != null);
    if (mp4Files.isNotEmpty) return mp4Files.first.downloadUrl!;
    final anyVideo = files
        .where((f) => f.downloadUrl != null && f.preset?.contains('video') == true);
    if (anyVideo.isNotEmpty) return anyVideo.first.downloadUrl!;
    for (final f in files) {
      if (f.downloadUrl != null) return f.downloadUrl!;
    }
    return '';
  }
}

class KolibriFile {
  final String id;
  final String? downloadUrl;
  final String? preset;
  final int? fileSize;
  final String? extension;
  final String? checksum;

  const KolibriFile({
    required this.id,
    this.downloadUrl,
    this.preset,
    this.fileSize,
    this.extension,
    this.checksum,
  });

  factory KolibriFile.fromJson(Map<String, dynamic> json) {
    return KolibriFile(
      id: json['id'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ??
          json['storage_url'] as String?,
      preset: json['preset'] as String?,
      fileSize: json['file_size'] as int?,
      extension: json['extension'] as String?,
      checksum: json['checksum'] as String?,
    );
  }
}

class ImportResult {
  final String topicQuery;
  final bool success;
  final int itemsFound;
  final int itemsImported;
  final int itemsFailed;
  final List<String> errors;
  final List<String> createdContentIds;
  final Duration duration;

  const ImportResult({
    required this.topicQuery,
    required this.success,
    this.itemsFound = 0,
    this.itemsImported = 0,
    this.itemsFailed = 0,
    this.errors = const [],
    this.createdContentIds = const [],
    this.duration = Duration.zero,
  });
}
