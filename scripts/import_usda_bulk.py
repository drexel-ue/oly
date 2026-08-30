#!/usr/bin/env python3
"""
High-Performance USDA FoodData Central Bulk Dataset Importer for Oly.
Streams and ingests Foundation Foods, SR Legacy, Survey/FNDDS, and Branded Foods
directly into SQLite with FTS5 indexing.
"""

import csv
import os
import sqlite3
import sys
import time
import urllib.request
import zipfile

DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data')
DB_PATH = os.path.join(DATA_DIR, 'usda_foods.db')
TEMP_DIR = os.path.join(os.path.dirname(__file__), '..', '.usda_cache')

NUTRIENT_ENERGY = {'1008', '2047', '2048', '208', '957', '958'}
NUTRIENT_PROTEIN = {'1003', '203', '1053', '257'}
NUTRIENT_FAT = {'1004', '204', '2044', '950'}
NUTRIENT_CARB = {'1005', '205', '2039', '956', '1050'}
NUTRIENT_FIBER = {'1079', '291'}

URLS = {
    'foundation': 'https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_csv_2024-10-31.zip',
    'sr_legacy': 'https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip',
    'survey_fndds': 'https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_survey_food_csv_2024-10-31.zip',
    'branded': 'https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_branded_food_csv_2024-10-31.zip',
}

def detect_serving_unit(name: str) -> str | None:
    if not name:
        return None
    n = name.lower()
    if 'wing' in n:
        return 'wing'
    if 'tender' in n or 'finger' in n:
        return 'tender'
    if 'nugget' in n:
        return 'nugget'
    if 'patty' in n or 'burger' in n:
        return 'patty'
    if 'slice' in n or 'pizza' in n:
        return 'slice'
    if 'taco' in n:
        return 'taco'
    if 'burrito' in n or 'wrap' in n:
        return 'burrito'
    if 'biscuit' in n:
        return 'biscuit'
    if 'donut' in n or 'doughnut' in n:
        return 'donut'
    if 'egg' in n and 'egg roll' not in n:
        return 'egg'
    return None

def download_and_extract(dataset_name: str, url: str) -> str:
    os.makedirs(TEMP_DIR, exist_ok=True)
    zip_path = os.path.join(TEMP_DIR, f"{dataset_name}.zip")
    extract_folder = os.path.join(TEMP_DIR, dataset_name)
    
    if os.path.exists(extract_folder) and os.listdir(extract_folder):
        print(f"[{dataset_name}] Using cached extracted files at {extract_folder}")
        return extract_folder
        
    if not os.path.exists(zip_path):
        print(f"[{dataset_name}] Downloading {url}...")
        headers = {'User-Agent': 'Oly-Nutrition-Pipeline/1.0'}
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as resp, open(zip_path, 'wb') as out_f:
            total_size = int(resp.headers.get('content-length', 0))
            downloaded = 0
            block_size = 1024 * 1024
            while True:
                chunk = resp.read(block_size)
                if not chunk:
                    break
                downloaded += len(chunk)
                out_f.write(chunk)
                if total_size > 0:
                    pct = (downloaded / total_size) * 100
                    print(f"\r  Downloaded {downloaded // (1024*1024)}MB / {total_size // (1024*1024)}MB ({pct:.1f}%)", end='')
                else:
                    print(f"\r  Downloaded {downloaded // (1024*1024)}MB", end='')
            print()
            
    print(f"[{dataset_name}] Extracting archive...")
    os.makedirs(extract_folder, exist_ok=True)
    with zipfile.ZipFile(zip_path, 'r') as zf:
        zf.extractall(extract_folder)
    print(f"[{dataset_name}] Extracted successfully.")
    return extract_folder

def find_file_in_dir(directory: str, filename: str) -> str | None:
    for root, _, files in os.walk(directory):
        for f in files:
            if f.lower() == filename.lower():
                return os.path.join(root, f)
    return None

