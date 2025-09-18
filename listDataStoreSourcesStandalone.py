import urllib.request
import urllib.parse
import json
import ssl
import getpass
import sys

server = "server1000.usda.net:6443"
adminUser = "usda\\ethanbarker"
adminPass = getpass.getpass("Enter admin password: ")
outCSV = r"C:\temp\datastores.csv"

# Create unverified SSL context (temporary workaround for expired cert)
ssl_context = ssl._create_unverified_context()

print(f"Connecting to server: {server}")
print(f"Writing datastore results to: {outCSV}")

# --- Generate Token ---
url = f"https://{server}/arcgis/admin/generateToken"
params = {
    'username': adminUser,
    'password': adminPass,
    'expiration': '600',
    'client': 'requestip',
    'f': 'json'
}
encoded_params = urllib.parse.urlencode(params).encode('utf-8')

with urllib.request.urlopen(url, data=encoded_params, context=ssl_context) as response:
    token_response = json.loads(response.read().decode('utf-8'))

if "token" not in token_response:
    print(f"Token error: {token_response.get('messages', 'Unknown error')}")
    sys.exit(1)

token = token_response['token']

# --- Get Data Stores List ---
datastores_url = f"https://{server}/arcgis/admin/data/items?f=json&token={token}"
with urllib.request.urlopen(datastores_url, context=ssl_context) as response:
    datastore_list = json.loads(response.read().decode('utf-8'))

if datastore_list.get("status") == "error":
    raise RuntimeError(f"JSON error: {datastore_list}")

# --- Write CSV Header ---
with open(outCSV, 'w', newline='', encoding='utf-8') as f:
    f.write("ID,Type,Path,Info\n")

    # Loop through each datastore item
    for item in datastore_list.get("items", []):
        item_id = item.get("id", "N/A")
        item_type = item.get("type", "N/A")

        # Skip system-managed data stores (we only want user managed)
        if item_type.lower() in ["managed_database", "folder"]:
            continue

        # Get full datastore info
        item_url = f"https://{server}/arcgis/admin/data/items/{item_id}?f=json&token={token}"
        with urllib.request.urlopen(item_url, context=ssl_context) as response:
            item_detail = json.loads(response.read().decode('utf-8'))

        if item_detail.get("status") == "error":
            raise RuntimeError(f"JSON error: {item_detail}")

        path = item_detail.get("path", "N/A")
        info = json.dumps(item_detail.get("info", {}))

        f.write(f"{item_id},{item_type},{path},{info}\n")

print("Finished writing datastore inventory.")
