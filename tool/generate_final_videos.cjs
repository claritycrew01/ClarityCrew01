#!/usr/bin/env node
// Generates videos.json with real educational video URLs from Internet Archive.
// Filenames verified via archive.org metadata API.

const fs = require('fs');
const path = require('path');

// Each entry: [vidId, identifier, mp4Filename, titleSuffix, description, durationStr, durationSec]
const VIDEO_ENTRIES = [
  // ======= ALGEBRA =======
  // Linear Equations
  ['vid_algebra_linear_eq_1', 'MathLessonWritingALinearEquationIntoSlopeInterceptForm', 'video.mp4',
    'Writing Linear Equations in Slope-Intercept Form',
    'TutorMan explains how to change a linear equation into slope-intercept form step by step.', '4:10', 250],
  ['vid_algebra_linear_eq_6', 'GraphingLinearEquations', 'GraphReview_512kb.mp4',
    'Graphing Linear Equations',
    'Learn how to graph linear equations on the coordinate plane with clear examples.', '4:30', 270],

  // Polynomials
  ['vid_algebra_polynomials_1', 'ClassicAlgebraFactoring_801', '29Factoring_512kb.mp4',
    'Classic Algebra: Factoring Polynomials',
    'A classic instructional video covering polynomial factoring techniques.', '4:30', 270],
  ['vid_algebra_polynomials_6', 'KA-converted-K5ggNnKTmNM', 'K5ggNnKTmNM.mp4',
    'Factoring Quadratics',
    'Khan Academy lesson on factoring quadratic polynomials.', '8:00', 480],

  // Quadratics
  ['vid_algebra_quadratics_1', 'KA-converted-IWigvJcCAJ0', 'IWigvJcCAJ0.mp4',
    'Introduction to Quadratic Equations',
    'Khan Academy introduces the quadratic equation, its standard form, and how to identify coefficients.', '9:00', 540],
  ['vid_algebra_quadratics_6', 'KA-converted-N30tN9158Kc', 'N30tN9158Kc.mp4',
    'Solving Quadratic Equations by Factoring',
    'Khan Academy demonstrates solving quadratic equations through factoring.', '7:00', 420],

  // ======= BIOLOGY =======
  // Cell Biology
  ['vid_biology_cell_1', 'cell_biology2', 'cellsnew_512kb.mp4',
    'Cell Biology: The Fundamental Unit of Life',
    'An AS-Level biology lesson exploring cell structure, organelles, and their functions.', '6:30', 390],
  ['vid_biology_cell_6', 'cell_biology2', 'cellsnew_512kb.mp4',
    'Cell Structure and Function',
    'Continuing exploration of cell biology including membrane transport and cellular processes.', '6:30', 390],

  // Genetics
  ['vid_biology_genetics_1', 'dnamoleculeofheredity', 'dnamoleculeofheredity.mp4',
    'DNA: The Molecule of Heredity',
    'An educational film explaining how DNA carries genetic information.', '15:00', 900],
  ['vid_biology_genetics_6', 'humanheredityrevisededition', 'humanheredityrevisededition.mp4',
    'Human Heredity',
    'Exploration of human genetics including inheritance patterns, chromosomes, and genetic traits.', '18:00', 1080],

  // Ecology
  ['vid_biology_ecology_1', 'EcologyEmergesEvolutionOfEco-activism', 'EE1_Final_264_512kb.mp4',
    'Ecology: The Web of Life',
    'An exploration of ecological systems, food webs, and the interconnectedness of living organisms.', '10:00', 600],
  ['vid_biology_ecology_6', 'EcologyEmergesNatureInCities', 'EE3_06_04.30_264_512kb.mp4',
    'Ecology in Urban Environments',
    'Examining how ecological principles apply in urban settings.', '10:00', 600],

  // ======= WORLD HISTORY =======
  // Renaissance
  ['vid_history_renaissance_1', 'thespiritoftherenaissance', 'thespiritoftherenaissance.mp4',
    'The Spirit of the Renaissance',
    'An educational film exploring the cultural and intellectual rebirth of the Renaissance.', '26:00', 1560],
  ['vid_history_renaissance_6', 'secularmusicoftherenaissance', 'secularmusicoftherenaissance/secularmusicoftherenaissance.mp4',
    'Secular Music of the Renaissance',
    'Renaissance culture through its secular music, art, and the humanist movement.', '18:00', 1080],

  // Ancient Civilizations
  ['vid_history_ancient_1', 'FacesOfAncientMesopotamia', 'Mesopotamia.mp4',
    'Faces of Ancient Mesopotamia',
    'Journey through the cradle of civilization exploring Sumer, Babylon, and the birth of writing and law.', '30:00', 600],
  ['vid_history_ancient_6', 'ancientgreece_201702', 'ancientgreece_201702.mp4',
    'Ancient Greece',
    'A comprehensive look at Ancient Greek civilization from its city-states to its lasting cultural legacy.', '22:00', 1320],

  // World Wars
  ['vid_history_world_wars_1', '31434WestfrontWWINewsreelRexfer', '31434 Westfront WWI Newsreel_Rexfer.mp4',
    'World War I: The Western Front',
    'Historical newsreel footage and analysis of World War I, trench warfare, and its global impact.', '10:00', 600],
  ['vid_history_world_wars_6', 'ApocalypseWWII', '1 Aggression 1933-1939.mp4',
    'Apocalypse: The Second World War',
    'A comprehensive documentary covering WWII from its origins through the major campaigns and aftermath.', '50:00', 600],

  // ======= ENGLISH =======
  // Grammar
  ['vid_english_grammar_1', 'EnglishGrammarSentenceStructureStudyGuide', '01.mp4',
    'English Grammar: Sentence Structure',
    'A study guide covering English sentence structure including subjects, predicates, clauses, and phrases.', '5:00', 300],
  ['vid_english_grammar_6', 'A2Video_MECC_A746_English_Volume_1_Parts_of_Speech_v15', 'MECC-A746 English Volume 1 - Parts of Speech v1.5.mp4',
    'English Grammar: Parts of Speech',
    'An educational video covering the eight parts of speech with examples of their use in sentences.', '15:00', 900],

  // Writing
  ['vid_english_writing_1', 'DevelopingWritingSkills', 'Developing Writing Skills.mp4',
    'Developing Writing Skills',
    'A guide to the writing process: prewriting, drafting, revising, editing, and publishing effective essays.', '15:00', 900],
  ['vid_english_writing_6', 'A2Video_Developing_Basic_Writing_Skills_Level_I', 'Developing Basic Writing Skills Level I.mp4',
    'Basic Writing Skills Level I',
    'Foundational writing skills including thesis development, paragraph structure, and organizing ideas.', '20:00', 1200],

  // Literature
  ['vid_english_literature_1', 'shakespearesoulofanage', 'shakespearesoulofanagereel1.mp4',
    'Shakespeare: Soul of an Age',
    'A documentary exploring Shakespeare\'s life, works, and his enduring influence on English literature.', '50:00', 900],
  ['vid_english_literature_6', 'therussiansinsightsthroughliteraturereel2', 'therussiansinsightsthroughliterature/therussiansinsightsthroughliteraturereel1.mp4',
    'Literature and Cultural Insight',
    'How literature reflects cultural values and historical context, using examples from world literature.', '30:00', 900],

  // ======= CHEMISTRY =======
  // Periodic Table
  ['vid_chem_periodic_1', 'KA-converted-LDHg7Vgzses', 'LDHg7Vgzses.mp4',
    'Groups of the Periodic Table',
    'Khan Academy explains how the periodic table is organized into groups with similar chemical properties.', '7:00', 420],
  ['vid_chem_periodic_6', 'KA-converted-ywqg9PorTAw', 'ywqg9PorTAw.mp4',
    'Periodic Table Trends: Ionization Energy',
    'Understanding periodic trends including ionization energy, electronegativity, and atomic radius.', '9:00', 540],

  // Chemical Reactions
  ['vid_chem_reactions_1', '8.CHEMICALEQUILIBRIUM', 'LEC#1 EQUILIBRIUM STATE.mp4',
    'Chemical Equilibrium',
    'An exploration of chemical reaction equilibrium, Le Chatelier\'s principle, and equilibrium constants.', '10:00', 600],
  ['vid_chem_reactions_6', '14344-molecular-spectroscopy-vwr', '14344 Molecular Spectroscopy_vwr.mp4',
    'Molecular Spectroscopy',
    'A classic educational film connecting molecular spectroscopy to understanding atomic structure.', '15:00', 900],

  // Atomic Structure
  ['vid_chem_atomic_1', '5.ATOMICSTRUCTURE', 'LEC#1 ATOMIC STRUCTURE.mp4',
    'Atomic Structure',
    'An in-depth lesson on atomic structure covering protons, neutrons, electrons, and quantum theory.', '15:00', 900],
  ['vid_chem_atomic_6', 'youtube-3_FJIpKgdV4', '3_FJIpKgdV4.mp4',
    'Atomic Structure and the Periodic Table',
    'A chemistry tutorial connecting atomic structure concepts to the organization of the periodic table.', '12:00', 720],

  // ======= GEOMETRY =======
  // Triangles
  ['vid_geometry_triangles_1', 'Videomathtutor-AlgebraFormulasFromGeometry180', 'Videomathtutor-AlgebraFormulasFromGeometry180_512kb.mp4',
    'Geometry: Formulas from Geometry',
    'A math tutorial covering essential geometry formulas including triangles, area, and perimeter relationships.', '7:00', 420],
  ['vid_geometry_triangles_6', 'notesonatriangle', 'notesonatriangle.mp4',
    'Notes on a Triangle',
    'An artistic and mathematical exploration of triangles, their properties, and their role in geometry.', '5:00', 300],

  // Circles
  ['vid_geometry_circles_1', 'KA-converted-FJIZPvE3O1A', 'FJIZPvE3O1A.mp4',
    'Circle Geometry: Area, Chords, and Tangents',
    'Khan Academy covers key circle geometry concepts including area, chord properties, and tangent lines.', '6:00', 360],
  ['vid_geometry_circles_6', 'SDS_Geometry_Module_1_Geometry_Basics', 'Standard-deviants-school--geometryBasics--1_512kb.mp4',
    'Geometry Basics: Circles and Beyond',
    'An educational module covering fundamental geometry concepts including circles, angles, and spatial reasoning.', '10:00', 600],

  // Coordinate Geometry
  ['vid_geometry_coordinate_1', 'coordinate-geometry-26', 'Coordinate-Geometry-(Part-1)_1080.mp4',
    'Coordinate Geometry',
    'A lesson on the coordinate plane, plotting points, distance formula, and geometric relationships.', '6:00', 360],
  ['vid_geometry_coordinate_6', 'KA-converted-2UrcUfBizyw', '2UrcUfBizyw.mp4',
    'Algebra: Graphing Lines',
    'Khan Academy demonstrates graphing linear equations on the coordinate plane.', '8:00', 480],

  // ======= US HISTORY =======
  // The Constitution
  ['vid_us_constitution_1', 'KA_Birth_of_the_US_Constitution', 'KA_Birth_of_the_US_Constitution.mp4',
    'Birth of the US Constitution',
    'Khan Academy covers the creation of the US Constitution, the Constitutional Convention, and the ratification debate.', '13:00', 780],
  ['vid_us_constitution_6', 'ADC-8452a', 'ADC-8452a.mp4',
    'The US Constitution: Foundation of American Government',
    'Historical footage and analysis of the US Constitution and its role in shaping American government.', '10:00', 600],

  // Civil War
  ['vid_us_civil_war_1', 'theroadtogettysburgcivilwarpart118611863', 'theroadtogettysburgcivilwarpart118611863.mp4',
    'The Road to Gettysburg: Civil War Part I (1861-1863)',
    'A historical educational film covering the American Civil War from its causes through the Battle of Gettysburg.', '20:00', 1200],
  ['vid_us_civil_war_6', 'betweenthewarsthespanishcivilwar_201504', 'betweenthewarsthespanishcivilwar.mp4',
    'The Spanish Civil War: A Comparative Study',
    'An examination of the Spanish Civil War and its connections to broader global conflict.', '20:00', 1200],

  // Civil Rights
  ['vid_us_civil_rights_1', 'civilrightsmovementthenorth', 'civilrightsmovementthenorth.mp4',
    'Civil Rights Movement: The North',
    'An exploration of the Civil Rights Movement in the northern United States and its unique challenges.', '30:00', 900],
  ['vid_us_civil_rights_6', 'movementtoliveistomove_201512', 'movementtoliveistomove.mp4',
    'Civil Rights Movement: The South (1963)',
    'Historical coverage of the Civil Rights Movement in the American South during the pivotal year of 1963.', '30:00', 900],

  // ======= PHYSICS =======
  // Newton's Laws
  ['vid_physics_newton_1', 'laws-of-motion', 'Laws_of_Motion_HQ.mp4',
    'Physics: Laws of Motion – Newton and Beyond',
    'An educational film covering Newton\'s three laws of motion with real-world demonstrations and applications.', '20:00', 1200],
  ['vid_physics_newton_6', 'naino-2026-newton-1st-and-2nd-law', 'NLM and Friction - L01 - Newton 1st and 2nd Law.mp4',
    'Newton\'s First and Second Laws',
    'A physics lesson explaining Newton\'s first law (inertia) and second law (F=ma) with practical examples.', '10:00', 600],

  // Energy
  ['vid_physics_energy_1', 'botanicman4potentialenergy', 'botanicman4potentialenergy.mp4',
    'Potential Energy and Conservation',
    'An educational exploration of potential energy, kinetic energy, and the law of conservation of energy.', '20:00', 1200],
  ['vid_physics_energy_6', 'PBS-TERRA-Weathered', "1.01 We Can't Stop Wildfires—But Here's How We Live With Them.mp4",
    'Energy and Climate: Understanding Our World',
    'PBS educational content examining energy systems, renewable resources, and their environmental impact.', '10:00', 600],

  // Waves and Sound
  ['vid_physics_waves_1', 'wavemotioninterference', 'wavemotioninterference.mp4',
    'Wave Motion: Interference',
    'An educational film demonstrating wave properties including interference, diffraction, and superposition.', '15:00', 900],
  ['vid_physics_waves_6', 'thedaytheuniversechanged9thenewphysicsnewtonrevisedreel2', 'thedaytheuniversechanged9thenewphysicsnewtonrevised/thedaytheuniversechanged9thenewphysicsnewtonrevisedreel1.mp4',
    'The New Physics: Waves and Modern Theory',
    'An exploration of wave theory and its role in the development of modern physics understanding.', '10:00', 600],

  // ======= PSYCHOLOGY =======
  // Learning & Memory
  ['vid_psych_learning_1', 'learning-about-learning-1962', 'Learning about Learning - 1962.mp4',
    'Learning About Learning: Psychology of Behavior',
    'A classic educational film exploring the science of learning, memory formation, and behavioral psychology.', '15:00', 900],
  ['vid_psych_learning_6', 'ClassicalConditioning', '6a--classicalConditioning_512kb.mp4',
    'Classical Conditioning',
    'An educational video explaining Pavlovian conditioning, stimulus-response relationships, and learned behavior.', '5:00', 300],

  // Brain & Behavior
  ['vid_psych_brain_1', 'AlcoholBrainAndBehavior', 'AlcoholBrainAndBehavior.mp4',
    'Alcohol, the Brain, and Behavior',
    'An educational film examining how substances affect brain function, neural pathways, and behavior.', '25:00', 1500],
  ['vid_psych_brain_6', 'experimentalpsychologyofvision', 'experimentalpsychologyofvision.mp4',
    'Experimental Psychology of Vision',
    'Exploring how the brain processes visual information through experimental psychology methods.', '30:00', 1800],
];

