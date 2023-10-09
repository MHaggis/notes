import streamlit as st
import openai
import tiktoken
from loguru import logger
from unstructured.partition.html import partition_html
from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional, Dict
import streamlit_mermaid as stmd
from fpdf import FPDF
import os
import subprocess
import iocextract
from typing import List

intel_summary_prompt = """
You are responsible for summarizing a threat intelligence report for review by a security analyst.
Analyze the REPORT provided below and perform the following tasks:
  - Provide 3-5 key takeaways from REPORT in bullet format
  - Summarize the REPORT with detailed analysis in 1-3 paragraphs
  - Retain important context from REPORT including, but not limited to, threat actors, malware, tools, techniques, targeting, motivation, vulnerabilities
  - Extract all MITRE ATT&CK Tactics, Techniques, and Procedures from REPORT using the format:
      - <Tactic Name> - <Tactic ID> - <Technique ID> - <Technique Name>

Example MITRE ATT&CK TTPs:
Reconnaissance - TA0043 - T1595 - Active Scanning

REPORT
------
{document}
"""

mindmap_prompt_template = """
You are responsible for creating a Mermaid.js mindmap for a threat intelligence report. 
Analyze the REPORT provided below and perform the following tasks:
    - Create a mindmap for REPORT using the Mermaid.js mindmap syntax
    - Return ONLY the mindmap syntax and nothing else
    - Always include the "mindmap" keyword at the beginning of the mindmap syntax
    - The (root) node should be the name of the REPORT
    - The sub-nodes must include: (Threat Actors), (Malware), (Targets), (TTPs)
    - The sub-nodes must include the appropriate icon for each category
    - Use the example mindmap below as a reference

Example Mindmap
---------------
```
mindmap
root(Qakbot affiliate distributes ransomware)
    (Threat Actors)
      ::icon(fa fa-user-secret)
      (Qakbot affiliated actors)
    (Malware)
      ::icon(fa fa-virus)
      (Remcos backdoor)
      (Ransom Knight ransomware)
    (Targets)
      ::icon(fa fa-bullseye)
      (Italian-speaking users)
    (TTPs)
      ::icon(fa fa-project-diagram)
      (Phishing email)
      (LNK attachment)
      (Powershell)
```

REPORT
------
{document}
"""

class Indicators:
    def __init__(self, ips: List[str], urls: List[str], hashes: List[str]):
        self.ips = ips
        self.urls = urls
        self.hashes = hashes

class Document(BaseModel):
    text: str
    source: str
    metadata: Optional[Dict[str, str]] = Field(
        None,
        description="Optional metadata for the document"
    )

class Summary(BaseModel):
    summary: str
    source: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    metadata: Optional[Dict[str, str]] = Field(
        None,
        description="Optional metadata for the document"
    )

class Summarizer:
    def __init__(self, openai_api_key: str, model_name: str) -> None:
        openai.api_key = openai_api_key
        self.model_name = model_name
        self.encoding_name = 'cl100k_base'
        self.token_limit = st.text_input('Enter token limit:', '8192')
        if self.token_limit.isdigit():
            self.token_limit = int(self.token_limit)
        else:
            st.error('Token limit must be a number.')
            self.token_limit = 8192

        try:
            openai.Model.list()
        except Exception as err:
            logger.error(f'error connecting to openai: {err}')
            raise err

    def num_tokens(self, text: str) -> int:
        try:
            encoding = tiktoken.get_encoding(self.encoding_name)
            return len(encoding.encode(text))
        except Exception as err:
            logger.error(f'error retrieving encoding: {err}')
            return 0

    def call_openai(self, prompt: str) -> str:
        num_tokens = self.num_tokens(prompt)
        if num_tokens > self.token_limit:
            logger.error(f'(error) token limit exceeded (limit: {self.token_limit}, tokens: {num_tokens})')
            return None

        logger.info(f'token count: {num_tokens}')

        try:
            response = openai.ChatCompletion.create(
              model=self.model_name,
              messages=[
                    {
                        'role': 'system',
                        'content': 'You are a helpful AI cybersecurity assistant.'
                    },
                    {
                        'role': 'user',
                        'content': prompt
                    }
                ]
            )
            return response.choices[0].message['content']
        except Exception as err:
            logger.error(f'error summarizing text: {err}')
            return None

    def mindmap(self, doc: Document) -> str:
        logger.info('creating mindmap')
        prompt = mindmap_prompt_template.format(document=doc.text)
        mindmap = self.call_openai(prompt=prompt)
        return mindmap

    def summarize(self, doc: Document) -> str:
        logger.info('summarizing text')
        prompt = intel_summary_prompt.format(document=doc.text)
        summary = self.call_openai(prompt=prompt)
        return Summary(source=doc.source, summary=summary)


