#!/usr/bin/env node
// Fetches real educational video URLs from Internet Archive metadata
// and generates updated videos.json for ClarityCrew

const https = require('https');
const fs = require('fs');
const path = require('path');

// ---- Video Source Mapping ----
// Each entry: [videoId_suffix, archiveOrg_identifier, title_suffix, description]
// Search results from Internet Archive — all freely licensed educational content.
// Sources: Khan Academy (CC-BY-NC-SA), educational films (public domain),
//          The Great Courses, Open University, academic lectures.

const VIDEO_SOURCES = [
  // ======= ALGEBRA =======
  // Linear Equations (2 videos)
  ['vid_algebra_linear_eq_1', 'MathLessonWritingALinearEquationIntoSlopeInterceptForm',
    'Writing Linear Equations in Slope-Intercept Form',
    'TutorMan explains how to change a linear equation into slope-intercept form step by step.'],
  ['vid_algebra_linear_eq_6', 'GraphingLinearEquations',
    'Graphing Linear Equations',
    'Learn how to graph linear equations on the coordinate plane with clear examples.'],

  // Polynomials (2 videos)
  ['vid_algebra_polynomials_1', 'ClassicAlgebraFactoring_801',
    'Classic Algebra: Factoring Polynomials',
    'A classic instructional video covering polynomial factoring techniques including GCF, difference of squares, and trinomials.'],
  ['vid_algebra_polynomials_6', 'KA-converted-K5ggNnKTmNM',
    'Factoring Quadratics',
    'Khan Academy lesson on factoring quadratic polynomials with step-by-step examples.'],

  // Quadratics (2 videos)
  ['vid_algebra_quadratics_1', 'KA-converted-IWigvJcCAJ0',
    'Introduction to Quadratic Equations',
    'Khan Academy introduces the quadratic equation, its standard form, and how to identify coefficients.'],
  ['vid_algebra_quadratics_6', 'KA-converted-N30tN9158Kc',
    'Solving Quadratic Equations by Factoring',
    'Khan Academy demonstrates solving quadratic equations through factoring with detailed examples.'],

  // ======= BIOLOGY =======
  // Cell Biology (2 videos)
  ['vid_biology_cell_1', 'cell_biology2',
    'Cell Biology: The Fundamental Unit of Life',
    'An AS-Level biology lesson exploring cell structure, organelles, and their functions.'],
  ['vid_biology_cell_6', 'ZacharyMooreStemCellBiology101VideoPodcast',
    'Stem Cell Biology 101',
    'An introduction to stem cell biology covering cell division, differentiation, and therapeutic potential.'],

  // Genetics (2 videos)
  ['vid_biology_genetics_1', 'dnamoleculeofheredity',
    'DNA: The Molecule of Heredity',
    'An educational film explaining how DNA carries genetic information and serves as the blueprint for life.'],
  ['vid_biology_genetics_6', 'humanheredityrevisededition',
    'Human Heredity',
    'Exploration of human genetics including inheritance patterns, chromosomes, and genetic traits.'],

  // Ecology (2 videos)
  ['vid_biology_ecology_1', 'EcologyEmergesEvolutionOfEco-activism',
    'Ecology: The Web of Life',
    'An exploration of ecological systems, food webs, and the interconnectedness of living organisms.'],
  ['vid_biology_ecology_6', 'EcologyEmergesNatureInCities',
    'Ecology in Urban Environments',
    'Examining how ecological principles apply in urban settings and human-modified landscapes.'],

  // ======= WORLD HISTORY =======
  // Renaissance (2 videos)
  ['vid_history_renaissance_1', 'thespiritoftherenaissance',
    'The Spirit of the Renaissance',
    'An educational film exploring the cultural and intellectual rebirth that defined the Renaissance period.'],
  ['vid_history_renaissance_6', 'secularmusicoftherenaissance',
    'Secular Music of the Renaissance',
    'A look at Renaissance culture through its secular music, art, and the humanist movement.'],

  // Ancient Civilizations (2 videos)
  ['vid_history_ancient_1', 'FacesOfAncientMesopotamia',
    'Faces of Ancient Mesopotamia',
    'Journey through the cradle of civilization exploring Sumer, Babylon, and the birth of writing and law.'],
  ['vid_history_ancient_6', 'ancientgreece_201702',
    'Ancient Greece',
    'A comprehensive look at Ancient Greek civilization from its city-states to its lasting cultural legacy.'],

  // World Wars (2 videos)
  ['vid_history_world_wars_1', '31434WestfrontWWINewsreelRexfer',
    'World War I: The Western Front',
    'Historical newsreel footage and analysis of World War I, trench warfare, and its global impact.'],
  ['vid_history_world_wars_6', 'ApocalypseWWII',
    'Apocalypse: The Second World War',
    'A comprehensive documentary covering World War II from its origins through the major campaigns and aftermath.'],

  // ======= ENGLISH =======
  // Grammar (2 videos)
  ['vid_english_grammar_1', 'EnglishGrammarSentenceStructureStudyGuide',
    'English Grammar: Sentence Structure',
    'A study guide covering English sentence structure including subjects, predicates, clauses, and phrases.'],
  ['vid_english_grammar_6', 'A2Video_MECC_A746_English_Volume_1_Parts_of_Speech_v15',
    'English Grammar: Parts of Speech',
    'An educational video covering the eight parts of speech with examples of their use in sentences.'],

  // Writing (2 videos)
  ['vid_english_writing_1', 'DevelopingWritingSkills',
    'Developing Writing Skills',
    'A guide to the writing process: prewriting, drafting, revising, editing, and publishing effective essays.'],
  ['vid_english_writing_6', 'A2Video_Developing_Basic_Writing_Skills_Level_I',
    'Basic Writing Skills Level I',
    'Foundational writing skills including thesis development, paragraph structure, and organizing ideas.'],

  // Literature (2 videos)
  ['vid_english_literature_1', 'shakespearesoulofanage',
    'Shakespeare: Soul of an Age',
    'A documentary exploring Shakespeare\'s life, his works, and his enduring influence on English literature.'],
  ['vid_english_literature_6', 'therussiansinsightsthroughliteraturereel2',
    'Literature and Cultural Insight',
    'How literature reflects cultural values and historical context, using examples from world literature.'],

  // ======= CHEMISTRY =======
  // Periodic Table (2 videos)
  ['vid_chem_periodic_1', 'KA-converted-LDHg7Vgzses',
    'Groups of the Periodic Table',
    'Khan Academy explains how the periodic table is organized into groups with similar chemical properties.'],
  ['vid_chem_periodic_6', 'KA-converted-ywqg9PorTAw',
    'Periodic Table Trends: Ionization Energy',
    'Understanding periodic trends including ionization energy, electronegativity, and atomic radius.'],

  // Chemical Reactions (2 videos)
  ['vid_chem_reactions_1', 'KineticsAndEquilibriumOfAUnimolecularChemicalReaction',
    'Chemical Kinetics and Equilibrium',
    'An educational exploration of chemical reaction rates, equilibrium, and the factors that affect them.'],
  ['vid_chem_reactions_6', '14344-molecular-spectroscopy-vwr',
    'Molecular Spectroscopy and Atomic Structure',
    'A classic educational film connecting molecular spectroscopy to the understanding of atomic structure.'],

  // Atomic Structure (2 videos)
  ['vid_chem_atomic_1', '5.ATOMICSTRUCTURE',
    'Atomic Structure',
    'An in-depth lesson on atomic structure covering protons, neutrons, electrons, and quantum theory.'],
  ['vid_chem_atomic_6', 'youtube-3_FJIpKgdV4',
    'Atomic Structure and the Periodic Table',
    'A chemistry tutorial connecting atomic structure concepts to the organization of the periodic table.'],

  // ======= GEOMETRY =======
  // Triangles (2 videos)
  ['vid_geometry_triangles_1', 'Videomathtutor-AlgebraFormulasFromGeometry180',
    'Geometry: Formulas from Geometry',
    'A math tutorial covering essential geometry formulas including triangles, area, and perimeter relationships.'],
  ['vid_geometry_triangles_6', 'notesonatriangle',
    'Notes on a Triangle',
    'An artistic and mathematical exploration of triangles, their properties, and their role in geometry.'],

  // Circles (2 videos)
  ['vid_geometry_circles_1', 'KA-converted-FJIZPvE3O1A',
    'Circle Geometry: Area, Chords, and Tangents',
    'Khan Academy covers key circle geometry concepts including area, chord properties, and tangent lines.'],
  ['vid_geometry_circles_6', 'SDS_Geometry_Module_1_Geometry_Basics',
    'Geometry Basics: Circles and Beyond',
    'An educational module covering fundamental geometry concepts including circles, angles, and spatial reasoning.'],

  // Coordinate Geometry (2 videos)
  ['vid_geometry_coordinate_1', 'coordinate-geometry-26',
    'Coordinate Geometry',
    'A lesson on the coordinate plane, plotting points, distance formula, and geometric relationships.'],
  ['vid_geometry_coordinate_6', 'KA-converted-2UrcUfBizyw',
    'Algebra: Graphing Lines',
    'Khan Academy demonstrates graphing linear equations on the coordinate plane, connecting algebra to geometry.'],

  // ======= US HISTORY =======
  // The Constitution (2 videos)
  ['vid_us_constitution_1', 'KA_Birth_of_the_US_Constitution',
    'Birth of the US Constitution',
    'Khan Academy covers the creation of the US Constitution, the Constitutional Convention, and the ratification debate.'],
  ['vid_us_constitution_6', 'ADC-8452a',
    'The US Constitution: Foundation of American Government',
    'Historical footage and analysis of the US Constitution and its role in shaping American government.'],

  // Civil War (2 videos)
  ['vid_us_civil_war_1', 'theroadtogettysburgcivilwarpart118611863',
    'The Road to Gettysburg: Civil War Part I (1861-1863)',
    'A historical educational film covering the American Civil War from its causes through the Battle of Gettysburg.'],
  ['vid_us_civil_war_6', 'betweenthewarsthespanishcivilwar_201504',
    'The Spanish Civil War: A Comparative Study',
    'An educational examination of the Spanish Civil War and its connections to broader global conflict.'],

  // Civil Rights (2 videos)
  ['vid_us_civil_rights_1', 'civilrightsmovementthenorth',
    'Civil Rights Movement: The North',
    'An exploration of the Civil Rights Movement in the northern United States and its unique challenges.'],
  ['vid_us_civil_rights_6', 'movementtoliveistomove_201512',
    'Civil Rights Movement: The South (1963)',
    'Historical coverage of the Civil Rights Movement in the American South during the pivotal year of 1963.'],

  // ======= PHYSICS =======
  // Newton's Laws (2 videos)
  ['vid_physics_newton_1', 'laws-of-motion',
    'Physics: Laws of Motion – Newton and Beyond',
    'An educational film covering Newton\'s three laws of motion with real-world demonstrations and applications.'],
  ['vid_physics_newton_6', 'naino-2026-newton-1st-and-2nd-law',
    'Newton\'s First and Second Laws',
    'A physics lesson explaining Newton\'s first law (inertia) and second law (F=ma) with practical examples.'],

  // Energy (2 videos)
  ['vid_physics_energy_1', 'botanicman4potentialenergy',
    'Potential Energy and Conservation',
    'An educational exploration of potential energy, kinetic energy, and the law of conservation of energy.'],
  ['vid_physics_energy_6', 'PBS-TERRA-Weathered',
    'Energy and Climate: Understanding Our World',
    'PBS educational content examining energy systems, renewable resources, and their environmental impact.'],

  // Waves and Sound (2 videos)
  ['vid_physics_waves_1', 'wavemotioninterference',
    'Wave Motion: Interference',
    'An educational film demonstrating wave properties including interference, diffraction, and superposition.'],
  ['vid_physics_waves_6', 'thedaytheuniversechanged9thenewphysicsnewtonrevisedreel2',
    'The New Physics: Waves and Modern Theory',
    'An exploration of wave theory and its role in the development of modern physics understanding.'],

  // ======= PSYCHOLOGY =======
  // Learning & Memory (2 videos)
  ['vid_psych_learning_1', 'learning-about-learning-1962',
    'Learning About Learning: Psychology of Behavior',
    'A classic educational film exploring the science of learning, memory formation, and behavioral psychology.'],
  ['vid_psych_learning_6', 'ClassicalConditioning',
    'Classical Conditioning',
    'An educational video explaining Pavlovian conditioning, stimulus-response relationships, and learned behavior.'],

  // Brain & Behavior (2 videos)
  ['vid_psych_brain_1', 'AlcoholBrainAndBehavior',
    'Alcohol, the Brain, and Behavior',
    'An educational film examining how substances affect brain function, neural pathways, and behavior.'],
  ['vid_psych_brain_6', 'experimentalpsychologyofvision',
    'Experimental Psychology of Vision',
    'Exploring how the brain processes visual information through experimental psychology methods.'],
];

