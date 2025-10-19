#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os

"""
Web Crawler Script

Description:
This script crawls a website starting from a given URL to find all navigable internal links.
It takes a base URL and an output file path as command-line arguments. The script will
explore the website, following only the links that belong to the same domain, and will
save the list of unique internal URLs found into the specified output file.

Author: Gemini Code Assist
Date: 2023-10-27

Usage:
python crawl_site.py --url <website_url> --output <output_file_path> [--workers <num_workers>] [--raw-output <output_pdf_path>] [--pdf-dir <pdf_save_directory>]

Example:
python crawl_site.py --url http://example.com --output links.txt --workers 15 --raw-output content.pdf --pdf-dir ./downloaded_pdfs
"""

import argparse
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse, urlunparse
from collections import deque
import concurrent.futures
import threading
import io

try:
    from fpdf import FPDF
    from pypdf import PdfWriter, PdfReader
    PDF_LIBS_INSTALLED = True
except ImportError:
    PDF_LIBS_INSTALLED = False

def crawl_website(base_url, output_file, num_workers, raw_output_file, pdf_dir):
    """
    Crawls a website to find all internal links.

    Args:
        base_url (str): The starting URL of the website to crawl.
        output_file (str): The path to the file where the found URLs will be saved.
        num_workers (int): The number of parallel worker threads to use.
        raw_output_file (str, optional): The path to the output PDF file to save all raw content.
        pdf_dir (str, optional): The directory where to save found PDF files independently.
    """
    if raw_output_file and not PDF_LIBS_INSTALLED:
        print("[!] PDF libraries not found. Please run: pip install fpdf2 pypdf")
        return

    # Get the domain of the base URL to ensure we only crawl internal links
    domain_name = urlparse(base_url).netloc

    # --- Setup output files ---
    raw_text_output_file = None
    if raw_output_file:
        # Create a path for the .txt file from the raw_output name (e.g., report.pdf -> report.txt)
        raw_text_output_file = os.path.splitext(raw_output_file)[0] + '.txt'
        open(raw_text_output_file, 'w').close() # Clear the file at the start

    # Create PDF output directory if it doesn't exist
    if pdf_dir:
        os.makedirs(pdf_dir, exist_ok=True)
        print(f"[*] PDF files will be saved in: {pdf_dir}")

    # Use a deque for an efficient queue of URLs to visit
    # This set will store all unique internal links found and also track visited URLs.
    # It's initialized with the base URL.
    internal_urls = set([base_url])
    # A queue for URLs to be processed by the threads.
    urls_to_crawl = deque([base_url])
    # A lock is necessary to safely modify shared data structures from multiple threads
    lock = threading.Lock()
    # A list to store the content for the raw PDF output
    content_for_pdf = []
    print(f"[*] Starting crawl at: {base_url}")

    # --- Sitemap Parsing ---
    # Attempt to find and parse the sitemap.xml file to quickly discover URLs.
    sitemap_url = urljoin(base_url, "/sitemap.xml")
    print(f"[*] Checking for sitemap at: {sitemap_url}")
    try:
        sitemap_response = requests.get(sitemap_url, timeout=5)
        # Process the sitemap only if the request was successful
        if sitemap_response.status_code == 200:
            # Use the 'xml' parser for sitemap files
            sitemap_soup = BeautifulSoup(sitemap_response.content, "xml")
            # Find all <loc> tags which contain the URLs
            locations = sitemap_soup.find_all("loc")
            sitemap_urls_found = 0
            for loc in locations:
                url = loc.get_text()
                # Ensure the URL is valid and belongs to the same domain
                if url and urlparse(url).netloc == domain_name and url not in internal_urls:
                    internal_urls.add(url)
                    # We add to the crawl queue, but not to internal_urls again inside the worker
                    urls_to_crawl.append(url)
                    sitemap_urls_found += 1
            if sitemap_urls_found > 0:
                print(f"[*] Found {sitemap_urls_found} new URLs in sitemap.xml")
    except requests.exceptions.RequestException as e:
        print(f"[-] Could not fetch or process sitemap.xml: {e}")

    def process_url(url):
        """
        Worker function to process a single URL.
        It fetches the page, parses it, and adds new internal links to the shared queue.
        If raw output is requested, it returns the content.
        """
        try:
            print(f"    -> Crawling: {url}")
            # Send an HTTP GET request to the URL
            response = requests.get(url, timeout=10)
            response.raise_for_status()  # Raise an exception for bad status codes (4xx or 5xx)
            content_type = response.headers.get('Content-Type', '').split(';')[0]

            # --- Content Processing and Saving ---
            if 'text/html' in content_type:
                soup = BeautifulSoup(response.text, 'html.parser')
                # If a text output file is specified, save content immediately
                if raw_text_output_file:
                    for script_or_style in soup(["script", "style"]):
                        script_or_style.decompose()
                    text_content = soup.get_text(separator='\n', strip=True)
                    with lock:
                        with open(raw_text_output_file, 'a', encoding='utf-8') as f:
                            f.write(f"--- Content from: {url} ---\n\n")
                            f.write(text_content)
                            f.write("\n\n")
                # If a global PDF report is requested, also add the text content for it
                if raw_output_file:
                    with lock:
                        content_for_pdf.append({'url': url, 'type': content_type, 'data': soup.get_text(separator='\n', strip=True)})

            elif 'image/' in content_type and raw_output_file:
                with lock:
                    content_for_pdf.append({'url': url, 'type': content_type, 'data': response.content})
            
            elif 'application/pdf' in content_type:
                    if pdf_dir:
                        # Save PDF independently if a directory is provided
                        pdf_filename = os.path.basename(urlparse(url).path)
                        if not pdf_filename:
                            pdf_filename = f"downloaded_{hash(url)}.pdf"
                        save_path = os.path.join(pdf_dir, pdf_filename)
                        with open(save_path, 'wb') as f:
                            f.write(response.content)
                        print(f"    -> Saved PDF: {save_path}")
                    # If a global PDF report is also requested (and not saving independently), queue it
                    elif raw_output_file:
                        with lock:
                            content_for_pdf.append({'url': url, 'type': content_type, 'data': response.content})

            # Only parse for more links if the content is HTML
            if 'text/html' not in content_type:
                return

            # Parse the HTML content of the page
            soup = BeautifulSoup(response.text, 'html.parser')

            # --- Link Discovery ---
            # Find all potential links: <a> tags with 'href' and <embed> tags with 'src'
            links_to_check = []
            for a_tag in soup.find_all('a', href=True):
                links_to_check.append(a_tag.get('href'))
            
            for embed_tag in soup.find_all('embed', src=True):
                if embed_tag.get('type') == 'application/pdf':
                    links_to_check.append(embed_tag.get('src'))

            for link in links_to_check:
                # Join the found href with the base URL to create an absolute URL
                absolute_url = urljoin(base_url, link)

                # --- Anchor/Fragment Filtering ---
                # Remove the fragment part (anything after '#') to avoid crawling the same page multiple times.
                parsed_url_obj = urlparse(absolute_url)
                absolute_url = urlunparse(parsed_url_obj._replace(fragment=""))

                # Ensure the link belongs to the same domain
                if urlparse(absolute_url).netloc == domain_name:
                    # Use a lock for thread-safe access to shared sets
                    with lock:
                        if absolute_url not in internal_urls:
                            # Add any new internal link (HTML, PDF, etc.) to the results
                            internal_urls.add(absolute_url)
                            # Only add non-PDF links to the crawl queue
                            if not absolute_url.lower().endswith('.pdf'):
                                urls_to_crawl.append(absolute_url)

        except requests.exceptions.RequestException as e:
            # Handle network-related errors (e.g., connection error, timeout)
            print(f"[!] Error processing {url}: {e}")
        except Exception as e:
            # Handle other potential errors
            print(f"[!] An unexpected error occurred at {url}: {e}")

    # Use a ThreadPoolExecutor to process URLs in parallel
    with concurrent.futures.ThreadPoolExecutor(max_workers=num_workers) as executor:
        # A set to keep track of futures that are currently running or finished
        futures = {executor.submit(process_url, base_url)}

        while futures:
            # Wait for the next future to complete
            done, futures = concurrent.futures.wait(
                futures, return_when=concurrent.futures.FIRST_COMPLETED
            )

            # Process any new URLs that were discovered by the completed tasks
            with lock:
                while urls_to_crawl:
                    url = urls_to_crawl.popleft()
                    futures.add(executor.submit(process_url, url))

    # --- PDF Generation ---
    if raw_output_file:
        print(f"\n[*] Generating main PDF report at: {raw_output_file}")
        generate_pdf_report(raw_output_file, content_for_pdf, base_url)

    # Write the found internal URLs to the output file
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            for url in sorted(list(internal_urls)):
                f.write(f"{url}\n")
        print(f"\n[*] Crawl finished. Found {len(internal_urls)} unique internal URLs.")
        print(f"[*] Results saved to: {output_file}")
    except IOError as e:
        print(f"[!] Error writing to file {output_file}: {e}")

