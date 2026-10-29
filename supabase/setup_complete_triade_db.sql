-- =====================================================================
-- SETUP COMPLETO DO BANCO SUPABASE (fvcdsolvmmgvspzqiyfm) + USUÁRIO DEV
-- Cole e execute no SQL Editor: https://supabase.com/dashboard/project/fvcdsolvmmgvspzqiyfm/sql/new
-- =====================================================================


-- >>> MIGRATION: 20260901000000_bootstrap_core_schema.sql <<<
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


-- >>> MIGRATION: 20260919_whatsapp_integration.sql <<<
-- =====================================================================
-- MIGRAÇÃO TRANSCUNHA LOGÍSTICA - CANAL DE COMUNICAÇÃO WHATSAPP
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABELA: whatsapp_instances (Instâncias & Conexões)
CREATE TABLE IF NOT EXISTS public.whatsapp_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    instance_key VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(30),
    status VARCHAR(30) DEFAULT 'disconnected' 
        CHECK (status IN ('disconnected', 'connecting', 'qrcode', 'connected', 'banned')),
    qr_code_base64 TEXT,
    battery_level INTEGER DEFAULT 100,
    is_plugged BOOLEAN DEFAULT false,
    api_token VARCHAR(255) NOT NULL,
    webhook_url TEXT,
    last_connected_at TIMESTAMPTZ,
    last_disconnected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TABELA: whatsapp_templates (Modelos de Mensagens e Réguas)
CREATE TABLE IF NOT EXISTS public.whatsapp_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(120) NOT NULL,
    trigger_event VARCHAR(80) NOT NULL,
    description TEXT,
    body_text TEXT NOT NULL,
    available_tags JSONB DEFAULT '[]'::jsonb,
    attachment_type VARCHAR(40) DEFAULT 'none' 
        CHECK (attachment_type IN ('none', 'fixed_file', 'dynamic_cte', 'dynamic_contract', 'dynamic_voucher', 'custom_url')),
    fixed_attachment_url TEXT,
    default_filename VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABELA: whatsapp_messages_queue (Fila de Envios & Mensagens)
CREATE TABLE IF NOT EXISTS public.whatsapp_messages_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID REFERENCES public.whatsapp_instances(id) ON DELETE SET NULL,
    template_id UUID REFERENCES public.whatsapp_templates(id) ON DELETE SET NULL,
    shipment_id UUID,
    recipient_phone VARCHAR(30) NOT NULL,
    recipient_name VARCHAR(150),
    message_type VARCHAR(30) DEFAULT 'text' 
        CHECK (message_type IN ('text', 'image', 'document', 'audio', 'video')),
    rendered_body TEXT NOT NULL,
    media_url TEXT,
    media_filename VARCHAR(255),
    media_caption TEXT,
    status VARCHAR(30) DEFAULT 'pending' 
        CHECK (status IN ('pending', 'processing', 'sent', 'delivered', 'read', 'failed', 'cancelled')),
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    scheduled_for TIMESTAMPTZ DEFAULT NOW(),
    sent_at TIMESTAMPTZ,
    error_message TEXT,
    external_message_id VARCHAR(120),
    idempotency_key VARCHAR(150) UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABELA: whatsapp_message_logs (Auditoria de Eventos e ACKs)
