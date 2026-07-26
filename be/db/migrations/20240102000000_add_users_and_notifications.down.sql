ALTER TABLE transactions DROP COLUMN ocr_items;

DROP TABLE IF EXISTS notifications;

ALTER TABLE auto_categorization_rules DROP COLUMN user_id;
ALTER TABLE income_sweeping_rules DROP COLUMN user_id;
ALTER TABLE transactions DROP COLUMN user_id;
ALTER TABLE pockets DROP COLUMN user_id;
ALTER TABLE accounts DROP COLUMN user_id;

DROP TABLE IF EXISTS users;