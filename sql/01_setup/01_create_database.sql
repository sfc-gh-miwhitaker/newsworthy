/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Create Database
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Create SNOWFLAKE_EXAMPLE database if it doesn't exist
 * 
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE (database)
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;

-- Create database for all demo projects
-- Safe to run multiple times (IF NOT EXISTS)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
  DATA_RETENTION_TIME_IN_DAYS = 1
  COMMENT = 'DEMO: Repository for example/demo projects - NOT FOR PRODUCTION';

-- Verify database created
SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE';

