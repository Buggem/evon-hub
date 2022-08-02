
#################################
# EVON API Client
#################################

import base64
import json
import logging
import os

import requests

from evon import log


logger = log.get_evon_logger()
EVON_DEBUG = os.environ.get('EVON_DEBUG', '').upper() == "TRUE"
if EVON_DEBUG:
    logger.setLevel(logging.DEBUG)
API_URL = os.environ.get("EVON_API_URL")


def generate_headers(api_key):
    response = requests.get("http://169.254.169.254/latest/dynamic/instance-identity/document")
    iid = base64.b64encode(response.text.encode("utf-8"))
    response = requests.get("http://169.254.169.254/latest/dynamic/instance-identity/signature")
    iid_signature = response.text.replace("\n", "")
    headers = {
        "Content-Type": "application/json",
        "X-API-Key": api_key,
        "document": iid,
        "signature": iid_signature
    }
    logger.debug(f"headers are: {headers}")
    return headers


def get_pub_ipv4():
    response = requests.get("http://169.254.169.254/latest/meta-data/public-ipv4")
    return response.text


def do_request(url, requests_method, headers, json_payload=None):
    request_kwargs = {
        "headers": headers,
    }
    if json_payload:
        request_kwargs["data"] = json_payload.encode("utf-8")
    try:
        response = requests_method(url, **request_kwargs)
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        logger.error(f"{requests_method.__name__.upper()} request failed: '{e}' ")
    return response


def get_records(api_url, api_key):
    url = f"{api_url}/zone/records"
    response = do_request(url, requests.get, headers=generate_headers(api_key))
    records = json.dumps(json.loads(response.text), indent=2)
    return records


def set_records(api_url, api_key, json_payload):
    url = f"{api_url}/zone/records"
    response = do_request(url, requests.put, headers=generate_headers(api_key), json_payload=json_payload)
    return response.text
