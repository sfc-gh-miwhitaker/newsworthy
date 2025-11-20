/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Load Sample Data
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Generate synthetic subscriber data for demo using GENERATOR function
 * 
 * DATA GENERATED:
 *   - 25,000 subscribers (RAW_SUBSCRIBER_EVENTS → STG_UNIFIED_CUSTOMER)
 *   - 50,000 subscription events (last 90 days)
 *   - 500,000 content engagement records (last 30 days)
 *   - 12,000 support interactions (last year)
 * 
 * NATIVE FEATURES LEVERAGED:
 *   - GENERATOR: Table function for row generation
 *   - UUID_STRING: Unique identifiers (both random and named)
 *   - UNIFORM: Evenly-distributed random values
 *   - NORMAL: Bell-curve distribution for realistic engagement patterns
 *   - ZIPF: Power-law distribution for article popularity (80/20 rule)
 *   - SEQ4: Deterministic sequences for cyclic patterns
 *   - RANDOM: Seed for reproducible randomness
 * 
 * RUNTIME: ~3-5 minutes on XSMALL warehouse
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;

-- =============================================================================
-- LOAD RAW SUBSCRIBER EVENTS (50K rows, 90 days)
-- =============================================================================

USE SCHEMA SFE_RAW_MEDIA;

INSERT INTO RAW_SUBSCRIBER_EVENTS (subscriber_id, event_type, event_timestamp, subscription_tier, payment_amount)
SELECT
    UUID_STRING() AS subscriber_id,
    CASE MOD(SEQ4(), 5)
        WHEN 0 THEN 'signup'
        WHEN 1 THEN 'upgrade'
        WHEN 2 THEN 'downgrade'
        WHEN 3 THEN 'renewal'
        WHEN 4 THEN 'cancel'
    END AS event_type,
    DATEADD('day', -UNIFORM(0, 90, RANDOM()), CURRENT_TIMESTAMP()) AS event_timestamp,
    CASE MOD(SEQ4(), 3)
        WHEN 0 THEN 'Basic'
        WHEN 1 THEN 'Premium'
        WHEN 2 THEN 'Enterprise'
    END AS subscription_tier,
    -- NORMAL distribution: Most subscribers pay around $19.99 (mean), with stddev of $10
    -- Clamped to realistic range: $9.99 - $49.99
    -- More realistic than uniform: clusters around common price points
    ROUND(GREATEST(9.99, LEAST(49.99, NORMAL(19.99, 10.0, RANDOM()))), 2) AS payment_amount
FROM TABLE(GENERATOR(ROWCOUNT => 50000));

-- =============================================================================
-- LOAD RAW CONTENT ENGAGEMENT (500K rows, 30 days)
-- =============================================================================

INSERT INTO RAW_CONTENT_ENGAGEMENT (engagement_id, subscriber_id, article_id, view_timestamp, time_spent_seconds, section)
SELECT
    UUID_STRING() AS engagement_id,
    UUID_STRING() AS subscriber_id,
    -- ZIPF distribution: Popular articles get most views (80/20 rule)
    -- Parameters: s=1.0 (moderate skew), N=1000 articles
    'ARTICLE_' || LPAD(ZIPF(1.0, 1000, RANDOM())::VARCHAR, 6, '0') AS article_id,
    DATEADD('day', -UNIFORM(0, 30, RANDOM()), CURRENT_TIMESTAMP()) AS view_timestamp,
    -- NORMAL distribution: Most readers spend 2-5 minutes (mean=180s, stddev=120s)
    -- More realistic than uniform distribution (avoids unrealistic extremes)
    GREATEST(10, LEAST(600, ROUND(NORMAL(180, 120, RANDOM()), 0))) AS time_spent_seconds,
    CASE MOD(SEQ4(), 5)
        WHEN 0 THEN 'News'
        WHEN 1 THEN 'Opinion'
        WHEN 2 THEN 'Sports'
        WHEN 3 THEN 'Business'
        WHEN 4 THEN 'Lifestyle'
    END AS section
FROM TABLE(GENERATOR(ROWCOUNT => 500000));

-- =============================================================================
-- LOAD RAW SUPPORT INTERACTIONS (12K rows, 1 year)
-- =============================================================================

INSERT INTO RAW_SUPPORT_INTERACTIONS (interaction_id, subscriber_id, ticket_type, interaction_timestamp, resolution_status)
SELECT
    UUID_STRING() AS interaction_id,
    UUID_STRING() AS subscriber_id,
    CASE MOD(SEQ4(), 4)
        WHEN 0 THEN 'billing'
        WHEN 1 THEN 'technical'
        WHEN 2 THEN 'account'
        WHEN 3 THEN 'content'
    END AS ticket_type,
    DATEADD('day', -UNIFORM(0, 365, RANDOM()), CURRENT_TIMESTAMP()) AS interaction_timestamp,
    CASE MOD(SEQ4(), 2)
        WHEN 0 THEN 'resolved'
        WHEN 1 THEN 'pending'
    END AS resolution_status
FROM TABLE(GENERATOR(ROWCOUNT => 12000));

-- =============================================================================
-- POPULATE STAGING LAYER (Initial Load)
-- =============================================================================

USE SCHEMA SFE_STG_MEDIA;

