#!/usr/bin/env python3
"""
Generates the comprehensive restaurant_foods.json catalog for Oly.
Includes exact macros, serving sizes, and piece-unit metadata for top chains.
"""

import json
import os

RESTAURANTS_JSON_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'restaurant_foods.json')

def get_all_restaurant_foods():
    foods = []
    
    # -------------------------------------------------------------
    # 1. WINGSTOP (All 12 Flavors Bone-In & Boneless + Tenders + Dips + Sides)
    # -------------------------------------------------------------
    wingstop_flavors = [
        ("lemon_pepper", "Lemon Pepper", 100, 8.0, 0.5, 7.5, 80, 6.0, 5.0, 4.0),
        ("garlic_parm", "Garlic Parmesan", 110, 8.0, 0.5, 8.5, 90, 6.0, 5.0, 5.0),
        ("louisiana_rub", "Louisiana Rub", 90, 8.0, 1.0, 6.5, 80, 6.0, 5.0, 4.0),
        ("original_hot", "Original Hot", 90, 8.0, 0.5, 6.5, 80, 6.0, 5.0, 4.0),
        ("cajun", "Cajun", 90, 8.0, 0.5, 6.5, 80, 6.0, 5.0, 4.0),
        ("mild", "Mild", 100, 8.0, 0.5, 7.5, 90, 6.0, 5.0, 5.0),
        ("atomic", "Atomic", 90, 8.0, 1.0, 6.5, 80, 6.0, 6.0, 4.0),
        ("mango_habanero", "Mango Habanero", 100, 8.0, 5.0, 6.0, 90, 6.0, 9.0, 3.5),
        ("spicy_korean_q", "Spicy Korean Q", 100, 8.0, 5.0, 6.0, 90, 6.0, 9.0, 3.5),
        ("hickory_smoked_bbq", "Hickory Smoked BBQ", 100, 8.0, 5.0, 6.0, 90, 6.0, 9.0, 3.5),
        ("hawaiian", "Hawaiian", 100, 8.0, 6.0, 6.0, 90, 6.0, 10.0, 3.5),
        ("plain", "Plain", 80, 8.0, 0.0, 5.5, 70, 6.0, 4.0, 3.0),
    ]
    for fid, fname, b_cal, b_p, b_c, b_f, bl_cal, bl_p, bl_c, bl_f in wingstop_flavors:
        foods.append({
            "id": f"wingstop_bonein_{fid}",
            "name": f"Classic Bone-In Wings - {fname}",
            "brand": "Wingstop",
            "category": "fast_food",
            "servingSize": "1 wing",
            "servingWeightGrams": 40.0,
            "servingUnitName": "wing",
            "calories": b_cal,
            "protein": b_p,
            "carbs": b_c,
            "fat": b_f,
            "fiber": 0.0,
            "source": "offline_restaurant"
        })
        foods.append({
            "id": f"wingstop_boneless_{fid}",
            "name": f"Boneless Wings - {fname}",
            "brand": "Wingstop",
            "category": "fast_food",
            "servingSize": "1 wing",
            "servingWeightGrams": 35.0,
            "servingUnitName": "wing",
            "calories": bl_cal,
            "protein": bl_p,
            "carbs": bl_c,
            "fat": bl_f,
            "fiber": 0.0,
            "source": "offline_restaurant"
        })
        
    foods.extend([
        {"id": "wingstop_tender_plain", "name": "Crispy Tender - Plain", "brand": "Wingstop", "category": "fast_food", "servingSize": "1 tender", "servingWeightGrams": 65.0, "servingUnitName": "tender", "calories": 140, "protein": 13.0, "carbs": 8.0, "fat": 6.0, "fiber": 0.0, "source": "offline_restaurant"},
        {"id": "wingstop_tender_lemon_pepper", "name": "Crispy Tender - Lemon Pepper", "brand": "Wingstop", "category": "fast_food", "servingSize": "1 tender", "servingWeightGrams": 70.0, "servingUnitName": "tender", "calories": 170, "protein": 13.0, "carbs": 9.0, "fat": 9.0, "fiber": 0.0, "source": "offline_restaurant"},
        {"id": "wingstop_ranch_dip", "name": "House Ranch Dipping Sauce", "brand": "Wingstop", "category": "fast_food", "servingSize": "1 cup (3.25 oz)", "servingWeightGrams": 92.0, "servingUnitName": None, "calories": 310, "protein": 1.0, "carbs": 2.0, "fat": 34.0, "fiber": 0.0, "source": "offline_restaurant"},
        {"id": "wingstop_bleu_cheese", "name": "Bleu Cheese Dipping Sauce", "brand": "Wingstop", "category": "fast_food", "servingSize": "1 cup (3.25 oz)", "servingWeightGrams": 92.0, "servingUnitName": None, "calories": 280, "protein": 2.0, "carbs": 3.0, "fat": 30.0, "fiber": 0.0, "source": "offline_restaurant"},
        {"id": "wingstop_honey_mustard", "name": "Honey Mustard Dipping Sauce", "brand": "Wingstop", "category": "fast_food", "servingSize": "1 cup (3.25 oz)", "servingWeightGrams": 92.0, "servingUnitName": None, "calories": 270, "protein": 1.0, "carbs": 18.0, "fat": 22.0, "fiber": 0.0, "source": "offline_restaurant"},
        {"id": "wingstop_cheese_sauce", "name": "Warm Cheese Sauce", "brand": "Wingstop", "category": "fast_food", "servingSize": "1 cup (3.25 oz)", "servingWeightGrams": 92.0, "servingUnitName": None, "calories": 150, "protein": 4.0, "carbs": 8.0, "fat": 11.0, "fiber": 0.0, "source": "offline_restaurant"},
        {"id": "wingstop_fries_regular", "name": "Seasoned French Fries (Regular)", "brand": "Wingstop", "category": "fast_food", "servingSize": "1 regular order", "servingWeightGrams": 227.0, "servingUnitName": None, "calories": 530, "protein": 6.0, "carbs": 70.0, "fat": 25.0, "fiber": 6.0, "source": "offline_restaurant"},
        {"id": "wingstop_voodoo_fries", "name": "Louisiana Voodoo Fries", "brand": "Wingstop", "category": "fast_food", "servingSize": "1 order", "servingWeightGrams": 310.0, "servingUnitName": None, "calories": 870, "protein": 11.0, "carbs": 82.0, "fat": 56.0, "fiber": 6.0, "source": "offline_restaurant"},
    ])

    # -------------------------------------------------------------
    # 2. MCDONALD'S (Comprehensive Menu)
    # -------------------------------------------------------------
    mcdonalds_items = [
        ("mcd_big_mac", "Big Mac", "1 burger", 215.0, None, 590, 25.0, 46.0, 34.0, 3.0),
        ("mcd_qpc", "Quarter Pounder with Cheese", "1 burger", 220.0, None, 520, 30.0, 42.0, 26.0, 2.0),
        ("mcd_double_qpc", "Double Quarter Pounder with Cheese", "1 burger", 285.0, None, 740, 48.0, 43.0, 42.0, 3.0),
        ("mcd_mcdouble", "McDouble Burger", "1 burger", 150.0, "patty", 400, 22.0, 33.0, 20.0, 2.0),
        ("mcd_double_cheeseburger", "Double Cheeseburger", "1 burger", 165.0, "patty", 450, 25.0, 34.0, 24.0, 2.0),
        ("mcd_cheeseburger", "Cheeseburger", "1 burger", 115.0, "patty", 300, 15.0, 33.0, 13.0, 2.0),
        ("mcd_hamburger", "Hamburger", "1 burger", 100.0, "patty", 250, 12.0, 31.0, 9.0, 1.0),
        ("mcd_triple_cheeseburger", "Triple Cheeseburger", "1 burger", 220.0, "patty", 590, 36.0, 35.0, 35.0, 2.0),
        ("mcd_filet_o_fish", "Filet-O-Fish", "1 sandwich", 140.0, None, 390, 16.0, 39.0, 19.0, 2.0),
        ("mcd_mcchicken", "McChicken Sandwich", "1 sandwich", 145.0, None, 400, 14.0, 40.0, 21.0, 2.0),
        ("mcd_spicy_mcchicken", "Spicy McChicken", "1 sandwich", 145.0, None, 400, 14.0, 40.0, 21.0, 2.0),
        ("mcd_mccrispy", "McCrispy Chicken Sandwich", "1 sandwich", 195.0, None, 470, 26.0, 46.0, 20.0, 1.0),
        ("mcd_spicy_mccrispy", "Spicy McCrispy Chicken Sandwich", "1 sandwich", 215.0, None, 530, 26.0, 48.0, 26.0, 2.0),
        ("mcd_deluxe_mccrispy", "Deluxe McCrispy Chicken Sandwich", "1 sandwich", 240.0, None, 530, 27.0, 48.0, 26.0, 2.0),
        
        # McNuggets
        ("mcd_nugget_1pc", "Chicken McNuggets (Piece)", "1 nugget", 16.5, "nugget", 42, 2.3, 2.6, 2.4, 0.1),
        ("mcd_nuggets_4pc", "Chicken McNuggets (4 Piece)", "4 nuggets (66g)", 66.0, "nugget", 170, 9.0, 10.0, 10.0, 0.5),
        ("mcd_nuggets_6pc", "Chicken McNuggets (6 Piece)", "6 nuggets (100g)", 100.0, "nugget", 250, 14.0, 15.0, 15.0, 1.0),
        ("mcd_nuggets_10pc", "Chicken McNuggets (10 Piece)", "10 nuggets (165g)", 165.0, "nugget", 410, 23.0, 26.0, 24.0, 1.0),
        ("mcd_nuggets_20pc", "Chicken McNuggets (20 Piece)", "20 nuggets (330g)", 330.0, "nugget", 830, 46.0, 51.0, 49.0, 2.0),
        
        # Fries
        ("mcd_fries_small", "World Famous Fries (Small)", "1 small (75g)", 75.0, None, 230, 3.0, 31.0, 11.0, 3.0),
        ("mcd_fries_medium", "World Famous Fries (Medium)", "1 medium (117g)", 117.0, None, 320, 5.0, 43.0, 15.0, 4.0),
        ("mcd_fries_large", "World Famous Fries (Large)", "1 large (150g)", 150.0, None, 480, 7.0, 65.0, 23.0, 5.0),
        
        # Breakfast
        ("mcd_egg_mcmuffin", "Egg McMuffin", "1 sandwich", 135.0, None, 310, 17.0, 30.0, 13.0, 2.0),
        ("mcd_sausage_mcmuffin", "Sausage McMuffin", "1 sandwich", 110.0, None, 400, 14.0, 29.0, 26.0, 2.0),
        ("mcd_sausage_mcmuffin_egg", "Sausage McMuffin with Egg", "1 sandwich", 160.0, None, 480, 20.0, 30.0, 31.0, 2.0),
        ("mcd_bacon_egg_cheese_biscuit", "Bacon, Egg & Cheese Biscuit", "1 sandwich", 150.0, "biscuit", 460, 19.0, 39.0, 26.0, 2.0),
        ("mcd_sausage_biscuit", "Sausage Biscuit", "1 sandwich", 115.0, "biscuit", 460, 11.0, 34.0, 31.0, 2.0),
        ("mcd_sausage_biscuit_egg", "Sausage Biscuit with Egg", "1 sandwich", 165.0, "biscuit", 530, 17.0, 34.0, 38.0, 2.0),
        ("mcd_bacon_egg_mcgriddle", "Bacon, Egg & Cheese McGriddles", "1 sandwich", 175.0, None, 430, 17.0, 44.0, 21.0, 2.0),
        ("mcd_sausage_egg_mcgriddle", "Sausage, Egg & Cheese McGriddles", "1 sandwich", 195.0, None, 550, 19.0, 44.0, 33.0, 2.0),
        ("mcd_hotcakes_3pc", "Hotcakes (3 Pancakes with Syrup & Butter)", "1 platter (230g)", 230.0, "pancake", 580, 9.0, 101.0, 15.0, 2.0),
        ("mcd_hotcakes_sausage", "Hotcakes and Sausage", "1 platter (285g)", 285.0, None, 770, 15.0, 102.0, 33.0, 2.0),
        ("mcd_hash_browns", "Hash Browns", "1 piece (56g)", 56.0, None, 140, 2.0, 18.0, 8.0, 2.0),
        ("mcd_sausage_burrito", "Sausage Burrito", "1 burrito (110g)", 110.0, "burrito", 310, 13.0, 25.0, 17.0, 1.0),
        ("mcd_oatmeal", "Fruit & Maple Oatmeal", "1 cup (265g)", 265.0, None, 320, 6.0, 64.0, 4.5, 4.0),
        
        # Desserts, Shakes & Drinks
        ("mcd_apple_pie", "Baked Apple Pie", "1 pie (77g)", 77.0, None, 230, 2.0, 33.0, 11.0, 3.0),
        ("mcd_mcflurry_oreo", "McFlurry with OREO Cookies (Regular)", "1 regular (285g)", 285.0, None, 510, 12.0, 80.0, 16.0, 1.0),
        ("mcd_mcflurry_mm", "McFlurry with M&M'S Candies (Regular)", "1 regular (330g)", 330.0, None, 640, 13.0, 96.0, 21.0, 2.0),
        ("mcd_vanilla_cone", "Vanilla Soft Serve Cone", "1 cone (85g)", 85.0, None, 200, 5.0, 33.0, 5.0, 0.0),
        ("mcd_chocolate_shake_small", "Chocolate Shake (Small)", "1 small (340ml)", 340.0, None, 520, 12.0, 84.0, 14.0, 1.0),
        ("mcd_vanilla_shake_small", "Vanilla Shake (Small)", "1 small (340ml)", 340.0, None, 480, 11.0, 78.0, 13.0, 0.0),
        ("mcd_strawberry_shake_small", "Strawberry Shake (Small)", "1 small (340ml)", 340.0, None, 470, 11.0, 77.0, 13.0, 0.0),
        ("mcd_iced_coffee_caramel_med", "Iced Caramel Coffee (Medium)", "1 cup (650ml)", 650.0, None, 190, 2.0, 30.0, 7.0, 0.0),
        ("mcd_tangy_bbq_sauce", "Tangy Barbeque Dipping Sauce", "1 cup (28g)", 28.0, None, 45, 0.0, 11.0, 0.0, 0.0),
        ("mcd_sweet_n_sour_sauce", "Sweet 'N Sour Dipping Sauce", "1 cup (28g)", 28.0, None, 50, 0.0, 11.0, 0.0, 0.0),
        ("mcd_creamy_ranch_sauce", "Creamy Ranch Dipping Sauce", "1 cup (28g)", 28.0, None, 110, 0.5, 2.0, 12.0, 0.0),
        ("mcd_spicy_buffalo_sauce", "Spicy Buffalo Dipping Sauce", "1 cup (28g)", 28.0, None, 30, 0.0, 1.0, 3.0, 0.0),
        ("mcd_honey_mustard_sauce", "Honey Mustard Dipping Sauce", "1 cup (28g)", 28.0, None, 60, 0.5, 7.0, 3.5, 0.0),
    ]
    for item in mcdonalds_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "McDonald's",
            "category": "fast_food",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 3. WENDY'S (Comprehensive Menu)
    # -------------------------------------------------------------
    wendys_items = [
        ("wen_daves_single", "Dave's Single Hamburger", "1 burger", 225.0, "patty", 590, 32.0, 38.0, 35.0, 2.0),
        ("wen_daves_double", "Dave's Double Hamburger", "1 burger", 310.0, "patty", 860, 52.0, 39.0, 56.0, 2.0),
        ("wen_daves_triple", "Dave's Triple Hamburger", "1 burger", 395.0, "patty", 1160, 75.0, 40.0, 78.0, 2.0),
        ("wen_baconator", "Baconator", "1 burger", 330.0, "patty", 960, 59.0, 38.0, 66.0, 1.0),
        ("wen_son_of_baconator", "Son of Baconator", "1 burger", 215.0, "patty", 630, 35.0, 37.0, 39.0, 1.0),
        ("wen_jr_bacon_cheeseburger", "Jr. Bacon Cheeseburger (JBC)", "1 burger", 155.0, "patty", 380, 19.0, 26.0, 23.0, 1.0),
        ("wen_jr_cheeseburger", "Jr. Cheeseburger", "1 burger", 130.0, "patty", 290, 14.0, 26.0, 15.0, 1.0),
        ("wen_classic_chicken", "Classic Chicken Sandwich", "1 sandwich", 200.0, None, 490, 28.0, 49.0, 21.0, 2.0),
        ("wen_spicy_chicken", "Spicy Chicken Sandwich", "1 sandwich", 205.0, None, 500, 28.0, 50.0, 21.0, 2.0),
        ("wen_grilled_chicken_wrap", "Grilled Chicken Ranch Wrap", "1 wrap", 160.0, "wrap", 420, 27.0, 32.0, 20.0, 2.0),
        ("wen_nuggets_1pc", "Crispy Chicken Nugget (Piece)", "1 nugget", 17.0, "nugget", 45, 2.5, 2.5, 3.0, 0.1),
        ("wen_nuggets_4pc", "Crispy Chicken Nuggets (4 Piece)", "4 nuggets (68g)", 68.0, "nugget", 180, 10.0, 10.0, 12.0, 0.5),
        ("wen_nuggets_6pc", "Crispy Chicken Nuggets (6 Piece)", "6 nuggets (102g)", 102.0, "nugget", 270, 15.0, 15.0, 18.0, 1.0),
        ("wen_nuggets_10pc", "Crispy Chicken Nuggets (10 Piece)", "10 nuggets (170g)", 170.0, "nugget", 450, 25.0, 25.0, 30.0, 1.0),
        ("wen_spicy_nuggets_10pc", "Spicy Chicken Nuggets (10 Piece)", "10 nuggets (170g)", 170.0, "nugget", 470, 24.0, 24.0, 31.0, 2.0),
        ("wen_fries_medium", "Hot & Crispy Fries (Medium)", "1 medium (140g)", 140.0, None, 350, 4.0, 47.0, 16.0, 4.0),
        ("wen_chili_small", "Rich & Meaty Chili (Small)", "1 cup (227g)", 227.0, None, 240, 16.0, 22.0, 9.0, 5.0),
        ("wen_chili_large", "Rich & Meaty Chili (Large)", "1 cup (340g)", 340.0, None, 340, 22.0, 31.0, 15.0, 6.0),
        ("wen_baked_potato_plain", "Plain Baked Potato", "1 potato (290g)", 290.0, None, 270, 7.0, 61.0, 0.0, 7.0),
        ("wen_baked_potato_sour_cream", "Baked Potato with Sour Cream & Chives", "1 potato (315g)", 315.0, None, 310, 8.0, 63.0, 3.5, 7.0),
        ("wen_frosty_chocolate_small", "Classic Chocolate Frosty (Small)", "1 small (250g)", 250.0, None, 350, 9.0, 58.0, 9.0, 0.0),
        ("wen_frosty_vanilla_small", "Vanilla Frosty (Small)", "1 small (250g)", 250.0, None, 340, 9.0, 56.0, 9.0, 0.0),
        ("wen_apple_pecan_salad", "Apple Pecan Salad (Full Size)", "1 salad (370g)", 370.0, None, 520, 32.0, 45.0, 25.0, 6.0),
    ]
    for item in wendys_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "Wendy's",
            "category": "fast_food",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 4. BURGER KING (Comprehensive Menu)
    # -------------------------------------------------------------
    bk_items = [
        ("bk_whopper", "Whopper Sandwich", "1 sandwich", 290.0, "patty", 670, 28.0, 51.0, 39.0, 3.0),
        ("bk_double_whopper", "Double Whopper Sandwich", "1 sandwich", 375.0, "patty", 900, 48.0, 52.0, 58.0, 3.0),
        ("bk_triple_whopper", "Triple Whopper Sandwich", "1 sandwich", 460.0, "patty", 1130, 68.0, 53.0, 77.0, 3.0),
        ("bk_whopper_jr", "Whopper Jr.", "1 sandwich", 145.0, "patty", 330, 13.0, 29.0, 19.0, 1.0),
        ("bk_impossible_whopper", "Impossible Whopper", "1 sandwich", 285.0, "patty", 630, 25.0, 58.0, 34.0, 4.0),
        ("bk_bacon_king", "Bacon King Sandwich", "1 sandwich", 380.0, "patty", 1200, 67.0, 49.0, 83.0, 2.0),
        ("bk_double_cheeseburger", "Double Cheeseburger", "1 burger", 160.0, "patty", 400, 21.0, 29.0, 23.0, 1.0),
        ("bk_bacon_double_cheeseburger", "Bacon Double Cheeseburger", "1 burger", 175.0, "patty", 460, 26.0, 29.0, 27.0, 1.0),
        ("bk_chicken_sandwich_original", "Original Chicken Sandwich", "1 sandwich", 220.0, None, 680, 28.0, 54.0, 40.0, 2.0),
        ("bk_royal_crispy_chicken", "Royal Crispy Chicken Sandwich", "1 sandwich", 235.0, None, 600, 31.0, 56.0, 28.0, 2.0),
        ("bk_chicken_fries_9pc", "Chicken Fries (9 Piece)", "9 pieces (120g)", 120.0, "piece", 280, 14.0, 19.0, 17.0, 1.0),
        ("bk_nuggets_8pc", "Chicken Nuggets (8 Piece)", "8 nuggets (130g)", 130.0, "nugget", 380, 16.0, 24.0, 25.0, 1.0),
        ("bk_fries_medium", "French Fries (Medium)", "1 medium (150g)", 150.0, None, 370, 5.0, 53.0, 16.0, 4.0),
        ("bk_onion_rings_medium", "Onion Rings (Medium)", "1 medium (145g)", 145.0, None, 410, 4.0, 48.0, 22.0, 3.0),
        ("bk_mozzarella_sticks_4pc", "Mozzarella Sticks (4 Piece)", "4 pieces (85g)", 85.0, "piece", 290, 11.0, 25.0, 16.0, 1.0),
        ("bk_croissanwich_sausage_egg", "Sausage, Egg & Cheese Croissan'wich", "1 sandwich", 160.0, None, 500, 18.0, 30.0, 34.0, 1.0),
        ("bk_croissanwich_bacon_egg", "Bacon, Egg & Cheese Croissan'wich", "1 sandwich", 125.0, None, 340, 14.0, 29.0, 19.0, 1.0),
        ("bk_french_toast_sticks_5pc", "French Toast Sticks (5 Piece)", "5 sticks (140g)", 140.0, "piece", 380, 5.0, 47.0, 19.0, 2.0),
        ("bk_hersheys_sundae_pie", "Hershey's Sundae Pie", "1 slice (78g)", 78.0, "slice", 300, 3.0, 32.0, 18.0, 1.0),
    ]
    for item in bk_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "Burger King",
            "category": "fast_food",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 5. TACO BELL (Comprehensive Menu)
    # -------------------------------------------------------------
    tb_items = [
        ("tb_crunchwrap_supreme", "Crunchwrap Supreme", "1 crunchwrap (260g)", 260.0, None, 540, 16.0, 71.0, 21.0, 6.0),
        ("tb_cheesy_gordita_crunch", "Cheesy Gordita Crunch", "1 taco (170g)", 170.0, "taco", 500, 20.0, 41.0, 28.0, 4.0),
        ("tb_beefy_5_layer_burrito", "Beefy 5-Layer Burrito", "1 burrito (230g)", 230.0, "burrito", 490, 18.0, 65.0, 18.0, 7.0),
        ("tb_burrito_supreme_beef", "Burrito Supreme (Beef)", "1 burrito (240g)", 240.0, "burrito", 390, 16.0, 52.0, 14.0, 7.0),
        ("tb_bean_burrito", "Bean Burrito", "1 burrito (198g)", 198.0, "burrito", 350, 13.0, 55.0, 9.0, 9.0),
        ("tb_cheesy_bean_rice_burrito", "Cheesy Bean & Rice Burrito", "1 burrito (180g)", 180.0, "burrito", 420, 10.0, 56.0, 17.0, 7.0),
        ("tb_cantina_chicken_burrito", "Cantina Chicken Burrito", "1 burrito (255g)", 255.0, "burrito", 540, 25.0, 43.0, 30.0, 4.0),
        ("tb_cantina_chicken_quesadilla", "Cantina Chicken Quesadilla", "1 quesadilla (240g)", 240.0, None, 570, 29.0, 43.0, 31.0, 3.0),
        ("tb_cantina_chicken_bowl", "Cantina Chicken Bowl", "1 bowl (360g)", 360.0, None, 490, 25.0, 44.0, 24.0, 11.0),
        ("tb_cantina_chicken_crispy_taco", "Cantina Chicken Crispy Taco", "1 taco (95g)", 95.0, "taco", 200, 10.0, 16.0, 11.0, 2.0),
        ("tb_cantina_chicken_soft_taco", "Cantina Chicken Soft Taco", "1 taco (125g)", 125.0, "taco", 260, 14.0, 19.0, 14.0, 2.0),
        ("tb_chicken_quesadilla", "Chicken Quesadilla", "1 quesadilla (185g)", 185.0, None, 520, 26.0, 41.0, 27.0, 3.0),
        ("tb_steak_quesadilla", "Steak Quesadilla", "1 quesadilla (190g)", 190.0, None, 520, 26.0, 41.0, 28.0, 3.0),
        ("tb_cheese_quesadilla", "Cheese Quesadilla", "1 quesadilla (150g)", 150.0, None, 470, 19.0, 40.0, 26.0, 3.0),
        ("tb_crunchy_taco", "Crunchy Taco (Beef)", "1 taco (78g)", 78.0, "taco", 170, 8.0, 13.0, 10.0, 3.0),
        ("tb_crunchy_taco_supreme", "Crunchy Taco Supreme", "1 taco (95g)", 95.0, "taco", 190, 8.0, 15.0, 11.0, 3.0),
        ("tb_soft_taco_beef", "Soft Taco (Beef)", "1 taco (96g)", 96.0, "taco", 180, 9.0, 18.0, 8.0, 2.0),
        ("tb_doritos_locos_taco", "Nacho Cheese Doritos Locos Taco", "1 taco (78g)", 78.0, "taco", 170, 8.0, 15.0, 9.0, 3.0),
        ("tb_doritos_locos_taco_supreme", "Nacho Cheese Doritos Locos Taco Supreme", "1 taco (95g)", 95.0, "taco", 190, 8.0, 16.0, 11.0, 3.0),
        ("tb_nacho_fries", "Nacho Fries with Warm Cheese", "1 order (135g)", 135.0, None, 330, 4.0, 37.0, 18.0, 4.0),
        ("tb_cinnamon_twists", "Cinnamon Twists", "1 bag (35g)", 35.0, None, 170, 1.0, 27.0, 6.0, 1.0),
        ("tb_cinnabon_delights_4pc", "Cinnabon Delights (4 Pack)", "4 pieces (62g)", 62.0, "piece", 260, 2.0, 24.0, 17.0, 1.0),
        ("tb_baja_blast_freeze_reg", "Mountain Dew Baja Blast Freeze (Regular)", "1 cup (473ml)", 473.0, None, 190, 0.0, 51.0, 0.0, 0.0),
    ]
    for item in tb_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "Taco Bell",
            "category": "fast_food",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 6. CHICK-FIL-A (Comprehensive Menu)
    # -------------------------------------------------------------
    cfa_items = [
        ("cfa_sandwich", "Chick-fil-A Chicken Sandwich", "1 sandwich", 160.0, None, 440, 29.0, 41.0, 18.0, 2.0),
        ("cfa_deluxe_sandwich", "Chick-fil-A Deluxe Sandwich", "1 sandwich", 225.0, None, 500, 32.0, 44.0, 22.0, 3.0),
        ("cfa_spicy_sandwich", "Spicy Chicken Sandwich", "1 sandwich", 165.0, None, 470, 29.0, 45.0, 19.0, 2.0),
        ("cfa_spicy_deluxe", "Spicy Deluxe Sandwich", "1 sandwich", 230.0, None, 540, 33.0, 47.0, 25.0, 3.0),
        ("cfa_grilled_sandwich", "Grilled Chicken Sandwich", "1 sandwich", 175.0, None, 390, 29.0, 44.0, 12.0, 3.0),
        ("cfa_grilled_club", "Grilled Chicken Club Sandwich", "1 sandwich", 225.0, None, 520, 38.0, 44.0, 22.0, 3.0),
        ("cfa_nuggets_1pc", "Chick-fil-A Nugget (Piece)", "1 nugget", 14.0, "nugget", 32, 3.5, 1.4, 1.5, 0.1),
        ("cfa_nuggets_8ct", "Chick-fil-A Nuggets (8 Count)", "8 nuggets (113g)", 113.0, "nugget", 250, 27.0, 11.0, 11.0, 1.0),
        ("cfa_nuggets_12ct", "Chick-fil-A Nuggets (12 Count)", "12 nuggets (170g)", 170.0, "nugget", 380, 40.0, 16.0, 17.0, 1.0),
        ("cfa_grilled_nuggets_8ct", "Grilled Nuggets (8 Count)", "8 nuggets (100g)", 100.0, "nugget", 130, 25.0, 1.0, 3.0, 0.0),
        ("cfa_grilled_nuggets_12ct", "Grilled Nuggets (12 Count)", "12 nuggets (145g)", 145.0, "nugget", 200, 38.0, 2.0, 4.5, 0.0),
        ("cfa_strips_3ct", "Chick-n-Strips (3 Count)", "3 strips (135g)", 135.0, "tender", 310, 28.0, 16.0, 14.0, 1.0),
        ("cfa_waffle_fries_med", "Waffle Potato Fries (Medium)", "1 medium (125g)", 125.0, None, 420, 5.0, 45.0, 24.0, 5.0),
        ("cfa_mac_cheese_med", "Mac & Cheese (Medium)", "1 container (230g)", 230.0, None, 450, 20.0, 30.0, 28.0, 2.0),
        ("cfa_sauce", "Chick-fil-A Sauce", "1 packet (28g)", 28.0, None, 140, 0.0, 7.0, 13.0, 0.0),
        ("cfa_polynesian_sauce", "Polynesian Sauce", "1 packet (28g)", 28.0, None, 110, 0.0, 14.0, 6.0, 0.0),
        ("cfa_honey_bbq_sauce", "Honey Roasted BBQ Sauce", "1 packet (14g)", 14.0, None, 60, 0.0, 3.0, 5.0, 0.0),
        ("cfa_egg_white_grill", "Egg White Grill", "1 sandwich", 170.0, None, 290, 26.0, 30.0, 8.0, 1.0),
        ("cfa_hashbrown_scramble_bowl", "Hash Brown Scramble Bowl (with Chicken)", "1 bowl (240g)", 240.0, None, 470, 30.0, 19.0, 30.0, 2.0),
        ("cfa_yogurt_parfait", "Greek Yogurt Parfait (with Granola)", "1 cup (155g)", 155.0, None, 270, 13.0, 36.0, 9.0, 2.0),
        ("cfa_milkshake_cookies_cream", "Cookies & Cream Milkshake (Small)", "1 small (400ml)", 400.0, None, 630, 13.0, 85.0, 26.0, 1.0),
    ]
    for item in cfa_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "Chick-fil-A",
            "category": "fast_food",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 7. CHIPOTLE (Complete Bowls, Burritos, Sides)
    # -------------------------------------------------------------
    chipotle_items = [
        ("chip_bowl_chicken", "Chicken Burrito Bowl (Standard Rice, Beans, Salsa)", "1 bowl (450g)", 450.0, None, 680, 48.0, 72.0, 21.0, 12.0),
        ("chip_bowl_steak", "Steak Burrito Bowl (Standard Rice, Beans, Salsa)", "1 bowl (450g)", 450.0, None, 620, 42.0, 72.0, 18.0, 12.0),
        ("chip_bowl_barbacoa", "Barbacoa Burrito Bowl", "1 bowl (450g)", 450.0, None, 640, 44.0, 72.0, 19.0, 12.0),
        ("chip_bowl_carnitas", "Carnitas Burrito Bowl", "1 bowl (450g)", 450.0, None, 680, 43.0, 72.0, 24.0, 12.0),
        ("chip_bowl_sofritas", "Sofritas Burrito Bowl (Plant-Based)", "1 bowl (450g)", 450.0, None, 620, 23.0, 78.0, 23.0, 14.0),
        ("chip_burrito_chicken", "Chicken Burrito (Standard)", "1 burrito (550g)", 550.0, "burrito", 990, 56.0, 118.0, 32.0, 14.0),
        ("chip_burrito_steak", "Steak Burrito (Standard)", "1 burrito (550g)", 550.0, "burrito", 930, 50.0, 118.0, 29.0, 14.0),
        ("chip_quesadilla_chicken", "Chicken Quesadilla", "1 quesadilla (310g)", 310.0, None, 830, 49.0, 52.0, 47.0, 4.0),
        ("chip_quesadilla_steak", "Steak Quesadilla", "1 quesadilla (310g)", 310.0, None, 800, 44.0, 52.0, 45.0, 4.0),
        ("chip_meat_chicken", "Grilled Adobo Chicken (Side/Portion)", "1 portion (113g / 4 oz)", 113.0, None, 180, 32.0, 0.0, 7.0, 0.0),
        ("chip_meat_steak", "Grilled Steak (Side/Portion)", "1 portion (113g / 4 oz)", 113.0, None, 150, 21.0, 1.0, 6.0, 0.0),
        ("chip_meat_barbacoa", "Barbacoa (Side/Portion)", "1 portion (113g / 4 oz)", 113.0, None, 170, 24.0, 2.0, 7.0, 1.0),
        ("chip_meat_carnitas", "Carnitas (Side/Portion)", "1 portion (113g / 4 oz)", 113.0, None, 210, 23.0, 0.0, 12.0, 0.0),
        ("chip_rice_white", "Cilantro-Lime White Rice", "1 serving (113g / 4 oz)", 113.0, None, 210, 4.0, 40.0, 4.0, 1.0),
        ("chip_rice_brown", "Cilantro-Lime Brown Rice", "1 serving (113g / 4 oz)", 113.0, None, 210, 4.0, 36.0, 6.0, 2.0),
        ("chip_beans_black", "Black Beans", "1 serving (113g / 4 oz)", 113.0, None, 130, 8.0, 22.0, 2.0, 7.0),
        ("chip_beans_pinto", "Pinto Beans", "1 serving (113g / 4 oz)", 113.0, None, 130, 8.0, 21.0, 2.0, 6.0),
        ("chip_fajita_veggies", "Fajita Veggies (Peppers & Onions)", "1 serving (70g)", 70.0, None, 20, 1.0, 5.0, 0.0, 1.0),
        ("chip_guacamole_side", "Guacamole (Side/Portion)", "1 portion (100g / 3.5 oz)", 100.0, None, 230, 2.0, 8.0, 22.0, 6.0),
        ("chip_queso_blanco_side", "Queso Blanco (Side/Portion)", "1 portion (100g / 3.5 oz)", 100.0, None, 240, 10.0, 4.0, 20.0, 1.0),
        ("chip_chips_large", "Tortilla Chips (Large Bag)", "1 bag (170g)", 170.0, None, 810, 11.0, 107.0, 38.0, 9.0),
    ]
    for item in chipotle_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "Chipotle",
            "category": "fast_food",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 8. IN-N-OUT BURGER
    # -------------------------------------------------------------
    in_n_out_items = [
        ("ino_double_double", "Double-Double Burger", "1 burger", 330.0, "patty", 670, 37.0, 39.0, 41.0, 3.0),
        ("ino_double_double_protein", "Double-Double (Protein Style - Lettuce Wrap)", "1 burger", 275.0, "patty", 520, 33.0, 11.0, 39.0, 3.0),
        ("ino_double_double_animal", "Double-Double (Animal Style)", "1 burger", 360.0, "patty", 720, 37.0, 42.0, 45.0, 4.0),
        ("ino_cheeseburger", "Cheeseburger", "1 burger", 240.0, "patty", 480, 22.0, 39.0, 27.0, 3.0),
        ("ino_cheeseburger_protein", "Cheeseburger (Protein Style)", "1 burger", 185.0, "patty", 330, 18.0, 11.0, 25.0, 3.0),
        ("ino_hamburger", "Hamburger", "1 burger", 215.0, "patty", 390, 16.0, 39.0, 19.0, 3.0),
        ("ino_hamburger_protein", "Hamburger (Protein Style)", "1 burger", 160.0, "patty", 240, 13.0, 11.0, 17.0, 3.0),
        ("ino_flying_dutchman", "Flying Dutchman (2 Meat, 2 Cheese)", "1 order", 180.0, "patty", 380, 30.0, 2.0, 28.0, 0.0),
        ("ino_french_fries", "Fresh Cut French Fries", "1 order (125g)", 125.0, None, 360, 5.0, 50.0, 15.0, 6.0),
        ("ino_animal_fries", "Animal Style Fries (Cheese, Spread, Grilled Onions)", "1 order (220g)", 220.0, None, 750, 16.0, 62.0, 48.0, 7.0),
        ("ino_shake_chocolate", "Chocolate Shake (15 oz)", "1 cup (425ml)", 425.0, None, 580, 14.0, 67.0, 28.0, 2.0),
        ("ino_shake_vanilla", "Vanilla Shake (15 oz)", "1 cup (425ml)", 425.0, None, 570, 14.0, 64.0, 28.0, 0.0),
    ]
    for item in in_n_out_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "In-N-Out",
            "category": "fast_food",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 9. PANDA EXPRESS
    # -------------------------------------------------------------
    panda_items = [
        ("panda_orange_chicken", "The Original Orange Chicken", "1 entree (160g)", 160.0, None, 490, 25.0, 51.0, 23.0, 2.0),
        ("panda_beijing_beef", "Beijing Beef", "1 entree (160g)", 160.0, None, 480, 14.0, 46.0, 27.0, 1.0),
        ("panda_kung_pao_chicken", "Kung Pao Chicken", "1 entree (170g)", 170.0, None, 290, 16.0, 14.0, 19.0, 2.0),
        ("panda_teriyaki_chicken", "Grilled Teriyaki Chicken", "1 entree (170g)", 170.0, None, 300, 36.0, 8.0, 13.0, 0.0),
        ("panda_honey_walnut_shrimp", "Honey Walnut Shrimp", "1 entree (150g)", 150.0, None, 360, 13.0, 35.0, 20.0, 2.0),
        ("panda_black_pepper_angus", "Black Pepper Angus Steak", "1 entree (150g)", 150.0, None, 180, 19.0, 10.0, 7.0, 1.0),
        ("panda_broccoli_beef", "Broccoli Beef", "1 entree (155g)", 155.0, None, 150, 9.0, 13.0, 7.0, 3.0),
        ("panda_super_greens", "Super Greens (Broccoli, Cabbage, Kale)", "1 side (210g)", 210.0, None, 90, 6.0, 10.0, 3.0, 5.0),
        ("panda_fried_rice", "Fried Rice", "1 side (260g)", 260.0, None, 520, 11.0, 85.0, 16.0, 2.0),
        ("panda_chow_mein", "Chow Mein", "1 side (260g)", 260.0, None, 510, 13.0, 80.0, 20.0, 6.0),
        ("panda_white_steamed_rice", "White Steamed Rice", "1 side (230g)", 230.0, None, 380, 7.0, 87.0, 0.0, 0.0),
        ("panda_cream_cheese_rangoon_3pc", "Cream Cheese Rangoon (3 Piece)", "3 pieces (70g)", 70.0, "piece", 190, 5.0, 24.0, 8.0, 1.0),
        ("panda_chicken_egg_roll", "Chicken Egg Roll", "1 roll (85g)", 85.0, "roll", 200, 6.0, 20.0, 10.0, 2.0),
    ]
    for item in panda_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "Panda Express",
            "category": "fast_food",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 10. SUBWAY (Subs & Wraps)
    # -------------------------------------------------------------
    subway_items = [
        ("sub_turkey_6in", "Turkey Breast Sub (6 inch)", "1 sub (215g)", 215.0, "sub", 280, 20.0, 41.0, 3.5, 4.0),
        ("sub_turkey_footlong", "Turkey Breast Sub (Footlong)", "1 sub (430g)", 430.0, "sub", 560, 40.0, 82.0, 7.0, 8.0),
        ("sub_tuna_6in", "Tuna Sub (6 inch)", "1 sub (235g)", 235.0, "sub", 430, 19.0, 40.0, 25.0, 4.0),
        ("sub_tuna_footlong", "Tuna Sub (Footlong)", "1 sub (470g)", 470.0, "sub", 860, 38.0, 80.0, 50.0, 8.0),
        ("sub_italian_bmt_6in", "Italian B.M.T. Sub (6 inch)", "1 sub (225g)", 225.0, "sub", 380, 19.0, 41.0, 17.0, 4.0),
        ("sub_italian_bmt_footlong", "Italian B.M.T. Sub (Footlong)", "1 sub (450g)", 450.0, "sub", 760, 38.0, 82.0, 34.0, 8.0),
        ("sub_meatball_6in", "Meatball Marinara Sub (6 inch)", "1 sub (290g)", 290.0, "sub", 460, 20.0, 52.0, 20.0, 5.0),
        ("sub_meatball_footlong", "Meatball Marinara Sub (Footlong)", "1 sub (580g)", 580.0, "sub", 920, 40.0, 104.0, 40.0, 10.0),
        ("sub_sweet_onion_chicken_6in", "Sweet Onion Chicken Teriyaki (6 inch)", "1 sub (260g)", 260.0, "sub", 340, 26.0, 52.0, 3.5, 4.0),
        ("sub_sweet_onion_chicken_footlong", "Sweet Onion Chicken Teriyaki (Footlong)", "1 sub (520g)", 520.0, "sub", 680, 52.0, 104.0, 7.0, 8.0),
        ("sub_rotisserie_chicken_6in", "Rotisserie-Style Chicken (6 inch)", "1 sub (240g)", 240.0, "sub", 310, 25.0, 41.0, 6.0, 4.0),
        ("sub_rotisserie_chicken_footlong", "Rotisserie-Style Chicken (Footlong)", "1 sub (480g)", 480.0, "sub", 620, 50.0, 82.0, 12.0, 8.0),
        ("sub_steak_cheese_6in", "Steak & Cheese Sub (6 inch)", "1 sub (245g)", 245.0, "sub", 360, 26.0, 42.0, 10.0, 4.0),
        ("sub_steak_cheese_footlong", "Steak & Cheese Sub (Footlong)", "1 sub (490g)", 490.0, "sub", 720, 52.0, 84.0, 20.0, 8.0),
        ("sub_cookie_chocolate_chip", "Chocolate Chip Cookie", "1 cookie (45g)", 45.0, "cookie", 200, 2.0, 28.0, 10.0, 1.0),
    ]
    for item in subway_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "Subway",
            "category": "fast_food",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 11. STARBUCKS (Coffee, Breakfast, Sandwiches, Bites)
    # -------------------------------------------------------------
    sbux_items = [
        ("sbux_nitro_cold_brew", "Nitro Cold Brew (Grande 16 oz)", "1 cup (473ml)", 473.0, None, 5, 0.0, 0.0, 0.0, 0.0),
        ("sbux_cold_brew_black", "Cold Brew Coffee (Grande 16 oz, Black)", "1 cup (473ml)", 473.0, None, 5, 0.0, 0.0, 0.0, 0.0),
        ("sbux_caffe_americano", "Caffè Americano (Grande 16 oz)", "1 cup (473ml)", 473.0, None, 15, 1.0, 3.0, 0.0, 0.0),
        ("sbux_caffe_latte_2pct", "Caffè Latte with 2% Milk (Grande 16 oz)", "1 cup (473ml)", 473.0, None, 190, 12.0, 18.0, 7.0, 0.0),
        ("sbux_caramel_macchiato", "Iced Caramel Macchiato with 2% Milk (Grande)", "1 cup (473ml)", 473.0, None, 250, 10.0, 37.0, 7.0, 0.0),
        ("sbux_brown_sugar_shaken_espresso", "Iced Brown Sugar Oatmilk Shaken Espresso (Grande)", "1 cup (473ml)", 473.0, None, 120, 1.0, 20.0, 3.0, 1.0),
        ("sbux_pink_drink", "Pink Drink (Grande 16 oz)", "1 cup (473ml)", 473.0, None, 140, 1.0, 28.0, 2.5, 1.0),
        ("sbux_chai_latte_2pct", "Chai Tea Latte with 2% Milk (Grande)", "1 cup (473ml)", 473.0, None, 240, 8.0, 45.0, 4.5, 0.0),
        ("sbux_bacon_gouda", "Bacon, Gouda & Egg Sandwich", "1 sandwich (120g)", 120.0, None, 360, 19.0, 35.0, 18.0, 1.0),
        ("sbux_double_smoked_bacon", "Double-Smoked Bacon, Cheddar & Egg Sandwich", "1 sandwich (150g)", 150.0, None, 500, 21.0, 42.0, 28.0, 1.0),
        ("sbux_turkey_bacon_egg_white", "Turkey Bacon, Cheddar & Egg White Sandwich", "1 sandwich (115g)", 115.0, None, 230, 17.0, 28.0, 5.0, 2.0),
        ("sbux_spinach_feta_wrap", "Spinach, Feta & Egg White Wrap", "1 wrap (160g)", 160.0, "wrap", 290, 20.0, 34.0, 8.0, 3.0),
        ("sbux_egg_bites_bacon", "Bacon & Gruyère Egg Bites (2 Pieces)", "2 bites (130g)", 130.0, "bite", 300, 19.0, 9.0, 20.0, 0.0),
        ("sbux_egg_bites_egg_white", "Egg White & Roasted Red Pepper Egg Bites (2 Pieces)", "2 bites (130g)", 130.0, "bite", 170, 12.0, 11.0, 8.0, 1.0),
        ("sbux_ham_swiss_panini", "Ham & Swiss on Baguette Panini", "1 panini (165g)", 165.0, None, 480, 24.0, 42.0, 24.0, 2.0),
        ("sbux_tomato_mozzarella_panini", "Tomato & Mozzarella on Focaccia", "1 panini (155g)", 155.0, None, 360, 15.0, 42.0, 14.0, 3.0),
        ("sbux_butter_croissant", "Butter Croissant", "1 croissant (68g)", 68.0, None, 250, 5.0, 30.0, 13.0, 1.0),
        ("sbux_banana_walnut_loaf", "Banana Walnut & Pecan Loaf", "1 slice (125g)", 125.0, "slice", 410, 6.0, 53.0, 20.0, 3.0),
    ]
    for item in sbux_items:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": "Starbucks",
            "category": "coffee_and_cafe",
            "servingSize": item[2],
            "servingWeightGrams": item[3],
            "servingUnitName": item[4],
            "calories": item[5],
            "protein": item[6],
            "carbs": item[7],
            "fat": item[8],
            "fiber": item[9],
            "source": "offline_restaurant"
        })

    # -------------------------------------------------------------
    # 12. POPEYES, RAISING CANE'S, FIVE GUYS, SHAKE SHACK, CAVA, SWEETGREEN, DOMINO'S, PANERA
    # -------------------------------------------------------------
    other_chains = [
        # Raising Cane's
        ("cane_finger", "Chicken Finger", "Raising Cane's", "fast_food", "1 finger (44g)", 44.0, "tender", 130, 13.0, 4.0, 7.0, 0.5),
        ("cane_sauce", "Cane's Sauce", "Raising Cane's", "fast_food", "1 cup (43g)", 43.0, None, 190, 0.0, 6.0, 19.0, 0.0),
        ("cane_toast", "Texas Toast", "Raising Cane's", "fast_food", "1 slice (40g)", 40.0, "slice", 140, 3.0, 17.0, 7.0, 1.0),
        ("cane_fries", "Crinkle Cut Fries", "Raising Cane's", "fast_food", "1 serving (113g)", 113.0, None, 390, 5.0, 49.0, 19.0, 4.0),
        ("cane_box_combo", "The Box Combo (4 Fingers, Fries, Toast, Slaw, Sauce)", "Raising Cane's", "fast_food", "1 combo box (420g)", 420.0, None, 1250, 61.0, 115.0, 62.0, 7.0),
        ("cane_caniac_combo", "The Caniac Combo (6 Fingers, Fries, Toast, Slaw, 2 Sauces)", "Raising Cane's", "fast_food", "1 combo box (620g)", 620.0, None, 1790, 87.0, 140.0, 99.0, 8.0),
        
        # Popeyes
        ("pop_tenders_mild_1pc", "Handcrafted Tender - Mild", "Popeyes", "fast_food", "1 tender (52g)", 52.0, "tender", 140, 13.0, 9.0, 6.0, 0.5),
        ("pop_tenders_spicy_1pc", "Handcrafted Tender - Spicy", "Popeyes", "fast_food", "1 tender (52g)", 52.0, "tender", 150, 13.0, 9.0, 7.0, 0.5),
        ("pop_blackened_tender_1pc", "Blackened Tender (Unbreaded)", "Popeyes", "fast_food", "1 tender (38g)", 38.0, "tender", 57, 9.0, 1.0, 1.0, 0.0),
        ("pop_chicken_sandwich_classic", "Classic Chicken Sandwich", "Popeyes", "fast_food", "1 sandwich (235g)", 235.0, None, 700, 28.0, 50.0, 42.0, 2.0),
        ("pop_chicken_sandwich_spicy", "Spicy Chicken Sandwich", "Popeyes", "fast_food", "1 sandwich (235g)", 235.0, None, 700, 28.0, 50.0, 42.0, 2.0),
        ("pop_biscuit", "Buttermilk Biscuit", "Popeyes", "fast_food", "1 biscuit (65g)", 65.0, "biscuit", 260, 4.0, 26.0, 15.0, 1.0),
        ("pop_red_beans_rice", "Red Beans & Rice", "Popeyes", "fast_food", "1 regular (174g)", 174.0, None, 230, 8.0, 27.0, 10.0, 5.0),
        ("pop_mashed_potatoes", "Mashed Potatoes with Cajun Gravy", "Popeyes", "fast_food", "1 regular (155g)", 155.0, None, 110, 3.0, 18.0, 4.0, 1.0),
        
        # Five Guys
        ("fg_hamburger", "Hamburger (2 Patties)", "Five Guys", "fast_food", "1 burger (265g)", 265.0, "patty", 840, 47.0, 39.0, 43.0, 2.0),
        ("fg_cheeseburger", "Cheeseburger (2 Patties)", "Five Guys", "fast_food", "1 burger (305g)", 305.0, "patty", 980, 53.0, 40.0, 55.0, 2.0),
        ("fg_bacon_cheeseburger", "Bacon Cheeseburger (2 Patties)", "Five Guys", "fast_food", "1 burger (320g)", 320.0, "patty", 1060, 59.0, 40.0, 62.0, 2.0),
        ("fg_little_hamburger", "Little Hamburger (1 Patty)", "Five Guys", "fast_food", "1 burger (170g)", 170.0, "patty", 540, 29.0, 39.0, 26.0, 2.0),
        ("fg_little_cheeseburger", "Little Cheeseburger (1 Patty)", "Five Guys", "fast_food", "1 burger (190g)", 190.0, "patty", 610, 32.0, 40.0, 32.0, 2.0),
        ("fg_fries_regular", "Five Guys Style Regular Fries", "Five Guys", "fast_food", "1 regular (227g)", 227.0, None, 953, 15.0, 131.0, 41.0, 11.0),
        ("fg_cajun_fries", "Cajun Style Regular Fries", "Five Guys", "fast_food", "1 regular (227g)", 227.0, None, 953, 15.0, 131.0, 41.0, 11.0),
        
        # Shake Shack
        ("ss_shackburger_single", "ShackBurger Single", "Shake Shack", "fast_food", "1 burger (198g)", 198.0, "patty", 500, 29.0, 26.0, 30.0, 1.0),
        ("ss_shackburger_double", "ShackBurger Double", "Shake Shack", "fast_food", "1 burger (290g)", 290.0, "patty", 770, 52.0, 26.0, 48.0, 1.0),
        ("ss_chicken_shack", "Chick'n Shack", "Shake Shack", "fast_food", "1 sandwich (215g)", 215.0, None, 550, 27.0, 49.0, 31.0, 2.0),
        ("ss_crinkle_fries", "Crinkle Cut Fries", "Shake Shack", "fast_food", "1 serving (155g)", 155.0, None, 420, 5.0, 56.0, 19.0, 4.0),
        
        # Domino's Pizza
        ("dom_hand_tossed_cheese", "Hand Tossed Cheese Pizza (Medium)", "Domino's", "fast_food", "1 slice (105g)", 105.0, "slice", 210, 9.0, 25.0, 8.0, 1.0),
        ("dom_hand_tossed_pep", "Hand Tossed Pepperoni Pizza (Medium)", "Domino's", "fast_food", "1 slice (112g)", 112.0, "slice", 240, 10.0, 25.0, 11.0, 1.0),
        ("dom_thin_crust_pep", "Crunchy Thin Crust Pepperoni (Medium)", "Domino's", "fast_food", "1 slice (58g)", 58.0, "slice", 150, 5.0, 12.0, 9.0, 0.5),
        ("dom_boneless_wings", "Boneless Wings - Plain", "Domino's", "fast_food", "1 piece (28g)", 28.0, "wing", 50, 4.0, 4.0, 2.0, 0.0),
        ("dom_garlic_bread_twist", "Garlic Bread Twists", "Domino's", "fast_food", "2 pieces (74g)", 74.0, None, 220, 5.0, 27.0, 11.0, 1.0),
        
        # Sweetgreen
        ("sg_harvest_bowl", "Harvest Bowl", "Sweetgreen", "healthy_casual", "1 bowl (420g)", 420.0, None, 685, 36.0, 65.0, 31.0, 9.0),
        ("sg_kale_caesar", "Kale Caesar with Roasted Chicken", "Sweetgreen", "healthy_casual", "1 bowl (340g)", 340.0, None, 440, 38.0, 19.0, 24.0, 5.0),
        ("sg_shroomami", "Shroomami Warm Bowl", "Sweetgreen", "healthy_casual", "1 bowl (430g)", 430.0, None, 600, 22.0, 68.0, 28.0, 11.0),
        ("sg_crispy_rice_bowl", "Crispy Rice Bowl with Blackened Chicken", "Sweetgreen", "healthy_casual", "1 bowl (410g)", 410.0, None, 610, 34.0, 62.0, 25.0, 8.0),
        
        # Cava
        ("cava_grains_greens_bowl", "Greens & Grains Bowl with Grilled Chicken", "Cava", "healthy_casual", "1 bowl (460g)", 460.0, None, 650, 42.0, 65.0, 24.0, 10.0),
        ("cava_harissa_avocado_bowl", "Harissa Avocado Bowl with Chicken", "Cava", "healthy_casual", "1 bowl (470g)", 470.0, None, 710, 41.0, 60.0, 34.0, 11.0),
        ("cava_grilled_chicken_portion", "Grilled Chicken (Protein Portion)", "Cava", "healthy_casual", "1 portion (115g)", 115.0, None, 190, 31.0, 1.0, 6.0, 0.0),
        ("cava_braised_lamb_portion", "Braised Lamb (Protein Portion)", "Cava", "healthy_casual", "1 portion (115g)", 115.0, None, 220, 25.0, 2.0, 12.0, 0.0),
        ("cava_crazy_feta_dip", "Crazy Feta Dip (Side)", "Cava", "healthy_casual", "1 scoop (57g)", 57.0, None, 140, 5.0, 2.0, 13.0, 0.0),
        ("cava_tzatziki_dip", "Tzatziki Dip (Side)", "Cava", "healthy_casual", "1 scoop (57g)", 57.0, None, 35, 2.0, 2.0, 2.0, 0.0),
        ("cava_pita_bread", "Cava Fresh Pita Bread", "Cava", "healthy_casual", "1 pita (90g)", 90.0, "pita", 230, 8.0, 47.0, 1.5, 2.0),
        
        # Panera Bread
        ("pan_broccoli_cheddar_cup", "Broccoli Cheddar Soup (Cup)", "Panera Bread", "healthy_casual", "1 cup (240ml)", 240.0, None, 240, 9.0, 19.0, 14.0, 3.0),
        ("pan_broccoli_cheddar_bowl", "Broccoli Cheddar Soup (Bread Bowl)", "Panera Bread", "healthy_casual", "1 bowl (550g)", 550.0, None, 840, 29.0, 116.0, 28.0, 6.0),
        ("pan_fuji_apple_chicken_salad", "Fuji Apple Salad with Chicken", "Panera Bread", "healthy_casual", "1 whole salad (360g)", 360.0, None, 550, 30.0, 34.0, 34.0, 5.0),
        ("pan_mediterranean_veggie_sandwich", "Mediterranean Veggie Sandwich", "Panera Bread", "healthy_casual", "1 sandwich (270g)", 270.0, None, 530, 20.0, 77.0, 17.0, 7.0),
        ("pan_chipotle_chicken_avocado_melt", "Chipotle Chicken, Avocado Melt", "Panera Bread", "healthy_casual", "1 sandwich (310g)", 310.0, None, 770, 38.0, 68.0, 39.0, 6.0),
        ("pan_bagel_cinnamon_crunch", "Cinnamon Crunch Bagel", "Panera Bread", "bakery", "1 bagel (115g)", 115.0, "bagel", 430, 9.0, 82.0, 7.0, 3.0),
        ("pan_bagel_asiago_cheese", "Asiago Cheese Bagel", "Panera Bread", "bakery", "1 bagel (110g)", 110.0, "bagel", 320, 13.0, 55.0, 5.0, 2.0),
        
        # Texas Roadhouse
        ("tr_sirloin_6oz", "USDA Choice Sirloin (6 oz)", "Texas Roadhouse", "steakhouses", "1 steak (170g)", 170.0, None, 250, 46.0, 1.0, 6.0, 0.0),
        ("tr_sirloin_8oz", "USDA Choice Sirloin (8 oz)", "Texas Roadhouse", "steakhouses", "1 steak (227g)", 227.0, None, 340, 61.0, 1.0, 8.0, 0.0),
        ("tr_ribeye_12oz", "Ft. Worth Ribeye (12 oz)", "Texas Roadhouse", "steakhouses", "1 steak (340g)", 340.0, None, 770, 71.0, 2.0, 53.0, 0.0),
        ("tr_herb_crusted_chicken", "Herb Crusted Chicken", "Texas Roadhouse", "steakhouses", "1 breast (220g)", 220.0, None, 260, 47.0, 6.0, 4.0, 2.0),
        ("tr_fresh_roll", "Fresh Baked Yeast Roll with Cinnamon Butter", "Texas Roadhouse", "steakhouses", "1 roll (48g)", 48.0, "roll", 227, 4.0, 28.0, 11.0, 1.0),
    ]
    for item in other_chains:
        foods.append({
            "id": item[0],
            "name": item[1],
            "brand": item[2],
            "category": item[3],
            "servingSize": item[4],
            "servingWeightGrams": item[5],
            "servingUnitName": item[6],
            "calories": item[7],
            "protein": item[8],
            "carbs": item[9],
            "fat": item[10],
            "fiber": item[11],
            "source": "offline_restaurant"
        })
        
    return foods

def main():
    foods = get_all_restaurant_foods()
    with open(RESTAURANTS_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(foods, f, indent=2)
    print(f"✓ Generated {len(foods)} restaurant foods in {RESTAURANTS_JSON_PATH}")

if __name__ == '__main__':
    main()
