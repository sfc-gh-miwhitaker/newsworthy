# Usage Guide - Newsworthy Customer 360 Analytics

**Last Updated:** 2025-11-20

---

## 📊 Accessing the Dashboard

### Via Snowsight UI
1. Navigate to your Snowflake account URL
2. Click **Apps** (left sidebar)
3. Select **Streamlit**
4. Click **SFE_CUSTOMER_360_DASHBOARD**

### Direct URL
```
https://<your-account>.snowflakecomputing.com/streamlit/SFE_CUSTOMER_360_DASHBOARD
```

---

## 🔍 Exploring the Data

### Customer 360 View

The unified view combines subscriber profiles, engagement metrics, and churn predictions:

```sql
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SFE_ANALYTICS_MEDIA;

-- View all subscriber insights
SELECT *
FROM V_CUSTOMER_360
LIMIT 100;

-- High-risk churn subscribers
SELECT
    email,
    demographic_segment,
    tenure_days,
    churn_risk_score,
    articles_viewed_30d,
    engagement_tier
FROM V_CUSTOMER_360
WHERE risk_tier = 'High'
ORDER BY churn_risk_score DESC
LIMIT 20;
```

### Churn Prediction Analysis

```sql
-- Churn risk distribution
SELECT
    risk_tier,
    COUNT(*) AS subscriber_count,
    AVG(churn_risk_score) AS avg_score,
    AVG(tenure_days) AS avg_tenure
FROM V_CUSTOMER_360
GROUP BY risk_tier
ORDER BY risk_tier;

-- Engagement vs Churn Correlation
SELECT
    engagement_tier,
    risk_tier,
    COUNT(*) AS count
FROM V_CUSTOMER_360
GROUP BY engagement_tier, risk_tier
ORDER BY engagement_tier, risk_tier;
```

### Real-Time CDC Monitoring

```sql
-- Check stream data availability
SELECT SYSTEM$STREAM_HAS_DATA('SFE_RAW_MEDIA.sfe_subscriber_events_stream');
SELECT SYSTEM$STREAM_HAS_DATA('SFE_RAW_MEDIA.sfe_content_stream');

-- Task execution history
SELECT
    name,
    state,
    scheduled_time,
    completed_time,
    error_message
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE name LIKE 'SFE_%'
ORDER BY scheduled_time DESC
LIMIT 10;
```

---

## 🎯 Common Use Cases

### Use Case 1: Identify At-Risk Subscribers

**Business Goal:** Proactively retain high-value subscribers before they churn

```sql
-- High-value, high-risk subscribers for retention campaign
SELECT
    subscriber_id,
    email,
    demographic_segment,
    lifetime_value,
    churn_risk_score,
    days_since_last_engagement
FROM V_CUSTOMER_360
WHERE churn_risk_score >= 0.7
  AND lifetime_value > 100
  AND is_active = TRUE
ORDER BY lifetime_value DESC
LIMIT 50;
```

### Use Case 2: Content Engagement Analysis

**Business Goal:** Understand which content keeps subscribers engaged

```sql
-- Most engaging content sections
SELECT
    section,
    COUNT(DISTINCT subscriber_id) AS unique_subscribers,
    SUM(articles_viewed) AS total_articles,
    AVG(total_time_spent / 60) AS avg_minutes_spent
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.FCT_ENGAGEMENT_DAILY f
JOIN SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_CONTENT_ENGAGEMENT e
  ON f.subscriber_id = e.subscriber_id
  AND f.engagement_date = e.engagement_date
WHERE f.engagement_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY section
ORDER BY avg_minutes_spent DESC;
```

### Use Case 3: Cohort Analysis

**Business Goal:** Track subscriber retention by signup cohort

