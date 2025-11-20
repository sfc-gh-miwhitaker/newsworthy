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
        AND risk_tier IS NOT NULL
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
        AND engagement_tier IS NOT NULL
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
        use_container_width=True
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
        AND risk_tier IS NOT NULL
        AND demographic_segment IS NOT NULL
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

# =============================================================================
# CONVERSATIONAL AI: "ASK WHY" SECTION
# =============================================================================

st.markdown("---")
st.markdown("## 💬 Ask Why: Conversational AI Analytics")
st.markdown("""
**Go beyond the charts** - Ask natural language questions to understand the "why" behind the numbers.  
Powered by **Snowflake Cortex Analyst** with semantic understanding of your data.
""")

# Initialize chat history in session state
if "messages" not in st.session_state:
    st.session_state.messages = []

# Display suggested questions
with st.expander("💡 Suggested Questions", expanded=False):
    st.markdown("""
    **Churn Analysis:**
    - "Which subscription tier has the highest churn risk?"
    - "How many subscribers are at high risk of churning?"
    - "Is there a correlation between engagement and churn risk?"
    
    **Engagement Patterns:**
    - "How many subscribers are inactive and what's their churn risk?"
    - "Which demographic segments have the highest churn risk?"
    
    **Support Impact:**
    - "Do support tickets correlate with higher churn risk?"
    - "What's the average churn risk for subscribers with multiple support tickets?"
    """)

# Display chat messages from history
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        if message["role"] == "user":
            st.markdown(message["content"])
        else:
            # Display assistant response with SQL if available
            st.markdown(message["content"])
            if "sql" in message and message["sql"]:
                with st.expander("🔍 View Generated SQL"):
                    st.code(message["sql"], language="sql")

# Chat input
if prompt := st.chat_input("Ask a question about subscriber churn and engagement..."):
    # Add user message to chat history and display it
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)
    
    # Call Cortex Analyst API
    with st.chat_message("assistant"):
        with st.spinner("Analyzing your question..."):
            try:
                # Make REST API call to Cortex Analyst
                import requests
                import json
                
                # Get connection details from session
                conn = session.connection
                
                # Build REST API URL
                account_url = conn.host
                if not account_url.startswith('https://'):
                    account_url = f"https://{account_url}"
                
                api_url = f"{account_url}/api/v2/cortex/analyst/message"
                
                # Prepare request payload with semantic view
                payload = {
                    "messages": [
                        {
                            "role": "user",
                            "content": [
                                {
                                    "type": "text",
                                    "text": prompt
                                }
                            ]
                        }
                    ],
                    "semantic_view": "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_CUSTOMER_360"
                }
                
                # Get auth token from connection
                headers = {
                    "Authorization": f"Snowflake Token=\"{conn._rest._token_request()}\"",
                    "Content-Type": "application/json",
                    "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT"
                }
                
                # Send request
                response = requests.post(api_url, json=payload, headers=headers)
                
                if response.status_code == 200:
                    result = response.json()
                    
                    # Extract text response
                    message_content = result.get("message", {})
                    content_blocks = message_content.get("content", [])
                    
                    response_text = ""
                    generated_sql = ""
                    
                    for block in content_blocks:
                        if block.get("type") == "text":
                            response_text += block.get("text", "")
                        elif block.get("type") == "sql":
                            generated_sql = block.get("statement", "")
                    
                    # Display response
                    if response_text:
                        st.markdown(response_text)
                    else:
                        st.markdown("I found relevant information about your question.")
                    
                    # Show generated SQL
                    if generated_sql:
                        with st.expander("🔍 View Generated SQL"):
                            st.code(generated_sql, language="sql")
                        
                        # Execute the SQL to show results
                        try:
                            with st.expander("📊 Query Results", expanded=True):
                                result_df = session.sql(generated_sql).to_pandas()
                                if not result_df.empty:
                                    st.dataframe(result_df, use_container_width=True)
                                else:
                                    st.info("Query returned no results")
                        except Exception as e:
                            st.error(f"Could not execute query: {str(e)}")
                    
                    # Add to chat history
                    st.session_state.messages.append({
                        "role": "assistant",
                        "content": response_text if response_text else "Analysis complete.",
                        "sql": generated_sql
                    })
                    
                else:
                    error_msg = f"Sorry, I encountered an error (Status: {response.status_code})"
                    st.error(error_msg)
                    if response.text:
                        st.error(f"Details: {response.text}")
                    st.session_state.messages.append({
                        "role": "assistant",
                        "content": error_msg,
                        "sql": None
                    })
                    
            except Exception as e:
                error_msg = f"Sorry, I couldn't process your question: {str(e)}"
                st.error(error_msg)
                st.session_state.messages.append({
                    "role": "assistant",
                    "content": error_msg,
                    "sql": None
                })

# Reset conversation button
if st.session_state.messages:
    if st.button("🔄 Reset Conversation"):
        st.session_state.messages = []
        st.rerun()

# Footer
st.markdown("---")
st.markdown("""
**📚 Reference Implementation**  
This dashboard demonstrates production-grade architecture patterns. Review and customize for your specific requirements.

**🔄 Data Sources:**
- `V_CUSTOMER_360`: Unified customer view
- `FCT_CUSTOMER_HEALTH_SCORES`: ML churn predictions
- `FCT_ENGAGEMENT_DAILY`: Engagement metrics
- `SV_CUSTOMER_360`: Semantic view for Cortex Analyst

**⚙️ Technology:**
- Snowflake Streams (CDC)
- Snowflake Tasks (Automation)
- Cortex ML Classification (Predictions)
- Cortex Analyst (Conversational AI)
- Streamlit in Snowflake (UI)
""")

