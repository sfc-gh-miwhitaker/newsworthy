/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Create Streamlit Dashboard
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Deploy Customer 360 Streamlit dashboard from Git repository
 * 
 * OBJECTS CREATED:
 *   - SFE_CUSTOMER_360_DASHBOARD (Streamlit application)
 * 
 * ACCESS:
 *   Navigate to Apps -> Streamlit -> SFE_CUSTOMER_360_DASHBOARD
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;
USE SCHEMA SFE_STREAMLIT_APPS;

-- Create Streamlit dashboard from Git repository
-- Note: In this demo, we'll create a simple inline Streamlit app
-- For production, code would come from Git repository

CREATE OR REPLACE STREAMLIT SFE_CUSTOMER_360_DASHBOARD
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = SFE_NEWSWORTHY_WH
    COMMENT = 'DEMO: newsworthy - Customer 360 analytics dashboard with churn predictions';

-- Since we can't directly write Python files via SQL, we'll note here that
-- the Streamlit app code would typically come from:
-- @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/streamlit/app.py

-- For this demo deployment, create a placeholder message
-- In practice, the app.py file would be in the Git repository

SELECT 
    'Streamlit dashboard created' AS status,
    'Navigate to Apps -> Streamlit -> SFE_CUSTOMER_360_DASHBOARD' AS next_step;

-- Verify Streamlit created
SHOW STREAMLITS IN SCHEMA SFE_STREAMLIT_APPS;

