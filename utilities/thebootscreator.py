import streamlit as st
import yaml
from datetime import date
import uuid

def new_bootloader_page():
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
                'OperatingSystem': '',
                'Privileges': '',
                'Usecase': ''
            },
            'Resources': [''],
            'Acknowledgement': {
                'Person': '',
                'Handle': '',
            },
            'Detection': [{'type': '', 'value': ''}],
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

    st.title("Create a New Bootloader")
    st.subheader('Create a new Bootloader yaml file quick and easy. Fill in as much details as possible and click Generate.')

    verified_options = ['TRUE', 'FALSE']
    category_options = ['Revoked Bootloaders', 'Malicious']

    yaml_template = create_yaml_template()
    yaml_template['Tags'][0] = st.text_input("Name", yaml_template['Tags'][0])
    yaml_template['Author'] = st.text_input("Author", yaml_template['Author'])
    yaml_template['Created'] = st.text_input("Created", date.today().strftime('%Y-%m-%d'))
    yaml_template['MitreID'] = st.text_input("MitreID", "T1542")
    yaml_template['Category'] = st.selectbox("Category", category_options, index=0)
    yaml_template['Verified'] = st.selectbox("Verified", verified_options, index=1)

    updated_command = f'bcdedit /copy "{{current}}" /d "TheBoots" | {{% if ($_ -match \'{{\\S+}}\') {{ bcdedit /set $matches[0] path \\windows\\temp\{yaml_template["Tags"][0]} }} }}'
    yaml_template['Commands']['Command'] = st.text_area("Command", updated_command)
    yaml_template['Commands']['Description'] = st.text_area("Description", yaml_template['Commands']['Description'])
    yaml_template['Commands']['Usecase'] = st.text_input("Usecase", "Persistence")
    yaml_template['Commands']['Privileges'] = st.text_input("Privileges", "System")
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

def main():
    st.set_page_config(page_title="Bootloaders")

    pages = {
        "Create a New Bootloader": new_bootloader_page,
    }

    st.sidebar.title("Navigation")
    page = st.sidebar.radio("Go to", list(pages.keys()))

    pages[page]()

if __name__ == "__main__":
    main()
