import 'package:flutter/material.dart';
import '../../models/content_item.dart';
import '../../models/video_content.dart';
import '../../models/subject_data.dart';

class ContentRepository {
  static final List<ContentItem> _lessons = [
    _algebraLinearEquations(),
    _biologyCellStructure(),
    _historyRenaissance(),
    _englishPartsOfSpeech(),
    _chemistryPeriodicTable(),
    _geometryTriangles(),
    _historyConstitution(),
    _englishEssayStructure(),
  ];

  static final List<VideoContent> _videos = [
    _algebraVideo(),
    _biologyVideo(),
  ];

  static List<ContentItem> getAll() => _lessons;

  static ContentItem getById(String id) =>
      _lessons.firstWhere((l) => l.id == id,
          orElse: () => _lessons.first);

  static List<ContentItem> getByTags(List<String> tags) =>
      _lessons.where((l) => l.tags.any((t) => tags.contains(t))).toList();

  static List<ContentItem> getByDifficulty(String difficulty) =>
      _lessons.where((l) => l.difficulty == difficulty).toList();

  static List<ContentItem> getByType(String contentType) =>
      _lessons.where((l) => l.contentType == contentType).toList();

  static List<ContentItem> getBySubject(String subject) =>
      _lessons.where((l) => l.subject == subject).toList();

  static List<String> getAllSubjectNames() =>
      _lessons.map((l) => l.subject).toSet().toList()..sort();

  static List<String> getChaptersForSubject(String subject) =>
      _lessons
          .where((l) => l.subject == subject)
          .map((l) => l.chapter)
          .toSet()
          .toList();

  static List<VideoContent> getVideosForSubject(String subject) =>
      _videos.where((v) => v.subject == subject).toList();

  static List<VideoContent> getAllVideos() => List.unmodifiable(_videos);

  static List<SubjectData> getSubjects() => [
        _subjectAlgebra(),
        _subjectBiology(),
        _subjectWorldHistory(),
        _subjectEnglish(),
        _subjectChemistry(),
        _subjectGeometry(),
        _subjectUSHistory(),
      ];

