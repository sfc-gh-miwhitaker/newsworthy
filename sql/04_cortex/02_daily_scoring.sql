/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Daily Churn Scoring (Updates Task Logic)
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Update daily scoring task to use trained ML model for predictions
 * 
 * REQUIREMENTS:
 *   - SFE_CHURN_CLASSIFIER model must be trained first
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;
USE SCHEMA SFE_ANALYTICS_MEDIA;

-- Suspend task before modification
ALTER TASK sfe_daily_churn_scoring_task SUSPEND;

-- Update task with ML model predictions
CREATE OR REPLACE TASK sfe_daily_churn_scoring_task
    WAREHOUSE = SFE_NEWSWORTHY_WH
    SCHEDULE = 'USING CRON 0 4 * * * America/Los_Angeles'
    COMMENT = 'DEMO: newsworthy - Daily churn prediction scoring using Cortex ML'
AS
BEGIN
    -- Score all active subscribers using trained ML model
    INSERT INTO FCT_CUSTOMER_HEALTH_SCORES
    SELECT
        d.subscriber_id,
        CURRENT_DATE() AS score_date,
        prediction['probability']::NUMBER(5,4) AS churn_risk_score,
        CASE
            WHEN prediction['probability']::NUMBER(5,4) >= 0.7 THEN 'High'
            WHEN prediction['probability']::NUMBER(5,4) >= 0.4 THEN 'Medium'
            ELSE 'Low'
        END AS risk_tier,
        'v1.0_cortex_ml' AS model_version
    FROM (
        SELECT
            d.subscriber_id,
            SFE_CHURN_CLASSIFIER!PREDICT(
                OBJECT_CONSTRUCT(
                    'engagement_score', COALESCE(AVG(f.total_time_spent) / 60.0, 0),
                    'support_tickets_count', COALESCE(sup.ticket_count, 0),
                    'days_since_last_read', COALESCE(DATEDIFF('day', MAX(f.engagement_date), CURRENT_DATE()), 999),
                    'subscription_tenure_days', d.tenure_days
                )
            ) AS prediction
        FROM DIM_SUBSCRIBERS d
        LEFT JOIN FCT_ENGAGEMENT_DAILY f
            ON d.subscriber_id = f.subscriber_id
            AND f.engagement_date >= DATEADD('day', -30, CURRENT_DATE())
        LEFT JOIN (
            SELECT subscriber_id, COUNT(*) AS ticket_count
            FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_SUPPORT_INTERACTIONS
            WHERE interaction_timestamp >= DATEADD('day', -90, CURRENT_TIMESTAMP())
            GROUP BY subscriber_id
        ) sup ON d.subscriber_id = sup.subscriber_id
        WHERE d.subscriber_id NOT IN (
            SELECT subscriber_id
            FROM FCT_CUSTOMER_HEALTH_SCORES
            WHERE score_date = CURRENT_DATE()
        )
        GROUP BY d.subscriber_id, d.tenure_days, sup.ticket_count
    );
END;

-- Resume task
ALTER TASK sfe_daily_churn_scoring_task RESUME;

-- Run task immediately for testing (one-time manual execution)
EXECUTE TASK sfe_daily_churn_scoring_task;

-- Verify predictions generated
SELECT
    score_date,
    risk_tier,
    COUNT(*) AS subscriber_count,
    AVG(churn_risk_score) AS avg_risk_score,
    MIN(churn_risk_score) AS min_risk_score,
    MAX(churn_risk_score) AS max_risk_score
FROM FCT_CUSTOMER_HEALTH_SCORES
WHERE score_date = CURRENT_DATE()
GROUP BY score_date, risk_tier
ORDER BY risk_tier;