```sql
-- Monthly cohort retention
SELECT
    DATE_TRUNC('month', signup_date) AS cohort_month,
    COUNT(*) AS cohort_size,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS still_active,
    ROUND(100.0 * SUM(CASE WHEN is_active THEN 1 ELSE 0 END) / COUNT(*), 2) AS retention_rate,
    AVG(tenure_days) AS avg_tenure,
    AVG(churn_risk_score) AS avg_churn_risk
FROM V_CUSTOMER_360
GROUP BY cohort_month
ORDER BY cohort_month DESC;
```

---

## 🔧 Customization Examples

### Adding New Features to Training Data

To improve churn prediction accuracy, add new features:

```sql
-- Create enhanced training table
CREATE OR REPLACE TABLE SFE_ANALYTICS_MEDIA.FCT_CHURN_TRAINING_V2 AS
SELECT
    t.*,
    -- Add new features
    COALESCE(sub.premium_tier_months, 0) AS premium_tenure,
    COALESCE(sup.avg_resolution_days, 0) AS avg_support_resolution,
    CASE
        WHEN t.engagement_score > 50 THEN 'highly_engaged'
        WHEN t.engagement_score > 20 THEN 'moderately_engaged'
        ELSE 'disengaged'
    END AS engagement_category
FROM FCT_CHURN_TRAINING t
LEFT JOIN (
    SELECT subscriber_id, COUNT(*) AS premium_tier_months
    FROM SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_SUBSCRIBER_EVENTS
    WHERE subscription_tier = 'Premium'
    GROUP BY subscriber_id
) sub ON t.subscriber_id = sub.subscriber_id
LEFT JOIN (
    SELECT subscriber_id, AVG(DATEDIFF('day', interaction_timestamp, CURRENT_DATE())) AS avg_resolution_days
    FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_SUPPORT_INTERACTIONS
    WHERE resolution_status = 'resolved'
    GROUP BY subscriber_id
) sup ON t.subscriber_id = sup.subscriber_id;

-- Retrain model with new features
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION SFE_CHURN_CLASSIFIER_V2(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'FCT_CHURN_TRAINING_V2'),
    TARGET_COLNAME => 'churned',
    CONFIG_OBJECT => {'evaluate': TRUE}
);
```

### Adjusting Task Schedules

```sql
-- Change task frequency (e.g., every 5 minutes instead of 1)
ALTER TASK sfe_process_subscribers_task SUSPEND;
ALTER TASK sfe_process_subscribers_task SET SCHEDULE = '5 MINUTES';
ALTER TASK sfe_process_subscribers_task RESUME;

-- Change daily scoring time
ALTER TASK sfe_daily_churn_scoring_task SUSPEND;
ALTER TASK sfe_daily_churn_scoring_task SET SCHEDULE = 'USING CRON 0 6 * * * America/Los_Angeles';  -- 6 AM instead of 4 AM
ALTER TASK sfe_daily_churn_scoring_task RESUME;
```

### Adding Custom Risk Tiers

```sql
-- Create custom risk segmentation view
CREATE OR REPLACE VIEW SFE_ANALYTICS_MEDIA.V_CUSTOM_RISK_SEGMENTS AS
SELECT
    *,
    CASE
        WHEN churn_risk_score >= 0.9 THEN 'Critical'
        WHEN churn_risk_score >= 0.7 THEN 'High'
        WHEN churn_risk_score >= 0.5 THEN 'Medium'
        WHEN churn_risk_score >= 0.3 THEN 'Low'
        ELSE 'Minimal'
    END AS custom_risk_tier,
    CASE
        WHEN churn_risk_score >= 0.7 AND engagement_tier = 'Low Engagement' THEN 'Immediate Action'
        WHEN churn_risk_score >= 0.5 AND tenure_days < 90 THEN 'Early Intervention'
        WHEN churn_risk_score >= 0.5 THEN 'Watch List'
        ELSE 'Healthy'
    END AS intervention_priority
FROM V_CUSTOMER_360;
```

---

## 📈 Performance Monitoring

### Query Performance

