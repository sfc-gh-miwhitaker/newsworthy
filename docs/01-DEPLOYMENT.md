# Deployment Guide - Newsworthy Customer 360 Analytics

**Status:** Production-Ready Reference Implementation  
**Last Updated:** 2025-11-20  
**Deployment Time:** ~15 minutes

---

## 🚀 Quick Start (Recommended)

The fastest way to deploy this entire demo:

### 1. Open Snowsight
Navigate to your Snowflake account in a web browser

### 2. Open Deployment Script
In your local clone of this repository, open:
```
sql/00_deploy_all.sql
```

### 3. Copy & Paste
- Select ALL content (Ctrl+A / Cmd+A)
- Copy to clipboard

### 4. Create New Worksheet in Snowsight
- Click "+ Worksheet" (top left)
- Paste the entire script

### 5. Click "Run All"
- Button is in top-right of worksheet
- Confirm role is ACCOUNTADMIN
- Wait ~12 minutes for completion

### 6. Access Dashboard
Navigate to: **Apps → Streamlit → SFE_CUSTOMER_360_DASHBOARD**

**That's it!** The entire Customer 360 demo is deployed.

---

## 📋 Prerequisites

### Required

| Requirement | Details |
|-------------|---------|
| **Snowflake Edition** | Enterprise Edition or higher (for Cortex ML) |
| **Role** | ACCOUNTADMIN (for API integration and warehouse creation) |
| **Network Access** | Outbound HTTPS (443) to `github.com` |
| **Warehouse** | Will be created automatically (SFE_NEWSWORTHY_WH) |

### Optional

- **Git Client:** Only if manually cloning repository
- **SnowSQL:** Only if deploying via CLI instead of Snowsight

---

## 🛠️ Deployment Methods

### Method 1: Snowsight (Recommended)

**Pros:**
- ✅ Simplest method (copy/paste, click run)
- ✅ No local tools required
- ✅ Visual progress tracking
- ✅ Automatic error highlighting

**Steps:** See Quick Start above

---

### Method 2: SnowSQL Command Line

**Pros:**
- ✅ Automation-friendly
- ✅ Can be integrated into CI/CD pipelines
- ✅ Progress logging to file

**Prerequisites:**
- SnowSQL installed and configured
- Connection profile with ACCOUNTADMIN role

**Steps:**

```bash
# Clone repository
git clone https://github.com/sfc-gh-miwhitaker/newsworthy.git
cd newsworthy

# Run deployment via SnowSQL
snowsql -c my_connection \
  -f sql/00_deploy_all.sql \
  -o output_file=deployment.log \
  -o friendly=false

# Monitor deployment
tail -f deployment.log
```

---

### Method 3: Manual Step-by-Step

**Pros:**
- ✅ Full control over each step
- ✅ Easy to troubleshoot
- ✅ Can customize between steps

**Cons:**
- ❌ Time-consuming (~30 minutes)
- ❌ Requires understanding of dependencies

**Steps:**

Execute scripts in this exact order:

```sql
-- 1. Setup
USE ROLE ACCOUNTADMIN;
@sql/01_setup/01_create_database.sql
@sql/01_setup/02_create_schemas.sql

-- 2. Create Tables & Load Data
@sql/02_data/01_create_tables.sql
@sql/02_data/02_load_sample_data.sql

-- 3. CDC Pipeline
@sql/03_transformations/01_create_streams.sql
@sql/03_transformations/02_create_views.sql
@sql/03_transformations/03_create_tasks.sql

-- 4. Machine Learning
@sql/04_cortex/01_train_model.sql
@sql/04_cortex/02_daily_scoring.sql

-- 5. Streamlit Dashboard
@sql/05_streamlit/01_create_dashboard.sql
```

---

## 🔍 Verification Steps

After deployment completes, verify all objects created:

```sql
-- Check database and schemas
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;
-- Should show: SFE_RAW_MEDIA, SFE_STG_MEDIA, SFE_ANALYTICS_MEDIA, SFE_STREAMLIT_APPS

-- Check tables
SELECT
    table_schema,
    COUNT(*) AS table_count
FROM SNOWFLAKE_EXAMPLE.INFORMATION_SCHEMA.TABLES
WHERE table_schema LIKE 'SFE_%'
GROUP BY table_schema;
-- Expected: RAW (3), STG (3), ANALYTICS (4)

-- Check row counts
SELECT
    'RAW_SUBSCRIBER_EVENTS' AS table_name,
    COUNT(*) AS row_count
FROM SNOWFLAKE_EXAMPLE.SFE_RAW_MEDIA.RAW_SUBSCRIBER_EVENTS
UNION ALL
SELECT 'DIM_SUBSCRIBERS', COUNT(*)
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.DIM_SUBSCRIBERS;
-- Expected: ~50K subscriber events, ~25K subscribers

-- Check tasks are running
SHOW TASKS IN DATABASE SNOWFLAKE_EXAMPLE;
-- Expected: 3 tasks in 'started' state

-- Check ML model trained
SHOW MODELS IN SCHEMA SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA;
-- Expected: SFE_CHURN_CLASSIFIER

-- Check Streamlit deployed
SHOW STREAMLITS IN DATABASE SNOWFLAKE_EXAMPLE;
-- Expected: SFE_CUSTOMER_360_DASHBOARD

-- Test dashboard query
SELECT *
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
LIMIT 10;
-- Should return subscriber 360 profiles with churn scores
```

