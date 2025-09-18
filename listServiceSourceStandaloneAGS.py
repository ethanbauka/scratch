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

def main(server, adminUser, adminPass, outCSV):
    print(f"Connecting to server: {server}")
    print(f"Writing results to: {outCSV}")

    token = gentoken(server, adminUser, adminPass)
    folders = getFolderList(server, token)

    with open(outCSV, 'w', newline='', encoding='utf-8') as serviceResultFile:
        serviceResultFile.write("Folder,ServiceName,Datasets,Database\n")

        for folder in folders:
            arcpy.AddMessage(f"Processing folder: {folder}")
            services = getServiceList(server, folder, token)

            for service in services:
                arcpy.AddMessage(f"Processing service: {service}")
                quoted_service = urllib.parse.quote(service.encode('utf-8'))

                service_url = f"https://{server}/arcgis/admin/services/{folder}/{quoted_service}/iteminfo/manifest/manifest.json?token={token}&f=json"
                try:
                    with urllib.request.urlopen(service_url, context=ssl_context) as response:
                        jsonResponse = response.read().decode('utf-8')
                except Exception as e:
                    arcpy.AddError(f"Failed to fetch manifest for {service}: {e}")
                    continue

                if not assertJsonSuccess(jsonResponse):
                    arcpy.AddError(f"Error in JSON response for service: {service}")
                    continue

                obj = json.loads(jsonResponse)

                for db in obj.get('databases', []):
                    datasetNames = [ds['onServerName'] for ds in db.get('datasets', [])]
                    db_conn = db.get('onServerConnectionString', 'N/A')
                    serviceResultFile.write(f"{folder},{service},{'; '.join(datasetNames)},{db_conn}\n")

    arcpy.AddMessage("Finished writing service inventory.")
    print("Finished.")

def gentoken(server, adminUser, adminPass, expiration=600):
    url = f"https://{server}/arcgis/admin/generateToken"
    params = {
        'username': adminUser,
        'password': adminPass,
        'expiration': str(expiration),
        'client': 'requestip',
        'f': 'json'
    }

    encoded_params = urllib.parse.urlencode(params).encode('utf-8')
    try:
        with urllib.request.urlopen(url, data=encoded_params, context=ssl_context) as response:
            token_response = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Token generation failed: {e}")
        sys.exit(1)

    if "token" not in token_response:
        print(f"Token error: {token_response.get('messages', 'Unknown error')}")
        sys.exit(1)

    return token_response['token']

def getFolderList(server, token):
    url = f"https://{server}/arcgis/admin/services?f=json&token={token}"
    try:
        with urllib.request.urlopen(url, context=ssl_context) as response:
            folder_data = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        arcpy.AddError(f"Failed to get folder list: {e}")
        return []

    folders = folder_data.get("folders", [])
    return [f for f in folders if f not in ["System", "Utilities"]]

def getServiceList(server, folder, token):
    url = f"https://{server}/arcgis/admin/services/{folder}?f=json&token={token}"
    try:
        with urllib.request.urlopen(url, context=ssl_context) as response:
            service_data = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        arcpy.AddError(f"Failed to get service list for folder {folder}: {e}")
        return []

    if not assertJsonSuccess(json.dumps(service_data)):
        return []

    return [f"{s['serviceName']}.{s['type']}" for s in service_data.get('services', [])]

def assertJsonSuccess(data):
    try:
        obj = json.loads(data)
        if obj.get('status') == "error":
            arcpy.AddError(f"JSON error: {obj}")
            return False
        return True
    except json.JSONDecodeError:
        arcpy.AddError("Invalid JSON response.")
        return False

if __name__ == "__main__":
    sys.exit(main(server, adminUser, adminPass, outCSV))
