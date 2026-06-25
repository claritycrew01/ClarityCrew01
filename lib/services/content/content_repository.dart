import '../../models/content_item.dart';

class ContentRepository {
  static final List<ContentItem> _lessons = [
    _focusBasics(),
    _chunkingDeepDive(),
    _visualNoteTaking(),
    _memoryTechniques(),
    _pomodoroMastery(),
    _mindMapping(),
    _activeRecall(),
    _growthMindset(),
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

  static ContentItem _focusBasics() => ContentItem(
        id: 'focus_basics',
        title: 'Focus Fundamentals',
        description: 'Build your focus muscle with simple, proven techniques.',
        contentType: 'micro_lesson',
        difficulty: 'beginner',
        estimatedDurationSeconds: 300,
        tags: ['focus', 'adhd', 'beginner'],
        body:
            'Focus is like a muscle — the more you train it, the stronger it gets. For neurodivergent learners, traditional "just concentrate" advice often falls short.\n\nStart with the 2-Minute Rule: commit to just two minutes of focused work. This lowers the barrier to starting. After two minutes, decide if you want to continue.\n\nUse external anchors: a visual timer, background noise (brown noise works well for ADHD), or a physical object on your desk that signals "focus time."\n\nReduce decision fatigue: keep only what you need for the current task visible. Hide your phone, close extra tabs, and use a single window.\n\nYour brain craves novelty, so rotate between 2-3 tasks in a session rather than forcing yourself to do only one thing.',
        quizOptions: [
          'Focus is a muscle that can be trained',
          'You either have focus or you do not',
          'Multitasking improves focus',
          'ADHD means you cannot focus at all',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_focus_1',
            title: '2-Minute Rule',
            contentType: 'flashcard',
            body: 'Commit to just two minutes of focused work to overcome the barrier to starting.',
          ),
          ContentItem(
            id: 'fc_focus_2',
            title: 'External Anchors',
            contentType: 'flashcard',
            body: 'Visual timers, brown noise, and physical objects that signal "focus time."',
          ),
          ContentItem(
            id: 'fc_focus_3',
            title: 'Task Rotation',
            contentType: 'flashcard',
            body: 'Rotate between 2-3 tasks in a session to satisfy your brain\'s need for novelty.',
          ),
        ],
      );

