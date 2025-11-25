![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2025--12--20-orange)

# Newsworthy: Customer 360 Media Analytics Demo

> DEMONSTRATION PROJECT - EXPIRES: 2025-12-20  
> This demo uses Snowflake features current as of November 2025.  
> After expiration, this repository will be archived and made private.

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

**Author:** SE Community  
**Purpose:** Reference implementation for Customer 360 subscriber analytics  
**Created:** 2025-11-20 | **Expires:** 2025-12-20 (30 days) | **Status:** ACTIVE

**⚠️ DEMO PROJECT - NOT FOR PRODUCTION USE**

This is a reference implementation for educational purposes demonstrating unified subscriber analytics with churn prediction for media publishers.

**Database:** All artifacts created in `SNOWFLAKE_EXAMPLE` database  
**Isolation:** Uses `SFE_` prefix for account-level objects  
**Industry:** Media & Entertainment - Digital Publishing

---

## 👋 First Time Here?

Deploy this entire demo in **~15 minutes** with one copy/paste operation:

1. **`sql/00_deploy_all.sql`** - Copy entire script into Snowsight, click "Run All" (~12 min)
2. **`docs/01-DEPLOYMENT.md`** - Detailed deployment guide with troubleshooting
3. **`docs/02-USAGE.md`** - Explore the Customer 360 dashboard and features
4. **`docs/03-CLEANUP.md`** - Complete removal instructions

**Total setup time:** ~15 minutes

---

## What This Demo Shows

### Business Challenge
Media publishers struggle with:
- **Fragmented subscriber data** across content, billing, and support systems
- **Reactive churn prevention** - identifying at-risk subscribers too late
- **Limited customer service context** - agents lack complete subscriber history

### Solution Architecture
Unified data platform enabling:
- ✅ **Real-time data integration** via Snowflake Streams
- ✅ **Automated CDC pipelines** via Tasks
- ✅ **Predictive churn modeling** via Cortex ML Classification (>85% accuracy)
- ✅ **Interactive analytics dashboard** via Streamlit

### Key Features Demonstrated
1. **Streams & Tasks** - Real-time subscriber event capture and processing
2. **Cortex ML** - Automated churn prediction without external ML platforms
3. **Customer 360 View** - Unified subscriber profiles with behavioral analytics
4. **Streamlit Dashboard** - Interactive analytics for business users

---

## Architecture Overview

```
┌─────────────────┐
│  Raw Sources    │
│  - Subscriber   │──┐
│  - Content      │  │  Snowflake Streams
│  - Support      │  │  (Real-time CDC)
└─────────────────┘  │
                     ↓
┌──────────────────────────────────┐
│  Staging Layer (SFE_STG_MEDIA)   │
│  - Cleaned events                │
│  - Unified customer profiles     │
└──────────────────────────────────┘
                     ↓
        ┌────────────┴────────────┐
        ↓                         ↓
┌───────────────┐     ┌───────────────────────┐
│ ML Training   │────→│ Cortex Churn Classifier│
└───────────────┘     └───────────────────────┘
                                  ↓
                      ┌───────────────────────┐
                      │  Customer Health      │
                      │  Scores (Daily)       │
                      └───────────────────────┘
                                  ↓
                      ┌───────────────────────┐
                      │ Streamlit Dashboard   │
                      │ - Subscriber 360      │
                      │ - Churn Risk Analysis │
                      └───────────────────────┘
```

See detailed architecture diagrams:
- `diagrams/data-model.md` - Complete schema design
- `diagrams/data-flow.md` - Data movement patterns
- `diagrams/network-flow.md` - System connectivity
- `diagrams/auth-flow.md` - Access control

---

## Objects Created by This Demo

### Account-Level Objects (Require ACCOUNTADMIN)
| Object Type | Name | Purpose |
|-------------|------|---------|
| API Integration | `SFE_NEWSWORTHY_GIT_INTEGRATION` | GitHub repository access |
| Warehouse | `SFE_NEWSWORTHY_WH` | Dedicated demo compute (XSMALL) |

### Database Objects (in SNOWFLAKE_EXAMPLE)
| Schema | Object Type | Count | Examples |
|--------|-------------|-------|----------|
| `SFE_RAW_MEDIA` | Tables | 3 | RAW_SUBSCRIBER_EVENTS, RAW_CONTENT_ENGAGEMENT |
| `SFE_RAW_MEDIA` | Streams | 2 | sfe_subscriber_events_stream, sfe_content_stream |
| `SFE_STG_MEDIA` | Tables | 3 | STG_SUBSCRIBER_EVENTS, STG_UNIFIED_CUSTOMER |
| `SFE_ANALYTICS_MEDIA` | Tables | 4 | DIM_SUBSCRIBERS, FCT_CUSTOMER_HEALTH_SCORES |
| `SFE_ANALYTICS_MEDIA` | Views | 1 | V_CUSTOMER_360 |
| `SFE_ANALYTICS_MEDIA` | ML Models | 1 | SFE_CHURN_CLASSIFIER |
| `SFE_ANALYTICS_MEDIA` | Tasks | 3 | sfe_process_subscribers_task, sfe_daily_churn_scoring_task |
| `SFE_STREAMLIT_APPS` | Streamlit | 1 | SFE_CUSTOMER_360_DASHBOARD |