-- Load cleaned subscription events
INSERT INTO STG_SUBSCRIBER_EVENTS (subscriber_id, event_type, cleaned_timestamp, subscription_tier, payment_amount, is_valid)
SELECT
    subscriber_id,
    event_type,
    event_timestamp AS cleaned_timestamp,
    subscription_tier,
    payment_amount,
    TRUE AS is_valid
FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_SUBSCRIBER_EVENTS
WHERE event_timestamp IS NOT NULL AND payment_amount > 0;

-- Create unified customer master (deduplicated)
INSERT INTO STG_UNIFIED_CUSTOMER (subscriber_id, email, first_name, last_name, signup_date, current_tier, is_active)
SELECT DISTINCT
    subscriber_id,
    'subscriber_' || SUBSTR(subscriber_id, 1, 8) || '@example.com' AS email,
    'Jane' AS first_name,
    'Smith' AS last_name,
    DATE_TRUNC('day', cleaned_timestamp) AS signup_date,
    subscription_tier AS current_tier,
    event_type != 'cancel' AS is_active
FROM STG_SUBSCRIBER_EVENTS
QUALIFY ROW_NUMBER() OVER (PARTITION BY subscriber_id ORDER BY cleaned_timestamp DESC) = 1;

-- Load parsed content engagement
INSERT INTO STG_CONTENT_ENGAGEMENT (engagement_id, subscriber_id, article_id, engagement_date, time_spent_seconds, section)
SELECT
    engagement_id,
    subscriber_id,
    article_id,
    DATE_TRUNC('day', view_timestamp) AS engagement_date,
    time_spent_seconds,
    section
FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_CONTENT_ENGAGEMENT;

-- =============================================================================
-- POPULATE ANALYTICS LAYER (Initial Load)
-- =============================================================================

USE SCHEMA SFE_ANALYTICS_MEDIA;

-- Populate subscriber dimension
INSERT INTO DIM_SUBSCRIBERS (subscriber_id, email, demographic_segment, signup_date, tenure_days, lifetime_value)
SELECT
    subscriber_id,
    email,
    CASE
        WHEN DATEDIFF('day', signup_date, CURRENT_DATE()) < 30 THEN 'New'
        WHEN DATEDIFF('day', signup_date, CURRENT_DATE()) < 180 THEN 'Growing'
        ELSE 'Loyal'
    END AS demographic_segment,
    signup_date,
    DATEDIFF('day', signup_date, CURRENT_DATE()) AS tenure_days,
    0.00 AS lifetime_value  -- Will be calculated later
FROM SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_UNIFIED_CUSTOMER;

-- Populate daily engagement facts
INSERT INTO FCT_ENGAGEMENT_DAILY
SELECT
    engagement_date,
    subscriber_id,
    COUNT(DISTINCT engagement_id) AS articles_viewed,
    SUM(time_spent_seconds) AS total_time_spent,
    COUNT(DISTINCT section) AS distinct_sections
FROM SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_CONTENT_ENGAGEMENT
GROUP BY engagement_date, subscriber_id;

-- Populate training dataset with features and churn labels
INSERT INTO FCT_CHURN_TRAINING (subscriber_id, engagement_score, support_tickets_count, days_since_last_read, subscription_tenure_days, churned)
SELECT
    d.subscriber_id,
    COALESCE(AVG(f.total_time_spent) / 60.0, 0) AS engagement_score,
    COALESCE(sup.ticket_count, 0) AS support_tickets_count,
    COALESCE(DATEDIFF('day', MAX(f.engagement_date), CURRENT_DATE()), 999) AS days_since_last_read,
    d.tenure_days AS subscription_tenure_days,
    CASE WHEN d.tenure_days > 30 AND COALESCE(MAX(f.engagement_date), CURRENT_DATE()) < DATEADD('day', -30, CURRENT_DATE()) THEN TRUE ELSE FALSE END AS churned
FROM DIM_SUBSCRIBERS d
LEFT JOIN FCT_ENGAGEMENT_DAILY f ON d.subscriber_id = f.subscriber_id
LEFT JOIN (
    SELECT subscriber_id, COUNT(*) AS ticket_count
    FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_SUPPORT_INTERACTIONS
    GROUP BY subscriber_id
) sup ON d.subscriber_id = sup.subscriber_id
GROUP BY d.subscriber_id, d.tenure_days, sup.ticket_count;

-- Display row counts
SELECT 'RAW_SUBSCRIBER_EVENTS' AS table_name, COUNT(*) AS row_count FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_SUBSCRIBER_EVENTS
UNION ALL
SELECT 'RAW_CONTENT_ENGAGEMENT', COUNT(*) FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_CONTENT_ENGAGEMENT
UNION ALL
SELECT 'RAW_SUPPORT_INTERACTIONS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_SUPPORT_INTERACTIONS
UNION ALL
SELECT 'STG_UNIFIED_CUSTOMER', COUNT(*) FROM SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_UNIFIED_CUSTOMER
UNION ALL
SELECT 'DIM_SUBSCRIBERS', COUNT(*) FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.DIM_SUBSCRIBERS
UNION ALL
SELECT 'FCT_ENGAGEMENT_DAILY', COUNT(*) FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.FCT_ENGAGEMENT_DAILY
UNION ALL
SELECT 'FCT_CHURN_TRAINING', COUNT(*) FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.FCT_CHURN_TRAINING;

