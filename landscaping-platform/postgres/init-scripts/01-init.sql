-- ============================================================================
-- Landscaping Platform Database Schema
-- Generated from data modeling Q&A session
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================================================
-- Custom Types
-- ============================================================================

CREATE TYPE customer_type AS ENUM ('residential', 'commercial', 'government', 'other');
CREATE TYPE project_status AS ENUM ('draft', 'active', 'completed', 'archived', 'cancelled');
CREATE TYPE job_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');
CREATE TYPE line_type AS ENUM ('plant', 'material', 'labor', 'equipment', 'other');
CREATE TYPE contract_status AS ENUM ('draft', 'active', 'expired', 'cancelled');
CREATE TYPE schedule_status AS ENUM ('active', 'paused', 'completed');
CREATE TYPE schedule_frequency AS ENUM ('weekly', 'biweekly', 'monthly', 'quarterly', 'custom');
CREATE TYPE processing_status AS ENUM ('pending', 'running', 'completed', 'failed');
CREATE TYPE media_entity_type AS ENUM ('plant_species', 'style', 'palette', 'guide', 'property', 'contract', 'project', 'job');

-- ============================================================================
-- Users & RBAC
-- ============================================================================

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,  -- System roles cannot be deleted
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource VARCHAR(50) NOT NULL,         -- e.g., 'projects', 'contracts', 'users'
    action VARCHAR(50) NOT NULL,           -- e.g., 'create', 'read', 'update', 'delete', 'manage'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(resource, action)
);

CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(role_id, permission_id)
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- Core Business Entities
-- ============================================================================


-- Customers (client accounts)
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    customer_type customer_type DEFAULT 'residential',
    email VARCHAR(255),
    phone VARCHAR(50),
    -- Correspondence address (separate from project property locations)
    correspondence_address TEXT,
    correspondence_city VARCHAR(100),
    correspondence_state VARCHAR(50),
    correspondence_zip VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Properties (project/job site locations)
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    -- Site address
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip VARCHAR(20),
    coordinates JSONB,  -- {lat: number, lng: number} -- PostGIS geometry on roadmap
    lot_size DECIMAL(12,2),  -- in sq ft or acres
    zone VARCHAR(20),  -- hardiness zone
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_properties_customer ON properties(customer_id);

-- Projects
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status project_status DEFAULT 'draft',
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Project <-> Properties junction (projects can span multiple properties)
CREATE TABLE project_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    UNIQUE(project_id, property_id)
);

CREATE INDEX idx_project_properties_project ON project_properties(project_id);
CREATE INDEX idx_project_properties_property ON project_properties(property_id);

-- Phases (optional logical groupings of jobs)
CREATE TABLE phases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    description TEXT,
    target_start_date DATE,
    target_end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_phases_project ON phases(project_id);

-- Jobs
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phase_id UUID REFERENCES phases(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status job_status DEFAULT 'pending',
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    scheduled_start DATE,
    scheduled_end DATE,
    actual_start DATE,
    actual_end DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_jobs_phase ON jobs(phase_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_assigned ON jobs(assigned_to);


-- ============================================================================
-- Contracts & Scheduling
-- ============================================================================

CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status contract_status DEFAULT 'draft',
    billing_frequency VARCHAR(50),  -- 'monthly', 'quarterly', 'upon_completion'
    term_start DATE,
    term_end DATE,
    documents JSONB DEFAULT '[]',  -- [{title, storage_key, ...}]
    notes JSONB DEFAULT '[]',
    specifications JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_contracts_customer ON contracts(customer_id);
CREATE INDEX idx_contracts_status ON contracts(status);

-- Contract <-> Properties junction (nullable relationship)
CREATE TABLE contract_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    UNIQUE(contract_id, property_id)
);

CREATE INDEX idx_contract_properties_contract ON contract_properties(contract_id);
CREATE INDEX idx_contract_properties_property ON contract_properties(property_id);

-- Contract <-> Projects junction
CREATE TABLE contract_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    UNIQUE(contract_id, project_id)
);

CREATE INDEX idx_contract_projects_contract ON contract_projects(contract_id);
CREATE INDEX idx_contract_projects_project ON contract_projects(project_id);