def init_db(conn: sqlite3.Connection):
    conn.execute("PRAGMA journal_mode = WAL;")
    conn.execute("PRAGMA synchronous = NORMAL;")
    conn.execute("PRAGMA temp_store = MEMORY;")
    conn.execute("PRAGMA cache_size = -100000;") # 100MB cache
    
    conn.execute("""
    CREATE TABLE IF NOT EXISTS foods (
        id TEXT PRIMARY KEY,
        fdc_id INTEGER,
        name TEXT NOT NULL,
        brand TEXT,
        category TEXT,
        serving_size TEXT,
        serving_weight_grams REAL,
        calories INTEGER,
        protein REAL,
        carbs REAL,
        fat REAL,
        fiber REAL,
        barcode TEXT,
        source TEXT,
        serving_unit_name TEXT
    );
    """)
    
    conn.execute("CREATE INDEX IF NOT EXISTS idx_foods_barcode ON foods(barcode);")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_foods_brand ON foods(brand);")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_foods_category ON foods(category);")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_foods_source ON foods(source);")
    
    conn.execute("""
    CREATE VIRTUAL TABLE IF NOT EXISTS foods_fts USING fts5(
        id UNINDEXED,
        name,
        brand,
        category,
        content='foods',
        content_rowid='rowid',
        tokenize='porter unicode61'
    );
    """)

