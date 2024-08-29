"""
Description: This script sets up a simple HTTP server and creates test scripts to be executed via curl or wget with | bash.
Author: Michael Haag (Twitter: @m_haggis)
"""

import os
import subprocess
import threading
import http.server
import socketserver
import gzip
import time
import sys
from typing import List, Tuple
import shutil

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
RESET = '\033[0m'

def print_ascii_art():
    art = """
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠠⢴⣶⣿⣯⣉⣉⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣇⣉⣉⣽⣿⣶⡦⠄⠀
⠀⢰⣤⡄⠈⢉⡉⠉⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠋⢉⣉⣁⣠⣤⡆⠀
⠀⢸⣿⡇⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀
⠀⢸⣿⡇⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀
⠀⠸⢿⡇⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠇⠀
⠀⠀⠀⣤⣀⠈⠉⠉⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠉⣉⣉⣁⣤⠀⠀⠀
⠀⠀⠀⣿⣿⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
⠀⠀⠀⣿⣿⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
⠀⠀⠀⣿⣿⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
⠀⠀⠀⣿⣿⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
⠀⠀⠀⣿⣿⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
⠀⠀⠀⠛⠛⠀⠀⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠀⠀⠀
    """
    print(art)

def write_test_script():
    try:
        script_content = '#!/bin/bash\necho "This script was executed successfully via curl | bash"'
        
        with open('test_script.sh', 'w') as f:
            f.write(script_content)
        os.chmod('test_script.sh', 0o755)
        
        with gzip.open('test_script.sh.gz', 'wt') as f:
            f.write(script_content)
        print("Test scripts created successfully.")
    except Exception as e:
        print(f"Error creating test scripts: {e}")
        sys.exit(1)

def start_http_server():
    PORT = 8000
    Handler = http.server.SimpleHTTPRequestHandler
    try:
        with socketserver.TCPServer(("", PORT), Handler) as httpd:
            print(f"Serving at port {PORT}")
            httpd.serve_forever()
    except Exception as e:
        print(f"Error starting HTTP server: {e}")
        sys.exit(1)

def run_command(command: str) -> Tuple[bool, str]:
    try:
        process = subprocess.Popen(['bash', '-c', command], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        stdout, stderr = process.communicate(timeout=15)
        if process.returncode == 0:
            return True, stdout.strip() or "Command executed successfully, but produced no output."
        else:
            return False, f"Error (return code {process.returncode}): {stderr.strip() or stdout.strip() or 'No error message provided'}"
    except subprocess.TimeoutExpired:
        return False, "Error: Command timed out"
    except Exception as e:
        return False, f"Error: {str(e)}"

def generate_tests(url: str) -> List[str]:
    shells = ['bash', '/bin/bash', 'sh', '/bin/sh', 'zsh', '/bin/zsh', 'csh', '/bin/csh']
    available_shells = [shell for shell in shells if shutil.which(shell.split('/')[-1])]
    
    base_tests = [
        '{shell} -c "curl -s {url} | {shell}"',
        '{shell} -c "wget -qO- {url} | {shell}"',
        '{shell} -c "eval \"$(curl -s {url})\""',
        '{shell} -c "eval \"$(wget -qO- {url})\""',
    ]
    
    bash_specific_tests = [
        '{shell} -c "{shell} <(curl -s {url})"',
        '{shell} -c "{shell} <(wget -qO- {url})"',
        '{shell} -c \'{shell} <<< "$(curl -s {url})"\''  # Fixed here-string
        '{shell} -c \'{shell} <<< "$(wget -qO- {url})"\''  # Fixed here-string
        '{shell} -c "{shell} -c \'$(curl -s {url})\'"',
        '{shell} -c "{shell} -c \'$(wget -qO- {url})\'"',
        '{shell} -c "bash < <(curl -s {url})"',
        '{shell} -c "bash < <(wget -qO- {url})"',
    ]
    
    common_tests = [
        '{shell} -c "curl -s {url} -o /tmp/script.sh && chmod +x /tmp/script.sh && {shell} /tmp/script.sh && rm /tmp/script.sh"',
        '{shell} -c "wget -q {url} -O /tmp/script.sh && chmod +x /tmp/script.sh && {shell} /tmp/script.sh && rm /tmp/script.sh"',
        '{shell} -c "curl -s {url} | base64 | base64 -d | {shell}"',
        '{shell} -c "wget -qO- {url} | base64 | base64 -d | {shell}"',
        '{shell} -c "curl -s {url}.gz | gunzip | {shell}"',
        '{shell} -c "wget -qO- {url}.gz | gunzip | {shell}"',
        # Modified FIFO test to be more reliable
        '{shell} -c "curl -s {url} > /tmp/script.sh; {shell} /tmp/script.sh; rm /tmp/script.sh"',
        '{shell} -c "wget -qO- {url} > /tmp/script.sh; {shell} /tmp/script.sh; rm /tmp/script.sh"',
    ]
    
    tests = []
    for shell in available_shells:
        tests.extend([test.format(url=url, shell=shell) for test in base_tests])
        tests.extend([test.format(url=url, shell=shell) for test in common_tests])
        if 'bash' in shell or 'zsh' in shell:
            tests.extend([test.format(url=url, shell=shell) for test in bash_specific_tests])
    
    return tests

def run_tests(url: str) -> List[Tuple[bool, str]]:
    tests = generate_tests(url)
    results = []
    
    for i, test in enumerate(tests, 1):
        print(f"\nRunning test {i}:")
        print(f"Command: {test}")
        success, output = run_command(test)
        if success:
            print(f"{GREEN}PASSED{RESET}")
            print("Output:", output)
        else:
            print(f"{RED}FAILED{RESET}")
            print("Error:", output)
        results.append((success, test))
        time.sleep(1)
    
    return results

def print_summary(results: List[Tuple[bool, str]]):
    passed = sum(1 for success, _ in results if success)
    total = len(results)
    
    print("\n" + "="*50)
    print(f"Test Summary: {passed}/{total} passed")
    print("="*50)
    
    print("\nPassed tests:")
    for i, (success, test) in enumerate(results, 1):
        if success:
            print(f"{GREEN}{i}. {test}{RESET}")
    
    print("\nFailed tests:")
    for i, (success, test) in enumerate(results, 1):
        if not success:
            print(f"{RED}{i}. {test}{RESET}")

def main():
    write_test_script()
    server_thread = threading.Thread(target=start_http_server, daemon=True)
    server_thread.start()
    time.sleep(1)
    
    while True:
        try:
            print("\n1. Start HTTP Server (already running)")
            print("2. Run Tests (localhost)")
            print("3. Run Tests (remote URL)")
            print("4. Exit")
            choice = input("Enter your choice (1-4): ")
            
            if choice == '1':
                print("HTTP Server is already running.")
            elif choice == '2':
                results = run_tests("http://localhost:8000/test_script.sh")
                print_summary(results)
            elif choice == '3':
                remote_url = input("Enter the remote URL (e.g., http://example.com/script.sh): ")
                results = run_tests(remote_url)
                print_summary(results)
            elif choice == '4':
                print("Exiting...")
                break
            else:
                print("Invalid choice. Please try again.")
        except KeyboardInterrupt:
            print("\nProgram interrupted. Exiting...")
            break
        except Exception as e:
            print(f"An unexpected error occurred: {e}")
            print("Continuing...")

def cleanup():
    for file in ['/tmp/script.sh', '/tmp/pipe']:
        try:
            os.remove(file)
        except FileNotFoundError:
            pass
    
if __name__ == "__main__":
    print_ascii_art()
    try:
        main()
    finally:
        cleanup()
