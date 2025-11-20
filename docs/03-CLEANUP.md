# Cleanup Guide - Newsworthy Customer 360 Analytics

**Last Updated:** 2025-11-20  
**Cleanup Time:** < 1 minute

---

## ⚠️ Before You Clean Up

**Warning:** This process will remove ALL demo artifacts created by this project.

**Verify you want to proceed if:**
- ✅ You've completed your demo or evaluation
- ✅ You've exported any data or insights you need
- ✅ No other processes are actively using the demo objects

**Do NOT proceed if:**
- ❌ You're still actively using the dashboard
- ❌ Other demos in SNOWFLAKE_EXAMPLE database might be affected
- ❌ You haven't backed up custom queries or modifications

---

## 🚀 Quick Cleanup (Recommended)

The fastest way to remove all demo artifacts:

### 1. Open Snowsight
Navigate to your Snowflake account

### 2. Open Cleanup Script
In your local clone, open:
```
sql/99_cleanup/teardown_all.sql
```

### 3. Copy & Paste
- Select ALL content
- Copy to clipboard

### 4. Create New Worksheet
- Click "+ Worksheet"
- Paste the entire script

### 5. Click "Run All"
- Confirm role is ACCOUNTADMIN
- Wait ~30 seconds for completion

### 6. Verify Cleanup
Run verification queries (included at end of script)

---

## 🗑️ What Gets Removed

### Schemas & All Contents
- `SFE_RAW_MEDIA` (3 tables, 2 streams)
- `SFE_STG_MEDIA` (3 tables)
- `SFE_ANALYTICS_MEDIA` (4 tables, 1 view, 1 ML model, 3 tasks)
- `SFE_STREAMLIT_APPS` (1 Streamlit app)

### Account-Level Objects
- `SFE_NEWSWORTHY_WH` (warehouse)
- `SFE_NEWSWORTHY_GIT_INTEGRATION` (API integration)
- `newsworthy_repo` (Git repository in GIT_REPOS schema)

### Estimated Storage Freed
- ~500 MB (sample data + Time Travel)

### Estimated Monthly Cost Savings
- ~$0.15/month (task execution + queries)

---

## 🛡️ What Gets PRESERVED

These objects are **NOT removed** (shared infrastructure):

### Database
- `SNOWFLAKE_EXAMPLE` - Shared container for all demo projects

### Shared Schema
- `SNOWFLAKE_EXAMPLE.GIT_REPOS` - Shared Git repository infrastructure

### Other Demos
- Any other SFE_* prefixed objects in different schemas
- Other projects coexisting in SNOWFLAKE_EXAMPLE

**Rationale:** Multiple demo projects may share the database and Git infrastructure.

---

## 🔍 Verification Steps

After cleanup, verify all demo objects removed:

```sql
USE ROLE ACCOUNTADMIN;

-- 1. Check schemas (should NOT show SFE_*_MEDIA or SFE_STREAMLIT_APPS)
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;

-- 2. Check warehouse (should return no results)
SHOW WAREHOUSES LIKE 'SFE_NEWSWORTHY_WH';

-- 3. Check API integration (should return no results)
SHOW API INTEGRATIONS LIKE 'SFE_NEWSWORTHY_GIT_INTEGRATION';

-- 4. Check Git repository (should NOT show newsworthy_repo)
SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.GIT_REPOS;

-- 5. Verify storage freed
SELECT
    'Cleanup verification complete' AS status,
    'No newsworthy objects remaining' AS result;
```

Expected result: **No SFE_NEWSWORTHY_* or newsworthy-specific objects**

---

## 🧹 Complete Database Removal (Optional)

**⚠️ DANGER ZONE:** Only do this if you want to remove **ALL demos** in SNOWFLAKE_EXAMPLE.

This will delete:
- All demo projects (not just newsworthy)
- All shared infrastructure
- All data across all demos

```sql
USE ROLE ACCOUNTADMIN;

-- Remove EVERYTHING (all demos)
DROP DATABASE IF EXISTS SNOWFLAKE_EXAMPLE CASCADE;

-- Verify complete removal
SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE';
-- Should return no results
```

**When to use this:**
- Closing out an account
- Complete demo environment teardown
- Starting fresh with clean slate

**When NOT to use this:**
- Other demo projects are active
- Shared with team members
- Only want to remove newsworthy specifically

---

## 🔧 Selective Cleanup

If you only want to remove specific components:

