/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Create Tables (All Layers)
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Create tables for 3-layer architecture: Raw, Staging, Analytics
 * 
 * OBJECTS CREATED (RAW LAYER):
 *   - RAW_SUBSCRIBER_EVENTS (subscription lifecycle events)
 *   - RAW_CONTENT_ENGAGEMENT (article views and reading behavior)
 *   - RAW_SUPPORT_INTERACTIONS (customer service tickets)
 * 
 * OBJECTS CREATED (STAGING LAYER):
 *   - STG_SUBSCRIBER_EVENTS (cleaned subscription events)
 *   - STG_UNIFIED_CUSTOMER (deduplicated subscriber master)
 *   - STG_CONTENT_ENGAGEMENT (parsed engagement metrics)
 * 
 * OBJECTS CREATED (ANALYTICS LAYER):
 *   - DIM_SUBSCRIBERS (subscriber dimension with demographics)
 *   - FCT_ENGAGEMENT_DAILY (daily engagement metrics per subscriber)
 *   - FCT_CHURN_TRAINING (ML training dataset with features + labels)
 *   - FCT_CUSTOMER_HEALTH_SCORES (churn risk predictions from ML model)
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;

-- =============================================================================
-- RAW LAYER: Landing zone for unmodified source data
-- =============================================================================

USE SCHEMA SFE_RAW_MEDIA;

-- Raw subscription events (signups, upgrades, cancellations)
CREATE OR REPLACE TABLE RAW_SUBSCRIBER_EVENTS (
    subscriber_id VARCHAR(36),
    event_type VARCHAR(50),
    event_timestamp TIMESTAMP_NTZ,
    subscription_tier VARCHAR(20),
    payment_amount NUMBER(10,2),
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: newsworthy - Raw subscription lifecycle events from source systems';

-- Raw content engagement (article views, time spent)
CREATE OR REPLACE TABLE RAW_CONTENT_ENGAGEMENT (
    engagement_id VARCHAR(36),
    subscriber_id VARCHAR(36),
    article_id VARCHAR(50),
    view_timestamp TIMESTAMP_NTZ,
    time_spent_seconds NUMBER(10,0),
    section VARCHAR(50),
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: newsworthy - Raw content engagement events from web analytics';

-- Raw support interactions (customer service tickets)
CREATE OR REPLACE TABLE RAW_SUPPORT_INTERACTIONS (
    interaction_id VARCHAR(36),
    subscriber_id VARCHAR(36),
    ticket_type VARCHAR(50),
    interaction_timestamp TIMESTAMP_NTZ,
    resolution_status VARCHAR(20),
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: newsworthy - Raw customer service ticket data';

-- =============================================================================
-- STAGING LAYER: Cleaned and validated data
-- =============================================================================

USE SCHEMA SFE_STG_MEDIA;

-- Cleaned subscription events
CREATE OR REPLACE TABLE STG_SUBSCRIBER_EVENTS (
    subscriber_id VARCHAR(36),
    event_type VARCHAR(50),
    cleaned_timestamp TIMESTAMP_NTZ,
    subscription_tier VARCHAR(20),
    payment_amount NUMBER(10,2),
    is_valid BOOLEAN,
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: newsworthy - Cleaned subscription events with validation flags';

-- Deduplicated subscriber master (single source of truth)
CREATE OR REPLACE TABLE STG_UNIFIED_CUSTOMER (
    subscriber_id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    signup_date DATE,
    current_tier VARCHAR(20),
    is_active BOOLEAN,
    last_updated TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: newsworthy - Unified customer master with current state';

-- Parsed content engagement
CREATE OR REPLACE TABLE STG_CONTENT_ENGAGEMENT (
    engagement_id VARCHAR(36),
    subscriber_id VARCHAR(36),
    article_id VARCHAR(50),
    engagement_date DATE,
    time_spent_seconds NUMBER(10,0),
    section VARCHAR(50),
    processed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: newsworthy - Parsed content engagement with clean dates';

-- =============================================================================
-- ANALYTICS LAYER: Dimensional model and ML predictions
-- =============================================================================

USE SCHEMA SFE_ANALYTICS_MEDIA;

-- Subscriber dimension with enriched fields
CREATE OR REPLACE TABLE DIM_SUBSCRIBERS (
    subscriber_id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255),
    demographic_segment VARCHAR(50),
    signup_date DATE,
    tenure_days NUMBER(10,0),
    lifetime_value NUMBER(10,2),
    effective_from TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: newsworthy - Subscriber dimension with calculated fields';

-- Daily engagement facts
CREATE OR REPLACE TABLE FCT_ENGAGEMENT_DAILY (
    engagement_date DATE,
    subscriber_id VARCHAR(36),
    articles_viewed NUMBER(10,0),
    total_time_spent NUMBER(10,0),
    distinct_sections NUMBER(10,0),
    PRIMARY KEY (engagement_date, subscriber_id)
)
COMMENT = 'DEMO: newsworthy - Daily aggregated engagement metrics per subscriber';

-- ML training dataset with features and labels
CREATE OR REPLACE TABLE FCT_CHURN_TRAINING (
    subscriber_id VARCHAR(36) PRIMARY KEY,
    engagement_score NUMBER(5,2),
    support_tickets_count NUMBER(10,0),
    days_since_last_read NUMBER(10,0),
    subscription_tenure_days NUMBER(10,0),
    churned BOOLEAN,
    training_date DATE DEFAULT CURRENT_DATE()
)
COMMENT = 'DEMO: newsworthy - Feature-engineered training data for churn prediction';

-- Churn risk predictions from ML model
CREATE OR REPLACE TABLE FCT_CUSTOMER_HEALTH_SCORES (
    subscriber_id VARCHAR(36),
    score_date DATE,
    churn_risk_score NUMBER(5,4),
    risk_tier VARCHAR(10),
    model_version VARCHAR(20),
    prediction_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (subscriber_id, score_date)
)
COMMENT = 'DEMO: newsworthy - Daily churn risk predictions from Cortex ML Classification';

-- Verify all tables created
SELECT
    'RAW_LAYER' AS layer,
    COUNT(*) AS table_count
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SFE_RAW_MEDIA'
UNION ALL
SELECT
    'STAGING_LAYER' AS layer,
    COUNT(*) AS table_count
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SFE_STG_MEDIA'
UNION ALL
SELECT
    'ANALYTICS_LAYER' AS layer,
    COUNT(*) AS table_count
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SFE_ANALYTICS_MEDIA';

