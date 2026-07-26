-- 1. Accounts (Rekening/Dompet Digital)
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    balance NUMERIC(15, 2) DEFAULT 0, -- Total fisik di rekening riil
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Master Envelopes (3 Pilar: Kebutuhan, Keinginan, Tabungan)
CREATE TABLE master_envelopes (
    id VARCHAR(50) PRIMARY KEY, -- 'kebutuhan', 'keinginan', 'tabungan'
    name VARCHAR(100) NOT NULL,
    total_allocated NUMERIC(15, 2) DEFAULT 0
);

-- 3. Pockets (Saku Pengeluaran)
CREATE TABLE pockets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    master_id VARCHAR(50) REFERENCES master_envelopes(id),
    name VARCHAR(100) NOT NULL,
    balance NUMERIC(15, 2) DEFAULT 0,
    icon VARCHAR(50),
    color VARCHAR(20)
);

-- 4. Transactions (Ledger Utama)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(20) NOT NULL, -- 'INCOME', 'EXPENSE', 'TRANSFER', 'CORRECTION'
    amount NUMERIC(15, 2) NOT NULL,
    source_account_id UUID REFERENCES accounts(id),
    pocket_id UUID REFERENCES pockets(id) NULL, -- Null jika belum dialokasikan (Inbox) atau masuk ke Unallocated Master
    master_id VARCHAR(50) REFERENCES master_envelopes(id) NULL, 
    merchant_name VARCHAR(255),
    status VARCHAR(20) DEFAULT 'PROCESSED', -- 'PENDING' (Inbox Triage) atau 'PROCESSED'
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Automation Rules
CREATE TABLE income_sweeping_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID REFERENCES accounts(id),
    master_id VARCHAR(50) REFERENCES master_envelopes(id),
    percentage NUMERIC(5,2) NULL, -- misal 50.00 untuk 50%
    fixed_amount NUMERIC(15,2) NULL
);

CREATE TABLE auto_categorization_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_keyword VARCHAR(255) NOT NULL,
    target_pocket_id UUID REFERENCES pockets(id)
);

-- Seed initial master envelopes
INSERT INTO master_envelopes (id, name, total_allocated) VALUES
('kebutuhan', 'Kebutuhan', 0),
('keinginan', 'Keinginan', 0),
('tabungan', 'Tabungan', 0);
