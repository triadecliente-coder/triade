-- =====================================================================
-- MIGRAÇÃO BASE: SCHEMA CORE DO SISTEMA TRIADE / TRANSCUNHA LOGÍSTICA
-- Criação das tabelas operacionais centrais, índices, RLS, RPCs e Storage
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Filiais (branches)
CREATE TABLE IF NOT EXISTS public.branches (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT '',
    state TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Clientes Tomadores (clients)
CREATE TABLE IF NOT EXISTS public.clients (
    id TEXT PRIMARY KEY,
    razao_social TEXT NOT NULL DEFAULT '',
    nome_fantasia TEXT NOT NULL DEFAULT '',
    cnpj TEXT NOT NULL DEFAULT '',
    phone TEXT DEFAULT '',
    email TEXT DEFAULT '',
    address TEXT DEFAULT '',
    city TEXT DEFAULT '',
    state TEXT DEFAULT '',
    payment_method TEXT DEFAULT 'Prazo',
    payment_term TEXT DEFAULT '0',
    requires_external_order BOOLEAN NOT NULL DEFAULT FALSE,
    requires_scheduling BOOLEAN NOT NULL DEFAULT FALSE,
    salesperson_name TEXT,
    salesperson_commission_per_ton NUMERIC(12, 2) DEFAULT 0,
    loading_order_model_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Proprietários de Frota / ANTT (owners)
CREATE TABLE IF NOT EXISTS public.owners (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    cpf_cnpj TEXT NOT NULL DEFAULT '',
    phone TEXT DEFAULT '',
    type TEXT DEFAULT 'PJ',
    bank_details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Motoristas (drivers)
CREATE TABLE IF NOT EXISTS public.drivers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    cpf TEXT NOT NULL,
    cnh TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    classification TEXT DEFAULT 'Terceiro',
    owner_id TEXT REFERENCES public.owners(id) ON DELETE SET NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    restriction_reason TEXT,
    has_app BOOLEAN NOT NULL DEFAULT FALSE,
    codigo_atua TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Veículos / Conjuntos (vehicles)
CREATE TABLE IF NOT EXISTS public.vehicles (
    id TEXT PRIMARY KEY,
    plate TEXT NOT NULL,
    set_type TEXT DEFAULT '',
    body_type TEXT DEFAULT '',
    classification TEXT DEFAULT 'Terceiro',
    driver_id TEXT REFERENCES public.drivers(id) ON DELETE SET NULL,
    owner_id TEXT REFERENCES public.owners(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Produtos (products)
CREATE TABLE IF NOT EXISTS public.products (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT 'ton',
    requires_risk_management BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Usuários do Sistema (app_users)
CREATE TABLE IF NOT EXISTS public.app_users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    profile TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    phone TEXT,
    password TEXT,
    client_id TEXT REFERENCES public.clients(id) ON DELETE SET NULL,
    require_password_change BOOLEAN NOT NULL DEFAULT FALSE,
    auth_id UUID,
    password_updated_at TIMESTAMPTZ,
    branch_id TEXT REFERENCES public.branches(id) ON DELETE SET NULL,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Cargas / Lotes (cargos)
CREATE TABLE IF NOT EXISTS public.cargos (
    id TEXT PRIMARY KEY,
    sequence_id INTEGER,
    client_id TEXT REFERENCES public.clients(id) ON DELETE SET NULL,
    product_id TEXT REFERENCES public.products(id) ON DELETE SET NULL,
    origin TEXT NOT NULL DEFAULT '',
    origin_location TEXT,
    origin_map_link TEXT,
    destination TEXT NOT NULL DEFAULT '',
    destination_location TEXT,
    destination_map_link TEXT,
    total_volume NUMERIC(14, 3) NOT NULL DEFAULT 0,
    scheduled_volume NUMERIC(14, 3) NOT NULL DEFAULT 0,
    loaded_volume NUMERIC(14, 3) NOT NULL DEFAULT 0,
    company_freight_value_per_ton NUMERIC(14, 2) NOT NULL DEFAULT 0,
    company_freight_has_toll BOOLEAN DEFAULT FALSE,
    driver_freight_value_per_ton NUMERIC(14, 2) NOT NULL DEFAULT 0,
    driver_freight_has_toll BOOLEAN DEFAULT FALSE,
    driver_freight_pf_has_toll BOOLEAN DEFAULT FALSE,
    has_icms BOOLEAN NOT NULL DEFAULT FALSE,
    icms_percentage NUMERIC(6, 2) NOT NULL DEFAULT 0,
    icms_value NUMERIC(14, 2) DEFAULT 0,
    requires_scheduling BOOLEAN NOT NULL DEFAULT FALSE,
    type TEXT DEFAULT 'CIF',
    status TEXT NOT NULL DEFAULT 'Em Andamento',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by_id TEXT,
    history JSONB NOT NULL DEFAULT '[]'::jsonb,
    loading_deadline TIMESTAMPTZ,
    allowed_vehicle_types JSONB,
    freight_legs JSONB,
    daily_schedule JSONB,
    observations TEXT,
    attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
    origin_coords JSONB,
    destination_coords JSONB,
    salesperson_name TEXT,
    salesperson_commission_per_ton NUMERIC(12, 2) DEFAULT 0,
    branch_id TEXT REFERENCES public.branches(id) ON DELETE SET NULL,
    allowed_profiles JSONB,
    allowed_user_ids JSONB,
    tms_lote_number TEXT,
    client_cnpj TEXT,
    client_branch_id TEXT,
    is_export BOOLEAN DEFAULT FALSE,
    freight_calculation_type TEXT,
    order_number TEXT,
    packaging TEXT,
    financial_cost_enabled BOOLEAN DEFAULT FALSE,
    financial_cost_monthly_rate NUMERIC(10, 4),
    financial_cost_days_term INTEGER,
    financial_cost_base_days INTEGER,
    financial_cost_effective_rate NUMERIC(10, 4),
    financial_cost_per_ton NUMERIC(14, 2),
    financial_cost_total NUMERIC(14, 2)
);

-- 9. Embarques (shipments)
CREATE TABLE IF NOT EXISTS public.shipments (
    id TEXT PRIMARY KEY,
    order_id TEXT,
    cargo_id TEXT REFERENCES public.cargos(id) ON DELETE SET NULL,
    driver_name TEXT NOT NULL DEFAULT '',
    driver_contact TEXT DEFAULT '',
    driver_cpf TEXT DEFAULT '',
    embarcador_id TEXT,
    horse_plate TEXT DEFAULT '',
    trailer1_plate TEXT,
    trailer2_plate TEXT,
    trailer3_plate TEXT,
    shipment_tonnage NUMERIC(14, 3) NOT NULL DEFAULT 0,
    driver_freight_value NUMERIC(14, 2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'Pré-cadastro',
    scheduled_date TEXT,
    scheduled_time TEXT,
    arrival_time TIMESTAMPTZ,
    documents JSONB NOT NULL DEFAULT '{}'::jsonb,
    history JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by_id TEXT,
    status_history JSONB NOT NULL DEFAULT '[]'::jsonb,
    antt_owner_identifier TEXT,
    payment_method TEXT,
    pix_key TEXT,
    bank_details JSONB,
    advance_percentage NUMERIC(6, 2),
    advance_value NUMERIC(14, 2),
    toll_value NUMERIC(14, 2),
    vehicle_tag TEXT,
    company_freight_rate_snapshot NUMERIC(14, 2),
    driver_freight_rate_snapshot NUMERIC(14, 2),
    driver_freight_type TEXT DEFAULT 'PJ',
    route TEXT,
    cancellation_reason TEXT,
    driver_references JSONB DEFAULT '[]'::jsonb,
    owner_name TEXT,
    owner_contact TEXT,
    balance_to_receive_value NUMERIC(14, 2),
    discount_value NUMERIC(14, 2),
    is_breakage_waived BOOLEAN DEFAULT FALSE,
    net_balance_value NUMERIC(14, 2),
    unloaded_tonnage NUMERIC(14, 3),
    branch_id TEXT REFERENCES public.branches(id) ON DELETE SET NULL,
    vehicle_set_type TEXT,
    vehicle_body_type TEXT
);

-- 10. Chamados Internos (tickets)
CREATE TABLE IF NOT EXISTS public.tickets (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'Aberto',
    priority TEXT NOT NULL DEFAULT 'Média',
    created_by_id TEXT NOT NULL,
    assigned_to_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    history JSONB NOT NULL DEFAULT '[]'::jsonb
);

-- 11. Ofertas de Frete & Solicitações de Embarque (freight_offers)
CREATE TABLE IF NOT EXISTS public.freight_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id TEXT,
    origin TEXT NOT NULL DEFAULT '',
    origin_location TEXT,
    destination TEXT NOT NULL DEFAULT '',
    destination_location TEXT,
    total_tonnage NUMERIC(14, 3) NOT NULL DEFAULT 0,
    daily_schedule JSONB,
    freight_value_per_ton NUMERIC(14, 2) NOT NULL DEFAULT 0,
    product_id TEXT,
    status TEXT NOT NULL DEFAULT 'Pendente',
    counter_offer_value NUMERIC(14, 2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    history JSONB NOT NULL DEFAULT '[]'::jsonb
);

-- 12. Locks de Concorrência em Embarques (shipment_locks)
CREATE TABLE IF NOT EXISTS public.shipment_locks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_id TEXT NOT NULL UNIQUE,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '5 minutes')
);

-- 13. Permissões por Perfil e Configurações JSON Globais (profile_permissions)
CREATE TABLE IF NOT EXISTS public.profile_permissions (
    id INTEGER PRIMARY KEY DEFAULT 1,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.profile_permissions (id, permissions)
VALUES (1, '{}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 14. Identidade Visual do Sistema (app_settings)
CREATE TABLE IF NOT EXISTS public.app_settings (
    id INTEGER PRIMARY KEY DEFAULT 1,
    company_logo TEXT,
    theme_image TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.app_settings (id, company_logo, theme_image)
VALUES (1, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- 15. Modalidades de Consulta de Risco (risk_query_options)
CREATE TABLE IF NOT EXISTS public.risk_query_options (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    cost NUMERIC(12, 2) NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    order_index INTEGER NOT NULL DEFAULT 0,
    description TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 16. Histórico SIGA GR (siga_requests)
CREATE TABLE IF NOT EXISTS public.siga_requests (
    id TEXT PRIMARY KEY,
    process_number TEXT NOT NULL,
    state TEXT NOT NULL,
    product_name TEXT,
    shipment_id TEXT,
    driver_id TEXT,
    driver_name TEXT,
    driver_cpf TEXT,
    truck_plate TEXT,
    vehicle_type TEXT,
    origin TEXT,
    destination TEXT,
    load_cost NUMERIC(14, 2),
    denial_reason TEXT,
    issues_count INTEGER DEFAULT 0,
    unsolved_issues_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    concluded_at TIMESTAMPTZ,
    created_by_id TEXT,
    created_by_name TEXT,
    raw_analysis JSONB
);

-- 17. Ferramentas: Clientes de Estadia / Cotação (tool_clients)
CREATE TABLE IF NOT EXISTS public.tool_clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT tool_clients_user_id_name_key UNIQUE (user_id, name)
);

-- 18. Ferramentas: Cálculo de Estadias (tool_stays)
CREATE TABLE IF NOT EXISTS public.tool_stays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    client_name TEXT,
    driver TEXT NOT NULL DEFAULT '',
    plate TEXT NOT NULL DEFAULT '',
    invoice TEXT,
    origin TEXT NOT NULL DEFAULT '',
    destination TEXT NOT NULL DEFAULT '',
    location TEXT NOT NULL DEFAULT 'Origem',
    entry_date TEXT NOT NULL DEFAULT '',
    exit_date TEXT NOT NULL DEFAULT '',
    total_hours NUMERIC(12, 2) NOT NULL DEFAULT 0,
    weight NUMERIC(14, 3) NOT NULL DEFAULT 0,
    value_per_hour NUMERIC(14, 2) NOT NULL DEFAULT 0,
    tolerance NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total_value NUMERIC(14, 2) NOT NULL DEFAULT 0,
    approved_value NUMERIC(14, 2),
    driver_paid_value NUMERIC(14, 2),
    cte_url TEXT,
    cte_number TEXT,
    payment_proof_url TEXT,
    status TEXT DEFAULT 'TON_HOUR',
    shipment_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 19. Ferramentas: Cotação de Frete (tool_quotes)
CREATE TABLE IF NOT EXISTS public.tool_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    client_name TEXT,
    origin TEXT NOT NULL DEFAULT '',
    destination TEXT NOT NULL DEFAULT '',
    distance NUMERIC(12, 2) NOT NULL DEFAULT 0,
    axes INTEGER NOT NULL DEFAULT 6,
    cargo_type TEXT NOT NULL DEFAULT '',
    input_mode TEXT NOT NULL DEFAULT 'PER_KM',
    value_per_km NUMERIC(14, 4) NOT NULL DEFAULT 0,
    driver_total_value NUMERIC(14, 2) NOT NULL DEFAULT 0,
    toll_value NUMERIC(14, 2) NOT NULL DEFAULT 0,
    antt_value NUMERIC(14, 2) NOT NULL DEFAULT 0,
    weight NUMERIC(14, 3) NOT NULL DEFAULT 0,
    margin NUMERIC(10, 4) NOT NULL DEFAULT 0,
    driver_freight_per_ton NUMERIC(14, 2) NOT NULL DEFAULT 0,
    company_freight_per_ton NUMERIC(14, 2) NOT NULL DEFAULT 0,
    company_total_freight NUMERIC(14, 2) NOT NULL DEFAULT 0,
    carrier_net_profit NUMERIC(14, 2) NOT NULL DEFAULT 0,
    carrier_profit_margin NUMERIC(10, 4) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
-- ÍNDICES DE PERFORMANCE (FKs e Buscas Frequentes)
-- =====================================================================
CREATE INDEX IF NOT EXISTS idx_app_users_email ON public.app_users (email);
CREATE INDEX IF NOT EXISTS idx_app_users_client_id ON public.app_users (client_id);
CREATE INDEX IF NOT EXISTS idx_app_users_branch_id ON public.app_users (branch_id);
CREATE INDEX IF NOT EXISTS idx_drivers_cpf ON public.drivers (cpf);
CREATE INDEX IF NOT EXISTS idx_drivers_owner_id ON public.drivers (owner_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_plate ON public.vehicles (plate);
CREATE INDEX IF NOT EXISTS idx_vehicles_driver_id ON public.vehicles (driver_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_owner_id ON public.vehicles (owner_id);
CREATE INDEX IF NOT EXISTS idx_cargos_client_id ON public.cargos (client_id);
CREATE INDEX IF NOT EXISTS idx_cargos_product_id ON public.cargos (product_id);
CREATE INDEX IF NOT EXISTS idx_cargos_branch_id ON public.cargos (branch_id);
CREATE INDEX IF NOT EXISTS idx_cargos_status_created ON public.cargos (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cargos_sequence_id ON public.cargos (sequence_id DESC);
CREATE INDEX IF NOT EXISTS idx_shipments_cargo_id ON public.shipments (cargo_id);
CREATE INDEX IF NOT EXISTS idx_shipments_branch_id ON public.shipments (branch_id);
CREATE INDEX IF NOT EXISTS idx_shipments_status_created ON public.shipments (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_shipments_driver_cpf ON public.shipments (driver_cpf);
CREATE INDEX IF NOT EXISTS idx_tickets_status_created ON public.tickets (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_freight_offers_created ON public.freight_offers (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tool_stays_shipment_id ON public.tool_stays (shipment_id);
CREATE INDEX IF NOT EXISTS idx_tool_stays_user_id ON public.tool_stays (user_id);
CREATE INDEX IF NOT EXISTS idx_tool_quotes_user_id ON public.tool_quotes (user_id);

-- =====================================================================
-- RPC: acquire_shipment_lock (Controle de Concorrência em Embarques)
-- =====================================================================
CREATE OR REPLACE FUNCTION public.acquire_shipment_lock(
    p_shipment_id TEXT,
    p_user_id TEXT,
    p_user_name TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_existing RECORD;
BEGIN
    DELETE FROM public.shipment_locks
    WHERE expires_at < NOW();

    SELECT * INTO v_existing
    FROM public.shipment_locks
    WHERE shipment_id = p_shipment_id
    FOR UPDATE;

    IF FOUND AND v_existing.user_id <> p_user_id THEN
        RETURN jsonb_build_object(
            'success', false,
            'locked_by', v_existing.user_name
        );
    END IF;

    INSERT INTO public.shipment_locks (shipment_id, user_id, user_name, created_at, expires_at)
    VALUES (p_shipment_id, p_user_id, p_user_name, NOW(), NOW() + INTERVAL '5 minutes')
    ON CONFLICT (shipment_id) DO UPDATE
    SET user_id = EXCLUDED.user_id,
        user_name = EXCLUDED.user_name,
        expires_at = NOW() + INTERVAL '5 minutes';

    RETURN jsonb_build_object(
        'success', true,
        'locked_by', p_user_name
    );
END;
$$;

-- =====================================================================
-- ROW LEVEL SECURITY (RLS) E PERMISSÕES OPERACIONAIS
-- =====================================================================
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'branches',
        'clients',
        'owners',
        'drivers',
        'vehicles',
        'products',
        'app_users',
        'cargos',
        'shipments',
        'tickets',
        'freight_offers',
        'shipment_locks',
        'profile_permissions',
        'app_settings',
        'risk_query_options',
        'siga_requests',
        'tool_clients',
        'tool_stays',
        'tool_quotes'
    ]
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);
        EXECUTE format('DROP POLICY IF EXISTS "triade_operational_access_%s" ON public.%I;', t, t);
        EXECUTE format(
            'CREATE POLICY "triade_operational_access_%s" ON public.%I FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);',
            t, t
        );
        EXECUTE format('GRANT ALL ON TABLE public.%I TO anon, authenticated, service_role;', t);
    END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION public.acquire_shipment_lock(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;

-- =====================================================================
-- STORAGE BUCKET & POLÍTICAS (shipment_attachments)
-- =====================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('shipment_attachments', 'shipment_attachments', true)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
    DROP POLICY IF EXISTS "triade_storage_shipment_attachments_all" ON storage.objects;
    CREATE POLICY "triade_storage_shipment_attachments_all"
        ON storage.objects FOR ALL
        TO anon, authenticated, service_role
        USING (bucket_id = 'shipment_attachments')
        WITH CHECK (bucket_id = 'shipment_attachments');
END $$;

