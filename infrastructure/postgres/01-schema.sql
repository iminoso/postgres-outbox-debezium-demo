CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE worker_jobs (
    -- The job producer generates the UUID before opening its transaction.
    id UUID PRIMARY KEY,
    job_type VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'queued'
        CHECK (status IN ('queued', 'running', 'succeeded', 'failed')),
    payload JSONB NOT NULL,
    worker_id VARCHAR(100),
    attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE outbox_events (
    -- Unique, application-generated event ID used for consumer deduplication.
    id UUID PRIMARY KEY,
    -- Domain entity kind; Debezium uses it to route the Kafka topic.
    aggregate_type VARCHAR(100) NOT NULL,
    -- Domain entity ID; Debezium uses it as the Kafka record key.
    aggregate_id UUID NOT NULL,
    -- Business event name, for example WorkerJobAccepted.
    type VARCHAR(100) NOT NULL,
    -- Versioned event data consumed by downstream services.
    payload JSONB NOT NULL,
    -- Time the service recorded the event in its transactional outbox.
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- The connector reads this publication through PostgreSQL logical replication.
CREATE PUBLICATION worker_outbox_publication FOR TABLE outbox_events;

CREATE ROLE cdc_reader WITH LOGIN REPLICATION PASSWORD 'cdc_reader_password';
GRANT CONNECT ON DATABASE worker_service TO cdc_reader;
GRANT USAGE ON SCHEMA public TO cdc_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cdc_reader;
