/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Train Churn Prediction Model
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Train Cortex ML Classification model for subscriber churn prediction
 * 
 * OBJECTS CREATED:
 *   - SFE_CHURN_CLASSIFIER (Cortex ML Classification model)
 * 
 * REQUIREMENTS:
 *   - Snowflake Enterprise Edition or higher
 *   - FCT_CHURN_TRAINING table must be populated
 * 
 * RUNTIME: ~2-3 minutes
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;
USE SCHEMA SFE_ANALYTICS_MEDIA;

-- Verify training data exists
SELECT
    'Training data summary' AS info,
    COUNT(*) AS total_records,
    SUM(CASE WHEN churned THEN 1 ELSE 0 END) AS churned_count,
    SUM(CASE WHEN NOT churned THEN 1 ELSE 0 END) AS active_count,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM FCT_CHURN_TRAINING;

-- Train Cortex ML Classification model for churn prediction
-- Source: Snowflake Cortex ML Functions documentation
-- Verified: 2025-11-20 (GA as of November 12, 2024)
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION SFE_CHURN_CLASSIFIER(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'FCT_CHURN_TRAINING'),
    TARGET_COLNAME => 'churned',
    CONFIG_OBJECT => {'evaluate': TRUE}
)
COMMENT = 'DEMO: newsworthy - Churn prediction model trained on subscriber behavior features';

-- Display model training results
CALL SFE_CHURN_CLASSIFIER!SHOW_EVALUATION_METRICS();

-- Show feature importance
CALL SFE_CHURN_CLASSIFIER!SHOW_GLOBAL_EVALUATION_METRICS();

-- Test prediction on sample records
SELECT
    subscriber_id,
    engagement_score,
    support_tickets_count,
    days_since_last_read,
    subscription_tenure_days,
    churned AS actual_churn,
    SFE_CHURN_CLASSIFIER!PREDICT(
        OBJECT_CONSTRUCT(
            'engagement_score', engagement_score,
            'support_tickets_count', support_tickets_count,
            'days_since_last_read', days_since_last_read,
            'subscription_tenure_days', subscription_tenure_days
        )
    ) AS predicted_churn
FROM FCT_CHURN_TRAINING
LIMIT 10;