---

## 🐛 Troubleshooting

### Issue: "API integration already exists"

**Error:**
```
SQL compilation error: Object 'SFE_NEWSWORTHY_GIT_INTEGRATION' already exists
```

**Solution:**
```sql
-- Option 1: Drop existing and re-create
DROP API INTEGRATION IF EXISTS SFE_NEWSWORTHY_GIT_INTEGRATION;
-- Then re-run deployment

-- Option 2: Skip (safe if previously created)
-- Comment out API integration creation in 00_deploy_all.sql
```

---

### Issue: "Git repository clone failed"

**Error:**
```
Network error accessing https://github.com/sfc-gh-miwhitaker/newsworthy.git
```

**Possible Causes:**
1. Corporate firewall blocking GitHub
2. Network policy restrictions
3. GitHub service disruption

**Solution:**
```sql
-- Test GitHub connectivity
SELECT SYSTEM$WHITELIST('github.com');

-- If blocked, work with network team to allow:
-- Outbound HTTPS (443) to github.com

-- Check if network policy blocking:
SHOW NETWORK POLICIES;

-- Temporarily remove network policy (if safe):
ALTER ACCOUNT UNSET NETWORK_POLICY;
```

---

### Issue: "Warehouse does not exist"

**Error:**
```
SQL execution error: Warehouse 'SFE_NEWSWORTHY_WH' does not exist
```

**Solution:**
```sql
-- Create warehouse manually
CREATE WAREHOUSE IF NOT EXISTS SFE_NEWSWORTHY_WH WITH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- Set as current warehouse
USE WAREHOUSE SFE_NEWSWORTHY_WH;

-- Then resume deployment
```

---

### Issue: "CREATE SNOWFLAKE.ML.CLASSIFICATION failed"

**Error:**
```
Insufficient privileges or feature not available in current edition
```

**Possible Causes:**
1. Account is not Enterprise Edition or higher
2. Cortex ML features not enabled

**Solution:**
```sql
-- Check Snowflake edition
SELECT CURRENT_EDITION();
-- Must be: ENTERPRISE, BUSINESS_CRITICAL, or VPS

-- If Standard Edition, upgrade required:
-- Contact Snowflake account team

-- If Enterprise+, verify Cortex ML enabled:
SHOW PARAMETERS LIKE 'ENABLE_CORTEX%' IN ACCOUNT;
```

---

### Issue: "Task execution failed - insufficient privileges"

**Error:**
```
Insufficient privileges to operate on task
```

**Solution:**
```sql
-- Grant EXECUTE TASK to SYSADMIN (if needed)
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE SYSADMIN;

-- Verify task privileges
SHOW GRANTS TO ROLE SYSADMIN;
```

---

### Issue: "Streamlit creation failed"

**Error:**
```
Streamlit is not enabled in this account
```

**Solution:**
```sql
-- Check if Streamlit enabled
SHOW PARAMETERS LIKE 'ENABLE_STREAMLIT' IN ACCOUNT;

-- If not enabled, contact Snowflake account team
-- Streamlit is generally available but may require enablement
```

---

## ⏱️ Deployment Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| Setup & Git Integration | 2 min | Create database, schemas, clone Git repo |
| Table Creation | 1 min | Create 9 tables across 3 layers |
| Sample Data Load | 4 min | Generate 562K rows of synthetic data |
| ML Model Training | 3 min | Train Cortex classification model |
| Streamlit Deployment | 1 min | Deploy Customer 360 dashboard |
| Task Activation | 1 min | Start automated CDC pipelines |
| **Total** | **~12 min** | Complete end-to-end deployment |

---

## 💰 Cost Estimation

**One-Time Deployment Cost:**
- Runtime: 12 minutes on XSMALL warehouse
- Credits: 0.2 credits
- Cost: ~$0.40 @ $2/credit (Standard Edition)

**Ongoing Monthly Cost:**
- Tasks: 3 tasks × 1 min/day × 30 days = 1.5 hours = 0.025 credits
- Streamlit queries: ~0.025 credits/month (5 users × 6 queries/day)
- Storage: 500 MB = ~$0.01/month
- **Total:** ~$0.15/month

---

## 🔐 Security Considerations

### Credentials

- **Never commit:** `.env` files, private keys, passwords
- **Use:** Snowflake Secrets for sensitive values
- **GitHub PAT:** Only required for private repositories

### Network Security

- Deployment requires outbound HTTPS (443) to github.com
- No inbound firewall rules required
- All traffic encrypted via TLS 1.2+

### Role-Based Access

- Deployment requires: ACCOUNTADMIN
- Dashboard access: Create custom ANALYST_ROLE with read-only access
- Production: Implement least-privilege access model

---

## 📚 Next Steps

After successful deployment:

1. **Explore Dashboard:** Navigate to SFE_CUSTOMER_360_DASHBOARD
2. **Review Architecture:** See `diagrams/` directory for system design
3. **Customize:** See `docs/02-USAGE.md` for customization examples
4. **Clean Up:** When done, run `sql/99_cleanup/teardown_all.sql`

---

## 🆘 Getting Help

- **Documentation:** All docs in `docs/` directory
- **Architecture:** See `diagrams/` for visual system design
- **GitHub Issues:** https://github.com/sfc-gh-miwhitaker/newsworthy/issues
- **Snowflake Support:** Contact your account team

---

**Deployment complete?** Proceed to [Usage Guide](02-USAGE.md)

