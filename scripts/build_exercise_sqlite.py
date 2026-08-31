#!/usr/bin/env python3
"""
Open-Source Exercise Datasets SQLite Database Builder for Oly.

Aggregates, normalizes, and indexes all three major open-source exercise datasets
along with Oly's curated Olympic weightlifting, mobility, and core library:
1. Free Exercise DB (yuhonas/free-exercise-db) - 870+ exercises with instructions & mechanics
2. wger Workout Manager (wger-project) - 860+ internationalized exercises & equipment classifications
3. Exercises Dataset (hasaneyldrm/exercises-dataset) - 1,320+ exercises with body parts & target muscles
4. Oly Curated Weightlifting & Mobility Catalog - Olympic lifts, loaded carries, Burgener prep, and core drills

Features:
- Idempotent: Caches downloads in `.exercise_cache/` and builds deterministic SQLite + FTS5 index.
- Clean Normalization: Standardized categories, body parts, muscles, equipment, and levels.
- High-Performance: Embedded SQLite database with FTS5 prefix and full-text search triggers.
"""

import os
import sys
import json
import sqlite3
import urllib.request
import re
import html
from typing import Dict, List, Any, Optional

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
CACHE_DIR = os.path.join(PROJECT_ROOT, '.exercise_cache')
DB_PATH = os.path.join(PROJECT_ROOT, 'assets', 'data', 'exercises.db')

URL_FREE_EXERCISE_DB = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"
URL_WGER_API = "https://wger.de/api/v2/exerciseinfo/?format=json&limit=1000"
URL_EXERCISES_DATASET = "https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/data/exercises.json"

USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 OlyApp/1.0"


def clean_html(raw_html: Optional[str]) -> str:
    """Removes HTML tags and decodes entities."""
    if not raw_html:
        return ""
    clean = re.sub(r'<[^>]+>', ' ', raw_html)
    clean = html.unescape(clean)
    clean = re.sub(r'\s+', ' ', clean).strip()
    return clean


def normalize_string(val: Optional[str]) -> str:
    if not val:
        return ""
    return val.strip().lower()


