import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
import io
import yaml
from datetime import date 
import uuid
import json

# Load the CSV data
@st.cache_data
def load_data(file):
    df = pd.read_csv(file)
    df['Created'] = pd.to_datetime(df['Created'])  # Ensure 'Created' is datetime type
    return df

# Search Function
def search_dataframe(df, query):
    query = query.lower()
    return df[df.apply(lambda row: row.astype(str).str.lower().str.contains(query).any(), axis=1)]

def new_loldriver_page():

    def create_yaml_template():
        template = {
            'Id': '',
            'Author': '',
            'Created': '',
            'MitreID': '',
            'Category': '',
            'Verified': '',
            'Commands': {
                'Command': '',
                'Description': '',
                'Usecase': '',
                'Privileges': '',
                'OperatingSystem': '',
            },
            'Resources': [''],
            'Acknowledgement': {
                'Person': '',
                'Handle': '',
            },
            'Detection': [],
            'KnownVulnerableSamples': [
                {
                    'Filename': '',
                    'MD5': '',
                    'SHA1': '',
                    'SHA256': '',
                    'Signature': '',
                    'Date': '',
                    'Publisher': '',
                    'Company': '',
                    'Description': '',
                    'Product': '',
                    'ProductVersion': '',
                    'FileVersion': '',
                    'MachineType': '',
                    'OriginalFilename': '',
                },
            ],
            'Tags': [''],
        }
        return template

    st.title("Create a New LOLDriver")
    st.subheader('Create a new LOLDriver yaml file quick and easy. Fill in as much details as possible and click Generate.')


    verified_options = ['TRUE', 'FALSE']
    category_options = ['vulnerable driver', 'malicious']

    yaml_template = create_yaml_template()
    yaml_template['Tags'][0] = st.text_input("Name", yaml_template['Tags'][0])
    yaml_template['Author'] = st.text_input("Author", yaml_template['Author'])
    yaml_template['Created'] = st.text_input("Created", date.today().strftime('%Y-%m-%d'))
    yaml_template['MitreID'] = st.text_input("MitreID", "T1068")
    yaml_template['Category'] = st.selectbox("Category", category_options, index=0)
    yaml_template['Verified'] = st.selectbox("Verified", verified_options, index=1)

    updated_command = f'sc.exe create {yaml_template["Tags"][0]} binPath=C:\\windows\\temp\\{yaml_template["Tags"][0]} type=kernel && sc.exe start {yaml_template["Tags"][0]}'
    yaml_template['Commands']['Command'] = st.text_area("Command", updated_command)
    yaml_template['Commands']['Description'] = st.text_area("Description", yaml_template['Commands']['Description'])
    yaml_template['Commands']['Usecase'] = st.text_input("Usecase", "Elevate privileges")
    yaml_template['Commands']['Privileges'] = st.text_input("Privileges", "kernel")
    yaml_template['Commands']['OperatingSystem'] = st.text_input("OperatingSystem", "Windows 10")
    yaml_template['Resources'][0] = st.text_input("Resources", yaml_template['Resources'][0])
    st.text('Binary Metadata')
    yaml_template['KnownVulnerableSamples'][0]['MD5'] = st.text_input("MD5", yaml_template['KnownVulnerableSamples'][0]['MD5'])
    yaml_template['KnownVulnerableSamples'][0]['SHA1'] = st.text_input("SHA1", yaml_template['KnownVulnerableSamples'][0]['SHA1'])
    yaml_template['KnownVulnerableSamples'][0]['SHA256'] = st.text_input("SHA256", yaml_template['KnownVulnerableSamples'][0]['SHA256'])

    if st.button("Generate"):
        yaml_template['Id'] = str(uuid.uuid4())
        generated_yaml = yaml.dump(yaml_template, sort_keys=False) 
        st.code(generated_yaml, language="yaml")

def csv_viewer_and_searcher():
    st.title("CSV Viewer and Searcher")

    uploaded_file = st.file_uploader("Choose a CSV file", type="csv")
    if uploaded_file is not None:
        df = load_data(uploaded_file)

        # Search
        query = st.text_input('Search Query', '')
        if query:
            search_df = search_dataframe(df.copy(), query)
        else:
            search_df = df.copy()

        # Generate clickable links
        search_df['Id'] = search_df['Id'].apply(lambda id: f'https://www.loldrivers.io/drivers/{id}/')

        st.write(search_df, unsafe_allow_html=True)

        # Top 10 list for 'KnownVulnerableSample_Company' and 'Publisher'
        col1, col2, col3 = st.columns(3)

        with col1:
            st.header('Top 10 Company')
            st.write(df['KnownVulnerableSamples_Company'].value_counts().head(10))

        with col2:
            st.header('Top 10 Publisher')
            st.write(df['KnownVulnerableSamples_Publisher'].value_counts().head(10))
            
        with col3:
            st.header('Top 10 Description')
            st.write(df['KnownVulnerableSamples_Description'].value_counts().head(10))

        # Time series plot of contributions over time
        st.header('Contributions over time')
        contributions = df.resample('M', on='Created').size()  # Resample to monthly frequency
        contributions.plot(kind='line')
        plt.ylabel('Number of contributions')
        st.pyplot(plt)

    else:
        st.write("Please upload a file.")

@st.cache_data
def load_json(file):
    with open(file) as f:
        data = json.load(f)
    return data

# Function to flatten json
def flatten_json(y):
    out = {}

    def flatten(x, name=''):
        if type(x) is dict:
            for a in x:
                flatten(x[a], name + a + '_')
        elif type(x) is list:
            i = 0
            for a in x:
                flatten(a, name + str(i) + '_')
                i += 1
        else:
            out[name[:-1]] = x

    flatten(y)
    return out

# Convert to DataFrame
def json_to_df(data):
    flat_data = [flatten_json(d) for d in data]
    df = pd.DataFrame(flat_data)
    return df

def json_viewer_and_searcher():
    st.title("JSON Viewer and Searcher")

    uploaded_file = st.file_uploader("Choose a JSON file", type="json")
    if uploaded_file is not None:
        data = json.load(uploaded_file)
        df = json_to_df(data)

        query = st.text_input('Search Query', '')
        if query:
            search_df = search_dataframe(df.copy(), query)
            st.dataframe(search_df)
        else:
            st.write("Please enter a search term.")
    else:
        st.write("Please upload a file.")

def main():
    st.set_page_config(page_title="LOLDriver")

    pages = {
        "Create a New LOLDriver": new_loldriver_page,
        "CSV Viewer and Searcher": csv_viewer_and_searcher,
        "JSON Viewer and Searcher": json_viewer_and_searcher
    }

    st.sidebar.title("Navigation")
    page = st.sidebar.radio("Go to", list(pages.keys()))

    pages[page]()

if __name__ == "__main__":
    main()
