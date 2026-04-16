-- Enable pgvector extension for vector embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Create application user (read-only for reporting)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'landscape_reader') THEN
        CREATE ROLE landscape_reader WITH LOGIN PASSWORD 'reader_password';
    END IF;
END
$$;

-- Grant schema permissions
GRANT USAGE ON SCHEMA public TO landscape_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO landscape_reader;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    client_id UUID,
    status VARCHAR(50) DEFAULT 'draft',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Design documents (Y.js collaborative)
CREATE TABLE IF NOT EXISTS yjs_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    content BYTEA,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for Y.js document lookups
CREATE INDEX IF NOT EXISTS idx_yjs_documents_name ON yjs_documents(name);

-- Plant species catalog with vector embeddings
CREATE TABLE IF NOT EXISTS plant_species (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    scientific_name VARCHAR(255),
    description TEXT,
    care_instructions TEXT,
    growth_rate VARCHAR(50),
    mature_height DECIMAL(10,2),
    mature_spread DECIMAL(10,2),
    zone_min INTEGER,
    zone_max INTEGER,
    sun_requirement VARCHAR(50),
    water_requirement VARCHAR(50),
    soil_type VARCHAR(100),
    image_url TEXT,
    embedding VECTOR(384),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create HNSW index for vector similarity search
CREATE INDEX IF NOT EXISTS idx_plant_species_embedding 
    ON plant_species USING hnsw (embedding vector_cosine_ops);

-- Project elements (plants, hardscape, zones)
CREATE TABLE IF NOT EXISTS project_elements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    element_type VARCHAR(50) NOT NULL,
    name VARCHAR(255),
    properties JSONB DEFAULT '{}',
    position JSONB NOT NULL,  -- {x, y, width, height}
    rotation DECIMAL(6,2) DEFAULT 0,
    plant_species_id UUID REFERENCES plant_species(id) ON DELETE SET NULL,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for project element queries
CREATE INDEX IF NOT EXISTS idx_project_elements_project 
    ON project_elements(project_id);
CREATE INDEX IF NOT EXISTS idx_project_elements_type 
    ON project_elements(element_type);

-- Clients table
CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert demo user for development
INSERT INTO users (id, email, name, password_hash, role)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'demo@landscaping.local',
    'Demo User',
    '$2b$10$dummy_hash_for_demo',
    'admin'
) ON CONFLICT (email) DO NOTHING;

-- Grant all permissions to application user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO landscape;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO landscape;
