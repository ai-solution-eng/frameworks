import random
import streamlit as st

st.set_page_config(page_title="Toy Streamlit App", page_icon="✨", layout="centered")

st.title("Toy Streamlit App")
st.write("This Streamlit preview is running inside the **opencode-web** pod.")

if "count" not in st.session_state:
    st.session_state.count = 0

if st.button("Increment counter"):
    st.session_state.count += 1

st.metric("Counter", st.session_state.count)
st.caption(f"Random preview token: {random.randint(1000, 9999)}")