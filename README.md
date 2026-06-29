# Azure Content Understanding vs Document Intelligence

**TL;DR:** To extract key-value pairs (KVPs) from documents **without LLM token consumption**, you must use **Azure Document Intelligence**. Azure Content Understanding's field extraction **always** invokes an LLM at inference time.

## Proof

| Method | KVPs? | LLM Tokens Used |
|--------|-------|-----------------|
| DI `prebuilt-layout` + keyValuePairs | ✅ Yes (24) | ❌ 0 (no LLM) |
| CU `prebuilt-layout` | ❌ No | ❌ 0 (no LLM) |
| CU `prebuilt-documentFields` | ✅ Yes (17) | 🔴 7,525 tokens |

The CU API response itself reports token consumption in the `usage` block:

```json
{
  "documentPagesStandard": 1,
  "contextualizationTokens": 1000,
  "tokens": {
    "gpt-4.1-mini-input": 6472,
    "gpt-4.1-mini-output": 1053
  }
}
```

## Files

| File | Purpose |
|------|---------|
| `main.bicep` | IaC deploying both DI (kind: FormRecognizer) and CU (kind: AIServices) side-by-side |
| `test-kvp-comparison.ps1` | PowerShell script running all 3 comparison tests |
| `test3-result.json` | Saved CU response with full token consumption proof |
| `validation/1_api_rest.py` | REST API validation (3 tests with token reporting) |
| `validation/2_sdk_python.py` | Python SDK/REST hybrid validation |
| `validation/3_portal_workflow.py` | Manual portal UI workflow guide with direct Azure links |

## ARM Resource Architecture

Both services are `Microsoft.CognitiveServices/accounts` but with different `kind` values:
- **Document Intelligence**: `kind: FormRecognizer`
- **Content Understanding**: `kind: AIServices` (multi-service Foundry resource)

## Key Findings

1. CU's `prebuilt-layout` and `prebuilt-read` are LLM-free (content extraction only)
2. CU's `prebuilt-documentFields` **requires** an LLM model deployment (gpt-4.1, gpt-4.1-mini, or gpt-5.2)
3. CU model aliases must be configured via `PATCH /contentunderstanding/defaults`
4. DI's `keyValuePairs` feature uses classical ML — no LLM, no token billing
5. The proof is in the API response: CU includes `usage.tokens`, DI has no such field

## Prerequisites

- Azure subscription with Cognitive Services Contributor role
- `az` CLI authenticated
- Python 3.10+ with `requests` package
- Bearer token auth (`az account get-access-token --resource https://cognitiveservices.azure.com`)

## Docs References

- [CU Prebuilt Analyzers](https://learn.microsoft.com/azure/ai-services/content-understanding/concepts/prebuilt-analyzers)
- [CU Pricing Explainer](https://learn.microsoft.com/azure/ai-services/content-understanding/pricing-explainer)
- [DI Key-Value Pairs Add-on](https://learn.microsoft.com/azure/ai-services/document-intelligence/concept/add-on-capabilities?view=doc-intel-4.0.0#key-value-pairs)
- [CU Model Deployments](https://learn.microsoft.com/azure/ai-services/content-understanding/concepts/models-deployments)
