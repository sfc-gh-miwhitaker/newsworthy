/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Complete Deployment (Git-Integrated)
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Single-script deployment of entire Customer 360 demo using native
 *   Snowflake Git integration. Demonstrates streams, tasks, Cortex ML
 *   classification, and Streamlit for subscriber churn prediction.
 * 
 * USAGE IN SNOWSIGHT:
 *   1. Copy this ENTIRE script (Ctrl+A / Cmd+A)
 *   2. Open Snowsight -> SQL Worksheets -> New Worksheet
 *   3. Paste the script
 *   4. Click "Run All" (top-right)
 *   5. Wait ~12 minutes for complete deployment
 *   6. Navigate to Apps -> Streamlit -> SFE_CUSTOMER_360_DASHBOARD
 * 
 * REQUIREMENTS:
 *   - Snowflake account with Enterprise Edition or higher
 *   - ACCOUNTADMIN role (for API integration and Git repository creation)
 *   - Internet access to GitHub (https://github.com/sfc-gh-miwhitaker/newsworthy)
 * 
 * GITHUB REPOSITORY:
 *   https://github.com/sfc-gh-miwhitaker/newsworthy
 *   - Public repository (no authentication required)
 *   - Contains: SQL scripts, Streamlit app, sample data generators
 * 
 * OBJECTS CREATED:
 *   Account-Level:
 *     - SFE_NEWSWORTHY_GIT_INTEGRATION (API Integration)
 *     - SFE_NEWSWORTHY_WH (XSMALL warehouse)
 *   
 *   Database: SNOWFLAKE_EXAMPLE
 *     - Schema: SFE_RAW_MEDIA (3 tables, 2 streams)
 *     - Schema: SFE_STG_MEDIA (3 tables)
 *     - Schema: SFE_ANALYTICS_MEDIA (4 tables, 1 view, 1 ML model, 3 tasks)
 *     - Schema: SFE_STREAMLIT_APPS (1 Streamlit app)
 * 
 * ESTIMATED RUNTIME: ~12 minutes
 *   - Setup & Git integration: 2 min
 *   - Table creation & sample data: 5 min
 *   - ML model training: 3 min
 *   - Streamlit deployment: 2 min
 * 
 * ESTIMATED COST: ~$0.40 (one-time)
 *   - 12 minutes on XSMALL warehouse = 0.2 credits
 *   - @ $2/credit (Standard Edition) = $0.40
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql for complete removal
 * 
 * TROUBLESHOOTING:
 *   - If "API integration already exists": Safe to ignore or drop existing
 *   - If "warehouse already exists": Safe to ignore or drop existing
 *   - If GitHub connection fails: Check network/firewall allows github.com:443
 *   - If ML training fails: Verify Enterprise Edition license
 *   - Support: docs/01-DEPLOYMENT.md for detailed troubleshooting
 ******************************************************************************/

-- =============================================================================
-- SECTION 1: ENVIRONMENT SETUP
-- =============================================================================

-- Capture deployment start time for runtime calculation
SET deployment_start_time = CURRENT_TIMESTAMP();

-- Use ACCOUNTADMIN role for API integration and Git repository creation
USE ROLE ACCOUNTADMIN;

-- Set context for deployment
SET deployment_warehouse = 'SFE_NEWSWORTHY_WH';
SET target_database = 'SNOWFLAKE_EXAMPLE';
SET github_repo_url = 'https://github.com/sfc-gh-miwhitaker/newsworthy.git';

-- =============================================================================
-- SECTION 2: CREATE API INTEGRATION FOR GITHUB ACCESS
-- =============================================================================

-- Create API integration for GitHub repository access (public repo, no auth)
-- This allows Snowflake to clone and read SQL scripts from GitHub
CREATE API INTEGRATION IF NOT EXISTS SFE_NEWSWORTHY_GIT_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/')
  ENABLED = TRUE
  COMMENT = 'DEMO: newsworthy - GitHub integration for deployment automation';

-- Verify API integration created successfully
SHOW API INTEGRATIONS LIKE 'SFE_NEWSWORTHY_GIT_INTEGRATION';

-- =============================================================================
-- SECTION 3: CREATE DEMO WAREHOUSE
-- =============================================================================

-- Create dedicated XSMALL warehouse for demo compute
-- Auto-suspend after 60 seconds to minimize costs
CREATE WAREHOUSE IF NOT EXISTS SFE_NEWSWORTHY_WH WITH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = FALSE
  COMMENT = 'DEMO: newsworthy - Dedicated warehouse for Customer 360 analytics';

-- Use the new warehouse for all subsequent operations
USE WAREHOUSE SFE_NEWSWORTHY_WH;

-- =============================================================================
-- SECTION 4: CREATE DATABASE & GIT REPOSITORY
-- =============================================================================

-- Create or use existing SNOWFLAKE_EXAMPLE database
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
  COMMENT = 'DEMO: Repository for example/demo projects - NOT FOR PRODUCTION';

-- Create schema for Git repository stage
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS
  COMMENT = 'DEMO: Git repository stages for deployment automation';

-- Clone GitHub repository as Snowflake stage
-- This creates a read-only stage that mirrors the GitHub repo
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo
  API_INTEGRATION = SFE_NEWSWORTHY_GIT_INTEGRATION
  ORIGIN = 'https://github.com/sfc-gh-miwhitaker/newsworthy.git'
  COMMENT = 'DEMO: newsworthy - Cloned repository for deployment scripts';

-- Fetch latest code from GitHub main branch
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo FETCH;

-- List files in repository to verify successful clone
LIST @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main;

-- =============================================================================
-- SECTION 5: EXECUTE SETUP SCRIPTS FROM GIT REPOSITORY
-- =============================================================================

-- Execute 01_setup scripts: Create database, schemas, warehouse (already done above)
-- Note: Database and warehouse created in previous sections
-- Creating schemas now

EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/01_setup/01_create_database.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/01_setup/02_create_schemas.sql;

-- =============================================================================
-- SECTION 6: EXECUTE DATA SCRIPTS FROM GIT REPOSITORY
-- =============================================================================

-- Execute 02_data scripts: Create tables and load sample data
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/02_data/01_create_tables.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/02_data/02_load_sample_data.sql;

-- =============================================================================
-- SECTION 7: EXECUTE TRANSFORMATION SCRIPTS FROM GIT REPOSITORY
-- =============================================================================

-- Execute 03_transformations scripts: Create streams, views, and tasks for CDC
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/03_transformations/01_create_streams.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/03_transformations/02_create_views.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/03_transformations/03_create_tasks.sql;

-- =============================================================================
-- SECTION 8: EXECUTE CORTEX ML SCRIPTS FROM GIT REPOSITORY
-- =============================================================================

-- Execute 04_cortex scripts: Train churn prediction model
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/04_cortex/01_train_model.sql;
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/04_cortex/02_daily_scoring.sql;

-- =============================================================================
-- SECTION 9: EXECUTE STREAMLIT DEPLOYMENT FROM GIT REPOSITORY
-- =============================================================================

-- Execute 05_streamlit script: Create Customer 360 dashboard
EXECUTE IMMEDIATE FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/05_streamlit/01_create_dashboard.sql;

-- =============================================================================
-- SECTION 10: DEPLOYMENT COMPLETE
-- =============================================================================

-- Display comprehensive deployment summary with actual runtime
-- Note: Single SELECT statement to avoid output being replaced in "Run All" mode
SELECT
    'DEPLOYMENT COMPLETE' AS status,
    CURRENT_TIMESTAMP() AS completed_at,
    TIMEDIFF(
        'SECOND',
        $deployment_start_time,
        CURRENT_TIMESTAMP()
    ) AS runtime_seconds,
    TO_VARCHAR(
        FLOOR(TIMEDIFF('SECOND', $deployment_start_time, CURRENT_TIMESTAMP()) / 60)
    ) || ' min ' ||
    TO_VARCHAR(
        MOD(TIMEDIFF('SECOND', $deployment_start_time, CURRENT_TIMESTAMP()), 60)
    ) || ' sec' AS total_runtime,
    'Navigate to Apps -> Streamlit -> SFE_CUSTOMER_360_DASHBOARD' AS next_step,
    'Run verification queries below individually for detailed object inspection' AS verification_note;

-- =============================================================================
-- VERIFICATION QUERIES (Run individually after deployment, not via "Run All")
-- =============================================================================

/*
 * After deployment completes, run these queries ONE AT A TIME to verify:
 * 
 * -- Check database and schemas created
 * SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;
 * 
 * -- Check tables created (expected: 3 in RAW, 3 in STG, 4 in ANALYTICS)
 * SELECT
 *     table_schema,
 *     COUNT(*) AS table_count,
 *     SUM(row_count) AS total_rows
 * FROM SNOWFLAKE_EXAMPLE.INFORMATION_SCHEMA.TABLES
 * WHERE table_schema LIKE 'SFE_%'
 * GROUP BY table_schema
 * ORDER BY table_schema;
 * 
 * -- Check streams created
 * SHOW STREAMS IN DATABASE SNOWFLAKE_EXAMPLE;
 * 
 * -- Check tasks created and running
 * SHOW TASKS IN DATABASE SNOWFLAKE_EXAMPLE;
 * 
 * -- Check ML model trained
 * SHOW MODELS IN SCHEMA SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA;
 * 
 * -- Check Streamlit deployed
 * SHOW STREAMLITS IN DATABASE SNOWFLAKE_EXAMPLE;
 * 
 * -- Test Customer 360 view
 * SELECT COUNT(*) AS subscriber_count
 * FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360;
 * 
 */

-- =============================================================================
-- TROUBLESHOOTING SECTION
-- =============================================================================

/*
 * COMMON ISSUES AND SOLUTIONS:
 * 
 * Issue: "API integration already exists"
 * Solution: Safe to ignore, or run: DROP API INTEGRATION SFE_NEWSWORTHY_GIT_INTEGRATION;
 * 
 * Issue: "Warehouse already exists"
 * Solution: Safe to ignore, or run: DROP WAREHOUSE SFE_NEWSWORTHY_WH;
 * 
 * Issue: "Git repository clone failed - network error"
 * Solution: Verify firewall allows HTTPS (443) to github.com
 *           Check: SELECT SYSTEM$WHITELIST('github.com');
 * 
 * Issue: "EXECUTE IMMEDIATE FROM failed - file not found"
 * Solution: Run: ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo FETCH;
 *           Verify: LIST @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main;
 * 
 * Issue: "CREATE SNOWFLAKE.ML.CLASSIFICATION failed"
 * Solution: Verify account has Enterprise Edition or higher
 *           Verify ACCOUNTADMIN role is active
 *           Check: SELECT CURRENT_EDITION();
 * 
 * Issue: "Task execution failed - insufficient privileges"
 * Solution: Verify ACCOUNTADMIN role: SELECT CURRENT_ROLE();
 *           Grant EXECUTE TASK: GRANT EXECUTE TASK ON ACCOUNT TO ROLE SYSADMIN;
 * 
 * Issue: "Streamlit creation failed"
 * Solution: Verify Streamlit is enabled in account
 *           Check: SHOW PARAMETERS LIKE 'ENABLE_STREAMLIT' IN ACCOUNT;
 * 
 * For detailed troubleshooting, see:
 *   - docs/01-DEPLOYMENT.md
 *   - GitHub Issues: https://github.com/sfc-gh-miwhitaker/newsworthy/issues
 */

-- =============================================================================
-- NEXT STEPS
-- =============================================================================

/*
 * 1. VIEW DASHBOARD:
 *    Navigate to: Apps -> Streamlit -> SFE_CUSTOMER_360_DASHBOARD
 *    Or direct URL: https://<your-account>.snowflakecomputing.com/streamlit/SFE_CUSTOMER_360_DASHBOARD
 * 
 * 2. EXPLORE DATA:
 *    SELECT * FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360 LIMIT 100;
 *    SELECT * FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.FCT_CUSTOMER_HEALTH_SCORES ORDER BY churn_risk_score DESC LIMIT 20;
 * 
 * 3. REVIEW ARCHITECTURE:
 *    See diagrams/ directory in GitHub repository:
 *    - data-model.md (complete schema design)
 *    - data-flow.md (data movement patterns)
 *    - network-flow.md (system connectivity)
 *    - auth-flow.md (access control)
 * 
 * 4. CUSTOMIZE:
 *    See docs/02-USAGE.md for customization examples
 * 
 * 5. CLEANUP (when done):
 *    Run: @SNOWFLAKE_EXAMPLE.GIT_REPOS.newsworthy_repo/branches/main/sql/99_cleanup/teardown_all.sql
 *    Or see: docs/03-CLEANUP.md
 */

-- =============================================================================
-- END OF DEPLOYMENT SCRIPT
-- =============================================================================

