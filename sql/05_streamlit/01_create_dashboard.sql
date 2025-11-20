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
CREATE OR REPLACE STREAMLIT SFE_CUSTOMER_360_DASHBOARD
    ROOT_LOCATION = '@SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/streamlit'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = SFE_NEWSWORTHY_WH
    COMMENT = 'DEMO: newsworthy - Customer 360 analytics dashboard with churn predictions';

-- Verify Streamlit created successfully
SELECT 
    'Streamlit dashboard created successfully' AS status,
    'SFE_CUSTOMER_360_DASHBOARD' AS streamlit_name,
    'Navigate to Apps -> Streamlit -> SFE_CUSTOMER_360_DASHBOARD' AS access_instructions,
    'https://<your-account>.snowflakecomputing.com/streamlit/SFE_CUSTOMER_360_DASHBOARD' AS direct_url;

-- Show created Streamlit
SHOW STREAMLITS IN SCHEMA SFE_STREAMLIT_APPS;

