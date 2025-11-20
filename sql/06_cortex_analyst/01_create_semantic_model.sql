/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Create Cortex Analyst Semantic Model
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Deploy semantic model for Cortex Analyst to enable natural language
 *   queries about subscriber churn, engagement, and customer health.
 *   This enables the "Ask Why" conversational AI experience in Streamlit.
 * 
 * REQUIREMENTS:
 *   - V_CUSTOMER_360 view must exist
 *   - Semantic model YAML file in Git repository
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;

-- Create schema for semantic models (standard location)
CREATE SCHEMA IF NOT EXISTS SEMANTIC_MODELS
    COMMENT = 'DEMO: Semantic models for Cortex Analyst - standard location across all projects';

USE SCHEMA SEMANTIC_MODELS;

-- Create semantic view using native DDL (GA June 2025)
-- Based on V_CUSTOMER_360 unified customer view
CREATE OR REPLACE SEMANTIC VIEW SV_CUSTOMER_360
TABLES (
    customer360 AS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
    COMMENT = 'Unified view of all subscribers with demographics, engagement, and churn predictions'
)
DIMENSIONS (
    customer360.subscriber_id AS subscriber_id
        WITH SYNONYMS = ('customer id', 'user id', 'subscriber', 'customer')
        COMMENT = 'Unique identifier for each subscriber',
    
    customer360.email AS email
        WITH SYNONYMS = ('email address', 'contact email', 'subscriber email')
        COMMENT = 'Email address of the subscriber',
    
    customer360.demographic_segment AS demographic_segment
        WITH SYNONYMS = ('segment', 'customer segment', 'demo', 'demographic')
        COMMENT = 'Demographic classification of the subscriber',
    
    customer360.signup_date AS signup_date
        WITH SYNONYMS = ('signup date', 'join date', 'registration date', 'account created')
        COMMENT = 'Date when the subscriber first signed up',
    
    customer360.risk_tier AS risk_tier
        WITH SYNONYMS = ('churn risk', 'risk level', 'risk category', 'churn likelihood')
        COMMENT = 'ML-predicted churn risk tier: High, Medium, or Low',
    
    customer360.engagement_tier AS engagement_tier
        WITH SYNONYMS = ('engagement level', 'activity level', 'engagement category')
        COMMENT = 'Engagement classification: High Engagement, Medium Engagement, Low Engagement, or Inactive',
    
    customer360.churn_risk_category AS churn_risk_category
        WITH SYNONYMS = ('risk category', 'churn category')
        COMMENT = 'Churn risk classification: High Risk (>70%), Medium Risk (40-70%), Low Risk (<40%)',
    
    customer360.prediction_timestamp AS prediction_timestamp
        WITH SYNONYMS = ('prediction time', 'scored at', 'model run time')
        COMMENT = 'Timestamp when the churn risk score was generated'
)
FACTS (
    customer360.tenure_days AS tenure_days
        WITH SYNONYMS = ('days subscribed', 'subscription length', 'tenure', 'time as subscriber')
        COMMENT = 'Number of days since the subscriber signed up',
    
    customer360.lifetime_value AS lifetime_value
        WITH SYNONYMS = ('LTV', 'total value', 'lifetime revenue')
        COMMENT = 'Total lifetime value of the subscriber',
    
    customer360.articles_viewed_30d AS articles_viewed_30d
        WITH SYNONYMS = ('articles read', 'content consumed', 'articles', 'reads in last 30 days')
        COMMENT = 'Count of articles viewed in the last 30 days (pre-aggregated)',
    
    customer360.total_time_spent_30d AS total_time_spent_30d
        WITH SYNONYMS = ('reading time', 'time spent', 'engagement time', 'seconds reading')
        COMMENT = 'Total time spent reading in the last 30 days in seconds (pre-aggregated)',
    
    customer360.avg_sections_per_day AS avg_sections_per_day
        WITH SYNONYMS = ('sections viewed', 'content diversity', 'section count')
        COMMENT = 'Average number of distinct sections viewed per day (pre-aggregated)',
    
    customer360.churn_risk_score AS churn_risk_score
        WITH SYNONYMS = ('risk score', 'churn probability', 'churn score', 'likelihood to churn')
        COMMENT = 'ML-predicted probability of churn (0-1 scale). >0.7=High risk, 0.4-0.7=Medium, <0.4=Low'
)
COMMENT = 'DEMO: newsworthy - Semantic view for Customer 360 churn analysis with Cortex Analyst';

-- Grant usage to SYSADMIN for Streamlit app
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE SYSADMIN;
GRANT SELECT ON VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CUSTOMER_360 TO ROLE SYSADMIN;