```sql
-- Slowest queries on Customer 360 view (last 7 days)
SELECT
    query_text,
    user_name,
    total_elapsed_time / 1000 AS execution_seconds,
    partitions_scanned,
    partitions_total,
    bytes_scanned / POWER(1024, 3) AS gb_scanned
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_text ILIKE '%V_CUSTOMER_360%'
  AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY total_elapsed_time DESC
LIMIT 10;
```

### Storage Monitoring

```sql
-- Storage usage by schema
SELECT
    table_schema,
    SUM(active_bytes) / POWER(1024, 3) AS active_gb,
    SUM(time_travel_bytes) / POWER(1024, 3) AS time_travel_gb,
    SUM(failsafe_bytes) / POWER(1024, 3) AS failsafe_gb
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
WHERE table_catalog = 'SNOWFLAKE_EXAMPLE'
  AND table_schema LIKE 'SFE_%'
GROUP BY table_schema;
```

### Credit Consumption

```sql
-- Daily credit consumption by warehouse (last 30 days)
SELECT
    TO_DATE(start_time) AS usage_date,
    warehouse_name,
    SUM(credits_used) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE warehouse_name = 'SFE_NEWSWORTHY_WH'
  AND start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2
ORDER BY 1 DESC;
```

---

## 🔄 Data Refresh Procedures

### Manual Data Refresh

Trigger tasks manually for testing:

```sql
-- Manually execute subscriber processing
EXECUTE TASK sfe_process_subscribers_task;

-- Manually execute engagement processing
EXECUTE TASK sfe_process_engagement_task;

-- Manually execute churn scoring
EXECUTE TASK sfe_daily_churn_scoring_task;
```

### Simulating New Data

Add test data to see CDC pipeline in action:

```sql
-- Insert new subscription events
INSERT INTO SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_SUBSCRIBER_EVENTS
VALUES
    (UUID_STRING(), 'signup', CURRENT_TIMESTAMP(), 'Premium', 29.99),
    (UUID_STRING(), 'cancel', CURRENT_TIMESTAMP(), 'Basic', 0.00);

-- Check if stream captured changes
SELECT * FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.sfe_subscriber_events_stream;

-- Wait for task to process (1 minute schedule)
-- Then verify staging table updated
SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA.STG_SUBSCRIBER_EVENTS
WHERE processed_at >= DATEADD('minute', -2, CURRENT_TIMESTAMP());
```

---

## 🎓 Best Practices

### Query Optimization

1. **Always filter by date first**
   ```sql
   -- Good
   SELECT * FROM V_CUSTOMER_360
   WHERE signup_date >= '2024-01-01';
   
   -- Avoid
   SELECT * FROM V_CUSTOMER_360
   WHERE email LIKE '%@example.com';
   ```

2. **Use appropriate warehouse sizes**
   - XSMALL: Dashboard queries, < 100K rows
   - SMALL: Analytics queries, < 1M rows
   - MEDIUM+: Large aggregations, ML training

3. **Leverage result caching**
   - Identical queries return cached results
   - Cache valid for 24 hours
   - Free (no compute cost)

### Task Management

1. **Monitor task failures**
   ```sql
   SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
   WHERE state = 'FAILED'
   ORDER BY scheduled_time DESC;
   ```

2. **Suspend tasks during maintenance**
   ```sql
   ALTER TASK sfe_process_subscribers_task SUSPEND;
   -- Perform maintenance
   ALTER TASK sfe_process_subscribers_task RESUME;
   ```

### ML Model Maintenance

1. **Retrain weekly** for fresh patterns
2. **Monitor prediction accuracy** via evaluation metrics
3. **Archive old model versions** before retraining

---

## 📚 Additional Resources

- **Architecture Diagrams:** See `diagrams/` directory
- **SQL Scripts:** All source code in `sql/` directory
- **Cleanup:** See `docs/03-CLEANUP.md` when done

---

**Ready to clean up?** Proceed to [Cleanup Guide](03-CLEANUP.md)

