import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import plotly.express as px

# Page config
st.set_page_config(page_title="RNDC Sales Dashboard", page_icon="🥃", layout="wide")

# Get Snowflake session
session = get_active_session()

# Title
st.title("🥃 RNDC Analytics Dashboard")
st.markdown("### Liquor Distribution Analytics")

# Create tabs
tab1, tab2 = st.tabs(["📊 Sales Dashboard", "🎫 Support Analytics"])

# Load data
@st.cache_data
def load_sales_data():
    query = """
        SELECT 
            s.DATE,
            s.TOTAL_SALE_AMOUNT,
            s.CASE_QUANTITY,
            c.CUSTOMER_NAME,
            c.ACCOUNT_TYPE,
            c.SALES_TERRITORY,
            p.BRAND_NAME,
            p.CATEGORY
        FROM RNDC_LAB.TARGET.SALES s
        LEFT JOIN RNDC_LAB.TARGET.CUSTOMER c ON s.CUSTOMER_ID = c.CUSTOMER_ID
        LEFT JOIN RNDC_LAB.TARGET.PRODUCT p ON s.PRODUCT_SKU = p.PRODUCT_SKU
    """
    return session.sql(query).to_pandas()

# TAB 1: SALES DASHBOARD
with tab1:
    df = load_sales_data()
    df['DATE'] = pd.to_datetime(df['DATE'])

    # Sidebar filters
    st.sidebar.header("Filters")
    territories = ['All'] + sorted(df['SALES_TERRITORY'].unique().tolist())
    selected_territory = st.sidebar.selectbox("Territory", territories)

    if selected_territory != 'All':
        df = df[df['SALES_TERRITORY'] == selected_territory]

    # Key Metrics
    st.markdown("---")
    col1, col2, col3, col4 = st.columns(4)

    with col1:
        st.metric("💰 Total Revenue", f"${df['TOTAL_SALE_AMOUNT'].sum():,.0f}")

    with col2:
        st.metric("📦 Cases Sold", f"{df['CASE_QUANTITY'].sum():,}")

    with col3:
        st.metric("🏪 Customers", f"{df['CUSTOMER_NAME'].nunique()}")

    with col4:
        st.metric("📊 Avg Sale", f"${df['TOTAL_SALE_AMOUNT'].mean():,.0f}")

    # Charts
    st.markdown("---")

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Sales by Category")
        category_sales = df.groupby('CATEGORY')['TOTAL_SALE_AMOUNT'].sum().reset_index()
        category_sales = category_sales.sort_values('TOTAL_SALE_AMOUNT', ascending=False).head(10)
        fig = px.bar(category_sales, x='CATEGORY', y='TOTAL_SALE_AMOUNT', 
                     labels={'TOTAL_SALE_AMOUNT': 'Revenue', 'CATEGORY': 'Category'})
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("Top 10 Products")
        product_sales = df.groupby('BRAND_NAME')['TOTAL_SALE_AMOUNT'].sum().reset_index()
        product_sales = product_sales.sort_values('TOTAL_SALE_AMOUNT', ascending=False).head(10)
        product_sales = product_sales.sort_values('TOTAL_SALE_AMOUNT', ascending=True)  # Reverse for display
        fig = px.bar(product_sales, x='TOTAL_SALE_AMOUNT', y='BRAND_NAME', orientation='h',
                     labels={'TOTAL_SALE_AMOUNT': 'Revenue', 'BRAND_NAME': 'Brand'})
        st.plotly_chart(fig, use_container_width=True)

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Sales Over Time")
        daily_sales = df.groupby('DATE')['TOTAL_SALE_AMOUNT'].sum().reset_index()
        fig = px.line(daily_sales, x='DATE', y='TOTAL_SALE_AMOUNT',
                      labels={'TOTAL_SALE_AMOUNT': 'Revenue', 'DATE': 'Date'})
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("On-Premise vs Off-Premise")
        account_sales = df.groupby('ACCOUNT_TYPE')['TOTAL_SALE_AMOUNT'].sum().reset_index()
        fig = px.pie(account_sales, values='TOTAL_SALE_AMOUNT', names='ACCOUNT_TYPE', hole=0.4)
        st.plotly_chart(fig, use_container_width=True)

    # Recent Transactions
    st.markdown("---")
    st.subheader("Recent Transactions")
    recent = df.nlargest(10, 'DATE')[['DATE', 'CUSTOMER_NAME', 'BRAND_NAME', 'CASE_QUANTITY', 'TOTAL_SALE_AMOUNT']]
    recent['TOTAL_SALE_AMOUNT'] = recent['TOTAL_SALE_AMOUNT'].apply(lambda x: f"${x:,.2f}")
    st.dataframe(recent, use_container_width=True, hide_index=True)

# TAB 2: SUPPORT ANALYTICS (Class Exercise)
with tab2:
    st.info("🎓 **Class Exercise**: Build a Support Analytics dashboard here!")
    st.markdown("""
    ### Your Task:
    Create visualizations for the **SUPPORT_CASES** table. Consider showing:
    - Key metrics (total cases, open cases, avg resolution time, satisfaction score)
    - Cases by type (bar chart)
    - Cases by status (pie chart)
    - Cases over time (line chart)
    - Recent support cases (table)
    
    **Hint**: Use the same pattern as Tab 1, but query the `RNDC_LAB.TARGET.SUPPORT_CASES` table!
    """)
    
    # Placeholder for students to build
    st.write("Start coding here... 👇")
