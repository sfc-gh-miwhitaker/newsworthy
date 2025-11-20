/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Create Schemas
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Create 3-layer schema architecture for Customer 360 analytics
 * 
 * OBJECTS CREATED:
 *   - SFE_RAW_MEDIA (raw landing layer)
 *   - SFE_STG_MEDIA (staging/cleaning layer)
 *   - SFE_ANALYTICS_MEDIA (analytics/reporting layer)
 *   - SFE_STREAMLIT_APPS (Streamlit applications)
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;

-- Raw data landing schema
CREATE SCHEMA IF NOT EXISTS SFE_RAW_MEDIA
  DATA_RETENTION_TIME_IN_DAYS = 1
  COMMENT = 'DEMO: newsworthy - Raw data landing zone for subscriber events';

-- Staging schema for cleaned/validated data
CREATE SCHEMA IF NOT EXISTS SFE_STG_MEDIA
  DATA_RETENTION_TIME_IN_DAYS = 1
  COMMENT = 'DEMO: newsworthy - Staging layer for data cleaning and validation';

-- Analytics schema for dimensional model and ML
CREATE SCHEMA IF NOT EXISTS SFE_ANALYTICS_MEDIA
  DATA_RETENTION_TIME_IN_DAYS = 1
  COMMENT = 'DEMO: newsworthy - Analytics layer with dimensional model and ML predictions';

-- Streamlit applications schema
CREATE SCHEMA IF NOT EXISTS SFE_STREAMLIT_APPS
  DATA_RETENTION_TIME_IN_DAYS = 1
  COMMENT = 'DEMO: newsworthy - Streamlit dashboard applications';

-- Verify schemas created
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;

