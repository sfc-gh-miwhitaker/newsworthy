# Authentication & Authorization Flow - Newsworthy Customer 360 Analytics

**Author:** Snowflake Solutions Engineering  
**Last Updated:** 2025-11-20  
**Status:** Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

**Reference Implementation:** This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and business logic for your organization's specific requirements before deployment.

## Overview

This diagram shows the authentication and authorization flows for the Customer 360 system, covering deployment (ACCOUNTADMIN), data access (custom roles), and dashboard usage (end users).

## Diagram

```mermaid
sequenceDiagram
    actor Admin as ACCOUNTADMIN
    actor Dev as Developer/SE
    actor Analyst as Business Analyst
    participant Snowsight
    participant Auth as Snowflake Auth
    participant GitHub
    participant Warehouse as SFE_NEWSWORTHY_WH
    participant DB as SNOWFLAKE_EXAMPLE DB
    participant Streamlit as Dashboard
    
    Note over Admin,DB: DEPLOYMENT FLOW (One-time Setup)
    
    Admin->>Snowsight: Login (username/password or OAuth)
    Snowsight->>Auth: Authenticate
    Auth-->>Snowsight: Session + ACCOUNTADMIN role
    
    Admin->>Snowsight: Open sql/00_deploy_all.sql
    Admin->>Snowsight: Click "Run All"
    
    Snowsight->>DB: CREATE API INTEGRATION (GitHub)
    Note over DB: SFE_NEWSWORTHY_GIT_INTEGRATION created
    
    Snowsight->>DB: CREATE GIT REPOSITORY
    DB->>GitHub: Clone repository (public read)
    GitHub-->>DB: SQL scripts + Streamlit code
    
    Snowsight->>DB: CREATE WAREHOUSE SFE_NEWSWORTHY_WH
    Note over Warehouse: XSMALL warehouse created
    
    Snowsight->>Warehouse: USE WAREHOUSE SFE_NEWSWORTHY_WH
    Warehouse->>DB: EXECUTE IMMEDIATE FROM @repo/sql/01_setup/...
    Note over DB: Schemas, tables, streams created
    
    Warehouse->>DB: EXECUTE IMMEDIATE FROM @repo/sql/02_data/...
    Note over DB: Sample data loaded
    
    Warehouse->>DB: EXECUTE IMMEDIATE FROM @repo/sql/04_cortex/...
    Note over DB: ML model trained
    
    Warehouse->>DB: CREATE STREAMLIT (from Git stage)
    Note over DB,Streamlit: Dashboard deployed
    
    Note over Admin,DB: ROLE-BASED ACCESS CONTROL
    
    Admin->>DB: GRANT USAGE ON DATABASE to ANALYST_ROLE
    Admin->>DB: GRANT USAGE ON SCHEMA SFE_ANALYTICS_MEDIA
    Admin->>DB: GRANT SELECT ON FCT_CUSTOMER_HEALTH_SCORES
    Admin->>DB: GRANT OPERATE ON WAREHOUSE SFE_NEWSWORTHY_WH
    
    Note over Analyst,Streamlit: END USER DASHBOARD ACCESS
    
    Analyst->>Snowsight: Login (OAuth or key-pair)
    Snowsight->>Auth: Authenticate
    Auth-->>Snowsight: Session + ANALYST_ROLE
    
    Analyst->>Streamlit: Navigate to SFE_CUSTOMER_360_DASHBOARD
    Streamlit->>Auth: Verify role grants
    Auth-->>Streamlit: USAGE on warehouse + SELECT on analytics
    
    Streamlit->>Warehouse: session.sql("SELECT FROM FCT_CUSTOMER_HEALTH_SCORES")
    Warehouse->>DB: Execute query with ANALYST_ROLE context
    DB-->>Warehouse: Result set (only authorized data)
    Warehouse-->>Streamlit: Query results
    Streamlit-->>Analyst: Rendered dashboard
    
    Note over Dev,Streamlit: DEVELOPER WORKFLOW
    
    Dev->>Snowsight: Login (key-pair auth)
    Snowsight->>Auth: Authenticate with private key
    Auth-->>Streamlit: Session + SYSADMIN role
    
    Dev->>DB: SELECT FROM RAW tables (debugging)
    Note over DB: Row-level access based on role
    
    Dev->>Warehouse: ALTER TASK to adjust schedule
    Note over Warehouse: Requires OWNERSHIP or sufficient grants
    
    Dev->>DB: Test new features in DEV schema
    Note over DB: Isolated from production data
```

## Authentication Methods

### ACCOUNTADMIN (Deployment)
- **Purpose:** Initial deployment and infrastructure setup
- **Method:** Username/password or federated SSO (OAuth)
- **Privileges:** Full account admin (create integrations, warehouses, databases)
- **Duration:** Temporary elevation for deployment only
- **Best Practice:** Use separate admin account, not day-to-day credentials

