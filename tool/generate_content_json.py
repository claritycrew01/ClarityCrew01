#!/usr/bin/env python3
"""Generates bundled content JSON from the canonical lesson seed data."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "content"

SUBJECTS = [
    {"id": "algebra", "name": "Algebra", "iconKey": "calculate_outlined", "color": "#4CAF50"},
    {"id": "biology", "name": "Biology", "iconKey": "biotech_outlined", "color": "#2196F3"},
    {"id": "world_history", "name": "World History", "iconKey": "public_outlined", "color": "#FF9800"},
    {"id": "english", "name": "English", "iconKey": "menu_book_outlined", "color": "#9C27B0"},
    {"id": "chemistry", "name": "Chemistry", "iconKey": "science_outlined", "color": "#E91E63"},
    {"id": "geometry", "name": "Geometry", "iconKey": "category_outlined", "color": "#00BCD4"},
    {"id": "us_history", "name": "US History", "iconKey": "flag_outlined", "color": "#795548"},
]

CHAPTERS = [
    {"id": "algebra_linear_eq", "subjectId": "algebra", "title": "Linear Equations", "order": 1},
    {"id": "biology_cell", "subjectId": "biology", "title": "Cell Biology", "order": 1},
    {"id": "history_renaissance", "subjectId": "world_history", "title": "The Renaissance", "order": 1},
    {"id": "english_grammar", "subjectId": "english", "title": "Grammar", "order": 1},
    {"id": "english_writing", "subjectId": "english", "title": "Writing", "order": 2},
    {"id": "chem_periodic", "subjectId": "chemistry", "title": "Periodic Table", "order": 1},
    {"id": "geometry_triangles", "subjectId": "geometry", "title": "Triangles", "order": 1},
    {"id": "us_constitution", "subjectId": "us_history", "title": "The Constitution", "order": 1},
]

# Lesson bodies loaded from the existing Dart seed (unchanged content).
LESSONS = json.loads((ROOT / "tool" / "lessons_seed.json").read_text(encoding="utf-8"))

VIDEOS = [
    {
        "id": "vid_algebra_1",
        "linkedLessonId": "algebra_linear_eq",
        "title": "Solving Linear Equations Visually",
        "description": "Watch step-by-step solutions to linear equations using a balance scale approach.",
        "duration": "4:30",
        "durationSeconds": 270,
        "subject": "Algebra",
        "chapter": "Linear Equations",
        "difficulty": "beginner",
        "assetPath": "assets/videos/algebra_linear_eq.mp4",
        "keyPoints": [
            "Isolate the variable by undoing operations in reverse order",
            "Whatever you do to one side, do to the other",
            "Check your answer by plugging it back into the original equation",
            "Use inverse operations: addition undoes subtraction, division undoes multiplication",
        ],
        "chapters": [
            "0:00 — What is a linear equation?",
            "0:45 — The balance scale method",
            "1:30 — Example 1: 2x + 5 = 13",
            "2:15 — Example 2: 3x - 7 = 2x + 5",
            "3:00 — Equations with fractions",
            "3:45 — Checking your answer",
        ],
    },
    {
        "id": "vid_bio_1",
        "linkedLessonId": "biology_cell",
        "title": "Cell Organelles: A Tour Inside the Cell",
        "description": "Explore the internal structure of animal and plant cells through detailed diagrams.",
        "duration": "5:00",
        "durationSeconds": 300,
        "subject": "Biology",
        "chapter": "Cell Biology",
        "difficulty": "beginner",
        "assetPath": "assets/videos/biology_cell.mp4",
        "keyPoints": [
            "The nucleus contains DNA and controls the cell",
            "Mitochondria produce ATP energy through cellular respiration",
            "Ribosomes build proteins from amino acids",
            "The cell membrane regulates what enters and exits",
            "Plant cells have cell walls and chloroplasts that animal cells lack",
        ],
        "chapters": [
            "0:00 — Overview of cell types",
            "0:40 — The nucleus and DNA",
            "1:20 — Mitochondria: power plant",
            "2:00 — Ribosomes and protein synthesis",
            "2:40 — Endoplasmic Reticulum and Golgi",
            "3:20 — Cell membrane structure",
            "4:00 — Plant vs animal cells",
            "4:30 — Summary diagram",
        ],
    },
    {
        "id": "vid_history_renaissance",
        "linkedLessonId": "history_renaissance",
        "title": "The Renaissance in Five Minutes",
        "description": "A visual tour of Renaissance art, science, and humanism.",
        "duration": "5:00",
        "durationSeconds": 300,
        "subject": "World History",
        "chapter": "The Renaissance",
        "difficulty": "intermediate",
        "assetPath": "assets/videos/history_renaissance.mp4",
        "keyPoints": [
            "Renaissance means rebirth of classical ideas",
            "Humanism shifted focus to human achievement",
            "Italian trade wealth funded art and science",
            "Printing spread knowledge across Europe",
        ],
        "chapters": [
            "0:00 — What was the Renaissance?",
            "1:00 — Humanism and classical texts",
            "2:00 — Art and realism",
            "3:00 — Science and exploration",
            "4:00 — Key figures summary",
        ],
    },
    {
        "id": "vid_english_grammar",
        "linkedLessonId": "english_grammar",
        "title": "Parts of Speech Explained",
        "description": "See how nouns, verbs, adjectives, and adverbs work in real sentences.",
        "duration": "4:00",
        "durationSeconds": 240,
        "subject": "English",
        "chapter": "Grammar",
        "difficulty": "beginner",
        "assetPath": "assets/videos/english_grammar.mp4",
        "keyPoints": [
            "Every English word fits one of eight parts of speech",
            "Nouns name people, places, things, or ideas",
            "Verbs show action or state of being",
            "Adverbs often end in -ly and modify verbs",
        ],
        "chapters": [
            "0:00 — Overview of eight parts",
            "1:00 — Nouns and pronouns",
            "2:00 — Verbs and adjectives",
            "3:00 — Adverbs, prepositions, conjunctions",
        ],
    },
    {
        "id": "vid_chem_periodic",
        "linkedLessonId": "chem_periodic",
        "title": "Reading the Periodic Table",
        "description": "Understand periods, groups, and element trends.",
        "duration": "4:30",
        "durationSeconds": 270,
        "subject": "Chemistry",
        "chapter": "Periodic Table",
        "difficulty": "intermediate",
        "assetPath": "assets/videos/chem_periodic.mp4",
        "keyPoints": [
            "Atomic number equals proton count",
            "Groups share valence electrons",
            "Periods share electron shell count",
            "Electronegativity increases up and to the right",
        ],
        "chapters": [
            "0:00 — Table layout",
            "1:00 — Groups and families",
            "2:00 — Periods and shells",
            "3:00 — Periodic trends",
        ],
    },
    {
        "id": "vid_geometry_triangles",
        "linkedLessonId": "geometry_triangles",
        "title": "Triangle Types and Theorems",
        "description": "Classify triangles and apply the Pythagorean theorem.",
        "duration": "4:30",
        "durationSeconds": 270,
        "subject": "Geometry",
        "chapter": "Triangles",
        "difficulty": "intermediate",
        "assetPath": "assets/videos/geometry_triangles.mp4",
        "keyPoints": [
            "Interior angles always sum to 180 degrees",
            "Right triangles follow a² + b² = c²",
            "Equilateral triangles have three 60-degree angles",
            "Triangle inequality limits which side lengths work",
        ],
        "chapters": [
            "0:00 — Classifying by sides",
            "1:00 — Classifying by angles",
            "2:00 — Triangle sum theorem",
            "3:00 — Pythagorean theorem example",
        ],
    },
    {
        "id": "vid_us_constitution",
        "linkedLessonId": "us_history_constitution",
        "title": "The US Constitution Overview",
        "description": "Three branches, checks and balances, and the Bill of Rights.",
        "duration": "5:00",
        "durationSeconds": 300,
        "subject": "US History",
        "chapter": "The Constitution",
        "difficulty": "intermediate",
        "assetPath": "assets/videos/us_history_constitution.mp4",
        "keyPoints": [
            "The Constitution is the supreme law of the US",
            "Three branches separate powers",
            "Checks and balances prevent one branch from dominating",
            "The Bill of Rights protects individual freedoms",
        ],
        "chapters": [
            "0:00 — Why a new constitution?",
            "1:00 — Legislative branch",
            "2:00 — Executive branch",
            "3:00 — Judicial branch",
            "4:00 — Bill of Rights",
        ],
    },
    {
        "id": "vid_english_essay",
        "linkedLessonId": "english_essay",
        "title": "Five-Paragraph Essay Structure",
        "description": "Build a strong introduction, body, and conclusion.",
        "duration": "4:30",
        "durationSeconds": 270,
        "subject": "English",
        "chapter": "Writing",
        "difficulty": "intermediate",
        "assetPath": "assets/videos/english_essay.mp4",
        "keyPoints": [
            "Introduction includes hook, context, and thesis",
            "Each body paragraph supports one main point",
            "Evidence plus analysis strengthens arguments",
            "Conclusion restates thesis without copying it",
        ],
        "chapters": [
            "0:00 — Essay overview",
            "1:00 — Writing the introduction",
            "2:00 — Body paragraph structure",
            "3:00 — Conclusion and revision",
        ],
    },
]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "subjects.json").write_text(
        json.dumps(SUBJECTS, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (OUT / "chapters.json").write_text(
        json.dumps(CHAPTERS, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (OUT / "lessons.json").write_text(
        json.dumps(LESSONS, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (OUT / "videos.json").write_text(
        json.dumps(VIDEOS, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote content JSON to {OUT}")


if __name__ == "__main__":
    main()
