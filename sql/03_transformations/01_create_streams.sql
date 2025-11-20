/*******************************************************************************
 * DEMO PROJECT: Newsworthy - Customer 360 Media Analytics
 * Script: Create Streams for CDC
 * 
 * ⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Create streams to capture change data from raw tables
 * 
 * OBJECTS CREATED:
 *   - sfe_subscriber_events_stream (on RAW_SUBSCRIBER_EVENTS)
 *   - sfe_content_stream (on RAW_CONTENT_ENGAGEMENT)
 * 
 * USAGE:
 *   Streams are consumed by tasks in 03_create_tasks.sql
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE WAREHOUSE SFE_NEWSWORTHY_WH;
USE SCHEMA SFE_RAW_MEDIA;

-- Stream on subscription events for real-time CDC
CREATE OR REPLACE STREAM sfe_subscriber_events_stream
ON TABLE RAW_SUBSCRIBER_EVENTS
COMMENT = 'DEMO: newsworthy - CDC stream capturing subscription event changes';

-- Stream on content engagement for real-time CDC
CREATE OR REPLACE STREAM sfe_content_stream
ON TABLE RAW_CONTENT_ENGAGEMENT
COMMENT = 'DEMO: newsworthy - CDC stream capturing content engagement changes';

-- Verify streams created
SHOW STREAMS IN DATABASE SNOWFLAKE_EXAMPLE;

-- Check stream offsets (should show 0 rows initially since no new changes)
SELECT SYSTEM$STREAM_HAS_DATA('sfe_subscriber_events_stream') AS subscriber_stream_has_data;
SELECT SYSTEM$STREAM_HAS_DATA('sfe_content_stream') AS content_stream_has_data;