def generate_pdf_report(output_path, content_list, base_url):
    """
    Generates a single PDF file from the collected content.

    Args:
        output_path (str): The path for the output PDF file.
        content_list (list): A list of dictionaries, each containing URL, content type, and data.
        base_url (str): The base URL, used for the title.
    """
    merger = PdfWriter()
    
    # Create a main PDF for text and images
    text_pdf = FPDF()
    text_pdf.set_auto_page_break(auto=True, margin=15)
    text_pdf.add_page()
    text_pdf.set_font("Arial", 'B', 16)
    text_pdf.cell(0, 10, f"Crawl Report for: {base_url}", 0, 1, 'C')
    text_pdf.ln(10)

    # Sort content by URL for a consistent order
    sorted_content = sorted(content_list, key=lambda x: x['url'])

    for content in sorted_content:
        url = content['url']
        content_type = content['type']
        data = content['data']

        if 'text/html' in content_type:
            text_pdf.set_font("Arial", 'B', 12)
            text_pdf.cell(0, 10, f"Content from: {url}", 0, 1)
            text_pdf.set_font("Arial", '', 10)
            # FPDF needs latin-1 encoding, we encode and ignore errors
            text_pdf.multi_cell(0, 5, data.encode('latin-1', 'replace').decode('latin-1'))
            text_pdf.add_page()
        elif 'image/' in content_type:
            text_pdf.set_font("Arial", 'B', 12)
            text_pdf.cell(0, 10, f"Image from: {url}", 0, 1)
            try:
                text_pdf.image(io.BytesIO(data), w=180) # width 180mm
                text_pdf.add_page()
            except Exception as e:
                print(f"    - Could not add image {url} to PDF: {e}")
        elif 'application/pdf' in content_type:
            try:
                # For found PDFs (not saved independently), add them to the merger
                pdf_stream = io.BytesIO(data)
                merger.append(PdfReader(pdf_stream))
                print(f"    - Queued PDF {url} for merging.")
            except Exception as e:
                print(f"    - Could not process PDF from {url}: {e}")

    # Save the text/image PDF to a temporary in-memory file.
    # fpdf2.output() returns a bytearray, which doesn't need encoding.
    text_pdf_bytes = text_pdf.output()
    if not text_pdf_bytes:
        return # Avoid errors if the PDF is empty
    merger.insert_page(PdfReader(io.BytesIO(text_pdf_bytes)).pages[0], 0) # Add title page at the beginning
    merger.append(PdfReader(io.BytesIO(text_pdf_bytes)))

    # Write the final merged PDF
    merger.write(output_path)
    merger.close()
    print(f"[*] PDF report generation complete.")

if __name__ == "__main__":
    # Set up the command-line argument parser
    parser = argparse.ArgumentParser(description="A simple web crawler to find all internal links on a website.")
    
    # Define the required arguments
    parser.add_argument("--url", required=True, help="The base URL of the website to crawl.")
    parser.add_argument("--output", required=True, help="The path to the output file to save the links.")
    parser.add_argument("--workers", type=int, default=10, help="The number of parallel worker threads to use for crawling. Default is 10.")
    parser.add_argument("--raw-output", help="Optional. Path to a single PDF file to store all crawled content (text, images, PDFs).")
    parser.add_argument("--pdf-dir", help="Optional. Directory to save all found PDF files independently.")

    # Parse the arguments from the command line
    args = parser.parse_args()

    # Call the main crawling function
    crawl_website(args.url, args.output, args.workers, args.raw_output, args.pdf_dir)
