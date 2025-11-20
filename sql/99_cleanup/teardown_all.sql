/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Complete Teardown
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Remove all demo artifacts created by this project
 * 
 * OBJECTS REMOVED:
 *   - All schemas in SNOWFLAKE_EXAMPLE database created by this demo
 *   - SFE_NEWSWORTHY_WH warehouse
 *   - SFE_NEWSWORTHY_GIT_INTEGRATION API integration
 *   - newsworthy_repo Git repository
 * 
 * PROTECTED (NOT REMOVED):
 *   - SNOWFLAKE_EXAMPLE database (shared across demos)
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared infrastructure)
 *   - Other projects' objects in SNOWFLAKE_EXAMPLE
 * 
 * RUNTIME: < 1 minute
 * 
 * USAGE:
 *   Copy/paste this entire script into Snowsight and click "Run All"
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- SECTION 1: SUSPEND AND DROP TASKS
-- =============================================================================

-- Suspend all tasks before dropping
ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_subscribers_task SUSPEND;
ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_engagement_task SUSPEND;
ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_daily_churn_scoring_task SUSPEND;

-- Drop tasks
DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_subscribers_task;
DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_engagement_task;
DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_daily_churn_scoring_task;

-- =============================================================================
-- SECTION 2: DROP ML MODELS
-- =============================================================================

DROP SNOWFLAKE.ML.CLASSIFICATION IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.SFE_CHURN_CLASSIFIER;

-- =============================================================================
-- SECTION 3: DROP SEMANTIC VIEWS (CORTEX ANALYST)
-- =============================================================================

DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CUSTOMER_360;

-- =============================================================================
-- SECTION 4: DROP STREAMLIT APPLICATIONS
-- =============================================================================

DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STREAMLIT_APPS.SFE_CUSTOMER_360_DASHBOARD;

-- =============================================================================
-- SECTION 5: DROP STREAMS
-- =============================================================================

DROP STREAM IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.sfe_subscriber_events_stream;
DROP STREAM IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.sfe_content_stream;

-- =============================================================================
-- SECTION 6: DROP SCHEMAS (CASCADE removes all tables, views)
-- =============================================================================

DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STREAMLIT_APPS CASCADE;

-- =============================================================================
-- SECTION 7: DROP GIT REPOSITORY
-- =============================================================================

DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo;

-- =============================================================================
-- SECTION 8: DROP WAREHOUSE
-- =============================================================================

DROP WAREHOUSE IF EXISTS SFE_NEWSWORTHY_WH;

-- =============================================================================
-- SECTION 9: DROP API INTEGRATION
-- =============================================================================

DROP API INTEGRATION IF EXISTS SFE_NEWSWORTHY_GIT_INTEGRATION;

-- =============================================================================
-- SECTION 10: VERIFICATION
-- =============================================================================

-- Verify all demo objects removed
-- Run these SHOW commands individually to verify cleanup

-- Check schemas (should return no SFE_*_MEDIA or SFE_STREAMLIT_APPS)
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;

-- Check warehouses (should not show SFE_NEWSWORTHY_WH)
SHOW WAREHOUSES LIKE 'SFE_NEWSWORTHY_WH';

-- Check API integrations (should not show SFE_NEWSWORTHY_GIT_INTEGRATION)
SHOW API INTEGRATIONS LIKE 'SFE_NEWSWORTHY_GIT_INTEGRATION';

-- Check Git repositories (should not show newsworthy_repo)
SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.GIT_REPOS;

SELECT
    'CLEANUP COMPLETE' AS status,
    'All newsworthy demo artifacts removed' AS message,
    'SNOWFLAKE_EXAMPLE database and GIT_REPOS schema preserved' AS note;

-- =============================================================================
-- PROTECTED OBJECTS (NOT REMOVED)
-- =============================================================================

/*
 * The following objects are PRESERVED (shared across demos):
 * 
 * - SNOWFLAKE_EXAMPLE database
 *   Rationale: Shared container for all demo projects
 * 
 * - SNOWFLAKE_EXAMPLE.GIT_REPOS schema
 *   Rationale: Shared infrastructure for Git-integrated deployments
 * 
 * - Other projects' SFE_* prefixed objects in different schemas
 *   Rationale: Other demos may coexist in SNOWFLAKE_EXAMPLE
 * 
 * To remove EVERYTHING including the database:
 *   DROP DATABASE SNOWFLAKE_EXAMPLE CASCADE;
 *   (Use with caution - removes ALL demo projects)
 */