### Developer/Solutions Engineer
- **Purpose:** Development, testing, and troubleshooting
- **Method:** Key-pair authentication (recommended for automation)
- **Privileges:** SYSADMIN or custom DEV_ROLE
- **Typical Grants:**
  * USAGE on SNOWFLAKE_EXAMPLE database
  * CREATE SCHEMA (for dev/test schemas)
  * MODIFY on SFE_NEWSWORTHY_WH
  * OPERATE on tasks for debugging
- **MFA:** Strongly recommended

### Business Analyst (Dashboard User)
- **Purpose:** Query analytics data and view dashboards
- **Method:** OAuth 2.0 (SSO with corporate identity provider)
- **Privileges:** Custom ANALYST_ROLE with read-only access
- **Typical Grants:**
  * USAGE on SFE_ANALYTICS_MEDIA schema
  * SELECT on analytics tables and views
  * USAGE on SFE_NEWSWORTHY_WH (query execution only)
  * No DDL privileges
- **Session Timeout:** 4 hours idle timeout

### Snowpipe Streaming (Source Systems)
- **Purpose:** Ingest real-time subscriber events
- **Method:** JWT token authentication
- **Privileges:** Custom INGEST_ROLE
- **Typical Grants:**
  * INSERT on RAW tables only
  * USAGE on SFE_NEWSWORTHY_WH
  * No SELECT privileges (write-only)
- **Token Rotation:** Every 90 days

## Authorization Model (RBAC)

### Role Hierarchy
```
ACCOUNTADMIN (deployment only)
    ├─ SYSADMIN (dev/operations)
    │   └─ DEV_ROLE (development)
    └─ ANALYST_ROLE (end users)
        └─ VIEWER_ROLE (read-only dashboards)

INGEST_ROLE (isolated, no hierarchy)
```

### Role Grants Matrix

| Object | ACCOUNTADMIN | SYSADMIN | ANALYST_ROLE | INGEST_ROLE |
|--------|--------------|----------|--------------|-------------|
| SFE_NEWSWORTHY_GIT_INTEGRATION | OWNERSHIP | USAGE | NONE | NONE |
| SFE_NEWSWORTHY_WH | OWNERSHIP | MODIFY | USAGE | USAGE |
| SNOWFLAKE_EXAMPLE database | OWNERSHIP | USAGE | USAGE | USAGE |
| SFE_RAW_MEDIA schema | OWNERSHIP | ALL | NONE | INSERT on tables |
| SFE_STG_MEDIA schema | OWNERSHIP | ALL | NONE | NONE |
| SFE_ANALYTICS_MEDIA schema | OWNERSHIP | ALL | SELECT on tables | NONE |
| SFE_STREAMLIT_APPS schema | OWNERSHIP | ALL | USAGE + RUN | NONE |
| Cortex ML models | OWNERSHIP | ALL | USAGE (predict only) | NONE |
| Tasks | OWNERSHIP | OPERATE | NONE | NONE |

### Principle of Least Privilege
- **Analysts:** Can only query analytics layer, cannot see raw PII
- **Ingest:** Can only write to RAW tables, cannot read any data
- **Developers:** Cannot access production roles without approval
- **Service Accounts:** Separate roles per system (subscription, content, support)

## Authentication Flows

### Flow 1: Deployment (ACCOUNTADMIN)
1. Admin logs into Snowsight with SSO (OAuth)
2. Snowflake validates credentials against identity provider
3. Session granted with ACCOUNTADMIN role
4. Admin opens `sql/00_deploy_all.sql` in Snowsight worksheet
5. Admin clicks "Run All" - no additional prompts
6. Script executes with ACCOUNTADMIN context:
   - Creates API Integration (requires ACCOUNTADMIN)
   - Creates Git Repository (requires API Integration USAGE)
   - Creates warehouse (requires CREATE WAREHOUSE privilege)
   - Grants permissions to analyst roles
7. Session ends when admin logs out or times out

### Flow 2: Dashboard Access (ANALYST_ROLE)
1. Analyst navigates to Snowflake-hosted URL
2. Snowflake redirects to corporate SSO login (OAuth 2.0)
3. Identity provider authenticates user
4. OAuth token returned to Snowflake
5. Snowflake maps user to ANALYST_ROLE (via SAML assertion)
6. Session established with 4-hour timeout
7. Analyst clicks on SFE_CUSTOMER_360_DASHBOARD
8. Streamlit app checks grants:
   - Does ANALYST_ROLE have USAGE on warehouse? ✓
   - Does ANALYST_ROLE have SELECT on FCT_CUSTOMER_HEALTH_SCORES? ✓
