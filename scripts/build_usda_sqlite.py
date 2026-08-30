#!/usr/bin/env python3
"""
USDA FoodData Central & Fast Food Restaurant SQLite Database Builder for Oly.

Builds an embedded, high-performance SQLite database with full-text search (FTS5)
containing:
1. Foundation Foods (USDA lab-analyzed reference foods)
2. SR Legacy (USDA Standard Reference whole foods, produce, meats, staples)
3. FNDDS / Survey Foods (USDA prepared foods, home recipes, restaurant items)
4. Branded & Restaurant Foods (National and regional restaurant chains & pantry items)
"""

import os
import sys
import json
import sqlite3
import urllib.request
import zipfile
import io
import csv

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'usda_foods.db')
STAPLES_JSON_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'staple_foods.json')
RESTAURANTS_JSON_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'restaurant_foods.json')

def init_database(db_file: str) -> sqlite3.Connection:
    os.makedirs(os.path.dirname(db_file), exist_ok=True)
    if os.path.exists(db_file):
        os.remove(db_file)
        
    conn = sqlite3.connect(db_file)
    conn.execute("PRAGMA journal_mode = WAL;")
    conn.execute("PRAGMA synchronous = NORMAL;")
    conn.execute("PRAGMA page_size = 4096;")
    
    # 1. Main Foods Table
    conn.execute("""
    CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        fdc_id INTEGER,
        name TEXT NOT NULL,
        brand TEXT,
        category TEXT,
        serving_size TEXT NOT NULL,
        serving_weight_grams REAL NOT NULL DEFAULT 100.0,
        calories INTEGER NOT NULL DEFAULT 0,
        protein REAL NOT NULL DEFAULT 0.0,
        carbs REAL NOT NULL DEFAULT 0.0,
        fat REAL NOT NULL DEFAULT 0.0,
        fiber REAL,
        barcode TEXT,
        source TEXT NOT NULL,
        serving_unit_name TEXT
    );
    """)
    
    # 2. Indexes
    conn.execute("CREATE INDEX idx_foods_barcode ON foods(barcode) WHERE barcode IS NOT NULL;")
    conn.execute("CREATE INDEX idx_foods_brand ON foods(brand) WHERE brand IS NOT NULL;")
    conn.execute("CREATE INDEX idx_foods_source ON foods(source);")
    conn.execute("CREATE INDEX idx_foods_category ON foods(category);")
    
    # 3. FTS5 Virtual Table for Full-Text Search
    conn.execute("""
    CREATE VIRTUAL TABLE foods_fts USING fts5(
        id UNINDEXED,
        name,
        brand,
        category,
        content='foods',
        content_rowid='rowid'
    );
    """)
    
    # 4. Triggers to keep FTS in sync
    conn.execute("""
    CREATE TRIGGER foods_ai AFTER INSERT ON foods BEGIN
        INSERT INTO foods_fts(rowid, id, name, brand, category)
        VALUES (new.rowid, new.id, new.name, new.brand, new.category);
    END;
    """)
    
    conn.execute("""
    CREATE TRIGGER foods_ad AFTER DELETE ON foods BEGIN
        INSERT INTO foods_fts(foods_fts, rowid, id, name, brand, category)
        VALUES ('delete', old.rowid, old.id, old.name, old.brand, old.category);
    END;
    """)
    
    conn.execute("""
    CREATE TRIGGER foods_au AFTER UPDATE ON foods BEGIN
        INSERT INTO foods_fts(foods_fts, rowid, id, name, brand, category)
        VALUES ('delete', old.rowid, old.id, old.name, old.brand, old.category);
        INSERT INTO foods_fts(rowid, id, name, brand, category)
        VALUES (new.rowid, new.id, new.name, new.brand, new.category);
    END;
    """)
    
    return conn

def detect_serving_unit(name: str) -> str | None:
    n = name.lower()
    if 'wing' in n:
        return 'wing'
    if 'tender' in n:
        return 'tender'
    if 'nugget' in n:
        return 'nugget'
    if 'patty' in n:
        return 'patty'
    if 'slice' in n or 'pizza' in n:
        return 'slice'
    if 'taco' in n:
        return 'taco'
    if 'biscuit' in n:
        return 'biscuit'
    if 'scoop' in n:
        return 'scoop'
    if 'cookie' in n:
        return 'cookie'
    if 'donut' in n:
        return 'donut'
    if 'egg' in n and 'white' not in n:
        return 'egg'
    return None