  static ContentItem _algebraLinearEquations() => ContentItem(
        id: 'algebra_linear_eq',
        title: 'Solving Linear Equations',
        description:
            'Learn to solve equations like 2x + 5 = 13 step by step.',
        contentType: 'micro_lesson',
        difficulty: 'beginner',
        estimatedDurationSeconds: 420,
        subject: 'Algebra',
        chapter: 'Linear Equations',
        tags: ['algebra', 'equations', 'solving', 'math'],
        body:
            'A linear equation is an equation where the variable has an exponent of 1. The standard form is ax + b = c, where x is the variable, and a, b, and c are constants.\n\nTo solve a linear equation, the goal is to isolate the variable on one side of the equals sign. Whatever you do to one side, you must do to the other — this keeps the equation balanced.\n\nStep-by-step method:\n1. Simplify both sides of the equation separately (combine like terms, remove parentheses)\n2. Move all terms with the variable to one side (use addition or subtraction)\n3. Move all constant terms to the other side\n4. Divide both sides by the coefficient of the variable\n\nExample: Solve 2x + 5 = 13\nStep 1: Subtract 5 from both sides → 2x = 8\nStep 2: Divide both sides by 2 → x = 4\nCheck: 2(4) + 5 = 8 + 5 = 13 ✓\n\nExample: Solve 3x - 7 = 2x + 5\nStep 1: Subtract 2x from both sides → x - 7 = 5\nStep 2: Add 7 to both sides → x = 12\nCheck: 3(12) - 7 = 36 - 7 = 29 and 2(12) + 5 = 24 + 5 = 29 ✓\n\nVisual tip: Draw the equation as a balance scale. Each side of the equation is a pan on the scale. Adding or removing the same weight from both pans keeps it balanced.',
        quizOptions: [
          'Subtract 5 from both sides, then divide by 2',
          'Add 5 to both sides, then multiply by 2',
          'Divide by 5 on both sides',
          'Subtract 2 from both sides',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_algebra_1',
            title: 'Golden Rule of Equations',
            contentType: 'flashcard',
            body: 'Whatever you do to one side, you must do to the other to keep the equation balanced.',
          ),
          ContentItem(
            id: 'fc_algebra_2',
            title: 'Goal of Solving',
            contentType: 'flashcard',
            body: 'Isolate the variable on one side of the equals sign.',
          ),
          ContentItem(
            id: 'fc_algebra_3',
            title: 'Check Your Answer',
            contentType: 'flashcard',
            body: 'Plug the solution back into the original equation to verify both sides are equal.',
          ),
        ],
      );

  static ContentItem _biologyCellStructure() => ContentItem(
        id: 'biology_cell',
        title: 'Cell Structure and Function',
        description:
            'Explore the basic building blocks of all living organisms.',
        contentType: 'micro_lesson',
        difficulty: 'beginner',
        estimatedDurationSeconds: 480,
        subject: 'Biology',
        chapter: 'Cell Biology',
        tags: ['biology', 'cells', 'science', 'organelles'],
        body:
            'The cell is the basic unit of life. All living organisms are made of cells — some have just one (unicellular), others have trillions (multicellular).\n\nTwo main cell types:\n1. Prokaryotic cells: Simple, no nucleus. Bacteria are prokaryotes. DNA floats freely in the cytoplasm.\n2. Eukaryotic cells: Complex, have a nucleus that holds DNA. Plants, animals, fungi, and protists are eukaryotes.\n\nKey organelles in animal cells:\n• Nucleus: The control center. Contains DNA and directs cell activities.\n• Mitochondria: The power plant. Converts glucose into ATP (energy) through cellular respiration.\n• Ribosomes: Protein factories. Read RNA instructions to build proteins.\n• Endoplasmic Reticulum (ER): Transportation network. Rough ER has ribosomes (makes proteins), Smooth ER makes lipids.\n• Golgi Apparatus: The shipping center. Packages proteins and sends them where they are needed.\n• Cell Membrane: The gatekeeper. A phospholipid bilayer that controls what enters and exits the cell.\n\nMemory trick: "Nick\'s Mighty Red Eagle Guards Cells" — Nucleus, Mitochondria, Ribosomes, Endoplasmic Reticulum, Golgi, Cell membrane.',
        quizOptions: [
          'Mitochondria — they convert glucose into energy (ATP)',
          'Nucleus — it controls everything including energy',
          'Ribosomes — they build energy molecules',
          'Cell membrane — it creates energy at the surface',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_bio_1',
            title: 'Prokaryotic vs Eukaryotic',
            contentType: 'flashcard',
            body: 'Prokaryotes: no nucleus, simple, bacteria. Eukaryotes: have a nucleus, complex, plants and animals.',
          ),
          ContentItem(
            id: 'fc_bio_2',
            title: 'Nucleus Function',
            contentType: 'flashcard',
            body: 'The control center of the cell. Contains DNA and directs all cellular activities.',
          ),
          ContentItem(
            id: 'fc_bio_3',
            title: 'Mitochondria Function',
            contentType: 'flashcard',
            body: 'The power plant of the cell. Converts glucose into ATP through cellular respiration.',
          ),
        ],
      );

  static ContentItem _historyRenaissance() => ContentItem(
        id: 'history_renaissance',
        title: 'The Renaissance: A Rebirth of Ideas',
        description:
            'Discover how Europe emerged from the Middle Ages into an age of art, science, and discovery.',
        contentType: 'visual_summary',
        difficulty: 'intermediate',
        estimatedDurationSeconds: 480,
        subject: 'World History',
        chapter: 'The Renaissance',
        tags: ['history', 'renaissance', 'europe', 'art', 'culture'],
        body:
            'The Renaissance (1400-1600 CE) was a period of cultural, artistic, and intellectual rebirth in Europe after the Middle Ages. It began in Italy and spread across the continent.\n\nWhat sparked the Renaissance?\n• The fall of Constantinople (1453) sent Greek scholars to Italy with ancient texts\n• Increased trade with Asia brought wealth to Italian city-states like Florence and Venice\n• The printing press (Gutenberg, ~1440) made books available to more people\n• A shift from religious focus to humanism — the study of human potential and achievement\n\nKey figures:\n• Leonardo da Vinci (1452-1519): Artist, inventor, scientist. Painted the Mona Lisa and The Last Supper. Filled notebooks with anatomical studies and flying machine designs.\n• Michelangelo (1475-1564): Sculptor and painter. Created David and painted the Sistine Chapel ceiling.\n• Galileo Galilei (1564-1642): Scientist who improved the telescope and supported the idea that the Earth orbits the Sun.\n• William Shakespeare (1564-1616): English playwright who wrote Hamlet, Romeo and Juliet, and Macbeth.\n\nVisual overview:\n[Art] → Realism, perspective, human emotion in paintings\n[Science] → Observation, experimentation, challenging old ideas\n[Exploration] → Columbus, Magellan, new trade routes\n[Literature] → Vernacular languages replacing Latin',
        quizOptions: [
          'Humanism — a focus on human potential and achievement',
          'Feudalism — a return to medieval social structures',
          'The Crusades — religious wars that shaped Europe',
          'The Inquisition — religious authority and control',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_hist_1',
            title: 'What does Renaissance mean?',
            contentType: 'flashcard',
            body: '"Rebirth" — a period of cultural and intellectual revival in Europe from 1400-1600.',
          ),
          ContentItem(
            id: 'fc_hist_2',
            title: 'Why Italy?',
            contentType: 'flashcard',
            body: 'Italian city-states like Florence grew wealthy from trade, funding artists and thinkers.',
          ),
        ],
      );

  static ContentItem _englishPartsOfSpeech() => ContentItem(
        id: 'english_grammar',
        title: 'Parts of Speech',
        description:
            'Master the eight building blocks of English sentences.',
        contentType: 'quiz',
        difficulty: 'beginner',
        estimatedDurationSeconds: 360,
        subject: 'English',
        chapter: 'Grammar',
        tags: ['english', 'grammar', 'writing', 'parts-of-speech'],
        body:
            'Every word in English belongs to one of eight categories called parts of speech. Understanding these helps you write clearly and analyze sentences.\n\n1. Noun: A person, place, thing, or idea. Examples: dog, freedom, Paris, teacher.\n2. Pronoun: Replaces a noun. Examples: she, they, it, who, everyone.\n3. Verb: Describes an action or state of being. Examples: run, is, believe, create.\n4. Adjective: Describes a noun. Examples: blue, tall, exciting, ancient.\n5. Adverb: Describes a verb, adjective, or other adverb. Often ends in -ly. Examples: quickly, very, quite, silently.\n6. Preposition: Shows relationship between a noun/pronoun and another word. Examples: in, on, at, by, with, under, between.\n7. Conjunction: Connects words, phrases, or clauses. Examples: and, but, or, because, although.\n8. Interjection: Expresses emotion. Examples: wow!, oops!, hey!, oh!\n\nQuick test: In the sentence "The tall student quickly finished her homework," can you identify each part?\n• The = article (type of adjective)\n• tall = adjective (describes student)\n• student = noun (person)\n• quickly = adverb (describes finished)\n• finished = verb (action)\n• her = pronoun (replaces a name)\n• homework = noun (thing)',
        quizOptions: [
          'Adverb — it describes the verb "finished"',
          'Adjective — it describes the student',
          'Verb — it shows the action of finishing',
          'Noun — it is a thing called quickly',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_eng_1',
            title: 'Noun vs Verb',
            contentType: 'flashcard',
            body: 'A noun is a person, place, thing, or idea. A verb is an action or state of being.',
          ),
          ContentItem(
            id: 'fc_eng_2',
            title: 'Adjective vs Adverb',
            contentType: 'flashcard',
            body: 'An adjective describes a noun. An adverb describes a verb, adjective, or other adverb (often -ly).',
          ),
        ],
      );

  static ContentItem _chemistryPeriodicTable() => ContentItem(
        id: 'chem_periodic',
        title: 'The Periodic Table: Elements and Organization',
        description:
            'Understand how 118 elements are arranged and why that matters.',
        contentType: 'micro_lesson',
        difficulty: 'intermediate',
        estimatedDurationSeconds: 540,
        subject: 'Chemistry',
        chapter: 'Periodic Table',
        tags: ['chemistry', 'elements', 'periodic-table', 'science'],
        body:
            'The periodic table organizes all known chemical elements by their atomic number (number of protons). It was developed by Dmitri Mendeleev in 1869, who famously left gaps for elements that had not yet been discovered.\n\nHow to read the table:\n• Rows are called periods (7 total). Elements in the same period have the same number of electron shells.\n• Columns are called groups (18 total). Elements in the same group have the same number of valence electrons and similar chemical properties.\n\nKey groups:\n• Group 1 — Alkali Metals (Li, Na, K): Highly reactive, 1 valence electron. React violently with water.\n• Group 2 — Alkaline Earth Metals (Mg, Ca): Reactive, 2 valence electrons.\n• Group 17 — Halogens (F, Cl, I): Very reactive nonmetals, 7 valence electrons. Need 1 more to fill their outer shell.\n• Group 18 — Noble Gases (He, Ne, Ar): Unreactive, full outer shell. They do not form compounds naturally.\n\nImportant trends (periodic trends):\n• Atomic radius: Increases as you go down a group (more electron shells). Decreases as you go right across a period (more protons pull electrons in tighter).\n• Electronegativity: The ability to attract electrons. Increases going right and up. Fluorine is the most electronegative element.\n\nMemory tip for the first 20 elements: "Happy Henry Likes Berries Better, Can Not Obtain Food Neutrons" — H, He, Li, Be, B, C, N, O, F, Ne.',
        quizOptions: [
          'They have the same number of valence electrons',
          'They have the same atomic mass',
          'They are all metals',
          'They were discovered at the same time',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_chem_1',
            title: 'Periods vs Groups',
            contentType: 'flashcard',
            body: 'Periods are rows (same electron shells). Groups are columns (same valence electrons, similar properties).',
          ),
          ContentItem(
            id: 'fc_chem_2',
            title: 'Noble Gases',
            contentType: 'flashcard',
            body: 'Group 18. Full outer electron shell. Very stable and unreactive. He, Ne, Ar, Kr, Xe, Rn.',
          ),
          ContentItem(
            id: 'fc_chem_3',
            title: 'Electronegativity Trend',
            contentType: 'flashcard',
            body: 'Increases going right and up. Fluorine is the most electronegative element.',
          ),
        ],
      );

  static ContentItem _geometryTriangles() => ContentItem(
        id: 'geometry_triangles',
        title: 'Triangles: Types, Theorems, and Proofs',
        description:
            'Learn to classify triangles and use key theorems to solve problems.',
        contentType: 'visual_summary',
        difficulty: 'intermediate',
        estimatedDurationSeconds: 480,
        subject: 'Geometry',
        chapter: 'Triangles',
        tags: ['geometry', 'triangles', 'math', 'angles'],
        body:
            'A triangle is a three-sided polygon. It is the simplest closed shape in geometry and the most fundamental. Understanding triangles unlocks trigonometry, engineering, and physics.\n\nClassified by sides:\n• Equilateral: All 3 sides equal, all 3 angles 60°\n• Isosceles: 2 sides equal, base angles are equal\n• Scalene: No sides equal, no angles equal\n\nClassified by angles:\n• Acute: All angles < 90°\n• Right: One angle = 90°\n• Obtuse: One angle > 90°\n\nKey theorems:\n• Triangle Sum Theorem: The three interior angles always add up to 180°.\n  Proof: Draw a line parallel to one side through the opposite vertex. Alternate interior angles show the three angles form a straight line (180°).\n\n• Pythagorean Theorem (right triangles only): a² + b² = c², where c is the hypotenuse (the side opposite the right angle).\n  Example: A right triangle has legs of 3 and 4. What is the hypotenuse?\n  3² + 4² = 9 + 16 = 25. √25 = 5. The hypotenuse is 5.\n\n• Triangle Inequality Theorem: The sum of any two sides must be greater than the third side.\n  Example: Can sides of 2, 3, and 6 form a triangle? 2 + 3 = 5, which is NOT > 6. No triangle.\n\nVisual: Draw a triangle and label vertices A, B, C. The side opposite angle A is side a, opposite B is side b, opposite C is side c.',
        quizOptions: [
          '5 — from the Pythagorean theorem: 3² + 4² = 9 + 16 = 25, √25 = 5',
          '6 — just add 3 and 4 and subtract 1',
          '7 — add the two legs together',
          '25 — square the legs and add them',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_geo_1',
            title: 'Triangle Sum Theorem',
            contentType: 'flashcard',
            body: 'The three interior angles of any triangle add up to 180°.',
          ),
          ContentItem(
            id: 'fc_geo_2',
            title: 'Pythagorean Theorem',
            contentType: 'flashcard',
            body: 'a² + b² = c² for right triangles. c is the hypotenuse opposite the right angle.',
          ),
          ContentItem(
            id: 'fc_geo_3',
            title: 'Triangle Inequality',
            contentType: 'flashcard',
            body: 'The sum of any two sides must be greater than the third side for a triangle to exist.',
          ),
        ],
      );

  static ContentItem _historyConstitution() => ContentItem(
        id: 'us_history_constitution',
        title: 'The US Constitution',
        description:
            'Understand the framework of American government and your rights.',
        contentType: 'micro_lesson',
        difficulty: 'intermediate',
        estimatedDurationSeconds: 540,
        subject: 'US History',
        chapter: 'The Constitution',
        tags: ['history', 'constitution', 'government', 'civics'],
        body:
            'The US Constitution, signed in 1787, is the supreme law of the United States. It replaced the Articles of Confederation, which created a weak central government. The Constitution established a stronger federal government with three branches.\n\nThe Preamble: "We the People of the United States, in Order to form a more perfect Union, establish Justice, insure domestic Tranquility, provide for the common defence, promote the general Welfare, and secure the Blessings of Liberty to ourselves and our Posterity, do ordain and establish this Constitution for the United States of America."\n\nThe Three Branches (Separation of Powers):\n• Legislative (Article I): Congress — makes laws. Bicameral: House of Representatives (based on population) and Senate (2 per state).\n• Executive (Article II): President — enforces laws. Includes the President, Vice President, and Cabinet.\n• Judicial (Article III): Supreme Court — interprets laws. Justices serve lifetime appointments.\n\nChecks and Balances: Each branch has power to limit the others.\n• President can veto laws passed by Congress\n• Congress can override a veto with a 2/3 vote\n• Supreme Court can declare laws unconstitutional (judicial review, established in Marbury v. Madison, 1803)\n\nThe Bill of Rights: The first 10 amendments, added in 1791.\n• 1st: Freedom of speech, religion, press, assembly, petition\n• 2nd: Right to bear arms\n• 4th: Protection from unreasonable searches\n• 5th: Right to remain silent, due process\n• 8th: Protection from cruel and unusual punishment',
        quizOptions: [
          'To create a stronger federal government with checks and balances',
          'To give all power to the President',
          'To eliminate state governments',
          'To establish a monarchy',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_us_1',
            title: 'Three Branches',
            contentType: 'flashcard',
            body: 'Legislative (Congress — makes laws), Executive (President — enforces laws), Judicial (Supreme Court — interprets laws).',
          ),
          ContentItem(
            id: 'fc_us_2',
            title: 'Bill of Rights',
            contentType: 'flashcard',
            body: 'First 10 amendments to the Constitution. Includes freedom of speech, right to bear arms, protections against unreasonable searches.',
          ),
        ],
      );

  static ContentItem _englishEssayStructure() => ContentItem(
        id: 'english_essay',
        title: 'Essay Structure: Building a Strong Argument',
        description:
            'Learn the five-paragraph essay framework and persuasive writing techniques.',
        contentType: 'guided_practice',
        difficulty: 'intermediate',
        estimatedDurationSeconds: 600,
        subject: 'English',
        chapter: 'Writing',
        tags: ['english', 'writing', 'essay', 'argument'],
        body:
            'The five-paragraph essay is the standard structure for academic writing. Mastering it gives you a reliable framework for any subject.\n\nStructure overview:\n1. Introduction Paragraph\n2. Body Paragraph 1 (First main point)\n3. Body Paragraph 2 (Second main point)\n4. Body Paragraph 3 (Third main point)\n5. Conclusion Paragraph\n\nIntroduction (3-4 sentences):\n• Hook: Grab the reader\'s attention with a question, fact, or quote\n• Background: Give 1-2 sentences of context\n• Thesis statement: Your main argument in one clear sentence. This is the most important sentence of your essay.\n\nBody Paragraphs (5-7 sentences each):\n• Topic sentence: States the main idea of this paragraph\n• Evidence: Facts, quotes, or examples that support your point\n• Analysis: Explain how the evidence supports your thesis\n• Concluding/transition sentence: Wrap up the point and lead to the next paragraph\n\nConclusion (3-4 sentences):\n• Restate your thesis in different words\n• Summarize your three main points\n• Leave the reader with a final thought or call to action\n\nPractice exercise: Pick a topic (e.g., "Why exercise is important" or "The best book I have read"). Write a thesis statement using this formula:\n"Although [counterargument], [your position] because [reason 1], [reason 2], and [reason 3]."\n\nExample: "Although some say exercise takes too much time, regular physical activity is essential because it improves physical health, boosts mental wellbeing, and builds discipline."',
        quizOptions: [
          'To state your main argument clearly in one sentence',
          'To introduce the first body paragraph',
          'To ask the reader a question',
          'To summarize the entire essay',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_essay_1',
            title: 'Five-Paragraph Essay',
            contentType: 'flashcard',
            body: 'Introduction, Body 1, Body 2, Body 3, Conclusion. A reliable framework for academic writing.',
          ),
          ContentItem(
            id: 'fc_essay_2',
            title: 'Thesis Statement Formula',
            contentType: 'flashcard',
            body: '"Although [counterargument], [your position] because [reason 1], [reason 2], and [reason 3]."',
          ),
        ],
      );

  static VideoContent _algebraVideo() => VideoContent(
        id: 'vid_algebra_1',
        title: 'Solving Linear Equations Visually',
        description:
            'Watch step-by-step solutions to linear equations using a balance scale approach.',
        duration: '4:30',
        subject: 'Algebra',
        chapter: 'Linear Equations',
        difficulty: 'beginner',
        source: 'Local media asset — animated diagrams',
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
      );

  static VideoContent _biologyVideo() => VideoContent(
        id: 'vid_bio_1',
        title: 'Cell Organelles: A Tour Inside the Cell',
        description:
            'Explore the internal structure of animal and plant cells through detailed diagrams.',
        duration: '5:00',
        subject: 'Biology',
        chapter: 'Cell Biology',
        difficulty: 'beginner',
        source: 'Local media asset — animated diagrams',
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
      );

  static SubjectData _subjectAlgebra() => const SubjectData(
        name: 'Algebra',
        icon: Icons.calculate_outlined,
        color: Color(0xFF4CAF50),
        chapters: ['Linear Equations'],
        lessonCount: 1,
        videoCount: 1,
      );

  static SubjectData _subjectBiology() => const SubjectData(
        name: 'Biology',
        icon: Icons.biotech_outlined,
        color: Color(0xFF2196F3),
        chapters: ['Cell Biology'],
        lessonCount: 1,
        videoCount: 1,
      );

  static SubjectData _subjectWorldHistory() => const SubjectData(
        name: 'World History',
        icon: Icons.public_outlined,
        color: Color(0xFFFF9800),
        chapters: ['The Renaissance'],
        lessonCount: 1,
        videoCount: 0,
      );

  static SubjectData _subjectEnglish() => const SubjectData(
        name: 'English',
        icon: Icons.menu_book_outlined,
        color: Color(0xFF9C27B0),
        chapters: ['Grammar', 'Writing'],
        lessonCount: 2,
        videoCount: 0,
      );

  static SubjectData _subjectChemistry() => const SubjectData(
        name: 'Chemistry',
        icon: Icons.science_outlined,
        color: Color(0xFFE91E63),
        chapters: ['Periodic Table'],
        lessonCount: 1,
        videoCount: 0,
      );

  static SubjectData _subjectGeometry() => const SubjectData(
        name: 'Geometry',
        icon: Icons.category_outlined,
        color: Color(0xFF00BCD4),
        chapters: ['Triangles'],
        lessonCount: 1,
        videoCount: 0,
      );

  static SubjectData _subjectUSHistory() => const SubjectData(
        name: 'US History',
        icon: Icons.flag_outlined,
        color: Color(0xFF795548),
        chapters: ['The Constitution'],
        lessonCount: 1,
        videoCount: 0,
      );
}
