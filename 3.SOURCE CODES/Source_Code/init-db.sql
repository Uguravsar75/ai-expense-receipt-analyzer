-- ========================================
-- Database Initialization Script
-- ========================================

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    verification_token VARCHAR(255) UNIQUE,
    reset_token VARCHAR(255) UNIQUE,
    reset_token_expiry TIMESTAMP
);

-- Create expense table
CREATE TABLE IF NOT EXISTS expense (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255),
    amount DOUBLE PRECISION NOT NULL,
    category VARCHAR(50) NOT NULL,
    predicted_category VARCHAR(50),
    ai_accepted BOOLEAN,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT NOT NULL,
    CONSTRAINT fk_expense_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_expense_user_id ON expense(user_id);
CREATE INDEX IF NOT EXISTS idx_expense_category ON expense(category);
CREATE INDEX IF NOT EXISTS idx_expense_created_at ON expense(created_at);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