9. Dashboard renders, queries execute with ANALYST_ROLE context
10. Row-level security (if configured) filters results based on role

### Flow 3: API Ingestion (JWT Token)
1. Source system generates JWT token signed with private key
2. Token includes:
   - Account identifier
   - Username for service account
   - Expiration (15 minutes max)
3. System sends HTTPS POST to Snowpipe Streaming API with JWT
4. Snowflake validates JWT signature against public key
5. Session established with INGEST_ROLE
6. INSERT statements execute with write-only privileges
7. Token expires after 15 minutes (system generates new one)

### Flow 4: Developer Key-Pair Auth
1. Developer configures Snowflake CLI with private key
2. CLI generates JWT token signed with private key
3. Snowflake validates signature against public key (stored in user profile)
4. Session established with developer's default role (SYSADMIN)
5. Developer can temporarily elevate to ACCOUNTADMIN if granted
6. All SQL executions logged with developer's identity

## Security Best Practices

### Key-Pair Authentication Setup
```sql
-- 1. Generate key pair (developer workstation)
openssl genrsa -out rsa_key.pem 2048
openssl rsa -in rsa_key.pem -pubout -out rsa_key.pub

-- 2. Assign public key to user (ACCOUNTADMIN)
ALTER USER dev_user SET RSA_PUBLIC_KEY='MIIBIjANBgkqhki...';

-- 3. Configure Snowflake CLI
snow connection add \
  --account myaccount \
  --user dev_user \
  --private-key-path rsa_key.pem
```

### OAuth 2.0 SSO Integration
```sql
-- Create security integration for corporate SSO
CREATE SECURITY INTEGRATION corporate_sso
  TYPE = SAML2
  ENABLED = TRUE
  SAML2_ISSUER = 'https://idp.example.com'
  SAML2_SSO_URL = 'https://idp.example.com/saml/sso'
  SAML2_PROVIDER = 'CUSTOM'
  SAML2_X509_CERT = '-----BEGIN CERTIFICATE-----...';

-- Map SSO groups to Snowflake roles
CREATE ROLE analyst_role;
GRANT USAGE ON DATABASE snowflake_example TO ROLE analyst_role;
-- Role mapping happens via SAML assertion attributes
```

### Network Policies (Optional Production Enhancement)
```sql
-- Restrict access to corporate IP ranges
CREATE NETWORK POLICY corp_network_policy
  ALLOWED_IP_LIST = ('203.0.113.0/24', '198.51.100.0/24')
  BLOCKED_IP_LIST = ();

-- Apply to specific users
ALTER USER analyst_user SET NETWORK_POLICY = corp_network_policy;

-- Apply account-wide (not recommended for demo)
ALTER ACCOUNT SET NETWORK_POLICY = corp_network_policy;
```

## Secret Management

### GitHub PAT for API Integration
```sql
-- Store GitHub Personal Access Token securely
CREATE SECRET sfe_github_pat
  TYPE = PASSWORD
  USERNAME = 'sfc-gh-miwhitaker'
  PASSWORD = 'ghp_xxxxxxxxxxxxxxxxxxxx'
  COMMENT = 'DEMO: GitHub PAT for newsworthy repo access';

-- Reference in API Integration
CREATE API INTEGRATION sfe_newsworthy_git_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/')
  ALLOWED_AUTHENTICATION_SECRETS = (sfe_github_pat)
  ENABLED = TRUE;
```

### JWT Keys for Snowpipe Streaming
```sql
-- Store JWT private key for streaming ingestion
CREATE SECRET sfe_streaming_jwt_key
  TYPE = GENERIC_STRING
  SECRET_STRING = '-----BEGIN PRIVATE KEY-----...'
  COMMENT = 'DEMO: JWT private key for Snowpipe Streaming API';

-- Access from Python ingestion script
-- key = session.sql("SELECT SECRET_STRING FROM SECRETS WHERE NAME = 'SFE_STREAMING_JWT_KEY'").collect()[0][0]
```

## Audit & Compliance

### Query History Logging
All queries logged to `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`:
- User who executed query
- Role used
- Warehouse consumed
- Rows returned
- Execution time

### Access Logging
All authentication attempts logged to `SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY`:
- Success/failure status
- Authentication method (password, key-pair, OAuth)
- Client IP address
- First/last authentication attempt

### Example Audit Query
```sql
-- Find all access to sensitive churn prediction data
SELECT
    user_name,
    role_name,
    query_text,
    start_time,
    execution_status
FROM snowflake.account_usage.query_history
WHERE query_text ILIKE '%FCT_CUSTOMER_HEALTH_SCORES%'
  AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;
```

## Change History

See `.cursor/DIAGRAM_CHANGELOG.md` for version history.

