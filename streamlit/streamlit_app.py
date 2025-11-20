"""
Customer 360 Analytics Dashboard
Newsworthy Media - Subscriber Churn Prediction

⚠️  NOT FOR PRODUCTION USE - REFERENCE IMPLEMENTATION ONLY
"""

import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

# Page configuration
st.set_page_config(
    page_title="Customer 360 Analytics",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Get Snowpark session
session = get_active_session()

# Title and description
st.title("📊 Customer 360 Analytics Dashboard")
st.markdown("**Real-time subscriber insights with ML-powered churn prediction**")
st.markdown("---")

# Sidebar filters
with st.sidebar:
    st.header("🔍 Filters")
    
    # Risk tier filter
    risk_tiers = st.multiselect(
        "Churn Risk Tier",
        options=["High", "Medium", "Low"],
        default=["High", "Medium", "Low"]
    )
    
    # Engagement tier filter
    engagement_tiers = st.multiselect(
        "Engagement Tier",
        options=["High Engagement", "Medium Engagement", "Low Engagement", "Inactive"],
        default=["High Engagement", "Medium Engagement", "Low Engagement", "Inactive"]
    )
    
    st.markdown("---")
    st.markdown("### 📈 About This Demo")
    st.markdown("""
    **Features:**
    - Real-time CDC via Streams
    - Automated pipelines via Tasks
    - ML churn prediction (Cortex)
    - Unified Customer 360 view
    
    **Data Refresh:**
    - Engagement: Every 1 minute
    - Churn Scores: Daily at 4 AM
    """)

# Build WHERE clause for filters (handle NULL values gracefully)
where_clauses = []
if risk_tiers:
    risk_list = "', '".join(risk_tiers)
    where_clauses.append(f"(risk_tier IN ('{risk_list}') OR risk_tier IS NULL)")
if engagement_tiers:
    engagement_list = "', '".join(engagement_tiers)
    where_clauses.append(f"(engagement_tier IN ('{engagement_list}') OR engagement_tier IS NULL)")

where_clause = " AND ".join(where_clauses) if where_clauses else "1=1"

# Key Metrics Row
col1, col2, col3, col4 = st.columns(4)

# Total Subscribers
total_subscribers_query = f"""
SELECT COUNT(*) AS total
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
WHERE {where_clause}
"""
total_subscribers = session.sql(total_subscribers_query).collect()[0]['TOTAL']

with col1:
    st.metric(
        label="Total Subscribers",
        value=f"{total_subscribers:,}"
    )

# High Risk Subscribers
high_risk_query = f"""
SELECT COUNT(*) AS high_risk
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
WHERE risk_tier = 'High' AND {where_clause}
"""
high_risk = session.sql(high_risk_query).collect()[0]['HIGH_RISK']

with col2:
    st.metric(
        label="High Risk Subscribers",
        value=f"{high_risk:,}",
        delta=f"{(high_risk/total_subscribers*100):.1f}%" if total_subscribers > 0 else "0%",
        delta_color="inverse"
    )

# Average Engagement (30 days)
avg_engagement_query = f"""
SELECT AVG(articles_viewed_30d) AS avg_articles
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
WHERE {where_clause}
"""
avg_articles = session.sql(avg_engagement_query).collect()[0]['AVG_ARTICLES']

with col3:
    st.metric(
        label="Avg Articles/Subscriber (30d)",
        value=f"{avg_articles:.1f}" if avg_articles else "0"
    )

# Average Churn Risk Score
avg_risk_query = f"""
SELECT AVG(churn_risk_score) AS avg_risk
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
WHERE {where_clause} AND churn_risk_score IS NOT NULL
"""
avg_risk = session.sql(avg_risk_query).collect()[0]['AVG_RISK']

with col4:
    st.metric(
        label="Avg Churn Risk Score",
        value=f"{avg_risk:.3f}" if avg_risk else "N/A",
        delta_color="inverse"
    )

st.markdown("---")

# Two-column layout for charts
col_left, col_right = st.columns(2)

with col_left:
    st.subheader("📊 Risk Distribution")
    
    risk_dist_query = f"""
    SELECT
        risk_tier,
        COUNT(*) AS subscriber_count
    FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
    WHERE {where_clause}
    GROUP BY risk_tier
    ORDER BY 
        CASE risk_tier
            WHEN 'High' THEN 1
            WHEN 'Medium' THEN 2
            WHEN 'Low' THEN 3
        END
    """
    risk_dist_df = session.sql(risk_dist_query).to_pandas()
    
    if not risk_dist_df.empty:
        st.bar_chart(risk_dist_df.set_index('RISK_TIER'))
    else:
        st.info("No data available for selected filters")

with col_right:
    st.subheader("📈 Engagement Distribution")
    
    engagement_dist_query = f"""
    SELECT
        engagement_tier,
        COUNT(*) AS subscriber_count
    FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
    WHERE {where_clause}
    GROUP BY engagement_tier
    ORDER BY 
        CASE engagement_tier
            WHEN 'High Engagement' THEN 1
            WHEN 'Medium Engagement' THEN 2
            WHEN 'Low Engagement' THEN 3
            WHEN 'Inactive' THEN 4
        END
    """
    engagement_dist_df = session.sql(engagement_dist_query).to_pandas()
    
    if not engagement_dist_df.empty:
        st.bar_chart(engagement_dist_df.set_index('ENGAGEMENT_TIER'))
    else:
        st.info("No data available for selected filters")

st.markdown("---")

# High-Risk Subscribers Table
st.subheader("⚠️ High-Risk Subscribers (Top 20)")

high_risk_table_query = f"""
SELECT
    subscriber_id,
    email,
    demographic_segment,
    tenure_days,
    articles_viewed_30d,
    churn_risk_score,
    risk_tier,
    engagement_tier
FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
WHERE {where_clause}
ORDER BY churn_risk_score DESC
LIMIT 20
"""
high_risk_df = session.sql(high_risk_table_query).to_pandas()

if not high_risk_df.empty:
    # Format the dataframe for better display
    high_risk_df['CHURN_RISK_SCORE'] = high_risk_df['CHURN_RISK_SCORE'].apply(lambda x: f"{x:.3f}" if pd.notna(x) else "N/A")
    high_risk_df['TENURE_DAYS'] = high_risk_df['TENURE_DAYS'].apply(lambda x: f"{int(x)} days" if pd.notna(x) else "N/A")
    
    st.dataframe(
        high_risk_df,
        use_container_width=True,
        hide_index=True
    )
else:
    st.info("No high-risk subscribers found for selected filters")

st.markdown("---")

# Detailed Analytics Section
with st.expander("📊 Detailed Analytics", expanded=False):
    st.subheader("Risk by Demographic Segment")
    
    demo_risk_query = f"""
    SELECT
        demographic_segment,
        risk_tier,
        COUNT(*) AS subscriber_count,
        AVG(churn_risk_score) AS avg_risk_score
    FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_MEDIA.V_CUSTOMER_360
    WHERE {where_clause}
    GROUP BY demographic_segment, risk_tier
    ORDER BY demographic_segment, risk_tier
    """
    demo_risk_df = session.sql(demo_risk_query).to_pandas()
    
    if not demo_risk_df.empty:
        # Pivot for better visualization
        pivot_df = demo_risk_df.pivot(
            index='DEMOGRAPHIC_SEGMENT',
            columns='RISK_TIER',
            values='SUBSCRIBER_COUNT'
        ).fillna(0)
        
        st.bar_chart(pivot_df)
        
        # Show detailed table
        st.dataframe(demo_risk_df, use_container_width=True, hide_index=True)
    else:
        st.info("No data available")

# Footer
st.markdown("---")
st.markdown("""
**📚 Reference Implementation**  
This dashboard demonstrates production-grade architecture patterns. Review and customize for your specific requirements.

**🔄 Data Sources:**
- `V_CUSTOMER_360`: Unified customer view
- `FCT_CUSTOMER_HEALTH_SCORES`: ML churn predictions
- `FCT_ENGAGEMENT_DAILY`: Engagement metrics

**⚙️ Technology:**
- Snowflake Streams (CDC)
- Snowflake Tasks (Automation)
- Cortex ML Classification (Predictions)
- Streamlit in Snowflake (UI)
""")