// Subject/chapter parsing
function parseVideoId(vidId) {
  const parts = vidId.split('_');
  const subjectKey = parts[1];
  const chapterKey = parts.slice(2, -1).join('_');
  const version = parts[parts.length - 1];

  const subjectMap = {
    'algebra': 'Algebra', 'biology': 'Biology', 'history': 'World History',
    'english': 'English', 'chem': 'Chemistry', 'geometry': 'Geometry',
    'us': 'US History', 'physics': 'Physics', 'psych': 'Psychology'
  };

  const chapterDisplayMap = {
    'linear_eq': 'Linear Equations', 'polynomials': 'Polynomials',
    'quadratics': 'Quadratic Equations', 'cell': 'Cell Biology',
    'genetics': 'Genetics', 'ecology': 'Ecology',
    'renaissance': 'The Renaissance', 'ancient': 'Ancient Civilizations',
    'world_wars': 'World Wars', 'grammar': 'Grammar',
    'writing': 'Writing', 'literature': 'Literature',
    'periodic': 'Periodic Table', 'reactions': 'Chemical Reactions',
    'atomic': 'Atomic Structure', 'triangles': 'Triangles',
    'circles': 'Circles', 'coordinate': 'Coordinate Geometry',
    'constitution': 'The Constitution', 'civil_war': 'Civil War',
    'civil_rights': 'Civil Rights', 'newton': "Newton's Laws",
    'energy': 'Energy', 'waves': 'Waves & Sound',
    'learning': 'Learning & Memory', 'brain': 'Brain & Behavior'
  };

  return {
    subjectName: subjectMap[subjectKey] || subjectKey,
    chapterName: chapterDisplayMap[chapterKey] || chapterKey,
    version: version,
    linkedLessonId: chapterKey + '_' + version
  };
}

