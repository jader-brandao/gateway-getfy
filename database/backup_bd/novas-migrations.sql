--
-- Name: Novas migrations
--

ALTER TABLE public.checkout_sessions
ADD COLUMN IF NOT EXISTS utm_content TEXT;

ALTER TABLE public.checkout_sessions
ADD COLUMN IF NOT EXISTS utm_term TEXT;

ALTER TABLE public.checkout_sessions
ADD COLUMN IF NOT EXISTS sck TEXT;

ALTER TABLE public.checkout_sessions
ADD COLUMN IF NOT EXISTS src TEXT;

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS admin_blocked BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.api_applications
ADD COLUMN IF NOT EXISTS public_key VARCHAR(80);

ALTER TABLE public.api_applications
ADD COLUMN IF NOT EXISTS secret_key_hash VARCHAR(255);

ALTER TABLE public.api_applications
ADD COLUMN IF NOT EXISTS secret_encrypted TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS api_applications_public_key_unique
ON public.api_applications (public_key);

CREATE TABLE IF NOT EXISTS public.shipping_stores (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    origin_zip VARCHAR(9),
    origin_street VARCHAR(255),
    origin_number VARCHAR(32),
    origin_complement VARCHAR(255),
    origin_neighborhood VARCHAR(255),
    origin_city VARCHAR(255),
    origin_state VARCHAR(2),
    created_at TIMESTAMP(0),
    updated_at TIMESTAMP(0)
);

CREATE INDEX IF NOT EXISTS shipping_stores_tenant_id_idx
ON public.shipping_stores (tenant_id);

CREATE TABLE IF NOT EXISTS public.shipping_rules (
    id BIGSERIAL PRIMARY KEY,
    shipping_store_id BIGINT NOT NULL,
    priority SMALLINT NOT NULL DEFAULT 100,
    name VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    match_type VARCHAR(32) NOT NULL,
    match_config JSONB,
    price NUMERIC(10,2) NOT NULL DEFAULT 0,
    is_free BOOLEAN NOT NULL DEFAULT FALSE,
    delivery_days_min SMALLINT,
    delivery_days_max SMALLINT,
    created_at TIMESTAMP(0),
    updated_at TIMESTAMP(0),

    CONSTRAINT fk_shipping_rules_store
        FOREIGN KEY (shipping_store_id)
        REFERENCES public.shipping_stores(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS shipping_rules_store_priority_idx
ON public.shipping_rules (shipping_store_id, priority);

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS shipping_store_id BIGINT;

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS physical_config JSONB;

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS shipping_amount NUMERIC(10,2) NOT NULL DEFAULT 0;

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS shipping_store_id BIGINT;

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS shipping_rule_id BIGINT;

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS shipping_address JSONB;

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS api_application_id BIGINT;

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS api_checkout_session_id BIGINT;

CREATE INDEX IF NOT EXISTS orders_api_checkout_session_id_idx
ON public.orders(api_checkout_session_id);

ALTER TABLE public.checkout_sessions
ADD COLUMN IF NOT EXISTS cpf VARCHAR(14);

ALTER TABLE public.checkout_sessions
ADD COLUMN IF NOT EXISTS phone VARCHAR(24);

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL;

ALTER TABLE public.orders
ALTER COLUMN product_id DROP NOT NULL;

ALTER TABLE public.orders
DROP CONSTRAINT IF EXISTS orders_product_id_foreign;

ALTER TABLE public.panel_push_subscriptions
ADD COLUMN IF NOT EXISTS provider VARCHAR(16) NOT NULL DEFAULT 'vapid';

ALTER TABLE public.panel_push_subscriptions
ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(512);

ALTER TABLE public.panel_push_subscriptions
ADD COLUMN IF NOT EXISTS device_label VARCHAR(120);

ALTER TABLE public.panel_push_subscriptions
ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP NULL;

CREATE INDEX IF NOT EXISTS panel_push_subscriptions_provider_idx
ON public.panel_push_subscriptions(provider);

CREATE INDEX IF NOT EXISTS panel_push_subscriptions_fcm_token_idx
ON public.panel_push_subscriptions(fcm_token);

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS privacy_policy_accepted_at TIMESTAMP NULL;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMP NULL;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS legal_consent_version VARCHAR(64);

CREATE TABLE IF NOT EXISTS public.med_disputes (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    cajupay_dispute_id VARCHAR(64) NOT NULL,
    cajupay_payment_id VARCHAR(64),
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    outcome VARCHAR(32),
    amount_cents BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(8) NOT NULL DEFAULT 'BRL',
    txid VARCHAR(128),
    defense_text TEXT,
    defended_at TIMESTAMP NULL,
    opened_at TIMESTAMP NULL,
    resolved_at TIMESTAMP NULL,
    metadata JSONB,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    CONSTRAINT med_disputes_order_id_foreign
        FOREIGN KEY (order_id)
        REFERENCES public.orders(id)
        ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS med_disputes_cajupay_dispute_id_unique
ON public.med_disputes(cajupay_dispute_id);

CREATE INDEX IF NOT EXISTS med_disputes_tenant_id_idx
ON public.med_disputes(tenant_id);

CREATE INDEX IF NOT EXISTS med_disputes_cajupay_payment_id_idx
ON public.med_disputes(cajupay_payment_id);

CREATE INDEX IF NOT EXISTS med_disputes_status_idx
ON public.med_disputes(status);

CREATE INDEX IF NOT EXISTS med_disputes_tenant_status_idx
ON public.med_disputes(tenant_id, status);

ALTER TABLE public.wallet_transactions
ADD COLUMN IF NOT EXISTS credit_reference VARCHAR(120);

ALTER TABLE public.checkout_sessions
ADD COLUMN IF NOT EXISTS form_started_at TIMESTAMP NULL;

ALTER TABLE public.checkout_sessions
ADD COLUMN IF NOT EXISTS form_filled_at TIMESTAMP NULL;

UPDATE public.checkout_sessions
SET form_started_at = updated_at
WHERE step IN ('form_started', 'form_filled')
  AND form_started_at IS NULL;

UPDATE public.checkout_sessions
SET form_filled_at = updated_at
WHERE step = 'form_filled'
  AND form_filled_at IS NULL;