def get_page_content(url: str) -> str:
    logger.info(f'retrieving html from {url}')
    try:
        elements = partition_html(url=url)
    except Exception as err:
        logger.error(f'error retrieving html: {url} - {err}')
        return None
    content = '\n'.join([elem.text for elem in elements])
    doc = Document(source=url, text=content)
    return doc

def process_report_url(url, summarizer):
    doc = get_page_content(url=url)
    if doc is None:
        return None, None
    iocs = extract_iocs(doc.text)
    # do something with the extracted IOCs...
    try:
        summ = summarizer.summarize(doc=doc)
        if summ is None:
            st.error("Failed to generate summary.")
            return None, None
    except Exception as e:
        st.error(f"Failed to generate summary: {str(e)}")
        return None, None
    mindmap = summarizer.mindmap(doc=doc)
    mindmap = mindmap.replace("```", '')
    # Add a subsection for the extracted indicators
    st.subheader("Indicators:")
    st.write(f"IPs: {', '.join(iocs.ips)}")
    st.write(f"URLs: {', '.join(iocs.urls)}")
    st.write(f"Hashes: {', '.join(iocs.hashes)}")
    return summ, mindmap

def create_pdf(summ, mindmap, url):
    # Convert the Mermaid code to an image using mermaid-cli (mmdc)
    with open('temp.mmd', 'w') as f:
        f.write(mindmap)
    subprocess.run(['mmdc', '-i', 'temp.mmd', '-o', 'mindmap.png'])
    os.remove('temp.mmd')

    # Create the PDF and add the text
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size = 15)
    pdf.cell(200, 10, txt = f"URL: {url}", ln = True, align = 'C')
    pdf.cell(200, 10, txt = "Summary:", ln = True, align = 'C')
    pdf.multi_cell(0, 10, txt = summ.summary)

    # Add a new page for the mindmap image
    pdf.add_page()

    # Add the mindmap image
    pdf.image('mindmap.png', x = 10, y = 10, w = 190)

    # Save the PDF
    pdf.output("summary.pdf")

    # Save the mindmap image
    os.rename('mindmap.png', 'mindmap_image.png')

def update_iocs(iocs, ext_func, content, defang=False):
    if ext_func == iocextract.extract_urls:
        for ioc in ext_func(content, defang=defang):
            if ioc not in iocs:
                iocs.append(ioc)
    else:
        for ioc in ext_func(content):
            if ioc not in iocs:
                iocs.append(ioc)


def extract_iocs(content: str):
    iocs = Indicators(
        ips=[],
        urls=[],
        hashes=[]
    )

    update_iocs(iocs.ips, iocextract.extract_ipv4s, content)
    update_iocs(iocs.urls, iocextract.extract_urls, content, defang=True)
    update_iocs(iocs.hashes, iocextract.extract_hashes, content)

    return iocs

def main():
    st.title("Intel Summarizer")
    openai_key = st.text_input("Enter OpenAI API Key:", type="password")
    url = st.text_input("Enter URL to summarize:")
    model = st.selectbox("Select GPT Model:", [
        "gpt-3.5-turbo",
        "gpt-3.5-turbo-0301",
        "gpt-3.5-turbo-0613",
        "gpt-3.5-turbo-16k",
        "gpt-3.5-turbo-16k-0613",
        "gpt-3.5-turbo-instruct",
        "gpt-3.5-turbo-instruct-0914",
        "gpt-4",
        "gpt-4-0314",
        "gpt-4-0613"
    ])
    if openai_key and url and model:
        try:
            summarizer = Summarizer(openai_api_key=openai_key, model_name=model)
            summ, mindmap = process_report_url(url, summarizer)
            st.subheader("Summary:")
            st.write(summ.summary)
            st.subheader("Mindmap:")
            # Allow user to edit the Mermaid code:
            mindmap = st.text_area("Edit the Mermaid code as needed:", mindmap)
            # Display the mermaid diagram:
            stmd.st_mermaid(mindmap)
            st.success("Processing Completed Successfully!")
            if st.button('Generate PDF and Mindmap Image'):
                create_pdf(summ, mindmap, url)  # pass url as the third argument
                # Add a download button for the mindmap image
                if os.path.exists('mindmap_image.png'):
                    with open('mindmap_image.png', 'rb') as f:
                        btn = st.download_button(
                            label="Download Mindmap Image",
                            data=f.read(),
                            file_name='mindmap_image.png',
                            mime='image/png',
                        )
                # Add a download button for the PDF
                if os.path.exists('summary.pdf'):
                    with open('summary.pdf', 'rb') as f:
                        btn = st.download_button(
                            label="Download Summary PDF",
                            data=f.read(),
                            file_name='summary.pdf',
                            mime='application/pdf',
                        )
        except Exception as e:
            st.error(f"Failed to process URL: {str(e)}")
    else:
        st.warning("Please enter OpenAI API key, URL and select a GPT model to proceed.")
        
if __name__ == "__main__":
    main()