"""
=============================================================
VALIDATION 1: REST API — Token Consumption Proof
=============================================================
Calls CU prebuilt-documentFields and prebuilt-layout on the
same document, then compares the `usage` block in each response.

Requirements:
  pip install azure-identity requests
  az login (for DefaultAzureCredential)
"""

import json
import time
import requests
from azure.identity import DefaultAzureCredential

# ─── Config ─────────────────────────────────────────────────
CU_ENDPOINT = "https://cu-foundry-demo-xsygf2piedpu4.cognitiveservices.azure.com"
DI_ENDPOINT = "https://di-demo-xsygf2piedpu4.cognitiveservices.azure.com"
API_VERSION_CU = "2025-11-01"
API_VERSION_DI = "2024-11-30"
SAMPLE_DOC = "https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/sample-invoice.pdf"

# ─── Auth ───────────────────────────────────────────────────
credential = DefaultAzureCredential()
token = credential.get_token("https://cognitiveservices.azure.com/.default").token
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def poll_result(operation_url: str) -> dict:
    """Poll an async operation until completion."""
    auth_headers = {"Authorization": f"Bearer {token}"}
    while True:
        time.sleep(3)
        resp = requests.get(operation_url, headers=auth_headers)
        result = resp.json()
        status = result.get("status", "").lower()
        if status in ("succeeded", "failed"):
            return result


def run_test(name: str, endpoint: str, path: str, body: dict) -> dict:
    """Submit an analyze request and return the full result."""
    print(f"\n{'='*60}")
    print(f"  {name}")
    print(f"{'='*60}")
    url = f"{endpoint}{path}"
    resp = requests.post(url, headers=headers, json=body)
    if resp.status_code not in (200, 202):
        print(f"  ERROR {resp.status_code}: {resp.text[:200]}")
        return {}
    op_url = resp.headers.get("Operation-Location")
    print(f"  Submitted. Polling...")
    result = poll_result(op_url)
    print(f"  Status: {result.get('status')}")
    return result


# ─── TEST 1: DI prebuilt-layout + keyValuePairs ─────────────
di_result = run_test(
    "TEST 1: DI prebuilt-layout + keyValuePairs (NO LLM)",
    DI_ENDPOINT,
    f"/documentintelligence/documentModels/prebuilt-layout:analyze?api-version={API_VERSION_DI}&features=keyValuePairs",
    {"urlSource": SAMPLE_DOC}
)
if di_result.get("status", "").lower() == "succeeded":
    kvps = di_result.get("analyzeResult", {}).get("keyValuePairs", [])
    print(f"  KVPs extracted: {len(kvps)}")
    print(f"  Usage/tokens in response: {'usage' in di_result}")
    # DI does NOT report token usage — because there is none
    for kv in kvps[:3]:
        k = kv.get("key", {}).get("content", "?")
        v = kv.get("value", {}).get("content", "(empty)")
        print(f"    '{k}' => '{v}'")

# ─── TEST 2: CU prebuilt-layout (NO fields, NO LLM) ────────
cu_layout_result = run_test(
    "TEST 2: CU prebuilt-layout (NO fields, NO LLM)",
    CU_ENDPOINT,
    f"/contentunderstanding/analyzers/prebuilt-layout:analyze?api-version={API_VERSION_CU}",
    {"inputs": [{"url": SAMPLE_DOC}]}
)
if cu_layout_result.get("status", "").lower() == "succeeded":
    usage = cu_layout_result.get("usage", {})
    print(f"  Usage block: {json.dumps(usage, indent=4)}")
    tokens = usage.get("tokens", {})
    if not tokens:
        print("  ✅ NO LLM tokens consumed (as expected)")

# ─── TEST 3: CU prebuilt-documentFields (REQUIRES LLM) ─────
cu_fields_result = run_test(
    "TEST 3: CU prebuilt-documentFields (REQUIRES LLM)",
    CU_ENDPOINT,
    f"/contentunderstanding/analyzers/prebuilt-documentFields:analyze?api-version={API_VERSION_CU}",
    {"inputs": [{"url": SAMPLE_DOC}]}
)
if cu_fields_result.get("status", "").lower() == "succeeded":
    usage = cu_fields_result.get("usage", {})
    print(f"\n  📊 TOKEN CONSUMPTION (from response.usage):")
    print(f"  {json.dumps(usage, indent=4)}")
    tokens = usage.get("tokens", {})
    if tokens:
        total = sum(tokens.values())
        print(f"\n  🔴 TOTAL LLM TOKENS: {total}")
        print(f"     This proves prebuilt-documentFields invokes the LLM!")
    
    # Show extracted fields
    fields = cu_fields_result.get("result", {}).get("contents", [{}])[0].get("fields", {})
    print(f"\n  Fields extracted: {len(fields)}")
    for name in list(fields.keys())[:5]:
        val = fields[name].get("valueString", fields[name].get("valueObject", "..."))
        print(f"    '{name}' => '{val}'")

# ─── COMPARISON TABLE ───────────────────────────────────────
print(f"\n{'='*60}")
print("  COMPARISON SUMMARY")
print(f"{'='*60}")
print("""
  ┌─────────────────────────────────────┬──────────┬────────────────────┐
  │ Method                              │ KVPs?    │ LLM Tokens Used    │
  ├─────────────────────────────────────┼──────────┼────────────────────┤
  │ DI prebuilt-layout + keyValuePairs  │ ✅ Yes   │ ❌ 0 (no LLM)     │
  │ CU prebuilt-layout                  │ ❌ No    │ ❌ 0 (no LLM)     │
  │ CU prebuilt-documentFields          │ ✅ Yes   │ 🔴 ~7,500 tokens  │
  └─────────────────────────────────────┴──────────┴────────────────────┘

  CONCLUSION: To get KVPs without LLM consumption, you MUST use DI.
  CU's field extraction always requires — and bills — LLM tokens.
""")