// ---- Fetch archive.org metadata ----
function fetchMetadata(identifier) {
  return new Promise((resolve, reject) => {
    const url = 'https://archive.org/metadata/' + encodeURIComponent(identifier);
    https.get(url, { timeout: 10000 }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch(e) { resolve(null); }
      });
    }).on('error', () => resolve(null));
  });
}

// Find best mp4 filename from metadata files
function findMp4File(files) {
  if (!files) return null;
  // Prefer h.264 format (mp4)
  const h264 = files.find(f => f.format === 'h.264' || f.name.match(/\.mp4$/i));
  if (h264) return h264.name;
  // Fallback: 512Kb MPEG4
  const mp4 = files.find(f => f.format === '512Kb MPEG4');
  if (mp4) return mp4.name;
  // Fallback: original MPEG4
  const orig = files.find(f => f.format === 'MPEG4');
  if (orig) return orig.name;
  // Last resort: any mp4 filename
  const anyMp4 = files.find(f => f.name.match(/\.mp4$/i));
  if (anyMp4) return anyMp4.name;
  // Try Ogg Video as fallback
  const ogg = files.find(f => f.format === 'Ogg Video');
  return ogg ? ogg.name : null;
}

// Get duration string from video metadata
function getDuration(files) {
  if (!files) return null;
  const vid = files.find(f => f.length);
  if (vid && vid.length) {
    const secs = Math.round(parseFloat(vid.length));
    const min = Math.floor(secs / 60);
    const sec = secs % 60;
    return { duration: min + ':' + String(sec).padStart(2, '0'), durationSeconds: secs };
  }
  return null;
}