def fetch_or_load_cached(filename: str, url: str, force: bool = False) -> Any:
    os.makedirs(CACHE_DIR, exist_ok=True)
    cache_path = os.path.join(CACHE_DIR, filename)

    if not force and os.path.exists(cache_path) and os.path.getsize(cache_path) > 0:
        print(f"📦 Loading cached {filename} from {cache_path}...")
        with open(cache_path, 'r', encoding='utf-8') as f:
            return json.load(f)

    print(f"🌐 Downloading {filename} from {url}...")
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            data_bytes = resp.read()
            with open(cache_path, 'wb') as f:
                f.write(data_bytes)
            data = json.loads(data_bytes.decode('utf-8'))
            print(f"✅ Successfully downloaded & cached {filename} ({len(data_bytes):,} bytes)")
            return data
    except Exception as e:
        if os.path.exists(cache_path) and os.path.getsize(cache_path) > 0:
            print(f"⚠️ Download failed ({e}). Reverting to existing cached copy.")
            with open(cache_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        raise RuntimeError(f"Failed to fetch {url} and no cached version exists: {e}")


def init_database(db_file: str) -> sqlite3.Connection:
    os.makedirs(os.path.dirname(db_file), exist_ok=True)
    if os.path.exists(db_file):
        try:
            os.remove(db_file)
        except OSError:
            pass

    conn = sqlite3.connect(db_file)
    conn.execute("PRAGMA journal_mode = WAL;")
    conn.execute("PRAGMA synchronous = NORMAL;")
    conn.execute("PRAGMA page_size = 4096;")

    # 1. Exercises Table
    conn.execute("""
    CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        body_part TEXT NOT NULL,
        target_muscle TEXT NOT NULL,
        secondary_muscles TEXT NOT NULL DEFAULT '[]',
        equipment TEXT NOT NULL,
        mechanic TEXT,
        force TEXT,
        level TEXT,
        instructions TEXT,
        tips TEXT,
        source TEXT NOT NULL,
        source_id TEXT,
        gif_url TEXT,
        video_url TEXT
    );
    """)

    # 2. B-Tree Indexes
    conn.execute("CREATE INDEX idx_exercises_category ON exercises(category);")
    conn.execute("CREATE INDEX idx_exercises_body_part ON exercises(body_part);")
    conn.execute("CREATE INDEX idx_exercises_target_muscle ON exercises(target_muscle);")
    conn.execute("CREATE INDEX idx_exercises_equipment ON exercises(equipment);")
    conn.execute("CREATE INDEX idx_exercises_source ON exercises(source);")
    conn.execute("CREATE INDEX idx_exercises_name ON exercises(name);")

    # 3. FTS5 Virtual Table for Instant Search
    conn.execute("""
    CREATE VIRTUAL TABLE exercises_fts USING fts5(
        id UNINDEXED,
        name,
        category,
        body_part,
        target_muscle,
        secondary_muscles,
        equipment,
        instructions,
        content='exercises',
        content_rowid='rowid'
    );
    """)

    # 4. Triggers to keep FTS in sync
    conn.execute("""
    CREATE TRIGGER exercises_ai AFTER INSERT ON exercises BEGIN
        INSERT INTO exercises_fts(rowid, id, name, category, body_part, target_muscle, secondary_muscles, equipment, instructions)
        VALUES (new.rowid, new.id, new.name, new.category, new.body_part, new.target_muscle, new.secondary_muscles, new.equipment, new.instructions);
    END;
    """)

    conn.execute("""
    CREATE TRIGGER exercises_ad AFTER DELETE ON exercises BEGIN
        INSERT INTO exercises_fts(exercises_fts, rowid, id, name, category, body_part, target_muscle, secondary_muscles, equipment, instructions)
        VALUES ('delete', old.rowid, old.id, old.name, old.category, old.body_part, old.target_muscle, old.secondary_muscles, old.equipment, old.instructions);
    END;
    """)

    conn.execute("""
    CREATE TRIGGER exercises_au AFTER UPDATE ON exercises BEGIN
        INSERT INTO exercises_fts(exercises_fts, rowid, id, name, category, body_part, target_muscle, secondary_muscles, equipment, instructions)
        VALUES ('delete', old.rowid, old.id, old.name, old.category, old.body_part, old.target_muscle, old.secondary_muscles, old.equipment, old.instructions);
        INSERT INTO exercises_fts(rowid, id, name, category, body_part, target_muscle, secondary_muscles, equipment, instructions)
        VALUES (new.rowid, new.id, new.name, new.category, new.body_part, new.target_muscle, new.secondary_muscles, new.equipment, new.instructions);
    END;
    """)

    return conn


# Normalization mappings
MUSCLE_MAP = {
    'abdominals': 'abs',
    'abs': 'abs',
    'rectus abdominis': 'abs',
    'obliques': 'obliques',
    'obliquus externus abdominis': 'obliques',
    'biceps': 'biceps',
    'biceps brachii': 'biceps',
    'brachialis': 'biceps',
    'triceps': 'triceps',
    'triceps brachii': 'triceps',
    'chest': 'pectorals',
    'pectorals': 'pectorals',
    'pectoralis major': 'pectorals',
    'pecs': 'pectorals',
    'lats': 'lats',
    'latissimus dorsi': 'lats',
    'middle back': 'upper_back',
    'upper back': 'upper_back',
    'rhomboids': 'upper_back',
    'lower back': 'lower_back',
    'erector spinae': 'lower_back',
    'spine': 'lower_back',
    'traps': 'traps',
    'trapezius': 'traps',
    'shoulders': 'deltoids',
    'deltoids': 'deltoids',
    'delts': 'deltoids',
    'anterior deltoid': 'deltoids',
    'posterior deltoid': 'deltoids',
    'quads': 'quadriceps',
    'quadriceps': 'quadriceps',
    'quadriceps femoris': 'quadriceps',
    'hamstrings': 'hamstrings',
    'biceps femoris': 'hamstrings',
    'glutes': 'glutes',
    'gluteus maximus': 'glutes',
    'calves': 'calves',
    'gastrocnemius': 'calves',
    'soleus': 'calves',
    'forearms': 'forearms',
    'adductors': 'adductors',
    'abductors': 'abductors',
    'neck': 'neck',
    'cardiovascular system': 'cardio',
    'cardio': 'cardio',
}

BODY_PART_MAP = {
    'waist': 'core',
    'abs': 'core',
    'chest': 'chest',
    'back': 'back',
    'shoulders': 'shoulders',
    'upper legs': 'upper_legs',
    'lower legs': 'lower_legs',
    'upper arms': 'arms',
    'lower arms': 'arms',
    'neck': 'neck',
    'cardio': 'cardio',
}

EQUIPMENT_MAP = {
    'body only': 'body weight',
    'body weight': 'body weight',
    'none': 'body weight',
    'none (bodyweight exercise)': 'body weight',
    'barbell': 'barbell',
    'dumbbell': 'dumbbell',
    'cable': 'cable',
    'cable machine': 'cable',
    'machine': 'machine',
    'leverage machine': 'machine',
    'sled machine': 'machine',
    'kettlebells': 'kettlebell',
    'kettlebell': 'kettlebell',
    'bands': 'band',
    'band': 'band',
    'resistance band': 'band',
    'medicine ball': 'medicine ball',
    'exercise ball': 'exercise ball',
    'stability ball': 'exercise ball',
    'swiss ball': 'exercise ball',
    'bosu ball': 'exercise ball',
    'foam roll': 'foam roller',
    'foam roller': 'foam roller',
    'roller': 'foam roller',
    'wheel roller': 'foam roller',
    'e-z curl bar': 'ez barbell',
    'ez barbell': 'ez barbell',
    'sz-bar': 'ez barbell',
    'smith machine': 'smith machine',
    'olympic barbell': 'barbell',
}


def normalize_muscle(muscle: Optional[str]) -> str:
    if not muscle:
        return "general"
    clean = normalize_string(muscle)
    return MUSCLE_MAP.get(clean, clean.replace(' ', '_'))


def normalize_equipment(equip: Optional[str]) -> str:
    if not equip:
        return "body weight"
    clean = normalize_string(equip)
    return EQUIPMENT_MAP.get(clean, clean)


def normalize_body_part(bp: Optional[str], muscle: Optional[str] = None) -> str:
    if bp:
        clean = normalize_string(bp)
        if clean in BODY_PART_MAP:
            return BODY_PART_MAP[clean]
        if 'arm' in clean:
            return 'arms'
        if 'leg' in clean:
            return 'upper_legs'
    
    # Infer from muscle
    if muscle:
        m = normalize_muscle(muscle)
        if m in ['abs', 'obliques']:
            return 'core'
        if m in ['pectorals']:
            return 'chest'
        if m in ['lats', 'upper_back', 'lower_back', 'traps']:
            return 'back'
        if m in ['deltoids']:
            return 'shoulders'
        if m in ['quadriceps', 'hamstrings', 'glutes', 'adductors', 'abductors']:
            return 'upper_legs'
        if m in ['calves']:
            return 'lower_legs'
        if m in ['biceps', 'triceps', 'forearms']:
            return 'arms'
        if m in ['cardio']:
            return 'cardio'
            
    return "full_body"


def normalize_category(cat: Optional[str], default: str = "strength") -> str:
    if not cat:
        return default
    clean = normalize_string(cat)
    if 'olympic' in clean or 'snatch' in clean or 'clean' in clean or 'jerk' in clean:
        return 'olympic_weightlifting'
    if 'strength' in clean or 'powerlifting' in clean or 'weight' in clean:
        return 'strength'
    if 'cardio' in clean or 'conditioning' in clean:
        return 'cardio'
    if 'plyo' in clean:
        return 'plyometrics'
    if 'stretch' in clean or 'flexibility' in clean:
        return 'stretching'
    if 'mobility' in clean or 'foam' in clean or 'warmup' in clean:
        return 'mobility'
    if 'core' in clean or 'abs' in clean:
        return 'core'
    return default


def parse_free_exercise_db(items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    parsed = []
    for item in items:
        raw_id = item.get('id', '')
        ex_id = f"fedb_{raw_id}"
        name = item.get('name', '').strip()
        if not name:
            continue

        primary = item.get('primaryMuscles', [])
        target_muscle = normalize_muscle(primary[0]) if primary else "general"
        secondary_raw = item.get('secondaryMuscles', [])
        secondary = [normalize_muscle(m) for m in secondary_raw]

        equipment = normalize_equipment(item.get('equipment'))
        category = normalize_category(item.get('category'), default='strength')
        body_part = normalize_body_part(None, target_muscle)
        mechanic = normalize_string(item.get('mechanic')) or None
        force = normalize_string(item.get('force')) or None
        level = normalize_string(item.get('level')) or 'intermediate'

        instructions_list = item.get('instructions', [])
        instructions = "\n".join(f"{i+1}. {step.strip()}" for i, step in enumerate(instructions_list) if step.strip())

        images = item.get('images', [])
        image_url = f"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{images[0]}" if images else None

        parsed.append({
            'id': ex_id,
            'name': name,
            'category': category,
            'body_part': body_part,
            'target_muscle': target_muscle,
            'secondary_muscles': json.dumps(secondary),
            'equipment': equipment,
            'mechanic': mechanic,
            'force': force,
            'level': level,
            'instructions': instructions,
            'tips': None,
            'source': 'free_exercise_db',
            'source_id': raw_id,
            'gif_url': image_url,
            'video_url': None,
        })
    return parsed


def parse_wger_exercises(data: Any) -> List[Dict[str, Any]]:
    parsed = []
    results = data.get('results', []) if isinstance(data, dict) else (data if isinstance(data, list) else [])
    
    for item in results:
        raw_id = str(item.get('id', ''))
        ex_id = f"wger_{raw_id}"
        
        # Find English translation or first translation
        translations = item.get('translations', [])
        en_trans = next((t for t in translations if t.get('language') == 2), translations[0] if translations else {})
        name = clean_html(en_trans.get('name', '')).strip()
        if not name or name == 'N/A':
            continue

        description = clean_html(en_trans.get('description', ''))
        
        # Muscle extraction
        muscles = item.get('muscles', [])
        target_raw = muscles[0].get('name_en') or muscles[0].get('name') if muscles else None
        target_muscle = normalize_muscle(target_raw)

        secondary_muscles_raw = item.get('muscles_secondary', [])
        secondary = [normalize_muscle(m.get('name_en') or m.get('name')) for m in secondary_muscles_raw if m]

        # Equipment
        eq_list = item.get('equipment', [])
        eq_raw = eq_list[0].get('name') if eq_list else None
        equipment = normalize_equipment(eq_raw)

        # Category
        cat_obj = item.get('category', {})
        cat_name = cat_obj.get('name') if isinstance(cat_obj, dict) else str(cat_obj)
        category = normalize_category(cat_name, default='strength')
        body_part = normalize_body_part(cat_name, target_muscle)

        # Images/Videos
        images = item.get('images', [])
        img_url = images[0].get('image') if images else None
        videos = item.get('videos', [])
        vid_url = videos[0].get('video') if videos else None

        parsed.append({
            'id': ex_id,
            'name': name,
            'category': category,
            'body_part': body_part,
            'target_muscle': target_muscle,
            'secondary_muscles': json.dumps(secondary),
            'equipment': equipment,
            'mechanic': 'compound' if len(secondary) > 0 else 'isolation',
            'force': None,
            'level': 'intermediate',
            'instructions': description,
            'tips': None,
            'source': 'wger',
            'source_id': raw_id,
            'gif_url': img_url,
            'video_url': vid_url,
        })
    return parsed


def parse_exercises_dataset(items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    parsed = []
    for item in items:
        raw_id = str(item.get('id', ''))
        ex_id = f"hasan_{raw_id}"
        name = item.get('name', '').strip().title()
        if not name:
            continue

        body_part_raw = item.get('body_part') or item.get('category')
        target_raw = item.get('target') or item.get('muscle_group')
        target_muscle = normalize_muscle(target_raw)
        body_part = normalize_body_part(body_part_raw, target_muscle)

        secondary_raw = item.get('secondary_muscles', [])
        if isinstance(secondary_raw, list):
            secondary = [normalize_muscle(m) for m in secondary_raw]
        else:
            secondary = []

        equipment = normalize_equipment(item.get('equipment'))
        category = normalize_category(body_part_raw, default='strength')

        instructions_data = item.get('instructions')
        if isinstance(instructions_data, dict):
            instructions = instructions_data.get('en', '')
        elif isinstance(instructions_data, list):
            instructions = "\n".join(f"{i+1}. {s}" for i, s in enumerate(instructions_data))
        else:
            instructions = str(instructions_data or '')

        gif_url = item.get('gif_url') or item.get('image')

        parsed.append({
            'id': ex_id,
            'name': name,
            'category': category,
            'body_part': body_part,
            'target_muscle': target_muscle,
            'secondary_muscles': json.dumps(secondary),
            'equipment': equipment,
            'mechanic': None,
            'force': None,
            'level': 'intermediate',
            'instructions': instructions,
            'tips': None,
            'source': 'exercises_dataset',
            'source_id': raw_id,
            'gif_url': gif_url,
            'video_url': None,
        })
    return parsed


def get_oly_curated_catalog() -> List[Dict[str, Any]]:
    """Curated Olympic weightlifting, mobility, core, and loaded carries library."""
    curated = [
        # OLYMPIC LIFTS
        {
            'id': 'oly_snatch',
            'name': 'Snatch',
            'category': 'olympic_weightlifting',
            'body_part': 'full_body',
            'target_muscle': 'full_body',
            'secondary_muscles': json.dumps(['quadriceps', 'glutes', 'traps', 'deltoids', 'erector_spinae']),
            'equipment': 'barbell',
            'mechanic': 'compound',
            'force': 'pull',
            'level': 'expert',
            'instructions': '1. Set up with wide hook grip over barbell at mid-shin with vertical chest.\n2. Drive off the floor keeping bar tight to shins.\n3. Accelerate bar vertically through the mid-thigh power pocket.\n4. Reach triple extension and pull yourself aggressively under the barbell into a deep squat.\n5. Lock out arms overhead with active shoulders and stand up.',
            'tips': 'Maintain full foot contact through the first pull; punch ceiling at lockout.',
            'source': 'oly_curated',
            'source_id': 'snatch',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Snatch+Weightlifting+Tutorial+Catalyst+Athletics',
        },
        {
            'id': 'oly_clean_and_jerk',
            'name': 'Clean & Jerk',
            'category': 'olympic_weightlifting',
            'body_part': 'full_body',
            'target_muscle': 'full_body',
            'secondary_muscles': json.dumps(['quadriceps', 'glutes', 'deltoids', 'triceps', 'upper_back']),
            'equipment': 'barbell',
            'mechanic': 'compound',
            'force': 'push',
            'level': 'expert',
            'instructions': '1. Pull barbell from floor to hip with shoulder-width grip.\n2. Triple extend and receive bar in front rack squat.\n3. Stand up out of front squat.\n4. Dip vertically 2-4 inches and drive bar violently off deltoids.\n5. Split feet into lunge stance and lock out arms overhead.',
            'tips': 'Vertical torso during jerk dip; fast elbow whip on clean rack.',
            'source': 'oly_curated',
            'source_id': 'clean_and_jerk',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Clean+and+Jerk+Weightlifting+Tutorial+Catalyst+Athletics',
        },
        {
            'id': 'oly_power_snatch',
            'name': 'Power Snatch',
            'category': 'olympic_weightlifting',
            'body_part': 'full_body',
            'target_muscle': 'full_body',
            'secondary_muscles': json.dumps(['quadriceps', 'traps', 'deltoids']),
            'equipment': 'barbell',
            'mechanic': 'compound',
            'force': 'pull',
            'level': 'intermediate',
            'instructions': 'Perform a snatch with receiving position above parallel squat (thighs above horizontal).',
            'tips': 'Focus on aggressive high pull and rapid turnover overhead.',
            'source': 'oly_curated',
            'source_id': 'power_snatch',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Power+Snatch+Catalyst+Athletics',
        },
        {
            'id': 'oly_power_clean',
            'name': 'Power Clean',
            'category': 'olympic_weightlifting',
            'body_part': 'full_body',
            'target_muscle': 'full_body',
            'secondary_muscles': json.dumps(['quadriceps', 'glutes', 'traps']),
            'equipment': 'barbell',
            'mechanic': 'compound',
            'force': 'pull',
            'level': 'intermediate',
            'instructions': 'Clean the barbell receiving the bar in a quarter squat position above parallel.',
            'tips': 'High elbows in front rack delivery.',
            'source': 'oly_curated',
            'source_id': 'power_clean',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Power+Clean+Catalyst+Athletics',
        },
        {
            'id': 'oly_back_squat',
            'name': 'Olympic Back Squat',
            'category': 'strength',
            'body_part': 'upper_legs',
            'target_muscle': 'quadriceps',
            'secondary_muscles': json.dumps(['glutes', 'hamstrings', 'lower_back', 'abs']),
            'equipment': 'barbell',
            'mechanic': 'compound',
            'force': 'push',
            'level': 'beginner',
            'instructions': 'High bar position on upper traps, upright torso, full depth squat driving knees outward over toes.',
            'tips': 'Keep chest elevated and maintain brace throughout bottom bounce.',
            'source': 'oly_curated',
            'source_id': 'back_squat',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=High+Bar+Olympic+Squat+Form',
        },
        {
            'id': 'oly_front_squat',
            'name': 'Front Squat',
            'category': 'strength',
            'body_part': 'upper_legs',
            'target_muscle': 'quadriceps',
            'secondary_muscles': json.dumps(['abs', 'glutes', 'upper_back']),
            'equipment': 'barbell',
            'mechanic': 'compound',
            'force': 'push',
            'level': 'intermediate',
            'instructions': 'Barbell resting across anterior deltoids and clavicles with high elbows. Squat deep while maintaining vertical torso.',
            'tips': 'Drive elbows toward ceiling coming out of the hole.',
            'source': 'oly_curated',
            'source_id': 'front_squat',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Front+Squat+Weightlifting+Form',
        },
        {
            'id': 'oly_snatch_pull',
            'name': 'Snatch Pull',
            'category': 'olympic_weightlifting',
            'body_part': 'back',
            'target_muscle': 'traps',
            'secondary_muscles': json.dumps(['quadriceps', 'glutes', 'lower_back']),
            'equipment': 'barbell',
            'mechanic': 'compound',
            'force': 'pull',
            'level': 'intermediate',
            'instructions': 'Perform the first and second pull of the snatch with heavy load, elevating onto toes and shrugging at full extension without catching.',
            'tips': 'Keep bar close to body and finish tall with vertical shoulders.',
            'source': 'oly_curated',
            'source_id': 'snatch_pull',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Snatch+Pull+Form+Catalyst+Athletics',
        },
        {
            'id': 'oly_kettlebell_mile',
            'name': 'Kettlebell Mile (Loaded Carry)',
            'category': 'cardio',
            'body_part': 'full_body',
            'target_muscle': 'cardio',
            'secondary_muscles': json.dumps(['traps', 'forearms', 'abs', 'obliques']),
            'equipment': 'kettlebell',
            'mechanic': 'compound',
            'force': 'static',
            'level': 'intermediate',
            'instructions': '1.0 Mile loaded walk with dual kettlebells (10% to 30% bodyweight). Track time, speed, and treadmill incline.',
            'tips': 'Maintain tall posture with retracted shoulder blades and braced core.',
            'source': 'oly_curated',
            'source_id': 'kettlebell_mile',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Kettlebell+Loaded+Carry+Mile',
        },
        {
            'id': 'oly_cable_crunches',
            'name': 'Kneeling Cable Crunches',
            'category': 'core',
            'body_part': 'core',
            'target_muscle': 'abs',
            'secondary_muscles': json.dumps(['obliques']),
            'equipment': 'cable',
            'mechanic': 'isolation',
            'force': 'pull',
            'level': 'beginner',
            'instructions': 'Kneel facing high cable pulley with rope attachment held at temple level. Flex spine and crunch ribcage down toward pelvis.',
            'tips': 'Do not rock hips backward; isolate spinal flexion.',
            'source': 'oly_curated',
            'source_id': 'cable_crunches',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Kneeling+Cable+Crunch+Rope',
        },
        {
            'id': 'oly_dragon_flags',
            'name': 'Dragon Flags',
            'category': 'core',
            'body_part': 'core',
            'target_muscle': 'abs',
            'secondary_muscles': json.dumps(['hip_flexors', 'lats', 'glutes']),
            'equipment': 'body weight',
            'mechanic': 'compound',
            'force': 'static',
            'level': 'expert',
            'instructions': 'Anchor hands behind head on bench. Raise entire body in straight line onto shoulder blades. Lower slowly with rigid torso without breaking at hips.',
            'tips': 'Maintain locked hollow body from shoulders to toes.',
            'source': 'oly_curated',
            'source_id': 'dragon_flags',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Dragon+Flag+Form+Bruce+Lee',
        },
        {
            'id': 'oly_ghd_back_extensions',
            'name': 'GHD Machine Back Extensions',
            'category': 'strength',
            'body_part': 'back',
            'target_muscle': 'lower_back',
            'secondary_muscles': json.dumps(['glutes', 'hamstrings', 'abs']),
            'equipment': 'other',
            'mechanic': 'compound',
            'force': 'pull',
            'level': 'intermediate',
            'instructions': 'Position yourself on the GHD machine with hips just past the pad. Cross arms over chest or hold plate against sternum. Hinge at hips to lower torso down into 90-degree stretch, then engage glutes, hamstrings, and erectors to rise to parallel.',
            'tips': 'Squeeze glutes at top without hyperextending cervical or lumbar spine.',
            'source': 'oly_curated',
            'source_id': 'ghd_back_extensions',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=GHD+Machine+Back+Extension+Form',
        },
        {
            'id': 'oly_seated_leg_extensions',
            'name': 'Seated Machine Leg Extensions',
            'category': 'strength',
            'body_part': 'upper_legs',
            'target_muscle': 'quadriceps',
            'secondary_muscles': json.dumps(['calves', 'shins']),
            'equipment': 'lever',
            'mechanic': 'isolation',
            'force': 'push',
            'level': 'beginner',
            'instructions': 'Sit on machine with back against pad and shin pad against lower shins. Extend legs upward to full extension, pause, then lower under control.',
            'tips': 'Keep hips down in seat; do not swing torso or use momentum.',
            'source': 'oly_curated',
            'source_id': 'seated_leg_extensions',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Seated+Machine+Leg+Extension+Form',
        },
        {
            'id': 'oly_burgener_warmup',
            'name': 'Burgener Barbell Snatch Warm-Up Complex',
            'category': 'mobility',
            'body_part': 'full_body',
            'target_muscle': 'deltoids',
            'secondary_muscles': json.dumps(['traps', 'quadriceps']),
            'equipment': 'barbell',
            'mechanic': 'compound',
            'force': 'pull',
            'level': 'beginner',
            'instructions': 'Perform 5 reps each of: Down & Up, High Pull with Elbows High and Outside, Muscle Snatch, Snatch Drops, Snatch Lands.',
            'tips': 'Keep empty barbell tight against body trajectory.',
            'source': 'oly_curated',
            'source_id': 'burgener_warmup',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Burgener+Warmup+Catalyst+Athletics',
        },
        {
            'id': 'oly_sotts_press',
            'name': 'Press in Snatch Bottom (Sotts Press)',
            'category': 'mobility',
            'body_part': 'shoulders',
            'target_muscle': 'deltoids',
            'secondary_muscles': json.dumps(['upper_back', 'abs', 'adductors']),
            'equipment': 'barbell',
            'mechanic': 'compound',
            'force': 'push',
            'level': 'expert',
            'instructions': 'Sit in deep snatch squat with empty barbell behind neck. Press barbell straight up to overhead lockout without rising from the squat.',
            'tips': 'Active thoracic extension and aggressive elbow lockout.',
            'source': 'oly_curated',
            'source_id': 'sotts_press',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Sotts+Press+Snatch+Catalyst+Athletics',
        },
        {
            'id': 'oly_bayesian_curl',
            'name': 'Bayesian Curl (Behind-the-Back Cable Curl)',
            'category': 'strength',
            'body_part': 'arms',
            'target_muscle': 'biceps',
            'secondary_muscles': json.dumps(['forearms']),
            'equipment': 'cable',
            'mechanic': 'isolation',
            'force': 'pull',
            'level': 'intermediate',
            'instructions': '1. Set a single cable pulley at wrist or lowest pin height with a D-handle.\n2. Grab handle and step forward facing away from the cable stack until your arm is drawn back behind your torso into shoulder hyperextension.\n3. Keep your chest up and elbow stationary slightly behind the torso line.\n4. Curl the handle upward into full elbow flexion, squeezing the bicep long head at the contraction peak.\n5. Lower the weight under control with a 3-second eccentric tempo into the lengthened stretch.',
            'tips': 'Keep the upper arm behind your torso throughout the repetition; do not swing the elbow forward.',
            'source': 'oly_curated',
            'source_id': 'bayesian_curl',
            'gif_url': None,
            'video_url': 'https://www.youtube.com/results?search_query=Bayesian+Cable+Curl+Tutorial',
        }
    ]
    return curated


def make_dedupe_key(name: str, equipment: str) -> str:
    """Generates a canonical deduplication key based on normalized movement tokens and equipment."""
    clean = name.lower().strip()
    
    # Common exercise name spelling variants
    clean = re.sub(r"\bbayseans?\b", "bayesian", clean)
    clean = re.sub(r"\bbayesians?\b", "bayesian", clean)
    clean = re.sub(r"\bbehind[\s\-_]+the[\s\-_]+back[\s\-_]+cable[\s\-_]+curls?\b", "bayesian curl", clean)
    
    # Standardize hyphenated exercise words and spellings
    clean = re.sub(r"\bpush-?ups?\b", "pushup", clean)
    clean = re.sub(r"\bpull-?ups?\b", "pullup", clean)
    clean = re.sub(r"\bchin-?ups?\b", "chinup", clean)
    clean = re.sub(r"\bsit-?ups?\b", "situp", clean)
    clean = re.sub(r"\broll-?outs?\b", "rollout", clean)
    clean = re.sub(r"\bstep-?ups?\b", "stepup", clean)
    clean = re.sub(r"\bmuscle-?ups?\b", "muscleup", clean)
    clean = re.sub(r"\bstraight-?arm\b", "straight arm", clean)
    clean = re.sub(r"\bclose-?grip\b", "close grip", clean)
    clean = re.sub(r"\bwide-?grip\b", "wide grip", clean)
    clean = re.sub(r"\bone-?arm\b|\b1-?arm\b|\bsingle-?arm\b", "single arm", clean)
    clean = re.sub(r"\bone-?leg\b|\b1-?leg\b|\bsingle-?leg\b", "single leg", clean)
    clean = re.sub(r"\btwo-?arm\b|\b2-?arm\b|\bdouble-?arm\b", "double arm", clean)
    clean = re.sub(r"\b2-?handed\b", "double arm", clean)
    
    # Remove parenthetical equipment e.g. "(barbell)", "[dumbbell]"
    clean = re.sub(r"\((barbell|dumbbell|cable|kettlebell|machine|bodyweight|bands?|ez bar)\)", "", clean)
    clean = re.sub(r"\[(barbell|dumbbell|cable|kettlebell|machine|bodyweight|bands?|ez bar)\]", "", clean)

    def normalize_plural(word: str) -> str:
        if word.endswith('presses'):
            return word[:-2]
        if word.endswith('crunches'):
            return word[:-2]
        if word.endswith('twists'):
            return word[:-1]
        if word.endswith('squats'):
            return word[:-1]
        if word.endswith('rows'):
            return word[:-1]
        if word.endswith('curls'):
            return word[:-1]
        if word.endswith('raises'):
            return word[:-1]
        if word.endswith('extensions'):
            return word[:-1]
        if word.endswith('swings'):
            return word[:-1]
        if word.endswith('shrugs'):
            return word[:-1]
        if word.endswith('lunges'):
            return word[:-1]
        if word.endswith('carries'):
            return word[:-3] + 'y'
        if word.endswith('deadlifts'):
            return word[:-1]
        if word.endswith('dips'):
            return word[:-1]
        if word.endswith('jumps'):
            return word[:-1]
        if word.endswith('planks'):
            return word[:-1]
        if word.endswith('flies') or word.endswith('flys'):
            return 'fly'
        return word

    tokens = re.findall(r"[a-z0-9]+(?:\/[a-z0-9]+)?", clean)
    tokens = [normalize_plural(t) for t in tokens]
    meaningful = [t for t in tokens if t not in {"the", "a", "an", "and", "with", "exercise", "drill"}]
    
    eq_norm = equipment.lower().replace("_", " ").strip()
    if eq_norm in {"body weight", "body only", "none"}:
        eq_key = "bodyweight"
    elif "barbell" in eq_norm and "ez" not in eq_norm:
        eq_key = "barbell"
    elif "dumbbell" in eq_norm:
        eq_key = "dumbbell"
    elif "cable" in eq_norm:
        eq_key = "cable"
    elif "kettlebell" in eq_norm:
        eq_key = "kettlebell"
    elif "machine" in eq_norm or "lever" in eq_norm or "sled" in eq_norm:
        eq_key = "machine"
    elif "band" in eq_norm:
        eq_key = "band"
    elif "ez" in eq_norm:
        eq_key = "ez_barbell"
    elif "foam" in eq_norm or "roller" in eq_norm:
        eq_key = "foam_roller"
    else:
        eq_key = eq_norm.replace(" ", "_")

    name_tokens = [t for t in meaningful if t not in {eq_key, eq_key.replace("_", ""), "barbell", "dumbbell", "cable", "kettlebell", "machine", "band", "bodyweight"}]
    return f"{eq_key}::" + "_".join(sorted(name_tokens))


SOURCE_PRIORITY = {
    "oly_curated": 4,
    "free_exercise_db": 3,
    "exercises_dataset": 2,
    "wger": 1,
}


def deduplicate_and_merge_exercises(raw_exercises: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Deduplicates exercises across sources, merging metadata into rich consolidated records."""
    from collections import defaultdict
    groups = defaultdict(list)
    
    for item in raw_exercises:
        key = make_dedupe_key(item['name'], item['equipment'])
        groups[key].append(item)
        
    merged = []
    for key, items in groups.items():
        if len(items) == 1:
            merged.append(items[0])
            continue
            
        # Sort items by source priority
        items.sort(key=lambda x: SOURCE_PRIORITY.get(x['source'], 0), reverse=True)
        primary = items[0]
        
        # Merge secondary muscles
        all_secondary = set()
        for it in items:
            sec_raw = it.get('secondary_muscles')
            if isinstance(sec_raw, str):
                try:
                    all_secondary.update(json.loads(sec_raw))
                except Exception:
                    pass
            elif isinstance(sec_raw, list):
                all_secondary.update(sec_raw)
        all_secondary.discard(primary['target_muscle'])
        
        # Pick most detailed instructions
        best_instructions = max(items, key=lambda x: len(x.get('instructions') or ''))['instructions']
        best_tips = next((x['tips'] for x in items if x.get('tips')), None)
        best_mechanic = next((x['mechanic'] for x in items if x.get('mechanic')), None)
        best_force = next((x['force'] for x in items if x.get('force')), None)
        best_level = next((x['level'] for x in items if x.get('level')), primary.get('level'))
        best_gif = next((x['gif_url'] for x in items if x.get('gif_url')), None)
        best_video = next((x['video_url'] for x in items if x.get('video_url')), None)
        
        # Combine unique sources
        sources = []
        for it in items:
            src = it.get('source', '')
            for s in src.split(','):
                s_clean = s.strip()
                if s_clean and s_clean not in sources:
                    sources.append(s_clean)
                    
        merged.append({
            'id': primary['id'],
            'name': primary['name'],
            'category': primary['category'],
            'body_part': primary['body_part'],
            'target_muscle': primary['target_muscle'],
            'secondary_muscles': json.dumps(sorted(list(all_secondary))),
            'equipment': primary['equipment'],
            'mechanic': best_mechanic,
            'force': best_force,
            'level': best_level,
            'instructions': best_instructions,
            'tips': best_tips,
            'source': ', '.join(sources),
            'source_id': primary['source_id'],
            'gif_url': best_gif,
            'video_url': best_video,
        })
        
    return merged


def main():
    print("=" * 70)
    print("🏋️  Oly Open-Source Exercise Database Bulk Ingestion Pipeline")
    print("=" * 70)

    # 1. Fetch / load all datasets
    try:
        raw_fedb = fetch_or_load_cached("free_exercise_db.json", URL_FREE_EXERCISE_DB)
        raw_wger = fetch_or_load_cached("wger_exercises.json", URL_WGER_API)
        raw_hasan = fetch_or_load_cached("exercises_dataset.json", URL_EXERCISES_DATASET)
    except Exception as e:
        print(f"❌ Error during data acquisition: {e}", file=sys.stderr)
        sys.exit(1)

    print("\n🔍 Parsing and normalizing datasets...")
    fedb_exercises = parse_free_exercise_db(raw_fedb)
    wger_exercises = parse_wger_exercises(raw_wger)
    hasan_exercises = parse_exercises_dataset(raw_hasan)
    oly_curated = get_oly_curated_catalog()

    print(f"  • Free Exercise DB: {len(fedb_exercises):,} exercises")
    print(f"  • wger Workout Manager: {len(wger_exercises):,} exercises")
    print(f"  • Exercises-Dataset: {len(hasan_exercises):,} exercises")
    print(f"  • Oly Curated & Mobility: {len(oly_curated):,} exercises")

    raw_all_exercises: List[Dict[str, Any]] = []
    raw_all_exercises.extend(oly_curated)
    raw_all_exercises.extend(fedb_exercises)
    raw_all_exercises.extend(wger_exercises)
    raw_all_exercises.extend(hasan_exercises)

    total_raw = len(raw_all_exercises)
    print(f"\n🔄 Running intelligent cross-dataset deduplication across {total_raw:,} movements...")
    deduped_exercises = deduplicate_and_merge_exercises(raw_all_exercises)
    dupes_eliminated = total_raw - len(deduped_exercises)
    print(f"  ✅ Eliminated {dupes_eliminated:,} duplicate movements (Consolidated total: {len(deduped_exercises):,})")

    # Deterministic sorting for 100% idempotent database builds
    deduped_exercises.sort(key=lambda x: (x['category'], x['name'], x['id']))

    print(f"\n💾 Building SQLite database at {DB_PATH} ({len(deduped_exercises):,} total entries)...")
    conn = init_database(DB_PATH)

    insert_sql = """
    INSERT INTO exercises (
        id, name, category, body_part, target_muscle, secondary_muscles,
        equipment, mechanic, force, level, instructions, tips,
        source, source_id, gif_url, video_url
    ) VALUES (
        :id, :name, :category, :body_part, :target_muscle, :secondary_muscles,
        :equipment, :mechanic, :force, :level, :instructions, :tips,
        :source, :source_id, :gif_url, :video_url
    );
    """

    cursor = conn.cursor()
    cursor.executemany(insert_sql, deduped_exercises)
    conn.commit()

    # Verify counts
    total_count = cursor.execute("SELECT COUNT(*) FROM exercises;").fetchone()[0]
    fts_count = cursor.execute("SELECT COUNT(*) FROM exercises_fts;").fetchone()[0]

    # Vacuum and optimize
    print("🧹 Running VACUUM and ANALYZE...")
    conn.execute("VACUUM;")
    conn.execute("ANALYZE;")
    conn.close()

    db_size = os.path.getsize(DB_PATH)
    print(f"\n🎉 Successfully created {DB_PATH}!")
    print(f"  • Total Exercises (Clean & Deduplicated): {total_count:,}")
    print(f"  • FTS5 Indexed Rows: {fts_count:,}")
    print(f"  • Duplicates Merged: {dupes_eliminated:,}")
    print(f"  • Final Database Size: {db_size / (1024 * 1024):.2f} MB")
    print("=" * 70)


if __name__ == '__main__':
    main()

