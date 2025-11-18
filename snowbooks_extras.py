import streamlit as st
import pandas as pd
from snowbook.executor import sql_executor
from snowbook.executor.sql_connector import ensure_session
import json
from functools import partial

def file_to_url(session, file_str):
    try:
        if file_str is None:
            return None
        file_obj = json.loads(file_str)
        stage = file_obj.get("STAGE") or file_obj.get("stage")
        rel_path = file_obj.get("RELATIVE_PATH") or file_obj.get("relative_path")
        url = session.sql(f"""select GET_PRESIGNED_URL('{stage}', '{rel_path}', 604800)""").collect()[0][0]
        return url
    except Exception as e:
        st.error(f"Error generating presigned URL: {e}")
        return None

if "patched" not in st.session_state:
    old_sql_statement = sql_executor.run_single_sql_statement
    
    def patched_run_single_sql_statement(*args, **kwargs):
        result = old_sql_statement(*args, **kwargs)
        
        result_df = result.query_scan_data_frame
        image_columns = {}
    
        for col, type in result_df.dtypes:
            if type == "file":
                image_columns[col] = st.column_config.ImageColumn()
        if image_columns:
            session = ensure_session()
            result_df_pd = result_df.to_pandas()
            for col in image_columns.keys():
                result_df_pd[col] = result_df_pd[col].apply(partial(file_to_url, session))
            st.dataframe(result_df_pd, column_config=image_columns, use_container_width=True, hide_index=True)
        else:
            return result
    
    sql_executor.run_single_sql_statement = patched_run_single_sql_statement
    st.session_state.patched = True
    st.success("✅ Snowbooks extras loaded - image rendering enabled")