CREATE TABLE IF NOT EXISTS public.whatsapp_message_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    queue_id UUID REFERENCES public.whatsapp_messages_queue(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    payload JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_wa_queue_status_sched ON public.whatsapp_messages_queue(status, scheduled_for);
CREATE INDEX IF NOT EXISTS idx_wa_queue_phone ON public.whatsapp_messages_queue(recipient_phone);
CREATE INDEX IF NOT EXISTS idx_wa_queue_shipment ON public.whatsapp_messages_queue(shipment_id);

-- RLS
ALTER TABLE public.whatsapp_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_messages_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_message_logs ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    DROP POLICY IF EXISTS "wa_instances_all" ON public.whatsapp_instances;
    DROP POLICY IF EXISTS "wa_instances_all" ON public.whatsapp_instances;
CREATE POLICY "wa_instances_all" ON public.whatsapp_instances FOR ALL TO authenticated USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "wa_templates_all" ON public.whatsapp_templates;
    DROP POLICY IF EXISTS "wa_templates_all" ON public.whatsapp_templates;
CREATE POLICY "wa_templates_all" ON public.whatsapp_templates FOR ALL TO authenticated USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "wa_queue_all" ON public.whatsapp_messages_queue;
    DROP POLICY IF EXISTS "wa_queue_all" ON public.whatsapp_messages_queue;
CREATE POLICY "wa_queue_all" ON public.whatsapp_messages_queue FOR ALL TO authenticated USING (true) WITH CHECK (true);
END $$;

-- SEEDS INICIAIS DE TEMPLATES PADRÕES DA TRANSCUNHA
INSERT INTO public.whatsapp_templates (name, trigger_event, description, body_text, available_tags, attachment_type, is_active)
VALUES
(
    'Aviso de Oferta / Nova Carga',
    'shipment.created',
    'Mensagem enviada a motoristas cadastrados quando uma nova oportunidade de frete na rota é aberta.',
    '🚛 *Transcunha Logística - Oportunidade de Carga*\n\nOlá, *{{motorista_nome}}*! Temos uma nova carga disponível para você:\n\n📍 *Origem:* {{origem}}\n🎯 *Destino:* {{destino}}\n📦 *Mercadoria:* {{mercadoria}}\n⚖️ *Peso:* {{peso}}\n💰 *Valor do Frete:* R$ {{valor_frete}}\n\nInteressado? Responda a esta mensagem ou acesse nosso app para confirmar!',
    '[{"tag": "{{motorista_nome}}", "label": "Nome do Motorista", "example": "Carlos Silva", "description": "Primeiro nome ou nome completo do motorista"}, {"tag": "{{origem}}", "label": "Origem", "example": "Santos - SP", "description": "Cidade e UF de coleta"}, {"tag": "{{destino}}", "label": "Destino", "example": "Curitiba - PR", "description": "Cidade e UF de entrega"}, {"tag": "{{mercadoria}}", "label": "Mercadoria", "example": "Soja a Granel", "description": "Tipo do produto transportado"}, {"tag": "{{peso}}", "label": "Peso / Volume", "example": "32.000 kg", "description": "Peso total da carga"}, {"tag": "{{valor_frete}}", "label": "Valor do Frete", "example": "6.800,00", "description": "Valor líquido do frete"}]'::jsonb,
    'none',
    true
),
(
    'Ordem de Carregamento & Documentos',
    'shipment.loading_order',
    'Disparo automático ao emitir a Ordem de Carregamento com o PDF anexo para o motorista.',
    '📋 *Ordem de Carregamento Transcunha*\n\nOlá, *{{motorista_nome}}*! Segue em anexo a sua Ordem de Carregamento referente ao embarque *#{{numero_carga}}*.\n\n📍 *Local de Coleta:* {{local_coleta}}\n📅 *Data Programada:* {{data_coleta}}\n📞 *Contato no Local:* {{contato_coleta}}\n\nPor favor, apresente este documento na portaria ao chegar.',
    '[{"tag": "{{motorista_nome}}", "label": "Nome do Motorista", "example": "Carlos Silva", "description": "Nome do motorista"}, {"tag": "{{numero_carga}}", "label": "Nº Carga / Embarque", "example": "TC-8492", "description": "Identificador da carga"}, {"tag": "{{local_coleta}}", "label": "Ponto de Coleta", "example": "Terminal Graneleiro Armazém 4", "description": "Endereço ou empresa de carregamento"}, {"tag": "{{data_coleta}}", "label": "Data da Coleta", "example": "20/09/2026", "description": "Data prevista"}, {"tag": "{{contato_coleta}}", "label": "Contato Coleta", "example": "(11) 98888-7777 - Sr. Marcos", "description": "Responsável na expedição"}]'::jsonb,
    'dynamic_contract',
    true
),
(
    'Comprovante de Adiantamento de Frete',
    'shipment.advance_paid',
    'Notificação com comprovante PIX/Transferência após a liberação do adiantamento.',
    '✅ *Adiantamento Pago com Sucesso!*\n\nOlá, *{{motorista_nome}}*! O adiantamento do seu frete referente ao embarque *#{{numero_carga}}* foi creditado em sua conta.\n\n💵 *Valor Pago:* R$ {{valor_adiantamento}}\n🏦 *Banco/Chave:* {{dados_bancarios}}\n📄 O comprovante bancário segue em anexo.\n\nBoa viagem e dirija com segurança!',
    '[{"tag": "{{motorista_nome}}", "label": "Nome do Motorista", "example": "Carlos Silva", "description": "Nome do motorista"}, {"tag": "{{numero_carga}}", "label": "Nº Embarque", "example": "TC-8492", "description": "Código do embarque"}, {"tag": "{{valor_adiantamento}}", "label": "Valor Adiantamento", "example": "3.500,00", "description": "Valor líquido adiantado"}, {"tag": "{{dados_bancarios}}", "label": "Dados Bancários", "example": "PIX (CPF 123.456.789-00)", "description": "Conta ou chave utilizada"}]'::jsonb,
    'dynamic_voucher',
    true
),
(
    'Emissão de CT-e e DACTE em PDF',
    'shipment.cte_emitted',
    'Envio do CT-e autorizado diretamente para o motorista e embarcador.',
    '📄 *CT-e Autorizado - Transcunha Logística*\n\nInformamos que o Conhecimento de Transporte Eletrônico (*CT-e nº {{numero_cte}}*) foi autorizado pela SEFAZ.\n\n🚛 *Placa:* {{placa_veiculo}}\n📦 *Carga:* {{numero_carga}}\n📄 O DACTE em formato PDF está anexado nesta mensagem para fiscalização rodoviária.',
    '[{"tag": "{{numero_cte}}", "label": "Nº do CT-e", "example": "10492", "description": "Número fiscal do CT-e"}, {"tag": "{{placa_veiculo}}", "label": "Placa do Veículo", "example": "BRA2E19", "description": "Placa do cavalo mecânico"}, {"tag": "{{numero_carga}}", "label": "Nº Embarque", "example": "TC-8492", "description": "Código da carga"}]'::jsonb,
    'dynamic_cte',
    true
),
(
    'Comprovante de Quitação do Saldo',
    'shipment.balance_paid',
    'Notificação de finalização do frete com envio do comprovante de quitação do saldo.',
    '🎉 *Frete Concluído - Saldo Quitado*\n\nOlá, *{{motorista_nome}}*! O saldo final do seu frete (*Embarque #{{numero_carga}}*) foi creditado com sucesso.\n\n💰 *Valor do Saldo:* R$ {{valor_saldo}}\n📄 O comprovante de transferência segue em anexo.\n\nA equipe Transcunha agradece pela parceria em mais uma viagem!',
    '[{"tag": "{{motorista_nome}}", "label": "Nome do Motorista", "example": "Carlos Silva", "description": "Nome do motorista"}, {"tag": "{{numero_carga}}", "label": "Nº Embarque", "example": "TC-8492", "description": "Código da carga"}, {"tag": "{{valor_saldo}}", "label": "Valor do Saldo", "example": "1.850,00", "description": "Valor líquido do saldo final"}]'::jsonb,
    'dynamic_voucher',
    true
)
ON CONFLICT DO NOTHING;


-- >>> MIGRATION: 20261006_financial_invoices.sql <<<
-- ====================================================================
-- MÓDULO FINANCEIRO: LANÇAMENTO E GESTÃO DE NOTAS FISCAIS
-- Migração para suporte a Notas Fiscais, Centros de Custo, Naturezas/Modalidades
-- e Vinculação de Responsáveis / Usuários Internos.
-- ====================================================================

-- 1. Tabela: Modalidades / Tipos de Custo
CREATE TABLE IF NOT EXISTS public.financial_cost_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    nature TEXT NOT NULL CHECK (nature IN ('servico', 'produto', 'bem', 'outros')),
    description TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Tabela: Centros de Custo
CREATE TABLE IF NOT EXISTS public.financial_cost_centers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT,
    name TEXT NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Tabela: Notas Fiscais e Despesas Financeiras
CREATE TABLE IF NOT EXISTS public.financial_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number TEXT NOT NULL,
    series TEXT,
    access_key TEXT,
    supplier_name TEXT NOT NULL,
    supplier_cnpj_cpf TEXT,
    total_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    payment_date DATE,
    status TEXT NOT NULL DEFAULT 'Pendente' CHECK (status IN ('Pendente', 'Pago', 'Atrasado', 'Cancelado')),
    payment_method TEXT,
    payment_details TEXT,
    cost_nature TEXT NOT NULL CHECK (cost_nature IN ('servico', 'produto', 'bem', 'outros')),
    cost_type_id UUID REFERENCES public.financial_cost_types(id) ON DELETE SET NULL,
    cost_type_name TEXT,
    cost_center_id UUID REFERENCES public.financial_cost_centers(id) ON DELETE SET NULL,
    cost_center_name TEXT,
    responsible_user_id TEXT NOT NULL,
    responsible_user_name TEXT NOT NULL,
    responsible_user_profile TEXT,
    description TEXT NOT NULL,
    notes TEXT,
    file_url TEXT,
    file_name TEXT,
    file_type TEXT,
    file_size BIGINT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Índices para otimização de consultas e relatórios
CREATE INDEX IF NOT EXISTS idx_financial_invoices_responsible_user ON public.financial_invoices(responsible_user_id);
CREATE INDEX IF NOT EXISTS idx_financial_invoices_cost_center ON public.financial_invoices(cost_center_id);
CREATE INDEX IF NOT EXISTS idx_financial_invoices_cost_type ON public.financial_invoices(cost_type_id);
CREATE INDEX IF NOT EXISTS idx_financial_invoices_dates ON public.financial_invoices(issue_date, due_date);
CREATE INDEX IF NOT EXISTS idx_financial_invoices_status ON public.financial_invoices(status);
CREATE INDEX IF NOT EXISTS idx_financial_invoices_number ON public.financial_invoices(invoice_number);

-- Políticas RLS
ALTER TABLE public.financial_cost_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_cost_centers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_invoices ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Permitir leitura para todos os usuários" ON public.financial_cost_types;
    DROP POLICY IF EXISTS "Permitir leitura para todos os usuários" ON public.financial_cost_types;
CREATE POLICY "Permitir leitura para todos os usuários" ON public.financial_cost_types FOR ALL USING (true);

    DROP POLICY IF EXISTS "Permitir leitura para todos os usuários" ON public.financial_cost_centers;
    DROP POLICY IF EXISTS "Permitir leitura para todos os usuários" ON public.financial_cost_centers;
CREATE POLICY "Permitir leitura para todos os usuários" ON public.financial_cost_centers FOR ALL USING (true);

    DROP POLICY IF EXISTS "Permitir leitura para todos os usuários" ON public.financial_invoices;
    DROP POLICY IF EXISTS "Permitir leitura para todos os usuários" ON public.financial_invoices;
CREATE POLICY "Permitir leitura para todos os usuários" ON public.financial_invoices FOR ALL USING (true);
END $$;

-- 4. Inserção de Centros de Custo Padrão
INSERT INTO public.financial_cost_centers (code, name, description, is_default)
VALUES 
    ('CC-001', 'Operacional', 'Custos diretos de transporte, pátio e logística', true),
    ('CC-002', 'Administrativo', 'Despesas administrativas e gerais da matriz', true),
    ('CC-003', 'Frota & Equipamentos', 'Manutenção preventiva/corretiva e suprimentos da frota', true),
    ('CC-004', 'Comercial & Vendas', 'Custos de agenciamento, prospecção e vendas', true),
    ('CC-005', 'TI & Sistemas', 'Sistemas TMS, licenças, servidores e infraestrutura', true),
    ('CC-006', 'Diretoria & Gestão', 'Custos estratégicos e gestão executiva', true)
ON CONFLICT DO NOTHING;

-- 5. Inserção de Modalidades / Tipos de Custo Padrão
INSERT INTO public.financial_cost_types (name, nature, description, is_default)
VALUES 
    ('Manutenção Mecânica e Peças', 'servico', 'Serviços mecânicos, elétricos e borracharia', true),
    ('Serviços de Tecnologia / TMS', 'servico', 'Assinaturas de software, ERP e rastreamento', true),
    ('Honorários Jurídicos e Contábeis', 'servico', 'Consultoria fiscal, contábil e advocatícia', true),
    ('Pedágio e Tags Eletrônicas', 'servico', 'Recargas e faturamento Sem Parar/Veloe', true),
    ('Seguros e Rastreamento / GR', 'servico', 'Gerenciamento de risco e apólices de transporte', true),
    ('Combustíveis e Lubrificantes', 'produto', 'Abastecimento de diesel, arla e óleos', true),
    ('Pneus e Câmaras de Ar', 'produto', 'Aquisição de pneumáticos e recapagens', true),
    ('Materiais de Escritório e Limpeza', 'produto', 'Insumos do dia a dia administrativo', true),
    ('Veículos e Implementos', 'bem', 'Aquisição e amortização de caminhões e carretas', true),
    ('Equipamentos de Informática', 'bem', 'Computadores, monitores, servidores e roteadores', true),
    ('Móveis e Utensílios', 'bem', 'Mobiliário de escritório e estações de trabalho', true),
    ('Tarifas e Despesas Bancárias', 'outros', 'Taxas de boletos, transferências e custódia', true)
ON CONFLICT DO NOTHING;


-- >>> MIGRATION: 20261012_locations_expedidor_recebedor.sql <<<
-- Migration: 20261012_locations_expedidor_recebedor.sql
-- Descrição: Criação da tabela de locais (Expedidor/Recebedor) com CNPJ/CPF, Telefone, WhatsApp e Classificação

CREATE TABLE IF NOT EXISTS public.locations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    document_type TEXT CHECK (document_type IN ('CNPJ', 'CPF')),
    document_number TEXT,
    phone TEXT,
    is_whatsapp BOOLEAN DEFAULT FALSE,
    classification TEXT NOT NULL DEFAULT 'Ambos' CHECK (classification = 'Ambos'),
    city TEXT,
    state TEXT,
    map_link TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para busca ágil
CREATE INDEX IF NOT EXISTS idx_locations_name ON public.locations (name);
CREATE INDEX IF NOT EXISTS idx_locations_document ON public.locations (document_number);
CREATE INDEX IF NOT EXISTS idx_locations_city ON public.locations (city);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso para usuários autenticados e anônimos (sistema operacional interno)
DROP POLICY IF EXISTS "Permitir leitura de locais" ON public.locations;
CREATE POLICY "Permitir leitura de locais" ON public.locations FOR SELECT 
    USING (true);

DROP POLICY IF EXISTS "Permitir inserção de locais" ON public.locations;
CREATE POLICY "Permitir inserção de locais" ON public.locations FOR INSERT 
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização de locais" ON public.locations;
CREATE POLICY "Permitir atualização de locais" ON public.locations FOR UPDATE 
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir exclusão de locais" ON public.locations;
CREATE POLICY "Permitir exclusão de locais" ON public.locations FOR DELETE 
    USING (true);


-- >>> MIGRATION: 20261012_add_boleto_attachment_to_invoices.sql <<<
-- ====================================================================
-- MÓDULO FINANCEIRO: ANEXO DE BOLETO BANCÁRIO PARA PAGAMENTO
-- Adiciona suporte ao armazenamento de comprovante/arquivo de boleto
-- vinculado aos lançamentos de Notas Fiscais e Despesas.
-- ====================================================================

ALTER TABLE public.financial_invoices
ADD COLUMN IF NOT EXISTS boleto_file_url TEXT,
ADD COLUMN IF NOT EXISTS boleto_file_name TEXT,
ADD COLUMN IF NOT EXISTS boleto_file_type TEXT,
ADD COLUMN IF NOT EXISTS boleto_file_size BIGINT;


-- >>> MIGRATION: 20261021_rdo_nacional.sql <<<
-- Migration: 20261021_rdo_nacional.sql
-- Descrição: Tabela para controle e histórico das solicitações e pareceres de análise cadastral do RDO Nacional (MRB Soluções)

CREATE TABLE IF NOT EXISTS public.rdo_requests (
    id UUID PRIMARY KEY,
    codigo INTEGER,
    shipment_id TEXT,
    driver_id TEXT,
    cpf TEXT NOT NULL,
    nome TEXT NOT NULL,
    nome_da_mae TEXT,
    data_nascimento DATE,
    documento_proprietario TEXT,
    nome_proprietario TEXT,
    placa_cavalo TEXT,
    status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovado', 'consta_informacao', 'erro')),
    parecer INTEGER CHECK (parecer IN (0, 1)),
    observacao TEXT,
    cnh_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    concluded_at TIMESTAMPTZ,
    created_by TEXT,
    created_by_name TEXT,
    raw_response JSONB,
    raw_webhook_payload JSONB
);

-- Índices para busca ágil
CREATE INDEX IF NOT EXISTS idx_rdo_requests_cpf ON public.rdo_requests (cpf);
CREATE INDEX IF NOT EXISTS idx_rdo_requests_shipment_id ON public.rdo_requests (shipment_id);
CREATE INDEX IF NOT EXISTS idx_rdo_requests_driver_id ON public.rdo_requests (driver_id);
CREATE INDEX IF NOT EXISTS idx_rdo_requests_status ON public.rdo_requests (status);
CREATE INDEX IF NOT EXISTS idx_rdo_requests_created_at ON public.rdo_requests (created_at DESC);

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.rdo_requests ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
DROP POLICY IF EXISTS "Permitir leitura de rdo_requests" ON public.rdo_requests;
CREATE POLICY "Permitir leitura de rdo_requests" ON public.rdo_requests FOR SELECT 
    USING (true);

DROP POLICY IF EXISTS "Permitir inserção de rdo_requests" ON public.rdo_requests;
CREATE POLICY "Permitir inserção de rdo_requests" ON public.rdo_requests FOR INSERT 
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização de rdo_requests" ON public.rdo_requests;
CREATE POLICY "Permitir atualização de rdo_requests" ON public.rdo_requests FOR UPDATE 
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir exclusão de rdo_requests" ON public.rdo_requests;
CREATE POLICY "Permitir exclusão de rdo_requests" ON public.rdo_requests FOR DELETE 
    USING (true);


-- =====================================================================
-- SEED DO USUÁRIO DESENVOLVEDOR (DEV) E ADMIN EM public.app_users
-- =====================================================================
INSERT INTO public.app_users (
    id,
    name,
    email,
    profile,
    active,
    password,
    require_password_change,
    auth_id,
    password_updated_at,
    permissions
)
VALUES (
    'USR-001',
    'DEV',
    '05561786539',
    'Desenvolvedor',
    TRUE,
    'ANITA2020',
    FALSE,
    '7cc2c149-4b9a-4139-a731-49422f86975b',
    NOW(),
    '{"availableForDriverRequests": true}'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    profile = EXCLUDED.profile,
    active = EXCLUDED.active,
    password = EXCLUDED.password,
    require_password_change = EXCLUDED.require_password_change,
    auth_id = EXCLUDED.auth_id,
    password_updated_at = NOW();

INSERT INTO public.app_users (
    id,
    name,
    email,
    profile,
    active,
    password,
    require_password_change,
    password_updated_at,
    permissions
)
VALUES (
    'USR-100',
    'Chales',
    'admin@triade.com',
    'Comercial',
    TRUE,
    'ANITA2020',
    FALSE,
    NOW(),
    '{"availableForDriverRequests": true}'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    profile = EXCLUDED.profile,
    active = EXCLUDED.active,
    password = EXCLUDED.password,
    require_password_change = EXCLUDED.require_password_change,
    password_updated_at = NOW();

NOTIFY pgrst, 'reload schema';