---

## Demo Data

**Synthetic data with statistically realistic patterns:**

- **50K subscriber events** (last 90 days) - subscriptions, upgrades, cancellations
  - Payment amounts follow **NORMAL distribution** (clusters around typical price points)
- **500K content engagement records** (last 30 days) - article views, time spent, sections visited
  - Article popularity follows **ZIPF distribution** (80/20 rule - viral content vs. long tail)
  - Reading time follows **NORMAL distribution** (most users read 2-5 minutes)
- **25K subscriber profiles** - demographics, subscription tiers, tenure, engagement levels
- **Churn labels** - 15% churn rate for model training

**Data Generation:** Leverages Snowflake native functions (GENERATOR, NORMAL, ZIPF, UUID_STRING) for production-grade synthetic patterns. All data is **synthetic and shareable** - no customer data used.

---

## Estimated Demo Costs

**Edition Required:** Standard ($2/credit)  
**One-time Deployment:** ~$0.45 (15 minutes on XSMALL warehouse)  
**Monthly Operational Cost:** ~$0.15 (scheduled tasks, Streamlit queries)

### Cost Breakdown
| Component | Credits | Cost @ $2/credit |
|-----------|---------|------------------|
| Initial deployment (15 min XSMALL) | 0.225 | $0.45 |
| Tasks (1 min/day × 30 days) | 0.050 | $0.10 |
| Streamlit queries (5 users × 6 queries/day) | 0.025 | $0.05 |
| **Monthly Total** | **0.075** | **$0.15** |

**Storage:** ~500 MB (~$0.01/month)

**Justification:** Minimal cost for demonstrating enterprise-grade subscriber analytics and churn prediction capabilities.

---

## Use Cases Demonstrated

1. **Churn Prevention**
   - Identify at-risk subscribers 30 days before cancellation
   - Prioritize retention campaigns by churn risk score
   - Track churn model accuracy and feature importance

2. **Content Personalization**
   - Analyze subscriber engagement patterns by content section
   - Identify content preferences by subscriber segment
   - Measure content effectiveness on subscriber retention

3. **Customer Service Excellence**
   - Complete subscriber context for support agents
   - Historical engagement and subscription timeline
   - Proactive identification of high-value at-risk accounts

4. **Business Intelligence**
   - Subscriber lifetime value analysis
   - Cohort analysis and retention curves
   - Real-time operational dashboards

---

## Complete Cleanup

Remove all demo artifacts in **< 1 minute**:

```sql
-- Run this script:
@sql/99_cleanup/teardown_all.sql

-- Or manually:
DROP DATABASE IF EXISTS SNOWFLAKE_EXAMPLE CASCADE;
DROP WAREHOUSE IF EXISTS SFE_NEWSWORTHY_WH;
DROP API INTEGRATION IF EXISTS SFE_NEWSWORTHY_GIT_INTEGRATION;
```

**Verification:** Run `SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE'` - should return no results.

See `docs/03-CLEANUP.md` for detailed cleanup instructions.

---

## Reference Implementation Notice

![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)

This code demonstrates production-grade architectural patterns and best practices. **Review and customize** security, networking, and business logic for your organization's specific requirements before deployment.

**Not Included:**
- Enterprise network policies
- Production-grade security hardening
- High-availability configuration
- Disaster recovery procedures
- Organization-specific data governance

---

## Technical Specifications

**Snowflake Features:**
- Streams (CDC)
- Tasks (Automation)
- Cortex ML Classification (Churn Prediction)
- Streamlit (Interactive UI)
- Git Integration (Native deployment)

**Data Architecture:**
- 3-layer design (Raw → Staging → Analytics)
- Type 1 Slowly Changing Dimensions
- Incremental processing via streams
- Daily batch ML predictions

**Performance:**
- XSMALL warehouse sufficient for demo workloads
- Optimized for <10M rows per table
- Query response time: <2 seconds typical

---

## Support & Feedback

**Author:** SE Community  
**Created:** 2025-11-20  
**Expires:** 2025-12-20  
**Version:** 1.0  

For questions or feedback on this demo:
1. Review documentation in `docs/` directory
2. Check architecture diagrams in `diagrams/` directory
3. Contact your Snowflake account team

---

## License

Copyright © 2025 Snowflake Inc. All rights reserved.

This demo is provided "as-is" for educational purposes.
