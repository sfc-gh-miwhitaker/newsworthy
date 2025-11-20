/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Create Tasks for Automated Processing
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Create automated tasks for CDC processing and daily analytics refresh
 * 
 * OBJECTS CREATED:
 *   - sfe_process_subscribers_task (1 MIN schedule, stream-triggered)
 *   - sfe_process_engagement_task (1 MIN schedule, stream-triggered)
 *   - sfe_daily_churn_scoring_task (DAILY schedule)
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;

-- =============================================================================
-- TASK 1: Process Subscriber Events (Triggered by Stream)
-- =============================================================================

CREATE OR REPLACE TASK sfe_process_subscribers_task
    WAREHOUSE = SFE_NEWSWORTHY_WH
    SCHEDULE = '1 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('SFE_RAW_MEDIA.sfe_subscriber_events_stream')
    COMMENT = 'DEMO: newsworthy - Process new subscription events from stream'
AS
BEGIN
    -- Merge new events into staging
    MERGE INTO SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_SUBSCRIBER_EVENTS t
    USING (
        SELECT
            subscriber_id,
            event_type,
            event_timestamp AS cleaned_timestamp,
            subscription_tier,
            payment_amount,
            TRUE AS is_valid
        FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.sfe_subscriber_events_stream
        WHERE METADATA$ACTION = 'INSERT'
          AND event_timestamp IS NOT NULL
          AND payment_amount > 0
    ) s
    ON t.subscriber_id = s.subscriber_id
       AND t.cleaned_timestamp = s.cleaned_timestamp
    WHEN NOT MATCHED THEN
        INSERT (subscriber_id, event_type, cleaned_timestamp, subscription_tier, payment_amount, is_valid)
        VALUES (s.subscriber_id, s.event_type, s.cleaned_timestamp, s.subscription_tier, s.payment_amount, s.is_valid);
    
    -- Update unified customer master
    MERGE INTO SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_UNIFIED_CUSTOMER t
    USING (
        SELECT DISTINCT
            subscriber_id,
            'subscriber_' || SUBSTR(subscriber_id, 1, 8) || '@example.com' AS email,
            'Jane' AS first_name,
            'Smith' AS last_name,
            DATE_TRUNC('day', cleaned_timestamp) AS signup_date,
            subscription_tier AS current_tier,
            event_type != 'cancel' AS is_active
        FROM SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_SUBSCRIBER_EVENTS
        WHERE subscriber_id IN (
            SELECT DISTINCT subscriber_id
            FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.sfe_subscriber_events_stream
            WHERE METADATA$ACTION = 'INSERT'
        )
        QUALIFY ROW_NUMBER() OVER (PARTITION BY subscriber_id ORDER BY cleaned_timestamp DESC) = 1
    ) s
    ON t.subscriber_id = s.subscriber_id
    WHEN MATCHED THEN
        UPDATE SET
            current_tier = s.current_tier,
            is_active = s.is_active,
            last_updated = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
        INSERT (subscriber_id, email, first_name, last_name, signup_date, current_tier, is_active)
        VALUES (s.subscriber_id, s.email, s.first_name, s.last_name, s.signup_date, s.current_tier, s.is_active);
END;

-- =============================================================================
-- TASK 2: Process Content Engagement (Triggered by Stream)
-- =============================================================================

CREATE OR REPLACE TASK sfe_process_engagement_task
    WAREHOUSE = SFE_NEWSWORTHY_WH
    SCHEDULE = '1 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('SFE_RAW_MEDIA.sfe_content_stream')
    COMMENT = 'DEMO: newsworthy - Process new content engagement from stream'
AS
BEGIN
    -- Insert new engagement records
    INSERT INTO SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_CONTENT_ENGAGEMENT
    SELECT
        engagement_id,
        subscriber_id,
        article_id,
        DATE_TRUNC('day', view_timestamp) AS engagement_date,
        time_spent_seconds,
        section
    FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.sfe_content_stream
    WHERE METADATA$ACTION = 'INSERT';
    
    -- Update daily engagement facts
    MERGE INTO SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.FCT_ENGAGEMENT_DAILY t
    USING (
        SELECT
            engagement_date,
            subscriber_id,
            COUNT(DISTINCT engagement_id) AS articles_viewed,
            SUM(time_spent_seconds) AS total_time_spent,
            COUNT(DISTINCT section) AS distinct_sections
        FROM SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_CONTENT_ENGAGEMENT
        WHERE engagement_date >= CURRENT_DATE() - 7  -- Reprocess last 7 days
        GROUP BY engagement_date, subscriber_id
    ) s
    ON t.engagement_date = s.engagement_date
       AND t.subscriber_id = s.subscriber_id
    WHEN MATCHED THEN
        UPDATE SET
            articles_viewed = s.articles_viewed,
            total_time_spent = s.total_time_spent,
            distinct_sections = s.distinct_sections
    WHEN NOT MATCHED THEN
        INSERT (engagement_date, subscriber_id, articles_viewed, total_time_spent, distinct_sections)
        VALUES (s.engagement_date, s.subscriber_id, s.articles_viewed, s.total_time_spent, s.distinct_sections);
END;

-- =============================================================================
-- TASK 3: Daily Churn Scoring (Scheduled Daily at 4 AM)
-- =============================================================================

CREATE OR REPLACE TASK sfe_daily_churn_scoring_task
    WAREHOUSE = SFE_NEWSWORTHY_WH
    SCHEDULE = 'USING CRON 0 4 * * * America/Los_Angeles'
    COMMENT = 'DEMO: newsworthy - Daily churn prediction scoring using ML model'
AS
BEGIN
    -- This task will call the trained ML model to score all active subscribers
    -- Implementation will be completed in sql/04_cortex/02_daily_scoring.sql
    -- after the model is trained
    
    INSERT INTO SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.FCT_CUSTOMER_HEALTH_SCORES
    SELECT
        subscriber_id,
        CURRENT_DATE() AS score_date,
        0.5 AS churn_risk_score,  -- Placeholder until model is trained
        'Medium' AS risk_tier,
        'v1.0' AS model_version
    FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.DIM_SUBSCRIBERS
    WHERE subscriber_id NOT IN (
        SELECT subscriber_id
        FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.FCT_CUSTOMER_HEALTH_SCORES
        WHERE score_date = CURRENT_DATE()
    );
END;

-- =============================================================================
-- RESUME TASKS TO ACTIVATE
-- =============================================================================

-- Resume tasks to start execution
ALTER TASK sfe_process_subscribers_task RESUME;
ALTER TASK sfe_process_engagement_task RESUME;
ALTER TASK sfe_daily_churn_scoring_task RESUME;

-- Verify tasks are running
SHOW TASKS IN DATABASE SNOWFLAKE_EXAMPLE;

-- Check task execution history
SELECT
    name,
    state,
    scheduled_time,
    query_start_time,
    completed_time,
    error_message
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE name IN ('SFE_PROCESS_SUBSCRIBERS_TASK', 'SFE_PROCESS_ENGAGEMENT_TASK', 'SFE_DAILY_CHURN_SCORING_TASK')
ORDER BY scheduled_time DESC
LIMIT 10;

