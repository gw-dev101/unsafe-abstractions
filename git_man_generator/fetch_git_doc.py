import os
import urllib.request
import json
import time

API_URL = "https://api.github.com/repos/git/git/contents/Documentation"
OUTPUT_DIR = "git_docs"

def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "python"})
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode())

def download_file(url, path):
    req = urllib.request.Request(url, headers={"User-Agent": "python"})
    with urllib.request.urlopen(req) as response:
        content = response.read()

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(content)

def download_dir(api_url, output_dir):
    items = fetch_json(api_url)
    print(f"Found {len(items)} items in the repository.")
    for item in items:
        if item["type"] == "file":
            print(f"Downloading {item['path']}")
            download_file(item["download_url"], os.path.join(output_dir, item["name"]))
            #time.sleep(0.1)  # avoid hitting rate limits
            print("absolute path: " + os.path.abspath(os.path.join(output_dir, item["name"])))

        elif item["type"] == "dir":
            new_output = os.path.join(output_dir, item["name"])
            download_dir(item["url"], new_output)

def main():
    download_dir(API_URL, OUTPUT_DIR)
    #print one of the files to verify it was downloaded correctly
    #Documentation/user-manual.adoc
    with open(os.path.join(OUTPUT_DIR, "Documentation", "user-manual.adoc"), "r") as f:
        print(f.read(500))  # print the first 500 characters of the file
    print("Done.")

if __name__ == "__main__":
    main()
