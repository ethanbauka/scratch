import arcpy
import urllib.request
import urllib.parse
import json
import sys
import os
import ssl
import getpass

server = "server1000.usda.net:6443"
adminUser = "usda\\ethanbarker"
adminPass = getpass.getpass("Enter admin password: ")
outCSV = r"C:\temp\output.csv"

# Create unverified SSL context (temporary workaround for expired cert)
ssl_context = ssl._create_unverified_context()

print(f"Connecting to server: {server}")
print(f"Writing results to: {outCSV}")

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

# --- Get Folder List ---
url = f"https://{server}/arcgis/admin/services?f=json&token={token}"
with urllib.request.urlopen(url, context=ssl_context) as response:
    folder_data = json.loads(response.read().decode('utf-8'))

folders = [f for f in folder_data.get("folders", []) if f not in ["System", "Utilities"]]

# --- Write Output CSV ---
with open(outCSV, 'w', newline='', encoding='utf-8') as serviceResultFile:
    serviceResultFile.write("Folder,ServiceName,Datasets,Database\n")

    for folder in folders:
        arcpy.AddMessage(f"Processing folder: {folder}")

        url = f"https://{server}/arcgis/admin/services/{folder}?f=json&token={token}"
        with urllib.request.urlopen(url, context=ssl_context) as response:
            service_data = json.loads(response.read().decode('utf-8'))

        if service_data.get("status") == "error":
            raise RuntimeError(f"JSON error: {service_data}")

        services = [f"{s['serviceName']}.{s['type']}" for s in service_data.get('services', [])]

        for service in services:
            arcpy.AddMessage(f"Processing service: {service}")
            quoted_service = urllib.parse.quote(service.encode('utf-8'))

            service_url = f"https://{server}/arcgis/admin/services/{folder}/{quoted_service}/iteminfo/manifest/manifest.json?token={token}&f=json"
            with urllib.request.urlopen(service_url, context=ssl_context) as response:
                jsonResponse = response.read().decode('utf-8')

            obj = json.loads(jsonResponse)

            if obj.get("status") == "error":
                raise RuntimeError(f"JSON error for service {service}: {obj}")

            for db in obj.get('databases', []):
                datasetNames = [ds['onServerName'] for ds in db.get('datasets', [])]
                db_conn = db.get('onServerConnectionString', 'N/A')
                serviceResultFile.write(f"{folder},{service},{'; '.join(datasetNames)},{db_conn}\n")

arcpy.AddMessage("Finished writing service inventory.")
print("Finished.")