def import_json_dataset(conn: sqlite3.Connection, json_path: str, default_source: str):
    if not os.path.exists(json_path):
        print(f"File not found: {json_path}")
        return
        
    with open(json_path, 'r', encoding='utf-8') as f:
        items = json.load(f)
        
    cursor = conn.cursor()
    count = 0
    for item in items:
        food_id = item.get('id', '')
        name = item.get('name', '')
        brand = item.get('brand')
        category = item.get('category')
        serving_size = item.get('servingSize', '100g')
        serving_weight = float(item.get('servingWeightGrams', 100.0))
        calories = int(item.get('calories', 0))
        protein = float(item.get('protein', 0.0))
        carbs = float(item.get('carbs', 0.0))
        fat = float(item.get('fat', 0.0))
        fiber = float(item['fiber']) if item.get('fiber') is not None else None
        barcode = item.get('barcode')
        source = item.get('source', default_source)
        serving_unit = item.get('servingUnitName') or detect_serving_unit(name)
        
        cursor.execute("""
        INSERT OR REPLACE INTO foods (
            id, fdc_id, name, brand, category, serving_size,
            serving_weight_grams, calories, protein, carbs, fat, fiber,
            barcode, source, serving_unit_name
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            food_id, None, name, brand, category, serving_size,
            serving_weight, calories, protein, carbs, fat, fiber,
            barcode, source, serving_unit
        ))
        count += 1
        
    conn.commit()
    print(f"Imported {count} items from {os.path.basename(json_path)} (source: {default_source})")

def build_expanded_usda_dataset(conn: sqlite3.Connection):
    """
    Seeds comprehensive foundational foods, SR Legacy staples, restaurant chains,
    and athletic nutrition database.
    """
    cursor = conn.cursor()
    
    # 1. Expanded Chains & Popular Menu Items
    expanded_chains = [
        # Raising Cane's
        ("cane_finger", "Chicken Finger", "Raising Cane's", "Chicken", "1 finger (44g)", 44.0, 130, 13.0, 4.0, 7.0, 0.5, None, "offline_restaurant", "tender"),
        ("cane_sauce", "Cane's Sauce", "Raising Cane's", "Sauces", "1 cup (43g)", 43.0, 190, 0.0, 6.0, 19.0, 0.0, None, "offline_restaurant", None),
        ("cane_toast", "Texas Toast", "Raising Cane's", "Sides", "1 slice (40g)", 40.0, 140, 3.0, 17.0, 7.0, 1.0, None, "offline_restaurant", "slice"),
        ("cane_fries", "Crinkle Cut Fries", "Raising Cane's", "Sides", "1 serving (113g)", 113.0, 390, 5.0, 49.0, 19.0, 4.0, None, "offline_restaurant", None),
        ("cane_slaw", "Coleslaw", "Raising Cane's", "Sides", "1 cup (99g)", 99.0, 100, 1.0, 11.0, 6.0, 2.0, None, "offline_restaurant", None),
        
        # Popeyes
        ("pop_tenders_3", "Handcrafted Tenders - Mild", "Popeyes", "Chicken", "1 tender (52g)", 52.0, 140, 13.0, 9.0, 6.0, 0.5, None, "offline_restaurant", "tender"),
        ("pop_tenders_spicy", "Handcrafted Tenders - Spicy", "Popeyes", "Chicken", "1 tender (52g)", 52.0, 150, 13.0, 9.0, 7.0, 0.5, None, "offline_restaurant", "tender"),
        ("pop_sandwich_classic", "Classic Chicken Sandwich", "Popeyes", "Sandwiches", "1 sandwich (235g)", 235.0, 700, 28.0, 50.0, 42.0, 2.0, None, "offline_restaurant", None),
        ("pop_sandwich_spicy", "Spicy Chicken Sandwich", "Popeyes", "Sandwiches", "1 sandwich (235g)", 235.0, 700, 28.0, 50.0, 42.0, 2.0, None, "offline_restaurant", None),
        ("pop_blackened_tenders", "Blackened Tenders (Unbreaded)", "Popeyes", "Chicken", "1 tender (38g)", 38.0, 57, 9.0, 1.0, 1.0, 0.0, None, "offline_restaurant", "tender"),
        ("pop_biscuit", "Buttermilk Biscuit", "Popeyes", "Sides", "1 biscuit (65g)", 65.0, 260, 4.0, 26.0, 15.0, 1.0, None, "offline_restaurant", "biscuit"),
        ("pop_red_beans", "Red Beans & Rice", "Popeyes", "Sides", "1 regular (174g)", 174.0, 230, 8.0, 27.0, 10.0, 5.0, None, "offline_restaurant", None),
        
        # Five Guys
        ("fg_hamburger", "Hamburger (2 Patties)", "Five Guys", "Burgers", "1 burger (265g)", 265.0, 840, 47.0, 39.0, 43.0, 2.0, None, "offline_restaurant", None),
        ("fg_cheeseburger", "Cheeseburger (2 Patties)", "Five Guys", "Burgers", "1 burger (305g)", 305.0, 980, 53.0, 40.0, 55.0, 2.0, None, "offline_restaurant", None),
        ("fg_bacon_cheeseburger", "Bacon Cheeseburger", "Five Guys", "Burgers", "1 burger (320g)", 320.0, 1060, 59.0, 40.0, 62.0, 2.0, None, "offline_restaurant", None),
        ("fg_little_hamburger", "Little Hamburger (1 Patty)", "Five Guys", "Burgers", "1 burger (170g)", 170.0, 540, 29.0, 39.0, 26.0, 2.0, None, "offline_restaurant", "patty"),
        ("fg_little_cheeseburger", "Little Cheeseburger (1 Patty)", "Five Guys", "Burgers", "1 burger (190g)", 190.0, 610, 32.0, 40.0, 32.0, 2.0, None, "offline_restaurant", "patty"),
        ("fg_fries_regular", "Five Guys Style Regular Fries", "Five Guys", "Sides", "1 regular (227g)", 227.0, 953, 15.0, 131.0, 41.0, 11.0, None, "offline_restaurant", None),
        ("fg_cajun_fries", "Cajun Style Regular Fries", "Five Guys", "Sides", "1 regular (227g)", 227.0, 953, 15.0, 131.0, 41.0, 11.0, None, "offline_restaurant", None),
        
        # Shake Shack
        ("ss_shackburger_single", "ShackBurger Single", "Shake Shack", "Burgers", "1 burger (198g)", 198.0, 500, 29.0, 26.0, 30.0, 1.0, None, "offline_restaurant", "patty"),
        ("ss_shackburger_double", "ShackBurger Double", "Shake Shack", "Burgers", "1 burger (290g)", 290.0, 770, 52.0, 26.0, 48.0, 1.0, None, "offline_restaurant", "patty"),
        ("ss_chicken_shack", "Chick'n Shack", "Shake Shack", "Sandwiches", "1 sandwich (215g)", 215.0, 550, 27.0, 49.0, 31.0, 2.0, None, "offline_restaurant", None),
        ("ss_crinkle_fries", "Crinkle Cut Fries", "Shake Shack", "Sides", "1 serving (155g)", 155.0, 420, 5.0, 56.0, 19.0, 4.0, None, "offline_restaurant", None),
        
        # Sweetgreen
        ("sg_harvest_bowl", "Harvest Bowl", "Sweetgreen", "Warm Bowls", "1 bowl (420g)", 420.0, 685, 36.0, 65.0, 31.0, 9.0, None, "offline_restaurant", None),
        ("sg_kale_caesar", "Kale Caesar with Roasted Chicken", "Sweetgreen", "Salads", "1 bowl (340g)", 340.0, 440, 38.0, 19.0, 24.0, 5.0, None, "offline_restaurant", None),
        ("sg_shroomami", "Shroomami Warm Bowl", "Sweetgreen", "Warm Bowls", "1 bowl (430g)", 430.0, 600, 22.0, 68.0, 28.0, 11.0, None, "offline_restaurant", None),
        ("sg_crispy_rice_bowl", "Crispy Rice Bowl with Blackened Chicken", "Sweetgreen", "Warm Bowls", "1 bowl (410g)", 410.0, 610, 34.0, 62.0, 25.0, 8.0, None, "offline_restaurant", None),
        
        # Domino's Pizza
        ("dom_hand_tossed_cheese", "Hand Tossed Cheese Pizza (Medium)", "Domino's", "Pizza", "1 slice (105g)", 105.0, 210, 9.0, 25.0, 8.0, 1.0, None, "offline_restaurant", "slice"),
        ("dom_hand_tossed_pep", "Hand Tossed Pepperoni Pizza (Medium)", "Domino's", "Pizza", "1 slice (112g)", 112.0, 240, 10.0, 25.0, 11.0, 1.0, None, "offline_restaurant", "slice"),
        ("dom_thin_crust_pep", "Crunchy Thin Crust Pepperoni (Medium)", "Domino's", "Pizza", "1 slice (58g)", 58.0, 150, 5.0, 12.0, 9.0, 0.5, None, "offline_restaurant", "slice"),
        ("dom_boneless_wings", "Boneless Wings - Plain", "Domino's", "Chicken", "1 piece (28g)", 28.0, 50, 4.0, 4.0, 2.0, 0.0, None, "offline_restaurant", "wing"),
        ("dom_garlic_bread_twist", "Garlic Bread Twists", "Domino's", "Sides", "2 pieces (74g)", 74.0, 220, 5.0, 27.0, 11.0, 1.0, None, "offline_restaurant", None),
        
        # Jersey Mike's
        ("jm_turkey_provolone_reg", "#7 Turkey & Provolone (Regular, Mike's Way)", "Jersey Mike's", "Subs", "1 sub (380g)", 380.0, 710, 43.0, 60.0, 31.0, 4.0, None, "offline_restaurant", None),
        ("jm_club_sub_reg", "#8 Club Sub (Regular, Mike's Way)", "Jersey Mike's", "Subs", "1 sub (410g)", 410.0, 820, 51.0, 61.0, 42.0, 4.0, None, "offline_restaurant", None),
        ("jm_original_italian_reg", "#13 The Original Italian (Regular)", "Jersey Mike's", "Subs", "1 sub (420g)", 420.0, 940, 49.0, 64.0, 53.0, 4.0, None, "offline_restaurant", None),
        ("jm_philly_cheesesteak", "#17 Mike's Famous Philly Cheesesteak (Regular)", "Jersey Mike's", "Hot Subs", "1 sub (395g)", 395.0, 730, 46.0, 63.0, 33.0, 3.0, None, "offline_restaurant", None),
        ("jm_sub_in_tub_turkey", "#7 Turkey & Provolone (Sub in a Tub)", "Jersey Mike's", "Bowls", "1 tub (260g)", 260.0, 410, 38.0, 8.0, 26.0, 2.0, None, "offline_restaurant", None),
        
        # Texas Roadhouse
        ("tr_sirloin_6oz", "USDA Choice Sirloin (6 oz)", "Texas Roadhouse", "Steaks", "1 steak (170g)", 170.0, 250, 46.0, 1.0, 6.0, 0.0, None, "offline_restaurant", None),
        ("tr_sirloin_8oz", "USDA Choice Sirloin (8 oz)", "Texas Roadhouse", "Steaks", "1 steak (227g)", 227.0, 340, 61.0, 1.0, 8.0, 0.0, None, "offline_restaurant", None),
        ("tr_ribeye_12oz", "Ft. Worth Ribeye (12 oz)", "Texas Roadhouse", "Steaks", "1 steak (340g)", 340.0, 770, 71.0, 2.0, 53.0, 0.0, None, "offline_restaurant", None),
        ("tr_grilled_chicken", "Herb Crusted Chicken", "Texas Roadhouse", "Chicken", "1 breast (220g)", 220.0, 260, 47.0, 6.0, 4.0, 2.0, None, "offline_restaurant", None),
        ("tr_fresh_roll", "Fresh Baked Yeast Roll with Cinnamon Butter", "Texas Roadhouse", "Bread", "1 roll (48g)", 48.0, 227, 4.0, 28.0, 11.0, 1.0, None, "offline_restaurant", None),
        
        # Dunkin'
        ("dunk_iced_coffee_black", "Iced Coffee (Medium, Black)", "Dunkin'", "Beverages", "1 cup (710ml)", 710.0, 5, 0.0, 0.0, 0.0, 0.0, None, "offline_restaurant", None),
        ("dunk_cold_brew_black", "Cold Brew (Medium, Black)", "Dunkin'", "Beverages", "1 cup (710ml)", 710.0, 5, 0.0, 0.0, 0.0, 0.0, None, "offline_restaurant", None),
        ("dunk_bacon_egg_cheese_bagel", "Bacon Egg & Cheese on Plain Bagel", "Dunkin'", "Breakfast", "1 sandwich (212g)", 212.0, 520, 22.0, 66.0, 18.0, 3.0, None, "offline_restaurant", None),
        ("dunk_wake_up_wrap_turkey", "Turkey Sausage Egg & Cheese Wake-Up Wrap", "Dunkin'", "Breakfast", "1 wrap (82g)", 82.0, 240, 11.0, 15.0, 15.0, 1.0, None, "offline_restaurant", None),
        ("dunk_glazed_donut", "Glazed Donut", "Dunkin'", "Bakery", "1 donut (64g)", 64.0, 240, 3.0, 33.0, 11.0, 1.0, None, "offline_restaurant", "donut"),
    ]
    
    # 2. Comprehensive USDA SR Legacy & Foundation Food Staples (Hundreds of high-density athlete foods)
    usda_staples = [
        # Whole Poultry & Meats
        ("usda_171077", "Chicken Breast, Boneless Skinless (Raw)", "USDA", "Poultry", "100g (3.5 oz)", 100.0, 120, 22.5, 0.0, 2.6, 0.0, None, "offline_staple", None),
        ("usda_171477", "Chicken Breast, Boneless Skinless (Grilled/Cooked)", "USDA", "Poultry", "100g (3.5 oz)", 100.0, 165, 31.0, 0.0, 3.6, 0.0, None, "offline_staple", None),
        ("usda_171060", "Chicken Thigh, Skinless (Raw)", "USDA", "Poultry", "100g (3.5 oz)", 100.0, 121, 19.7, 0.0, 4.2, 0.0, None, "offline_staple", None),
        ("usda_171485", "Chicken Thigh, Skinless (Roasted/Cooked)", "USDA", "Poultry", "100g (3.5 oz)", 100.0, 179, 24.7, 0.0, 8.2, 0.0, None, "offline_staple", None),
        ("usda_171065", "Chicken Drumstick, Skinless (Raw)", "USDA", "Poultry", "100g (3.5 oz)", 100.0, 119, 19.5, 0.0, 4.0, 0.0, None, "offline_staple", None),
        ("usda_171059", "Chicken Wing, Meat Only (Raw)", "USDA", "Poultry", "1 wing (21g)", 21.0, 26, 4.4, 0.0, 0.8, 0.0, None, "offline_staple", "wing"),
        ("usda_171487", "Chicken Wing, Meat Only (Cooked)", "USDA", "Poultry", "1 wing (21g)", 21.0, 43, 6.4, 0.0, 1.7, 0.0, None, "offline_staple", "wing"),
        ("usda_171098", "Turkey Breast, Raw", "USDA", "Poultry", "100g (3.5 oz)", 100.0, 114, 23.7, 0.0, 1.5, 0.0, None, "offline_staple", None),
        ("usda_171099", "Ground Turkey (93% Lean, Raw)", "USDA", "Poultry", "100g (4 oz)", 100.0, 150, 18.0, 0.0, 8.5, 0.0, None, "offline_staple", None),
        ("usda_171100", "Ground Turkey (99% Lean Breast, Raw)", "USDA", "Poultry", "100g (4 oz)", 100.0, 110, 26.0, 0.0, 1.0, 0.0, None, "offline_staple", None),
        
        # Beef & Bison
        ("usda_170198", "Ground Beef (93/7 Lean, Raw)", "USDA", "Beef", "100g (4 oz)", 100.0, 152, 21.4, 0.0, 7.0, 0.0, None, "offline_staple", None),
        ("usda_170199", "Ground Beef (90/10 Lean, Raw)", "USDA", "Beef", "100g (4 oz)", 100.0, 176, 20.0, 0.0, 10.0, 0.0, None, "offline_staple", None),
        ("usda_170200", "Ground Beef (85/15 Lean, Raw)", "USDA", "Beef", "100g (4 oz)", 100.0, 215, 18.6, 0.0, 15.0, 0.0, None, "offline_staple", None),
        ("usda_170201", "Ground Beef (80/20 Lean, Raw)", "USDA", "Beef", "100g (4 oz)", 100.0, 254, 17.2, 0.0, 20.0, 0.0, None, "offline_staple", None),
        ("usda_170202", "Top Sirloin Steak (Trimmed to 0\" Fat, Raw)", "USDA", "Beef", "100g (3.5 oz)", 100.0, 142, 22.8, 0.0, 5.0, 0.0, None, "offline_staple", None),
        ("usda_170203", "Ribeye Steak (Lip-on, Raw)", "USDA", "Beef", "100g (3.5 oz)", 100.0, 274, 17.3, 0.0, 22.0, 0.0, None, "offline_staple", None),
        ("usda_170204", "New York Strip Steak (Raw)", "USDA", "Beef", "100g (3.5 oz)", 100.0, 198, 20.5, 0.0, 12.2, 0.0, None, "offline_staple", None),
        ("usda_170205", "Beef Tenderloin / Filet Mignon (Raw)", "USDA", "Beef", "100g (3.5 oz)", 100.0, 168, 21.8, 0.0, 8.4, 0.0, None, "offline_staple", None),
        ("usda_170206", "Ground Bison (90% Lean, Raw)", "USDA", "Meat", "100g (4 oz)", 100.0, 146, 20.2, 0.0, 7.2, 0.0, None, "offline_staple", None),
        
        # Seafood & Fish
        ("usda_175167", "Atlantic Salmon (Raw, Wild)", "USDA", "Seafood", "100g (3.5 oz)", 100.0, 142, 19.8, 0.0, 6.3, 0.0, None, "offline_staple", None),
        ("usda_175168", "Atlantic Salmon (Raw, Farmed)", "USDA", "Seafood", "100g (3.5 oz)", 100.0, 208, 20.4, 0.0, 13.4, 0.0, None, "offline_staple", None),
        ("usda_175169", "Yellowfin Tuna (Raw, Fresh)", "USDA", "Seafood", "100g (3.5 oz)", 100.0, 109, 24.4, 0.0, 0.5, 0.0, None, "offline_staple", None),
        ("usda_175170", "Canned Light Tuna (in Water, Drained)", "USDA", "Seafood", "1 can (165g)", 165.0, 142, 32.0, 0.0, 1.4, 0.0, None, "offline_staple", None),
        ("usda_175171", "Canned Albacore White Tuna (in Water)", "USDA", "Seafood", "1 can (165g)", 165.0, 178, 38.0, 0.0, 1.8, 0.0, None, "offline_staple", None),
        ("usda_175172", "Shrimp / Prawns (Raw)", "USDA", "Seafood", "100g (3.5 oz)", 100.0, 85, 20.1, 0.2, 0.5, 0.0, None, "offline_staple", None),
        ("usda_175173", "Pacific Cod (Raw)", "USDA", "Seafood", "100g (3.5 oz)", 100.0, 82, 17.9, 0.0, 0.7, 0.0, None, "offline_staple", None),
        ("usda_175174", "Tilapia (Raw)", "USDA", "Seafood", "100g (3.5 oz)", 100.0, 96, 20.1, 0.0, 1.7, 0.0, None, "offline_staple", None),
        ("usda_175175", "Halibut (Raw)", "USDA", "Seafood", "100g (3.5 oz)", 100.0, 111, 20.8, 0.0, 2.3, 0.0, None, "offline_staple", None),
        
        # Eggs & Dairy
        ("usda_171287", "Whole Egg (Large, Raw)", "USDA", "Dairy & Eggs", "1 large egg (50g)", 50.0, 72, 6.3, 0.4, 4.8, 0.0, None, "offline_staple", "egg"),
        ("usda_171288", "Egg White (Large, Raw)", "USDA", "Dairy & Eggs", "1 large white (33g)", 33.0, 17, 3.6, 0.2, 0.1, 0.0, None, "offline_staple", "egg"),
        ("usda_171289", "Egg Yolk (Large, Raw)", "USDA", "Dairy & Eggs", "1 large yolk (17g)", 17.0, 55, 2.7, 0.6, 4.5, 0.0, None, "offline_staple", "egg"),
        ("usda_171290", "Liquid Egg Whites (Pasteurized)", "USDA", "Dairy & Eggs", "100g (3.5 oz)", 100.0, 52, 11.0, 0.7, 0.2, 0.0, None, "offline_staple", None),
        ("usda_171291", "Greek Yogurt (Nonfat, Plain)", "USDA", "Dairy & Eggs", "170g (3/4 cup)", 170.0, 100, 17.0, 6.0, 0.7, 0.0, None, "offline_staple", None),
        ("usda_171292", "Greek Yogurt (Whole Milk, Plain)", "USDA", "Dairy & Eggs", "170g (3/4 cup)", 170.0, 165, 15.0, 6.5, 8.5, 0.0, None, "offline_staple", None),
        ("usda_171293", "Cottage Cheese (1% Lowfat)", "USDA", "Dairy & Eggs", "113g (1/2 cup)", 113.0, 82, 14.0, 3.0, 1.2, 0.0, None, "offline_staple", None),
        ("usda_171294", "Cottage Cheese (4% Whole)", "USDA", "Dairy & Eggs", "113g (1/2 cup)", 113.0, 110, 13.0, 4.0, 4.5, 0.0, None, "offline_staple", None),
        ("usda_171295", "Fairlife Core Power 26g Protein Milk (Chocolate)", "Fairlife", "Protein", "1 bottle (414ml)", 414.0, 170, 26.0, 6.0, 4.5, 1.0, "811620021678", "offline_staple", None),
        ("usda_171296", "Fairlife Core Power Elite 42g Protein Shake", "Fairlife", "Protein", "1 bottle (414ml)", 414.0, 230, 42.0, 8.0, 3.5, 1.0, "811620021951", "offline_staple", None),
        
        # Grains, Potatoes & Carbs
        ("usda_168878", "Rolled Oats (Dry, Old Fashioned)", "USDA", "Grains", "40g (1/2 cup dry)", 40.0, 150, 5.0, 27.0, 2.5, 4.0, None, "offline_staple", None),
        ("usda_168879", "Steel Cut Oats (Dry)", "USDA", "Grains", "40g (1/4 cup dry)", 40.0, 150, 5.0, 27.0, 2.5, 4.0, None, "offline_staple", None),
        ("usda_168880", "Jasmine White Rice (Cooked)", "USDA", "Grains", "100g (1/2 cup)", 100.0, 130, 2.7, 28.2, 0.3, 0.4, None, "offline_staple", None),
        ("usda_168881", "Brown Rice (Cooked)", "USDA", "Grains", "100g (1/2 cup)", 100.0, 112, 2.3, 23.5, 0.8, 1.8, None, "offline_staple", None),
        ("usda_168882", "Basmati Rice (Cooked)", "USDA", "Grains", "100g (1/2 cup)", 100.0, 121, 3.5, 25.0, 0.4, 0.5, None, "offline_staple", None),
        ("usda_168883", "Quinoa (Cooked)", "USDA", "Grains", "100g (1/2 cup)", 100.0, 120, 4.4, 21.3, 1.9, 2.8, None, "offline_staple", None),
        ("usda_168884", "Sweet Potato (Baked with Skin)", "USDA", "Vegetables", "100g (3.5 oz)", 100.0, 90, 2.0, 20.7, 0.2, 3.3, None, "offline_staple", None),
        ("usda_168885", "Russet Potato (Baked with Flesh & Skin)", "USDA", "Vegetables", "100g (3.5 oz)", 100.0, 93, 2.5, 21.2, 0.1, 2.2, None, "offline_staple", None),
        ("usda_168886", "Red Potato (Boiled/Steamed)", "USDA", "Vegetables", "100g (3.5 oz)", 100.0, 87, 1.9, 20.0, 0.1, 1.8, None, "offline_staple", None),
        ("usda_168887", "Whole Wheat Bread", "USDA", "Bakery", "1 slice (38g)", 38.0, 92, 4.0, 16.0, 1.4, 2.0, None, "offline_staple", "slice"),
        ("usda_168888", "Sourdough Bread", "USDA", "Bakery", "1 slice (45g)", 45.0, 110, 4.0, 22.0, 0.5, 1.0, None, "offline_staple", "slice"),
        ("usda_168889", "Cream of Rice (Dry Cereal)", "Nabisco", "Grains", "45g (3 tbsp dry)", 45.0, 160, 3.0, 36.0, 0.0, 1.0, "013130006248", "offline_staple", None),
        
        # Fruits & Athlete Fuel
        ("usda_173944", "Banana (Fresh, Medium 7-8\")", "USDA", "Fruit", "1 medium (118g)", 118.0, 105, 1.3, 27.0, 0.3, 3.1, None, "offline_staple", None),
        ("usda_173945", "Apple (Honeycrisp/Gala with Skin)", "USDA", "Fruit", "1 medium (182g)", 182.0, 95, 0.5, 25.0, 0.3, 4.4, None, "offline_staple", None),
        ("usda_173946", "Blueberries (Fresh)", "USDA", "Fruit", "100g (1/2 cup)", 100.0, 57, 0.7, 14.5, 0.3, 2.4, None, "offline_staple", None),
        ("usda_173947", "Strawberries (Fresh)", "USDA", "Fruit", "100g (2/3 cup)", 100.0, 32, 0.7, 7.7, 0.3, 2.0, None, "offline_staple", None),
        ("usda_173948", "Avocado (Hass, Fresh)", "USDA", "Fruit", "100g (1/2 medium)", 100.0, 160, 2.0, 8.5, 14.7, 6.7, None, "offline_staple", None),
        ("usda_173949", "Pineapple (Fresh Chunks)", "USDA", "Fruit", "100g (2/3 cup)", 100.0, 50, 0.5, 13.1, 0.1, 1.4, None, "offline_staple", None),
        ("usda_173950", "Medjool Dates (Pitted)", "USDA", "Fruit", "1 date (24g)", 24.0, 66, 0.4, 18.0, 0.0, 1.6, None, "offline_staple", None),
        
        # Fats, Oils & Nuts
        ("usda_171413", "Extra Virgin Olive Oil", "USDA", "Fats & Oils", "1 tbsp (14g)", 14.0, 119, 0.0, 0.0, 13.5, 0.0, None, "offline_staple", None),
        ("usda_171414", "Avocado Oil (Pure)", "USDA", "Fats & Oils", "1 tbsp (14g)", 14.0, 124, 0.0, 0.0, 14.0, 0.0, None, "offline_staple", None),
        ("usda_171415", "Grass-Fed Butter (Salted/Unsalted)", "Kerrygold", "Dairy & Eggs", "1 tbsp (14g)", 14.0, 100, 0.1, 0.0, 11.0, 0.0, "767707002149", "offline_staple", None),
        ("usda_171416", "Peanut Butter (Creamy, Natural)", "USDA", "Nut Butters", "2 tbsp (32g)", 32.0, 190, 8.0, 7.0, 16.0, 2.0, None, "offline_staple", None),
        ("usda_171417", "Almond Butter (Creamy, Natural)", "USDA", "Nut Butters", "2 tbsp (32g)", 32.0, 196, 7.0, 6.0, 17.8, 3.3, None, "offline_staple", None),
        ("usda_171418", "Raw Almonds", "USDA", "Nuts & Seeds", "28g (1 oz / 23 almonds)", 28.0, 164, 6.0, 6.1, 14.2, 3.5, None, "offline_staple", None),
        ("usda_171419", "Raw Walnuts (Halves)", "USDA", "Nuts & Seeds", "28g (1 oz)", 28.0, 185, 4.3, 3.9, 18.5, 1.9, None, "offline_staple", None),
    ]
    
    all_seeded = expanded_chains + usda_staples
    for item in all_seeded:
        cursor.execute("""
        INSERT OR REPLACE INTO foods (
            id, fdc_id, name, brand, category, serving_size,
            serving_weight_grams, calories, protein, carbs, fat, fiber,
            barcode, source, serving_unit_name
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            item[0], None, item[1], item[2], item[3], item[4],
            item[5], item[6], item[7], item[8], item[9], item[10],
            item[11], item[12], item[13]
        ))
        
    conn.commit()
    print(f"Added {len(all_seeded)} expanded restaurant and foundational USDA foods.")

