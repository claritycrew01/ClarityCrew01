class TopicMapping {
  final String id;
  final String subject;
  final String? chapter;
  final List<String> searchQueries;
  final String difficulty;
  final bool enabled;
  final String? iconKey;
  final String? color;

  const TopicMapping({
    this.id = '',
    required this.subject,
    this.chapter,
    required this.searchQueries,
    this.difficulty = 'beginner',
    this.enabled = true,
    this.iconKey,
    this.color,
  });

  factory TopicMapping.fromJson(Map<String, dynamic> json) {
    return TopicMapping(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String,
      chapter: json['chapter'] as String?,
      searchQueries:
          (json['searchQueries'] as List<dynamic>).cast<String>(),
      difficulty: json['difficulty'] as String? ?? 'beginner',
      enabled: json['enabled'] as bool? ?? true,
      iconKey: json['iconKey'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        if (chapter != null) 'chapter': chapter,
        'searchQueries': searchQueries,
        'difficulty': difficulty,
        'enabled': enabled,
        if (iconKey != null) 'iconKey': iconKey,
        if (color != null) 'color': color,
      };
}

class TopicMapper {
  static List<TopicMapping> get defaultMappings => [
        // Algebra
        const TopicMapping(
          subject: 'Algebra',
          chapter: 'Linear Equations',
          searchQueries: [
            'linear equations algebra',
            'solving equations algebra',
            'algebra basics',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'Algebra',
          chapter: 'Linear Equations',
          searchQueries: [
            'systems of equations',
            'graphing linear equations',
          ],
          difficulty: 'intermediate',
        ),
        const TopicMapping(
          subject: 'Algebra',
          chapter: 'Polynomials',
          searchQueries: [
            'polynomials algebra',
            'factoring polynomials',
            'quadratic equations',
          ],
          difficulty: 'intermediate',
        ),

        // Biology
        const TopicMapping(
          subject: 'Biology',
          chapter: 'Cell Structure',
          searchQueries: [
            'cell biology structure',
            'cell organelles',
            'cell division mitosis',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'Biology',
          chapter: 'Genetics',
          searchQueries: [
            'genetics biology',
            'DNA structure function',
            'inheritance patterns',
          ],
          difficulty: 'intermediate',
        ),
        const TopicMapping(
          subject: 'Biology',
          chapter: 'Ecology',
          searchQueries: [
            'ecology ecosystems',
            'food chains webs',
            'biodiversity',
          ],
          difficulty: 'beginner',
        ),

        // World History
        const TopicMapping(
          subject: 'World History',
          chapter: 'The Renaissance',
          searchQueries: [
            'renaissance history',
            'italian renaissance art',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'World History',
          chapter: 'Ancient Civilizations',
          searchQueries: [
            'ancient civilizations',
            'ancient rome history',
            'ancient greece',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'World History',
          chapter: 'World Wars',
          searchQueries: [
            'world war 1 history',
            'world war 2 history',
            'causes world war',
          ],
          difficulty: 'intermediate',
        ),

        // English
        const TopicMapping(
          subject: 'English',
          chapter: 'Grammar',
          searchQueries: [
            'english grammar parts of speech',
            'sentence structure grammar',
            'punctuation grammar',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'English',
          chapter: 'Writing',
          searchQueries: [
            'essay writing structure',
            'paragraph writing',
            'creative writing',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'English',
          chapter: 'Literature',
          searchQueries: [
            'literary analysis',
            'poetry analysis',
            'reading comprehension',
          ],
          difficulty: 'intermediate',
        ),

        // Chemistry
        const TopicMapping(
          subject: 'Chemistry',
          chapter: 'Periodic Table',
          searchQueries: [
            'periodic table elements',
            'atoms elements chemistry',
            'chemical bonding',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'Chemistry',
          chapter: 'Chemical Reactions',
          searchQueries: [
            'chemical reactions equations',
            'balancing equations chemistry',
            'stoichiometry chemistry',
          ],
          difficulty: 'intermediate',
        ),

        // Geometry
        const TopicMapping(
          subject: 'Geometry',
          chapter: 'Triangles',
          searchQueries: [
            'geometry triangles',
            'pythagorean theorem',
            'congruent triangles',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'Geometry',
          chapter: 'Circles',
          searchQueries: [
            'geometry circles',
            'circle theorems',
            'area circumference circle',
          ],
          difficulty: 'beginner',
        ),

        // US History
        const TopicMapping(
          subject: 'US History',
          chapter: 'Constitution',
          searchQueries: [
            'us constitution history',
            'founding fathers constitution',
            'bill of rights',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'US History',
          chapter: 'Civil War',
          searchQueries: [
            'american civil war',
            'causes civil war us',
            'reconstruction era',
          ],
          difficulty: 'intermediate',
        ),
        const TopicMapping(
          subject: 'US History',
          chapter: 'Civil Rights',
          searchQueries: [
            'civil rights movement',
            'martin luther king',
            'brown vs board education',
          ],
          difficulty: 'intermediate',
        ),

        // Physics (new subject, auto-created)
        const TopicMapping(
          subject: 'Physics',
          chapter: 'Newton\'s Laws',
          searchQueries: [
            'newton laws motion physics',
            'forces physics',
            'gravity physics',
          ],
          difficulty: 'beginner',
        ),
        const TopicMapping(
          subject: 'Physics',
          chapter: 'Energy',
          searchQueries: [
            'energy physics',
            'kinetic potential energy',
            'conservation of energy',
          ],
          difficulty: 'intermediate',
        ),

        // Psychology (new subject, auto-created)
        const TopicMapping(
          subject: 'Psychology',
          chapter: 'Learning & Memory',
          searchQueries: [
            'learning psychology',
            'memory cognitive psychology',
            'classical conditioning',
          ],
          difficulty: 'beginner',
        ),
      ];

  static TopicMapping? findMapping(String subject, {String? chapter}) {
    for (final m in defaultMappings) {
      if (m.subject == subject) {
        if (chapter == null || m.chapter == chapter) return m;
      }
    }
    return null;
  }

  static String generateId(String subject, String? chapter) {
    final parts = [subject];
    if (chapter != null && chapter.isNotEmpty) parts.add(chapter);
    return parts
        .join('_')
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
        .replaceAll(RegExp(r"_+"), '_')
        .replaceAll(RegExp(r"^_|_$"), '');
  }
}