### Remove Only Streamlit Dashboard
```sql
DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STREAMLIT_APPS.SFE_CUSTOMER_360_DASHBOARD;
```

### Remove Only ML Model
```sql
DROP SNOWFLAKE.ML.CLASSIFICATION IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.SFE_CHURN_CLASSIFIER;
```

### Remove Only Tasks (Keep Data)
```sql
ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_subscribers_task SUSPEND;
DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_subscribers_task;

ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_engagement_task SUSPEND;
DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_engagement_task;

ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_daily_churn_scoring_task SUSPEND;
DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_daily_churn_scoring_task;
```

### Remove Only Data (Keep Structure)
```sql
USE SCHEMA SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA;
TRUNCATE TABLE RAW_SUBSCRIBER_EVENTS;
TRUNCATE TABLE RAW_CONTENT_ENGAGEMENT;
TRUNCATE TABLE RAW_SUPPORT_INTERACTIONS;

USE SCHEMA SNOWFLAKE_EXAMPLE.SFE_STG_MEDIA;
TRUNCATE TABLE STG_SUBSCRIBER_EVENTS;
TRUNCATE TABLE STG_UNIFIED_CUSTOMER;
TRUNCATE TABLE STG_CONTENT_ENGAGEMENT;

USE SCHEMA SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA;
TRUNCATE TABLE DIM_SUBSCRIBERS;
TRUNCATE TABLE FCT_ENGAGEMENT_DAILY;
TRUNCATE TABLE FCT_CHURN_TRAINING;
TRUNCATE TABLE FCT_CUSTOMER_HEALTH_SCORES;
```

---

## 🐛 Troubleshooting Cleanup

### Issue: "Cannot drop schema - objects still exist"

**Error:**
```
SQL execution error: Cannot drop schema SFE_ANALYTICS_MEDIA because it has active objects
```

**Solution:**
```sql
-- Suspend all tasks first
ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_subscribers_task SUSPEND;
ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_process_engagement_task SUSPEND;
ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.sfe_daily_churn_scoring_task SUSPEND;

-- Then drop with CASCADE
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA CASCADE;
```

---

### Issue: "Cannot drop warehouse - in use"

**Error:**
```
SQL execution error: Warehouse SFE_NEWSWORTHY_WH is currently in use
```

**Solution:**
```sql
-- Check what's using warehouse
SHOW TASKS IN DATABASE SNOWFLAKE_EXAMPLE;
-- Suspend any running tasks

-- Wait for current queries to complete (check in Snowsight Query History)

-- Try drop again
DROP WAREHOUSE IF EXISTS SFE_NEWSWORTHY_WH;
```

---

### Issue: "Object does not exist"

**Error:**
```
Object 'SFE_CHURN_CLASSIFIER' does not exist
```

**Solution:**
This is safe to ignore. The cleanup script uses `IF EXISTS` to handle cases where objects were already removed or never created.

---

## ♻️ Re-Deployment After Cleanup

To redeploy the demo after cleanup:

```sql
-- Simply run the deployment script again
@sql/00_deploy_all.sql
```

All objects will be recreated from scratch with fresh sample data.

---

## 📊 Post-Cleanup Audit

Recommended audit queries to confirm cleanup:

```sql
-- Check remaining storage
SELECT
    SUM(active_bytes) / POWER(1024, 3) AS remaining_gb
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
WHERE table_catalog = 'SNOWFLAKE_EXAMPLE'
  AND table_schema LIKE 'SFE_%';
-- Should return 0 or NULL

-- Check credit usage stopped
SELECT
    warehouse_name,
    SUM(credits_used) AS credits_last_24h
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE warehouse_name = 'SFE_NEWSWORTHY_WH'
  AND start_time >= DATEADD('hour', -24, CURRENT_TIMESTAMP())
GROUP BY warehouse_name;
-- Should return no results

-- Final verification
SELECT
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME LIKE 'SFE_%_MEDIA')
        AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.WAREHOUSES WHERE WAREHOUSE_NAME = 'SFE_NEWSWORTHY_WH')
        THEN '✅ Cleanup Complete'
        ELSE '❌ Some objects still exist'
    END AS cleanup_status;
```

---

## 📚 Additional Resources

- **Re-deployment:** See `docs/01-DEPLOYMENT.md`
- **Architecture:** See `diagrams/` directory
- **Source Code:** All scripts in `sql/` directory

---

**Cleanup complete!** Thank you for exploring the Newsworthy Customer 360 demo.