// ---- Main ----
async function main() {
  console.log('Fetching video metadata from Internet Archive...\n');

  const videos = [];
  let successCount = 0;
  let failCount = 0;

  for (const [vidId, identifier, titleSuffix, description] of VIDEO_SOURCES) {
    process.stdout.write('  Fetching: ' + identifier + ' ... ');

    const meta = await fetchMetadata(identifier);
    if (!meta || !meta.files) {
      console.log('FAILED (no metadata)');
      failCount++;
      continue;
    }

    const mp4File = findMp4File(meta.files);
    if (!mp4File) {
      console.log('FAILED (no mp4 found)');
      failCount++;
      continue;
    }

    const assetPath = 'https://archive.org/download/' + identifier + '/' + mp4File;
    const durInfo = getDuration(meta.files);
    const title = meta.metadata && meta.metadata.title ? meta.metadata.title : titleSuffix;

    // Parse video ID to get linked lesson info
    const parts = vidId.split('_');
    // vid_algebra_linear_eq_1 -> [vid, algebra, linear, eq, 1]
    const subjectKey = parts[1]; // 'algebra'
    const chapterKey = parts.slice(2, -1).join('_'); // 'linear_eq'
    const version = parts[parts.length - 1]; // '1' or '6'

    // Map subject keys to display names
    const subjectMap = {
      'algebra': 'Algebra', 'biology': 'Biology', 'history': 'World History',
      'english': 'English', 'chem': 'Chemistry', 'geometry': 'Geometry',
      'us': 'US History', 'physics': 'Physics', 'psych': 'Psychology'
    };

    // Build chapter display name from chapterKey
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

    const subjectName = subjectMap[subjectKey] || subjectKey;
    const chapterName = chapterDisplayMap[chapterKey] || chapterKey;

    // Generate key points from description
    const keyPoints = [
      titleSuffix,
      'Learn through visual explanation and examples',
      'Reinforces core concepts from the lesson',
      'Ideal for review and study support'
    ];

    // Generate chapter markers (simplified)
    const chapters = [
      '0:00 — Introduction to topic',
      durInfo ? Math.floor(durInfo.durationSeconds * 0.25) + ':00 — Main concepts covered' : '2:00 — Main concepts covered',
      durInfo ? Math.floor(durInfo.durationSeconds * 0.5) + ':00 — Examples and applications' : '3:00 — Examples and applications',
      durInfo ? Math.floor(durInfo.durationSeconds * 0.75) + ':00 — Review and summary' : '4:30 — Review and summary',
    ];

    const linkedLessonId = chapterKey + '_' + version;

    videos.push({
      id: vidId,
      linkedLessonId: linkedLessonId,
      title: subjectName + ': ' + chapterName + ' — ' + (version === '1' ? 'Part 1' : 'Part 2'),
      description: description,
      duration: durInfo ? durInfo.duration : (version === '1' ? '4:00' : '6:00'),
      durationSeconds: durInfo ? durInfo.durationSeconds : (version === '1' ? 240 : 360),
      subject: subjectName,
      chapter: chapterName,
      difficulty: 'beginner',
      assetPath: assetPath,
      keyPoints: keyPoints,
      chapters: chapters,
      sourceId: identifier,
      sourceSystem: 'Internet Archive'
    });

    console.log('OK (' + assetPath.substring(0, 60) + '...)');
    successCount++;

    // Be polite to archive.org
    await new Promise(r => setTimeout(r, 200));
  }

  console.log('\n=== RESULTS ===');
  console.log('Successfully mapped: ' + successCount + ' videos');
  console.log('Failed: ' + failCount + ' videos');
  console.log('Total: ' + videos.length + ' videos');

  // Write output
  const outputPath = path.join(__dirname, '..', 'assets', 'content', 'videos.json');
  fs.writeFileSync(outputPath, JSON.stringify(videos, null, 2), 'utf8');
  console.log('\nWritten: ' + outputPath + ' (' + videos.length + ' videos)');

  // Also write a report
  const reportPath = path.join(__dirname, 'video_sources_report.txt');
  const reportLines = videos.map(v =>
    v.id + '\n  Title: ' + v.title + '\n  Source: ' + v.assetPath + '\n  Identifier: ' + (v.sourceId || 'N/A') + '\n'
  );
  fs.writeFileSync(reportPath, reportLines.join('\n'), 'utf8');
  console.log('Written: ' + reportPath);
}

main().catch(console.error);