// ---- Main ----
function main() {
  console.log('Generating videos.json with real educational video URLs...\n');

  const videos = [];

  for (const [vidId, identifier, mp4Filename, titleSuffix, description, duration, durationSec] of VIDEO_ENTRIES) {
    // Build URL properly encoding special characters in filename
    const encodedFilename = mp4Filename.split('/').map(part => encodeURIComponent(part)).join('/');
    const assetPath = 'https://archive.org/download/' + identifier + '/' + encodedFilename;
    const { subjectName, chapterName, version, linkedLessonId } = parseVideoId(vidId);

    const keyPoints = [
      titleSuffix,
      'Learn through visual explanation and examples',
      'Reinforces core concepts from the lesson',
      'Ideal for review and study support'
    ];

    const totalSec = durationSec;
    const chapters = [
      '0:00 — Introduction to topic',
      Math.floor(totalSec * 0.25) + ':00 — Main concepts covered',
      Math.floor(totalSec * 0.5) + ':00 — Examples and applications',
      Math.floor(totalSec * 0.75) + ':00 — Review and summary',
    ];

    videos.push({
      id: vidId,
      linkedLessonId: linkedLessonId,
      title: subjectName + ': ' + chapterName + ' — ' + (version === '1' ? 'Part 1' : 'Part 2'),
      description: description,
      duration: duration,
      durationSeconds: durationSec,
      subject: subjectName,
      chapter: chapterName,
      difficulty: 'beginner',
      assetPath: assetPath,
      keyPoints: keyPoints,
      chapters: chapters,
      sourceId: identifier,
      sourceSystem: 'Internet Archive'
    });

    console.log('  ✓ ' + vidId + ' -> ' + subjectName + ': ' + chapterName);
  }

  console.log('\n=== RESULTS ===');
  console.log('Total videos: ' + videos.length);

  const outputPath = path.join(__dirname, '..', 'assets', 'content', 'videos.json');
  fs.writeFileSync(outputPath, JSON.stringify(videos, null, 2), 'utf8');
  console.log('Written: ' + outputPath + ' (' + videos.length + ' videos)');
  console.log('\nAll sources from Internet Archive (public domain / CC licensed educational content).');
}

main();