def process_standard_dataset(dataset_name: str, folder_path: str, conn: sqlite3.Connection):
    food_csv = find_file_in_dir(folder_path, 'food.csv')
    nutrient_csv = find_file_in_dir(folder_path, 'food_nutrient.csv')
    portion_csv = find_file_in_dir(folder_path, 'food_portion.csv')
    
    if not food_csv or not nutrient_csv:
        print(f"[{dataset_name}] Missing CSV files, skipping.")
        return
        
    print(f"[{dataset_name}] 1. Parsing foods...")
    foods_by_id = {}
    with open(food_csv, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for row in reader:
            fdc_id = row.get('fdc_id')
            if not fdc_id:
                continue
            desc = row.get('description', '').strip()
            if not desc:
                continue
            foods_by_id[int(fdc_id)] = {
                'id': f"usda_{fdc_id}",
                'fdc_id': int(fdc_id),
                'name': desc,
                'brand': None,
                'category': row.get('data_type', 'whole_food'),
                'serving_size': '100g',
                'serving_weight_grams': 100.0,
                'barcode': None,
                'source': f"usda_{dataset_name}",
                'calories': 0,
                'protein': 0.0,
                'carbs': 0.0,
                'fat': 0.0,
                'fiber': 0.0,
            }
            
    if portion_csv and os.path.exists(portion_csv):
        print(f"[{dataset_name}] 2. Parsing food portions...")
        with open(portion_csv, 'r', encoding='utf-8', errors='replace') as f:
            reader = csv.DictReader(f)
            for row in reader:
                try:
                    fdc_id = int(row.get('fdc_id', 0))
                except ValueError:
                    continue
                if fdc_id in foods_by_id:
                    gw = row.get('gram_weight')
                    desc = row.get('portion_description') or row.get('modifier') or ''
                    if gw:
                        try:
                            val = float(gw)
                            if val > 0 and foods_by_id[fdc_id]['serving_weight_grams'] == 100.0:
                                foods_by_id[fdc_id]['serving_weight_grams'] = round(val, 1)
                                if desc:
                                    foods_by_id[fdc_id]['serving_size'] = f"1 serving ({desc})"
                        except ValueError:
                            pass

    print(f"[{dataset_name}] 3. Parsing macronutrients...")
    with open(nutrient_csv, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                fdc_id = int(row.get('fdc_id', 0))
            except ValueError:
                continue
            if fdc_id not in foods_by_id:
                continue
                
            n_id = row.get('nutrient_id')
            amt = row.get('amount')
            if not amt:
                continue
            try:
                val = float(amt)
            except ValueError:
                continue
                
            if n_id in NUTRIENT_ENERGY:
                foods_by_id[fdc_id]['calories'] = round(val)
            elif n_id in NUTRIENT_PROTEIN:
                foods_by_id[fdc_id]['protein'] = round(val, 1)
            elif n_id in NUTRIENT_CARB:
                foods_by_id[fdc_id]['carbs'] = round(val, 1)
            elif n_id in NUTRIENT_FAT:
                foods_by_id[fdc_id]['fat'] = round(val, 1)
            elif n_id in NUTRIENT_FIBER:
                foods_by_id[fdc_id]['fiber'] = round(val, 1)

    print(f"[{dataset_name}] 4. Writing {len(foods_by_id):,} foods to SQLite...")
    cursor = conn.cursor()
    insert_sql = """
    INSERT OR REPLACE INTO foods (
        id, fdc_id, name, brand, category, serving_size,
        serving_weight_grams, calories, protein, carbs, fat, fiber,
        barcode, source, serving_unit_name
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    batch = []
    for item in foods_by_id.values():
        unit_name = detect_serving_unit(item['name'])
        batch.append((
            item['id'], item['fdc_id'], item['name'], item['brand'], item['category'],
            item['serving_size'], item['serving_weight_grams'], item['calories'],
            item['protein'], item['carbs'], item['fat'], item['fiber'],
            item['barcode'], item['source'], unit_name
        ))
        if len(batch) >= 10000:
            cursor.executemany(insert_sql, batch)
            batch.clear()
            
    if batch:
        cursor.executemany(insert_sql, batch)
    conn.commit()
    print(f"[{dataset_name}] ✓ Inserted {len(foods_by_id):,} items.")

def process_branded_dataset(folder_path: str, conn: sqlite3.Connection):
    food_csv = find_file_in_dir(folder_path, 'food.csv')
    branded_csv = find_file_in_dir(folder_path, 'branded_food.csv')
    nutrient_csv = find_file_in_dir(folder_path, 'food_nutrient.csv')
    
    if not food_csv or not branded_csv or not nutrient_csv:
        print("[branded] Missing branded CSV files, skipping.")
        return

    print("[branded] 1. Creating high-speed temporary staging tables in SQLite...")
    cursor = conn.cursor()
    cursor.execute("CREATE TEMP TABLE temp_branded (fdc_id INTEGER PRIMARY KEY, brand TEXT, category TEXT, barcode TEXT, serving_size TEXT, serving_weight REAL);")
    cursor.execute("CREATE TEMP TABLE temp_food (fdc_id INTEGER PRIMARY KEY, name TEXT);")
    cursor.execute("CREATE TEMP TABLE temp_nutrients (fdc_id INTEGER PRIMARY KEY, calories INTEGER, protein REAL, carbs REAL, fat REAL, fiber REAL);")
    
    # 1. Load Branded metadata (only items with valid description/brand/UPC)
    print("[branded] 2. Streaming branded product metadata...")
    b_batch = []
    with open(branded_csv, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for row in reader:
            fdc_id = row.get('fdc_id')
            if not fdc_id:
                continue
            brand = (row.get('brand_name') or row.get('brand_owner') or '').strip()
            cat = (row.get('branded_food_category') or 'branded').strip()
            upc = (row.get('gtin_upc') or '').strip()
            household = (row.get('household_serving_fulltext') or '').strip()
            ss = row.get('serving_size')
            ss_unit = (row.get('serving_size_unit') or '').strip()
            
            serving_size_str = household or (f"{ss} {ss_unit}".strip() if ss else '100g')
            weight = 100.0
            if ss:
                try:
                    weight = float(ss)
                except ValueError:
                    pass
                    
            b_batch.append((int(fdc_id), brand or None, cat, upc or None, serving_size_str, weight))
            if len(b_batch) >= 50000:
                cursor.executemany("INSERT OR IGNORE INTO temp_branded VALUES (?, ?, ?, ?, ?, ?)", b_batch)
                b_batch.clear()
                print(f"    Loaded {cursor.execute('SELECT COUNT(*) FROM temp_branded').fetchone()[0]:,} branded records...", end='\r')
                
        if b_batch:
            cursor.executemany("INSERT OR IGNORE INTO temp_branded VALUES (?, ?, ?, ?, ?, ?)", b_batch)
            b_batch.clear()
            
    total_branded = cursor.execute("SELECT COUNT(*) FROM temp_branded").fetchone()[0]
    print(f"\n[branded] Staged {total_branded:,} branded products.")

    # 2. Stream food descriptions
    print("[branded] 3. Streaming food names...")
    f_batch = []
    with open(food_csv, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for row in reader:
            fdc_id = row.get('fdc_id')
            name = (row.get('description') or '').strip()
            if fdc_id and name:
                f_batch.append((int(fdc_id), name))
                if len(f_batch) >= 50000:
                    cursor.executemany("INSERT OR IGNORE INTO temp_food VALUES (?, ?)", f_batch)
                    f_batch.clear()
        if f_batch:
            cursor.executemany("INSERT OR IGNORE INTO temp_food VALUES (?, ?)", f_batch)
            f_batch.clear()

    # 3. Stream nutrients
    print("[branded] 4. Streaming macronutrients (Filtering Calories, Protein, Carbs, Fat, Fiber)...")
    # In-memory accumulator for batch writing
    nut_map = {}
    with open(nutrient_csv, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        count = 0
        for row in reader:
            count += 1
            if count % 2000000 == 0:
                print(f"    Processed {count // 1000000}M raw nutrient rows...", end='\r')
                
            n_id = row.get('nutrient_id')
            if not n_id:
                continue

            amt = row.get('amount')
            if not amt:
                continue
            try:
                val = float(amt)
            except ValueError:
                continue

            try:
                fdc_id = int(row.get('fdc_id', 0))
            except ValueError:
                continue

            if n_id in NUTRIENT_ENERGY:
                if fdc_id not in nut_map:
                    nut_map[fdc_id] = [0, 0.0, 0.0, 0.0, 0.0]
                nut_map[fdc_id][0] = round(val)
            elif n_id in NUTRIENT_PROTEIN:
                if fdc_id not in nut_map:
                    nut_map[fdc_id] = [0, 0.0, 0.0, 0.0, 0.0]
                nut_map[fdc_id][1] = round(val, 1)
            elif n_id in NUTRIENT_CARB:
                if fdc_id not in nut_map:
                    nut_map[fdc_id] = [0, 0.0, 0.0, 0.0, 0.0]
                nut_map[fdc_id][2] = round(val, 1)
            elif n_id in NUTRIENT_FAT:
                if fdc_id not in nut_map:
                    nut_map[fdc_id] = [0, 0.0, 0.0, 0.0, 0.0]
                nut_map[fdc_id][3] = round(val, 1)
            elif n_id in NUTRIENT_FIBER:
                if fdc_id not in nut_map:
                    nut_map[fdc_id] = [0, 0.0, 0.0, 0.0, 0.0]
                nut_map[fdc_id][4] = round(val, 1)
                
            if len(nut_map) >= 100000:
                cursor.executemany("INSERT OR IGNORE INTO temp_nutrients VALUES (?, ?, ?, ?, ?, ?)", [
                    (k, v[0], v[1], v[2], v[3], v[4]) for k, v in nut_map.items()
                ])
                nut_map.clear()

        if nut_map:
            cursor.executemany("INSERT OR IGNORE INTO temp_nutrients VALUES (?, ?, ?, ?, ?, ?)", [
                (k, v[0], v[1], v[2], v[3], v[4]) for k, v in nut_map.items()
            ])
            nut_map.clear()
            
    print("\n[branded] 5. Merging staged datasets directly into main 'foods' table in SQLite...")
    cursor.execute("""
    INSERT OR REPLACE INTO foods (
        id, fdc_id, name, brand, category, serving_size,
        serving_weight_grams, calories, protein, carbs, fat, fiber,
        barcode, source, serving_unit_name
    )
    SELECT
        'usda_' || b.fdc_id,
        b.fdc_id,
        f.name,
        b.brand,
        b.category,
        b.serving_size,
        b.serving_weight,
        COALESCE(n.calories, 0),
        COALESCE(n.protein, 0.0),
        COALESCE(n.carbs, 0.0),
        COALESCE(n.fat, 0.0),
        COALESCE(n.fiber, 0.0),
        b.barcode,
        'usda_branded',
        NULL
    FROM temp_branded b
    JOIN temp_food f ON b.fdc_id = f.fdc_id
    LEFT JOIN temp_nutrients n ON b.fdc_id = n.fdc_id
    WHERE f.name IS NOT NULL AND LENGTH(f.name) > 0;
    """)
    conn.commit()
    
    # Drop temp tables
    cursor.execute("DROP TABLE temp_branded;")
    cursor.execute("DROP TABLE temp_food;")
    cursor.execute("DROP TABLE temp_nutrients;")
    conn.commit()
    print("[branded] ✓ Successfully merged all Branded Foods into main SQLite table.")

def main():
    include_branded = True # User requested full offline everything
    print("=" * 60)
    print("USDA FoodData Central Complete Bulk Importer")
    print(f"Target DB: {DB_PATH}")
    print(f"Include Branded Foods: {include_branded}")
    print("=" * 60)
    
    start_time = time.time()
    os.makedirs(DATA_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    init_db(conn)
    
    # 1. Foundation Foods
    f_folder = download_and_extract('foundation', URLS['foundation'])
    process_standard_dataset('foundation', f_folder, conn)
    
    # 2. SR Legacy (All whole foods, meats, poultry, fish, grains)
    sr_folder = download_and_extract('sr_legacy', URLS['sr_legacy'])
    process_standard_dataset('sr_legacy', sr_folder, conn)
    
    # 3. Survey FNDDS (Prepared foods, restaurant meals)
    fndds_folder = download_and_extract('survey_fndds', URLS['survey_fndds'])
    process_standard_dataset('survey_fndds', fndds_folder, conn)
    
    # 4. Branded Foods (Complete grocery store database)
    if include_branded:
        b_folder = download_and_extract('branded', URLS['branded'])
        process_branded_dataset(b_folder, conn)
        
    # 5. Local Curated Restaurants and Staples
    print("Re-importing curated fast-food menus & piece-unit rules...")
    from generate_restaurant_catalog import get_all_restaurant_foods
    rest_foods = get_all_restaurant_foods()
    cursor = conn.cursor()
    insert_sql = """
    INSERT OR REPLACE INTO foods (
        id, fdc_id, name, brand, category, serving_size,
        serving_weight_grams, calories, protein, carbs, fat, fiber,
        barcode, source, serving_unit_name
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    for r in rest_foods:
        cursor.execute(insert_sql, (
            r['id'], None, r['name'], r['brand'], r['category'],
            r['servingSize'], r['servingWeightGrams'], r['calories'],
            r['protein'], r['carbs'], r['fat'], r['fiber'],
            None, r['source'], r['servingUnitName']
        ))
    conn.commit()

    # 6. Rebuild FTS5 Index
    print("Rebuilding FTS5 full-text index across complete dataset...")
    conn.execute("INSERT INTO foods_fts(foods_fts) VALUES('rebuild');")
    conn.commit()
    
    # 7. Optimize SQLite Database
    print("Optimizing SQLite database & running VACUUM...")
    conn.execute("PRAGMA wal_checkpoint(TRUNCATE);")
    conn.execute("PRAGMA journal_mode = DELETE;")
    conn.execute("VACUUM;")
    
    total_foods = conn.execute("SELECT COUNT(*) FROM foods").fetchone()[0]
    total_brands = conn.execute("SELECT COUNT(DISTINCT brand) FROM foods WHERE brand IS NOT NULL").fetchone()[0]
    total_barcodes = conn.execute("SELECT COUNT(*) FROM foods WHERE barcode IS NOT NULL").fetchone()[0]
    size_mb = os.path.getsize(DB_PATH) / (1024 * 1024)
    conn.close()
    
    elapsed = time.time() - start_time
    print("=" * 60)
    print("✓ Full USDA Bulk Import Complete!")
    print(f"  Total Foods:      {total_foods:,}")
    print(f"  Total Brands:     {total_brands:,}")
    print(f"  Barcoded Items:   {total_barcodes:,}")
    print(f"  Database Size:    {size_mb:.2f} MB")
    print(f"  Time Elapsed:     {elapsed:.1f}s")
    print("=" * 60)

if __name__ == '__main__':
    main()