  static ContentItem _chunkingDeepDive() => ContentItem(
        id: 'chunking_deep',
        title: 'Chunking Deep Dive',
        description:
            'Master the art of breaking complex topics into learnable pieces.',
        contentType: 'micro_lesson',
        difficulty: 'intermediate',
        estimatedDurationSeconds: 420,
        tags: ['chunking', 'organization', 'executive-function'],
        body:
            'Chunking is the most powerful learning technique for neurodivergent minds. It works with your brain\'s natural pattern-recognition ability instead of against it.\n\nWhy chunking works: Your working memory can hold about 3-5 items at once. By grouping information into chunks, each chunk becomes one "slot" in working memory. This reduces cognitive load by up to 80%.\n\nThe Chunking Method:\n1. Scan the material and identify 3-5 main categories\n2. Group related details under each category\n3. Give each chunk a memorable name or image\n4. Practice recalling chunks in order\n5. Connect chunks into a story\n\nFor ADHD learners: use colorful sticky notes (physical or digital) for each chunk. Move them around. The physical act of organizing helps encode the information.\n\nFor autistic learners: create clear hierarchical outlines. Each chunk should have a logical, predictable relationship to the others.',
        quizOptions: [
          'Reduces cognitive load by up to 80%',
          'Makes information more complex',
          'Only works for math problems',
          'Requires a tutor',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_chunk_1',
            title: 'Working Memory Limit',
            contentType: 'flashcard',
            body: 'Working memory holds about 3-5 items at once.',
          ),
          ContentItem(
            id: 'fc_chunk_2',
            title: 'The Chunking Method',
            contentType: 'flashcard',
            body: 'Scan, group, name, practice, connect — five steps to master any topic.',
          ),
        ],
      );

  static ContentItem _visualNoteTaking() => ContentItem(
        id: 'visual_notes',
        title: 'Visual Note-Taking',
        description:
            'Use drawings, diagrams, and color to make information stick.',
        contentType: 'visual_summary',
        difficulty: 'beginner',
        estimatedDurationSeconds: 360,
        tags: ['visual', 'creativity', 'memory', 'dyslexia'],
        body:
            'Visual note-taking is a game-changer for neurodivergent learners. It uses multiple areas of the brain simultaneously — spatial, visual, kinesthetic, and verbal — creating stronger memory traces.\n\nCore techniques:\n• Mind Maps: Start with a central idea, branch out. Uses radial thinking which matches how your brain naturally works.\n• Sketchnotes: Combine handwriting with simple drawings (icons, arrows, containers). No artistic talent needed.\n• Flowcharts: Perfect for processes, sequences, and decision trees.\n• Color Coding: Assign colors to themes. Red for definitions, blue for examples, green for action items.\n\nFor dyslexic learners: Use diagrams instead of long text. Draw relationships instead of describing them. Color helps with visual tracking and reduces letter confusion.\n\nFor ADHD learners: The act of drawing while listening gives your hands a job, which helps your brain focus on the audio. It channels fidgeting into learning.',
        quizOptions: [
          'Drawings, diagrams, and color coding',
          'Writing everything in one color',
          'Typing notes without looking',
          'Recording and transcribing later',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_visual_1',
            title: 'Mind Maps',
            contentType: 'flashcard',
            body: 'A central idea with branching connections — matches your brain\'s natural thinking.',
          ),
          ContentItem(
            id: 'fc_visual_2',
            title: 'Sketchnotes',
            contentType: 'flashcard',
            body: 'Handwriting + simple drawings. No artistic talent required.',
          ),
        ],
      );

  static ContentItem _memoryTechniques() => ContentItem(
        id: 'memory_tech',
        title: 'Memory Techniques That Work',
        description:
            'Evidence-based memory strategies designed for neurodivergent brains.',
        contentType: 'visual_summary',
        difficulty: 'intermediate',
        estimatedDurationSeconds: 480,
        tags: ['memory', 'study-skills', 'executive-function'],
        body:
            'Forget traditional memorization. These techniques are built for how your brain actually works.\n\nActive Recall: The single most effective learning technique. After studying, close the book and try to remember what you learned. Every attempt to retrieve strengthens the memory. Use flashcards, cover-and-recall, or teach someone else.\n\nSpaced Repetition: Review information at increasing intervals — 1 day, 3 days, 1 week, 2 weeks, 1 month. Your brain strengthens memories just before they would be forgotten.\n\nMemory Palace (Method of Loci): Associate each item with a location in a familiar place (your home, your route to school). Walk through the location mentally to retrieve items. Works especially well for visual thinkers.\n\nInterleaving: Mix different topics in one study session. It feels harder but produces better long-term learning. Your brain has to discriminate between concepts, which deepens understanding.',
        quizOptions: [
          'Testing yourself to strengthen memory',
          'Reading the same material multiple times',
          'Highlighting key sentences',
          'Listening to recordings while sleeping',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_mem_1',
            title: 'Active Recall',
            contentType: 'flashcard',
            body: 'Close the book and try to remember — every retrieval strengthens the memory.',
          ),
          ContentItem(
            id: 'fc_mem_2',
            title: 'Spaced Repetition',
            contentType: 'flashcard',
            body: 'Review at increasing intervals: 1 day, 3 days, 1 week, 2 weeks, 1 month.',
          ),
          ContentItem(
            id: 'fc_mem_3',
            title: 'Interleaving',
            contentType: 'flashcard',
            body: 'Mix different topics in one session. Feels harder but works better.',
          ),
        ],
      );

  static ContentItem _pomodoroMastery() => ContentItem(
        id: 'pomodoro_mastery',
        title: 'Focus Sprints: Pomodoro Mastery',
        description:
            'Adapt the Pomodoro Technique for ADHD, autism, and varying energy levels.',
        contentType: 'guided_practice',
        difficulty: 'beginner',
        estimatedDurationSeconds: 300,
        tags: ['focus', 'adhd', 'autism', 'time-management'],
        body:
            'The Pomodoro Technique is perfect for neurodivergent learners — but you need to adapt it.\n\nStandard Pomodoro: 25 min work, 5 min break. But that doesn\'t work for everyone.\n\nADHD Adaptation: Start with 10-minute sprints. The key is starting, not duration. Once you\'re in flow, extend naturally. Use a visual timer (not a phone — too distracting).\n\nAutism Adaptation: Predictability matters. Keep the same break routine every time. Same drink, same activity, same duration. Routine reduces transition anxiety.\n\nDyslexia Adaptation: During breaks, rest your eyes. Look at something 20 feet away for 20 seconds. Avoid screens during breaks to reduce visual fatigue.\n\nGeneral Rule: Your focus duration will vary day to day. That\'s normal. The goal is not perfection — it\'s showing up.',
        quizOptions: [
          'Adapt the timing to your needs',
          'Always do exactly 25 minutes',
          'Never take breaks',
          'Only use it for homework',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_pom_1',
            title: 'ADHD Pomodoro',
            contentType: 'flashcard',
            body: 'Start with 10-minute sprints. Focus on starting, not duration.',
          ),
          ContentItem(
            id: 'fc_pom_2',
            title: 'Autism Pomodoro',
            contentType: 'flashcard',
            body: 'Keep the same break routine every time. Predictability reduces transition anxiety.',
          ),
        ],
      );

  static ContentItem _mindMapping() => ContentItem(
        id: 'mind_mapping',
        title: 'Mind Mapping for Complex Topics',
        description:
            'Turn overwhelming information into clear, connected visual maps.',
        contentType: 'visual_summary',
        difficulty: 'intermediate',
        estimatedDurationSeconds: 420,
        tags: ['visual', 'organization', 'creativity', 'executive-function'],
        body:
            'When a topic feels overwhelming, a mind map turns chaos into clarity.\n\nHow to build a mind map:\n1. Start with the main topic in the center of the page\n2. Draw thick branches for main subtopics (use different colors)\n3. Add thinner branches for supporting details\n4. Use single words or short phrases — not sentences\n5. Add images or symbols for key concepts\n\nWhy it works for neurodivergent brains:\n• Non-linear: matches how your brain actually connects ideas\n• Visual hierarchy: shows what\'s important at a glance\n• Reduces overwhelm: breaks big topics into visible pieces\n• Engages creativity: making it pretty helps memory\n\nTip for ADHD: Use mind maps as a "brain dump" tool. When your mind is racing, put everything on the map. The physical act of organizing thoughts is calming.\n\nTip for autism: Use mind maps to plan routines and visualize sequences. Seeing the whole structure reduces anxiety about what comes next.',
        quizOptions: [
          'A visual map of connected ideas around a central topic',
          'A list of facts in order',
          'A detailed written outline',
          'A diagram of a process',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_map_1',
            title: 'Mind Map Structure',
            contentType: 'flashcard',
            body: 'Center topic → thick branches (subtopics) → thin branches (details) → images/symbols.',
          ),
          ContentItem(
            id: 'fc_map_2',
            title: 'Brain Dump',
            contentType: 'flashcard',
            body: 'When your mind is racing, put everything on a mind map. Organizing thoughts visually is calming.',
          ),
        ],
      );

  static ContentItem _activeRecall() => ContentItem(
        id: 'active_recall',
        title: 'Active Recall Practice',
        description:
            'A guided practice session to build your active recall skill.',
        contentType: 'guided_practice',
        difficulty: 'beginner',
        estimatedDurationSeconds: 360,
        tags: ['memory', 'study-skills', 'practice'],
        body:
            'Let us practice active recall together. This is the #1 most effective learning technique.\n\nStep 1: Pick a topic you studied recently (even something from 5 minutes ago).\n\nStep 2: Close your eyes or look away. Try to remember everything about it. Say it out loud if you can — speaking uses different neural pathways than thinking.\n\nStep 3: Check what you missed. That gap? That\'s where learning happens. The struggle to remember IS the learning.\n\nStep 4: Try again. You will remember more this time.\n\nStep 5: Repeat the next day. Each recall attempt strengthens the neural pathway.\n\nRemember: Forgetting is not failure. Forgetting and remembering again is how your brain builds lasting memories. Every time you recall, the memory gets stronger.',
        quizOptions: [
          'The struggle to remember IS the learning',
          'If you forget, you are bad at studying',
          'Only smart people can use active recall',
          'Reading is better than recalling',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_recall_1',
            title: 'Active Recall',
            contentType: 'flashcard',
            body: 'The #1 most effective learning technique. Close the material and try to remember.',
          ),
          ContentItem(
            id: 'fc_recall_2',
            title: 'Forgetting is Learning',
            contentType: 'flashcard',
            body: 'Forgetting and remembering again builds lasting memories. Every recall strengthens the pathway.',
          ),
        ],
      );

  static ContentItem _growthMindset() => ContentItem(
        id: 'growth_mindset',
        title: 'Learning with a Growth Mindset',
        description:
            'Reframe challenges as opportunities. Built for neurodivergent learners.',
        contentType: 'micro_lesson',
        difficulty: 'beginner',
        estimatedDurationSeconds: 300,
        tags: ['mindset', 'motivation', 'wellbeing'],
        body:
            'A growth mindset is the belief that your abilities can develop through effort and learning. For neurodivergent learners, this mindset is essential.\n\nThe Trap of "Fixed" Thinking:\n• "I\'m not good at this" → You haven\'t learned it yet\n• "This is too hard" → This is where growth happens\n• "I made a mistake" → Mistakes are data for learning\n\nReframe for Your Brain:\n• Instead of "I can\'t focus" → "My focus works differently, and I\'m learning how to use it"\n• Instead of "I\'m bad at tests" → "I need to find a test format that works for me"\n• Instead of "Everyone else finds this easy" → "Everyone struggles with something"\n\nPractical exercise: When you catch yourself thinking "I can\'t do this," add the word "yet." I can\'t do this yet. This small change opens the door to possibility.',
        quizOptions: [
          'Abilities can develop through effort and learning',
          'You are either good at something or you are not',
          'Mistakes mean you should give up',
          'Only some people can learn new things',
        ],
        correctOptionIndex: 0,
        flashcards: [
          ContentItem(
            id: 'fc_growth_1',
            title: 'Fixed vs Growth',
            contentType: 'flashcard',
            body: '"I can\'t do this" becomes "I can\'t do this YET." A small word that opens possibility.',
          ),
          ContentItem(
            id: 'fc_growth_2',
            title: 'Mistakes are Data',
            contentType: 'flashcard',
            body: 'Mistakes are not failures — they are information about what to try next.',
          ),
        ],
      );
}
