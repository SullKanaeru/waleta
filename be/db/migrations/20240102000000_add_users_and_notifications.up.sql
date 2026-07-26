-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add user_id to all user-scoped tables
ALTER TABLE accounts ADD COLUMN user_id UUID REFERENCES users(id);
ALTER TABLE pockets ADD COLUMN user_id UUID REFERENCES users(id);
ALTER TABLE transactions ADD COLUMN user_id UUID REFERENCES users(id);
ALTER TABLE income_sweeping_rules ADD COLUMN user_id UUID REFERENCES users(id);
ALTER TABLE auto_categorization_rules ADD COLUMN user_id UUID REFERENCES users(id);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    type VARCHAR(50) NOT NULL, -- 'FRUGALITY_WARNING', 'SYSTEM_INFO', 'REMINDER'
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- OCR receipt items (JSONB alternative as structured table)
ALTER TABLE transactions ADD COLUMN ocr_items JSONB NULL;