-- Recurring schedules for maintenance contracts
CREATE TABLE recurring_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    frequency schedule_frequency NOT NULL,
    -- Custom recurrence pattern (RFC 5545 RRULE format or simplified)
    recurrence_pattern JSONB,  -- {interval: 1, byday: 'MO', bymonthday: null, ...}
    next_run_date DATE,
    last_run_date DATE,
    status schedule_status DEFAULT 'active',
    -- Hidden key linking schedule to projects it originates
    hidden_key VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_recurring_schedules_contract ON recurring_schedules(contract_id);
CREATE INDEX idx_recurring_schedules_status ON recurring_schedules(status);
CREATE INDEX idx_recurring_schedules_hidden_key ON recurring_schedules(hidden_key) WHERE hidden_key IS NOT NULL;

-- Task orders for IDIQ contracts (jobs created from templates on demand)
CREATE TABLE task_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    template_id UUID,  -- References template that instantiated this
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    requested_by UUID REFERENCES users(id),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_task_orders_contract ON task_orders(contract_id);

-- ============================================================================
-- Reference Library
-- ============================================================================

-- Plant Species catalog
CREATE TABLE plant_species (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    common_name VARCHAR(255),
    scientific_name VARCHAR(255) NOT NULL,
    description TEXT,
    care_instructions TEXT,
    growth_rate VARCHAR(50),
    mature_height DECIMAL(10,2),  -- feet
    mature_spread DECIMAL(10,2),  -- feet
    zone_min INTEGER,
    zone_max INTEGER,
    sun_requirement VARCHAR(50),  -- 'full_sun', 'partial_shade', 'full_shade'
    water_requirement VARCHAR(50),  -- 'low', 'moderate', 'high'
    soil_type VARCHAR(100),
    native_region VARCHAR(100),
    is_native BOOLEAN DEFAULT FALSE,
    is_invasive BOOLEAN DEFAULT FALSE,
    invasive_notes TEXT,
    bloom_color VARCHAR(100),
    bloom_season VARCHAR(50),
    foliage_texture VARCHAR(50),
    fall_color VARCHAR(100),
    typical_cost_range JSONB,  -- {low: 10, high: 50, unit: 'gallon'}
    supplier_ids JSONB DEFAULT '{}',  -- {supplier_name: external_id}
    usda_plants_id VARCHAR(50),  -- USDA PLANTS database ID
    embedding VECTOR(1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE INDEX idx_plant_species_scientific ON plant_species(scientific_name);
CREATE INDEX idx_plant_species_common ON plant_species(common_name);
CREATE INDEX idx_plant_species_native ON plant_species(is_native) WHERE is_native = TRUE;
CREATE INDEX idx_plant_species_invasive ON plant_species(is_invasive) WHERE is_invasive = TRUE;
CREATE INDEX idx_plant_species_embedding ON plant_species USING hnsw (embedding vector_cosine_ops);

-- Landscaping Styles
CREATE TABLE landscaping_styles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    -- 6 default structured sections
    design_philosophy TEXT,
    site_analysis TEXT,
    hardscape_materials TEXT,
    plant_palette_structure TEXT,
    color_scheme TEXT,
    maintenance_sustainability TEXT,
    -- Flexible custom sections
    custom_sections JSONB DEFAULT '[]',
    tags JSONB DEFAULT '[]',
    embedding VECTOR(1536),
    is_published BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_landscaping_styles_slug ON landscaping_styles(slug);
CREATE INDEX idx_landscaping_styles_embedding ON landscaping_styles USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_landscaping_styles_published ON landscaping_styles(is_published) WHERE is_published = TRUE;

-- Plant Palettes
CREATE TABLE plant_palettes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Palette categories (size and function groupings)
CREATE TABLE palette_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    palette_id UUID NOT NULL REFERENCES plant_palettes(id) ON DELETE CASCADE,
    category_name VARCHAR(100) NOT NULL,  -- 'Structural Trees', 'Groundcover Perennials'
    description TEXT,
    sort_order INTEGER DEFAULT 0
);

CREATE INDEX idx_palette_categories_palette ON palette_categories(palette_id);

-- Palette items (species within a category)
CREATE TABLE palette_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    palette_id UUID NOT NULL REFERENCES plant_palettes(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES palette_categories(id) ON DELETE CASCADE,
    species_id UUID NOT NULL REFERENCES plant_species(id) ON DELETE CASCADE,
    role_description TEXT,  -- 'Primary shade provider, summer bloom accent'
    proportion VARCHAR(50),  -- 'dominant', 'accent', 'filler'
    sort_order INTEGER DEFAULT 0
);

CREATE INDEX idx_palette_items_palette ON palette_items(palette_id);
CREATE INDEX idx_palette_items_category ON palette_items(category_id);
CREATE INDEX idx_palette_items_species ON palette_items(species_id);


-- Style <-> Palette many-to-many
CREATE TABLE style_palettes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    style_id UUID NOT NULL REFERENCES landscaping_styles(id) ON DELETE CASCADE,
    palette_id UUID NOT NULL REFERENCES plant_palettes(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    UNIQUE(style_id, palette_id)
);

CREATE INDEX idx_style_palettes_style ON style_palettes(style_id);
CREATE INDEX idx_style_palettes_palette ON style_palettes(palette_id);

-- Design Guides (Wiki-like, TipTap JSONB)
CREATE TABLE design_guides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content JSONB NOT NULL,  -- TipTap JSON format
    tags JSONB DEFAULT '[]',
    is_published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_design_guides_slug ON design_guides(slug);
CREATE INDEX idx_design_guides_published ON design_guides(is_published) WHERE is_published = TRUE;

-- ============================================================================
-- Media & Document Management
-- ============================================================================

-- Polymorphic attachments (documents, generic files)
CREATE TABLE attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL,  -- 'customer', 'property', 'contract', 'project', 'job', etc.
    entity_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    storage_key VARCHAR(500) NOT NULL,  -- MinIO/S3 key
    mime_type VARCHAR(100),
    size_bytes BIGINT,
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_attachments_entity ON attachments(entity_type, entity_id);
CREATE INDEX idx_attachments_uploaded_by ON attachments(uploaded_by);

-- Media files (images with gallery support, metadata, AI analysis)
CREATE TABLE media_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL,  -- 'plant_species', 'style', 'palette', 'guide', 'property', etc.
    entity_id UUID NOT NULL,
    -- Storage
    storage_key VARCHAR(500) NOT NULL,
    thumbnail_key VARCHAR(500),
    original_filename VARCHAR(255),
    mime_type VARCHAR(100),
    size_bytes BIGINT,
    -- Metadata
    metadata JSONB DEFAULT '{}',  -- AI-generated description, tags, annotations, area tagging
    -- Gallery support
    caption TEXT,
    is_featured BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    -- AI embeddings
    embedding VECTOR(1536),  -- For image similarity search
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_media_files_entity ON media_files(entity_type, entity_id);
CREATE INDEX idx_media_files_embedding ON media_files USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_media_files_uploaded_by ON media_files(uploaded_by);

-- Media processing log (track AI/workflow runs on files)
CREATE TABLE media_processing_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_file_id UUID NOT NULL REFERENCES media_files(id) ON DELETE CASCADE,
    workflow_name VARCHAR(100) NOT NULL,  -- 'thumbnail', 'ai_description', 'embeddings', etc.
    workflow_version VARCHAR(50),
    status processing_status DEFAULT 'pending',
    input_params JSONB DEFAULT '{}',
    output_results JSONB DEFAULT '{}',
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_media_processing_log_media ON media_processing_log(media_file_id);
CREATE INDEX idx_media_processing_log_workflow ON media_processing_log(workflow_name);
CREATE INDEX idx_media_processing_log_status ON media_processing_log(status);

-- ============================================================================
-- Project Elements (Design Canvas)
-- ============================================================================

CREATE TABLE project_elements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    -- Element can optionally be linked to a job
    job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
    element_type VARCHAR(50) NOT NULL,  -- 'plant', 'hardscape', 'zone', 'annotation', 'measurement'
    name VARCHAR(255),
    position JSONB NOT NULL,  -- {x, y, width, height, rotation}
    properties JSONB DEFAULT '{}',  -- Type-specific attributes
    -- Link to reference library
    plant_species_id UUID REFERENCES plant_species(id) ON DELETE SET NULL,
    -- Canvas layer (z-index)
    layer INTEGER DEFAULT 0,
    is_locked BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_project_elements_project ON project_elements(project_id);
CREATE INDEX idx_project_elements_job ON project_elements(job_id);
CREATE INDEX idx_project_elements_type ON project_elements(element_type);
CREATE INDEX idx_project_elements_species ON project_elements(plant_species_id);

-- ============================================================================
-- Billing & Estimates
-- ============================================================================

-- Unified line items (hierarchical: contract, project, job level)
CREATE TABLE line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(20) NOT NULL,  -- 'contract', 'project', 'job'
    entity_id UUID NOT NULL,
    line_type VARCHAR(20) NOT NULL,  -- 'plant', 'material', 'labor', 'equipment', 'other'
    description TEXT NOT NULL,
    quantity DECIMAL(12,2) NOT NULL DEFAULT 1,
    unit VARCHAR(30),  -- 'gallon', 'sq_ft', 'hour', 'each', 'day', 'linear_ft'
    unit_cost DECIMAL(10,2) NOT NULL DEFAULT 0,
    -- Type-specific attributes in JSONB
    attributes JSONB DEFAULT '{}',
    -- Plant example: {species_id, size: '15 gallon', variety}
    -- Labor example: {crew_type, hourly_rate_override}
    -- Material example: {material_type, coverage_per_unit}
    sort_order INTEGER DEFAULT 0,
    is_billable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_line_items_entity ON line_items(entity_type, entity_id);
CREATE INDEX idx_line_items_type ON line_items(line_type);
CREATE INDEX idx_line_items_sort ON line_items(entity_type, entity_id, sort_order);

-- Estimates (grouping header for line items)
CREATE TABLE estimates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(20) NOT NULL,  -- 'project' or 'contract'
    entity_id UUID NOT NULL,
    version INTEGER DEFAULT 1,
    name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'draft',  -- 'draft', 'submitted', 'approved', 'revised'
    valid_until DATE,
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_estimates_entity ON estimates(entity_type, entity_id);
CREATE INDEX idx_estimates_status ON estimates(status);

-- ============================================================================
-- Collaboration (Y.js CRDT)
-- ============================================================================

CREATE TABLE yjs_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,  -- e.g., 'project:{project_id}:canvas'
    content BYTEA,  -- CRDT document state
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_yjs_documents_name ON yjs_documents(name);

-- ============================================================================
-- Seed Data: Default Roles & Permissions
-- ============================================================================

-- System roles
INSERT INTO roles (name, description, is_system) VALUES
('admin', 'System administrator with full access', TRUE),
('manager', 'Contract and project manager', TRUE),
('designer', 'Landscape designer', TRUE),
('field_crew', 'Field crew member', TRUE),
('estimator', 'Estimator', TRUE),
('viewer', 'Read-only viewer', TRUE),
('customer', 'External customer portal user', TRUE);

-- Permissions
INSERT INTO permissions (resource, action, description) VALUES
-- Users & RBAC
('users', 'read', 'View users'),
('users', 'create', 'Create users'),
('users', 'update', 'Update users'),
('users', 'delete', 'Delete users'),
('roles', 'manage', 'Manage roles and permissions'),
-- Customers
('customers', 'read', 'View customers'),
('customers', 'create', 'Create customers'),
('customers', 'update', 'Update customers'),
('customers', 'delete', 'Delete customers'),
-- Properties
('properties', 'read', 'View properties'),
('properties', 'create', 'Create properties'),
('properties', 'update', 'Update properties'),
('properties', 'delete', 'Delete properties'),
-- Projects
('projects', 'read', 'View projects'),
('projects', 'create', 'Create projects'),
('projects', 'update', 'Update projects'),
('projects', 'delete', 'Delete projects'),
('projects', 'manage', 'Full project management including scheduling'),
-- Contracts
('contracts', 'read', 'View contracts'),
('contracts', 'create', 'Create contracts'),
('contracts', 'update', 'Update contracts'),
('contracts', 'delete', 'Delete contracts'),
('contracts', 'confirm', 'Confirm scheduled projects from contracts'),
-- Reference Library
('reference_library', 'read', 'View reference library'),
('reference_library', 'curate', 'Add and edit reference library entries'),
('reference_library', 'manage', 'Full reference library management'),
-- Estimates
('estimates', 'read', 'View estimates'),
('estimates', 'create', 'Create estimates'),
('estimates', 'approve', 'Approve estimates'),
-- Jobs
('jobs', 'read', 'View jobs'),
('jobs', 'create', 'Create jobs'),
('jobs', 'update', 'Update job status'),
('jobs', 'assign', 'Assign jobs to users'),
-- Media
('media', 'upload', 'Upload media files'),
('media', 'delete', 'Delete media files'),
('media', 'process', 'Trigger media processing workflows');

-- Admin role gets all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p WHERE r.name = 'admin';

-- Manager role permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'manager'
AND (
    p.resource IN ('users') AND p.action IN ('read')
    OR p.resource IN ('customers', 'properties', 'projects', 'contracts')
    OR p.resource = 'jobs' AND p.action IN ('read', 'create', 'update', 'assign')
    OR p.resource = 'contracts' AND p.action = 'confirm'
    OR p.resource = 'estimates' AND p.action IN ('read', 'create', 'approve')
    OR p.resource = 'reference_library' AND p.action = 'read'
    OR p.resource = 'media' AND p.action = 'upload'
);

-- Designer role permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'designer'
AND (
    p.resource IN ('customers', 'properties') AND p.action IN ('read', 'create', 'update')
    OR p.resource = 'projects' AND p.action IN ('read', 'create', 'update', 'delete')
    OR p.resource = 'jobs' AND p.action IN ('read', 'create', 'update')
    OR p.resource = 'reference_library' AND p.action IN ('read', 'curate')
    OR p.resource = 'estimates' AND p.action IN ('read', 'create')
    OR p.resource = 'media' AND p.action IN ('upload', 'delete')
);

-- Field crew permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'field_crew'
AND (
    p.resource IN ('properties') AND p.action = 'read'
    OR p.resource = 'projects' AND p.action = 'read'
    OR p.resource = 'jobs' AND p.action IN ('read', 'update')
    OR p.resource = 'media' AND p.action = 'upload'
);

-- Estimator permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'estimator'
AND (
    p.resource IN ('customers', 'properties', 'projects') AND p.action = 'read'
    OR p.resource = 'estimates' AND p.action IN ('read', 'create', 'approve')
    OR p.resource = 'reference_library' AND p.action = 'read'
    OR p.resource = 'jobs' AND p.action = 'read'
);

-- Viewer permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'viewer'
AND p.resource IN ('customers', 'properties', 'projects', 'contracts', 'jobs', 'reference_library')
AND p.action = 'read';

-- Customer permissions (future external portal)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'customer'
AND (
    p.resource = 'projects' AND p.action = 'read'
    OR p.resource = 'contracts' AND p.action = 'read'
);

-- ============================================================================
-- Seed Data: Demo User
-- ============================================================================

INSERT INTO users (id, email, name, password_hash, role_id)
SELECT 
    '00000000-0000-0000-0000-000000000001',
    'admin@landscaping.local',
    'Admin User',
    '$2b$10$dummy_hash_for_demo',
    id
FROM roles WHERE name = 'admin'
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- Grant Permissions
-- ============================================================================

-- Application user (created at container startup via POSTGRES_USER env)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'landscape_app') THEN
        CREATE ROLE landscape_app WITH LOGIN PASSWORD 'app_password';
    END IF;
END
$$;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO landscape_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO landscape_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO landscape_app;
GRANT ALL PRIVILEGES ON SCHEMA public TO landscape_app;

-- Read-only role for reporting
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'landscape_reader') THEN
        CREATE ROLE landscape_reader WITH LOGIN PASSWORD 'reader_password';
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO landscape_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO landscape_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO landscape_reader;
