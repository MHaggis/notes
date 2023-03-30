import streamlit as st
import yaml
import collections
import os
import glob

def create_yaml_template():
    template = collections.OrderedDict([
        ('Name', ''),
        ('Author', ''),
        ('Created', ''),
        ('MitreID', ''),
        ('Category', ''),
        ('Verified', ''),
        ('Commands', collections.OrderedDict([
            ('Command', ''),
            ('Description', ''),
            ('Usecase', ''),
            ('Privileges', ''),
            ('OperatingSystem', ''),
        ])),
        ('Resources', ['']),
        ('driver_description', ''),
        ('Acknowledgement', collections.OrderedDict([
            ('Person', ''),
            ('Handle', ''),
        ])),
        ('Detection', []),
        ('KnownVulnerableSamples', collections.OrderedDict([
            ('Filename', ''),
            ('MD5', ''),
            ('SHA1', ''),
            ('SHA256', ''),
            ('Signature', ''),
            ('Date', ''),
            ('Publisher', ''),
            ('Company', ''),
            ('Description', ''),
            ('Product', ''),
            ('ProductVersion', ''),
            ('FileVersion', ''),
            ('MachineType', ''),
            ('OriginalFilename', ''),
        ])),
    ])
    return template

def represent_ordereddict(dumper, data):
    value_list = []
    for key, value in data.items():
        node_key = dumper.represent_data(key)
        node_value = dumper.represent_data(value)
        value_list.append((node_key, node_value))
    return yaml.nodes.MappingNode(u'tag:yaml.org,2002:map', value_list)


yaml.add_representer(collections.OrderedDict, represent_ordereddict)

def generate_yaml():
    yaml_template = create_yaml_template()
    
    for key in yaml_template:
        if isinstance(yaml_template[key], dict):
            for subkey in yaml_template[key]:
                yaml_template[key][subkey] = st.session_state[f"{key}_{subkey}"]
        elif isinstance(yaml_template[key], list):
            yaml_template[key] = st.session_state[key].split("\n")
        else:
            yaml_template[key] = st.session_state[key]

    return yaml.dump(yaml_template)

from datetime import date

def new_loldriver_page():
    st.title("Create a New LOLDriver")
    st.subheader('Create a new LOLDriver yaml file quick and easy. Fill in as much details as possible and click Generate.')


    # Define the dropdown options for Verified and Category fields
    verified_options = ['TRUE', 'FALSE']
    category_options = ['vulnerable driver', 'malicious']

    # Create the inputs
    yaml_template = create_yaml_template()
    yaml_template['Name'] = st.text_input("Driver Name", yaml_template['Name'])
    yaml_template['Author'] = st.text_input("Author", yaml_template['Author'])
    yaml_template['Created'] = st.text_input("Created", date.today().strftime('%Y-%m-%d'))
    yaml_template['MitreID'] = st.text_input("MitreID", "T1068")
    yaml_template['Category'] = st.selectbox("Category", category_options, index=0)
    yaml_template['Verified'] = st.selectbox("Verified", verified_options, index=1)

    # Update the Command field dynamically based on the Name field
    updated_command = f'sc.exe create {yaml_template["Name"]} binPath=C:\\windows\\temp\\{yaml_template["Name"]} type=kernel\n    sc.exe start {yaml_template["Name"]}'
    yaml_template['Commands']['Command'] = st.text_area("Command", updated_command)
    yaml_template['Commands']['Description'] = st.text_area("Description", yaml_template['Commands']['Description'])
    yaml_template['Commands']['Usecase'] = st.text_input("Usecase", "Elevate privileges")
    yaml_template['Commands']['Privileges'] = st.text_input("Privileges", "kernel")
    yaml_template['Commands']['OperatingSystem'] = st.text_input("OperatingSystem", "Windows 10")
    yaml_template['Resources'][0] = st.text_input("Resources", yaml_template['Resources'][0])
    st.text('Binary Metadata')
    yaml_template['KnownVulnerableSamples']['MD5'] = st.text_input("MD5", yaml_template['KnownVulnerableSamples']['MD5'])
    yaml_template['KnownVulnerableSamples']['SHA1'] = st.text_input("SHA1", yaml_template['KnownVulnerableSamples']['SHA1'])
    yaml_template['KnownVulnerableSamples']['SHA256'] = st.text_input("SHA256", yaml_template['KnownVulnerableSamples']['SHA256'])

    # When the user clicks the "Generate" button, display the generated YAML content
    if st.button("Generate"):
        generated_yaml = yaml.dump(yaml_template)
        st.code(generated_yaml, language="yaml")



def main():
    st.set_page_config(page_title="LOLDriver")
    

    pages = {
    "Create a New LOLDriver": new_loldriver_page,
    }

    st.sidebar.title("Navigation")
    page = st.sidebar.radio("Go to", list(pages.keys()))

    pages[page]()

if __name__ == "__main__":
    main()
