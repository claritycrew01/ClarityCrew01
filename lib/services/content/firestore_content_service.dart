import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../../models/content_item.dart';
import '../../models/subject_data.dart';
import '../../models/video_content.dart';
import 'subject_icon_registry.dart';

class FirestoreContentService {
  FirestoreContentService._();
  static final FirestoreContentService instance = FirestoreContentService._();

  List<ContentItem> _lessons = [];
  List<VideoContent> _videos = [];
  List<_SubjectRecord> _subjects = [];
  List<_ChapterRecord> _chapters = [];
  bool _initialized = false;
  bool _usingRemote = false;
  bool _firestoreAvailable = true;

  bool get isInitialized => _initialized;
  bool get usingRemote => _usingRemote;

  Future<void> initialize() async {
    if (_initialized) return;

    _firestoreAvailable = await _tryInitFirebase();

    if (_firestoreAvailable) {
      final loaded = await _loadFromFirestore();
      if (loaded) {
        _usingRemote = true;
        _initialized = true;
        return;
      }
    }

    await _loadFromBundle();
    _initialized = true;
  }

  Future<bool> _tryInitFirebase() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadFromFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final subjectsSnapshot = await firestore.collection('subjects').get();
      final chaptersSnapshot = await firestore.collection('chapters').get();
      final lessonsSnapshot = await firestore.collection('lessons').get();
      final videosSnapshot = await firestore.collection('videos').get();

      if (subjectsSnapshot.docs.isEmpty) return false;

      _subjects = subjectsSnapshot.docs
          .map((doc) =>
              _SubjectRecord.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _chapters = chaptersSnapshot.docs
          .map((doc) =>
              _ChapterRecord.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _lessons = lessonsSnapshot.docs
          .map((doc) =>
              ContentItem.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _videos = videosSnapshot.docs
          .map((doc) =>
              VideoContent.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadFromBundle() async {
    final subjectsJson =
        await rootBundle.loadString('assets/content/subjects.json');
    final chaptersJson =
        await rootBundle.loadString('assets/content/chapters.json');
    final lessonsJson =
        await rootBundle.loadString('assets/content/lessons.json');
    final videosJson =
        await rootBundle.loadString('assets/content/videos.json');

    _subjects = (jsonDecode(subjectsJson) as List<dynamic>)
        .map((e) => _SubjectRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    _chapters = (jsonDecode(chaptersJson) as List<dynamic>)
        .map((e) => _ChapterRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    _lessons = (jsonDecode(lessonsJson) as List<dynamic>)
        .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _videos = (jsonDecode(videosJson) as List<dynamic>)
        .map((e) => VideoContent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<ContentItem> get allLessons => List.unmodifiable(_lessons);
  List<VideoContent> get allVideos => List.unmodifiable(_videos);
  List<_SubjectRecord> get allSubjects => List.unmodifiable(_subjects);
  List<_ChapterRecord> get allChapters => List.unmodifiable(_chapters);

  Future<void> seedFromBundle() async {
    if (!_firestoreAvailable) return;

    await _loadFromBundle();
    final firestore = FirebaseFirestore.instance;

    final batch = firestore.batch();

    for (final subject in _subjects) {
      final ref = firestore.collection('subjects').doc(subject.id);
      batch.set(ref, subject.toJson());
    }

    for (final chapter in _chapters) {
      final ref = firestore.collection('chapters').doc(chapter.id);
      batch.set(ref, chapter.toJson());
    }

    for (final lesson in _lessons) {
      final ref = firestore.collection('lessons').doc(lesson.id);
      final map = lesson.toJson();
      map.remove('flashcards');
      batch.set(ref, map);
      for (final flashcard in lesson.flashcards) {
        final fcRef = firestore
            .collection('lessons')
            .doc(lesson.id)
            .collection('flashcards')
            .doc(flashcard.id);
        batch.set(fcRef, flashcard.toJson());
      }
    }

    for (final video in _videos) {
      final ref = firestore.collection('videos').doc(video.id);
      batch.set(ref, video.toJson());
    }

    await batch.commit();
  }
}

class _SubjectRecord {
  final String id;
  final String name;
  final String iconKey;
  final String color;

  const _SubjectRecord({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.color,
  });

  factory _SubjectRecord.fromJson(Map<String, dynamic> json) {
    return _SubjectRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['iconKey'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'color': color,
      };
}

class _ChapterRecord {
  final String id;
  final String subjectId;
  final String title;
  final int order;

  const _ChapterRecord({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.order,
  });

  factory _ChapterRecord.fromJson(Map<String, dynamic> json) {
    return _ChapterRecord(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'order': order,
      };
}
