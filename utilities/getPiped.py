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


def print_ascii_art():
    art = """
                    ######                         
 ####  ###### ##### #     # # #####  ###### #####  
#    # #        #   #     # # #    # #      #    # 
#      #####    #   ######  # #    # #####  #    # 
#  ### #        #   #       # #####  #      #    # 
#    # #        #   #       # #      #      #    # 
 ####  ######   #   #       # #      ###### #####  
    """
    print(art)

print_ascii_art()

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
RESET = '\033[0m'

def write_test_script():
    try:
        with open('test_script.sh', 'w') as f:
            f.write('#!/bin/bash\necho "This script was executed via curl | bash"')
        os.chmod('test_script.sh', 0o755)
        
        with gzip.open('test_script.sh.gz', 'wt') as f:
            f.write('#!/bin/bash\necho "This script was executed via curl | bash (gzipped)"')
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

def run_command(command):
    try:
        output = subprocess.check_output(command, shell=True, text=True, stderr=subprocess.STDOUT, timeout=15)
        return True, output.strip()
    except subprocess.CalledProcessError as e:
        return False, f"Error (return code {e.returncode}): {e.output.strip()}"
    except subprocess.TimeoutExpired:
        return False, "Error: Command timed out"
    except Exception as e:
        return False, f"Error: {str(e)}"

def run_tests(url):
    tests = [
        f'curl -s {url} | bash',
        f'curl -s {url} | sh',
        f'curl -s {url} | zsh',
        f'eval "$(curl -s {url})"',
        f'bash -c "bash <(curl -s {url})"',
        f'bash -c \'bash <<< "$(curl -s {url})"\'',
        f'curl -s {url} -o /tmp/script.sh && chmod +x /tmp/script.sh && bash /tmp/script.sh && rm /tmp/script.sh',
        f'curl -s {url} | base64 | base64 -d | bash',
        f'curl -s {url}.gz | gunzip | bash',
        f'bash -c "bash < <(curl -s {url})"',
        f'mkfifo /tmp/pipe && curl -s {url} > /tmp/pipe & bash /tmp/pipe; rm /tmp/pipe',
        f'bash -c "$(curl -s {url})"',
        
        f'wget -qO- {url} | bash',
        f'wget -qO- {url} | sh',
        f'wget -qO- {url} | zsh',
        f'eval "$(wget -qO- {url})"',
        f'bash -c "bash <(wget -qO- {url})"',
        f'bash -c \'bash <<< "$(wget -qO- {url})"\'',
        f'wget -q {url} -O /tmp/script.sh && chmod +x /tmp/script.sh && bash /tmp/script.sh && rm /tmp/script.sh',
        f'wget -qO- {url} | base64 | base64 -d | bash',
        f'wget -qO- {url}.gz | gunzip | bash',
        f'bash -c "bash < <(wget -qO- {url})"',
        f'mkfifo /tmp/pipe && wget -qO- {url} > /tmp/pipe & bash /tmp/pipe; rm /tmp/pipe',
        f'bash -c "$(wget -qO- {url})"',
    ]
    
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
        time.sleep(1)  # Small delay between tests
    
    return results

def print_summary(results):
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
    time.sleep(1)  # Give the server a moment to start
    
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
    try:
        os.remove('/tmp/script.sh')
    except FileNotFoundError:
        pass
    try:
        os.remove('/tmp/pipe')
    except FileNotFoundError:
        pass
    
if __name__ == "__main__":
    try:
        main()
    finally:
        cleanup()

