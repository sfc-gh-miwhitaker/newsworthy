/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Create Views
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Create unified Customer 360 view for dashboard consumption
 * 
 * OBJECTS CREATED:
 *   - V_CUSTOMER_360 (unified subscriber view with health scores)
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;
USE SCHEMA SFE_ANALYTICS_MEDIA;

-- Unified Customer 360 view combining dimension, facts, and health scores
CREATE OR REPLACE VIEW V_CUSTOMER_360
COMMENT = 'DEMO: newsworthy - Unified Customer 360 view for dashboard and analytics'
AS
SELECT
    d.subscriber_id,
    d.email,
    d.demographic_segment,
    d.signup_date,
    d.tenure_days,
    d.lifetime_value,
    
    -- Latest engagement metrics (last 30 days)
    COALESCE(SUM(e.articles_viewed), 0) AS articles_viewed_30d,
    COALESCE(SUM(e.total_time_spent), 0) AS total_time_spent_30d,
    COALESCE(AVG(e.distinct_sections), 0) AS avg_sections_per_day,
    
    -- Latest churn prediction
    h.churn_risk_score,
    h.risk_tier,
    h.prediction_timestamp,
    
    -- Calculated fields
    CASE
        WHEN h.churn_risk_score >= 0.7 THEN 'High Risk'
        WHEN h.churn_risk_score >= 0.4 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS churn_risk_category,
    
    CASE
        WHEN COALESCE(SUM(e.articles_viewed), 0) = 0 THEN 'Inactive'
        WHEN COALESCE(SUM(e.articles_viewed), 0) < 5 THEN 'Low Engagement'
        WHEN COALESCE(SUM(e.articles_viewed), 0) < 20 THEN 'Medium Engagement'
        ELSE 'High Engagement'
    END AS engagement_tier

FROM DIM_SUBSCRIBERS d

-- Join latest 30 days of engagement
LEFT JOIN FCT_ENGAGEMENT_DAILY e
    ON d.subscriber_id = e.subscriber_id
    AND e.engagement_date >= DATEADD('day', -30, CURRENT_DATE())

-- Join latest health score
LEFT JOIN FCT_CUSTOMER_HEALTH_SCORES h
    ON d.subscriber_id = h.subscriber_id
    AND h.score_date = (
        SELECT MAX(score_date)
        FROM FCT_CUSTOMER_HEALTH_SCORES h2
        WHERE h2.subscriber_id = d.subscriber_id
    )

GROUP BY
    d.subscriber_id,
    d.email,
    d.demographic_segment,
    d.signup_date,
    d.tenure_days,
    d.lifetime_value,
    h.churn_risk_score,
    h.risk_tier,
    h.prediction_timestamp;

-- Test view with sample query
SELECT
    risk_tier,
    engagement_tier,
    COUNT(*) AS subscriber_count,
    AVG(churn_risk_score) AS avg_risk_score,
    AVG(articles_viewed_30d) AS avg_articles_viewed
FROM V_CUSTOMER_360
GROUP BY risk_tier, engagement_tier
ORDER BY risk_tier, engagement_tier;

