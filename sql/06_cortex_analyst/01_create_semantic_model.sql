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
    SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360 AS customer360
    COMMENT = 'Unified view of all subscribers with demographics, engagement, and churn predictions'
)
DIMENSIONS (
    customer360.subscriber_id AS subscriber_id
        WITH SYNONYMS = ('customer id', 'user id', 'subscriber', 'customer')
        COMMENT = 'Unique identifier for each subscriber',
    
    customer360.subscriber_name AS subscriber_name
        WITH SYNONYMS = ('customer name', 'name', 'user')
        COMMENT = 'Full name of the subscriber',
    
    customer360.demographic_segment AS demographic_segment
        WITH SYNONYMS = ('segment', 'customer segment', 'demo', 'demographic')
        COMMENT = 'Demographic classification: Young Urban Premium, Middle-Age Suburban Standard, Senior Rural Basic',
    
    customer360.subscription_tier AS subscription_tier
        WITH SYNONYMS = ('tier', 'plan', 'subscription level', 'package')
        COMMENT = 'Subscription level: Basic ($9.99/mo), Premium ($19.99/mo), Enterprise ($49.99/mo)',
    
    customer360.risk_tier AS risk_tier
        WITH SYNONYMS = ('churn risk', 'risk level', 'risk category', 'churn likelihood')
        COMMENT = 'ML-predicted churn risk: High (>70%), Medium (40-70%), Low (<40%)',
    
    customer360.engagement_tier AS engagement_tier
        WITH SYNONYMS = ('engagement level', 'activity level', 'engagement category')
        COMMENT = 'Engagement classification: High (>60 min/day), Medium (30-60), Low (10-30), Inactive (<10)',
    
    customer360.sign_up_date AS sign_up_date
        WITH SYNONYMS = ('signup date', 'join date', 'registration date', 'account created')
        COMMENT = 'Date when the subscriber first signed up',
    
    customer360.last_read_date AS last_read_date
        WITH SYNONYMS = ('last active', 'last activity', 'last engagement', 'most recent read')
        COMMENT = 'Most recent date the subscriber read content. NULL indicates never read'
)
METRICS (
    customer360.tenure_days AS tenure_days
        WITH SYNONYMS = ('days subscribed', 'subscription length', 'tenure', 'time as subscriber')
        COMMENT = 'Number of days since the subscriber signed up',
    
    customer360.total_articles_read AS total_articles_read
        WITH SYNONYMS = ('articles read', 'content consumed', 'articles', 'reads')
        COMMENT = 'Lifetime count of articles the subscriber has read',
    
    customer360.avg_daily_reading_minutes AS avg_daily_reading_minutes
        WITH SYNONYMS = ('daily reading time', 'reading minutes', 'time spent reading', 'engagement time')
        COMMENT = 'Average minutes per day spent reading content (last 30 days)',
    
    customer360.support_interactions_count AS support_interactions_count
        WITH SYNONYMS = ('support tickets', 'tickets', 'support requests', 'customer service interactions')
        COMMENT = 'Total number of support interactions in the last 90 days',
    
    customer360.churn_risk_score AS churn_risk_score
        WITH SYNONYMS = ('risk score', 'churn probability', 'churn score', 'likelihood to churn')
        COMMENT = 'ML-predicted probability of churn (0-1 scale). >0.7=High risk, 0.4-0.7=Medium, <0.4=Low',
    
    customer360.days_since_last_read AS days_since_last_read
        WITH SYNONYMS = ('days inactive', 'inactivity period', 'time since last read', 'days without reading')
        COMMENT = 'Number of days since the subscriber last read content. >30 indicates at-risk'
)
COMMENT = 'DEMO: newsworthy - Semantic view for Customer 360 churn analysis with Cortex Analyst';

-- Grant usage to SYSADMIN for Streamlit app
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE SYSADMIN;
GRANT SELECT ON VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CUSTOMER_360 TO ROLE SYSADMIN;

