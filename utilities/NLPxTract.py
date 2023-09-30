# Published thanks to https://github.com/deadbits
import os
import sys
import streamlit as st
import requests
import iocextract
from sumy.parsers.html import HtmlParser
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.lsa import LsaSummarizer as Summarizer
from sumy.nlp.stemmers import Stemmer
from sumy.utils import get_stop_words
import nltk

# Download 'punkt' if it's not already downloaded
try:
    nltk.data.find('tokenizers/punkt')
except LookupError:
    nltk.download('punkt')
    
LANGUAGE = "english"
SENTENCES_COUNT = 10

def get_website_text(url):
    html_content = None
    try:
        req = requests.get(url)
    except Exception as err:
        st.write(f'[error] failed to get url: {url}')
        pass

    if req.status_code == 200:
        html_content = req.text
    else:
        st.write(f'[error] non 200 status code: {req.status_code} - {url}')
        pass

    return html_content

def summarize_url(url):
    summary = []
    parser = HtmlParser.from_url(url, Tokenizer(LANGUAGE))
    stemmer = Stemmer(LANGUAGE)

    summarizer = Summarizer(stemmer)
    summarizer.stop_words = get_stop_words(LANGUAGE)

    for sentence in summarizer(parser.document, SENTENCES_COUNT):
        summary.append(str(sentence))

    return summary

def extract_iocs_from_text(content):
    indicators = {'ipv4': [], 'url': [], 'hash': []}

    for url in iocextract.extract_urls(content):
        indicators['url'].append(url)

    for file_hash in iocextract.extract_hashes(content):
        indicators['hash'].append(file_hash)

    for ip in iocextract.extract_ipv4s(content):
        indicators['ipv4'].append(ip)

    return indicators

def analyze_url():
    url = st.session_state.url
    text_summary = summarize_url(url)
    html_content = get_website_text(url)
    iocs = extract_iocs_from_text(html_content)
    result = {
        "summary": text_summary,
        "iocs": iocs,
    }
    st.session_state.history[url] = result

def save_as_markdown():
    selected_url = st.session_state.selected_url
    result = st.session_state.history[selected_url]
    with open(f"{selected_url.replace('/', '_')}.md", 'w') as f:
        f.write(f"# Summary for {selected_url}\n\n")
        f.write("\n".join(result["summary"]))
        f.write("\n\n# Indicators\n\n")
        f.write("\n".join(result["iocs"]["hash"]))

if 'history' not in st.session_state:
    st.session_state.history = {}

st.text_input("Enter a URL to analyze:", key='url')
st.button("Analyze", on_click=analyze_url)

st.session_state.selected_url = st.sidebar.selectbox("Select a URL to view", list(st.session_state.history.keys()), format_func=lambda x: x)

if st.session_state.selected_url:
    result = st.session_state.history[st.session_state.selected_url]

    st.write('[SUMMARY]')
    st.write("\n".join(result["summary"]))

    st.write('\n[INDICATORS]')
    st.write(result["iocs"]["hash"])

st.button("Save as Markdown", on_click=save_as_markdown)