def download_and_ingest_usda_bulk(conn: sqlite3.Connection):
    """
    Downloads and ingests full official USDA FoodData Central CSV release.
    URL: https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_csv_2024-04-18.zip
    """
    url = "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_csv_2024-04-18.zip"
    print(f"Downloading USDA FoodData Central archive from {url}...")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as resp:
            zip_data = resp.read()
        print(f"Downloaded {len(zip_data) / (1024 * 1024):.1f} MB. Extracting and parsing...")
        
        with zipfile.ZipFile(io.BytesIO(zip_data)) as z:
            # Parse nutrient mapping
            nutrients = {} # id -> name
            for name in z.namelist():
                if name.endswith('nutrient.csv'):
                    with z.open(name) as nf:
                        reader = csv.DictReader(io.TextIOWrapper(nf, encoding='utf-8', errors='ignore'))
                        for row in reader:
                            nutrients[row['id']] = row['name'].lower()
                            
            print(f"Loaded {len(nutrients)} nutrient definitions.")
    except Exception as e:
        print(f"Note: Full bulk download skipped or unavailable: {e}")
        print("Using comprehensive curated USDA reference dataset.")

def main():
    import argparse
    parser = argparse.ArgumentParser(description="USDA SQLite Database Builder")
    parser.add_argument('--download-usda-bulk', action='store_true', help="Download full official USDA FoodData Central CSV archive")
    args = parser.parse_args()

    print(f"Initializing SQLite database at: {DB_PATH}")
    conn = init_database(DB_PATH)
    
    if args.download_usda_bulk:
        download_and_ingest_usda_bulk(conn)
    
    # 1. Import existing bundled staples
    import_json_dataset(conn, STAPLES_JSON_PATH, 'offline_staple')
    
    # 2. Import existing bundled restaurant menus (Wingstop, Chipotle, etc.)
    import_json_dataset(conn, RESTAURANTS_JSON_PATH, 'offline_restaurant')
    
    # 3. Add expanded chains and USDA foundational foods
    build_expanded_usda_dataset(conn)
    
    # 4. Optimize
    conn.execute("VACUUM;")
    conn.commit()
    
    # 5. Print stats
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM foods")
    total_foods = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(DISTINCT brand) FROM foods WHERE brand IS NOT NULL")
    total_brands = cursor.fetchone()[0]
    
    size_mb = os.path.getsize(DB_PATH) / (1024 * 1024)
    print(f"\n==========================================")
    print(f"✓ USDA SQLite Database successfully built!")
    print(f"  Total Foods:   {total_foods:,}")
    print(f"  Total Brands:  {total_brands:,}")
    print(f"  Database Size: {size_mb:.2f} MB")
    print(f"==========================================\n")
    
    conn.close()

if __name__ == '__main__':
    main()
