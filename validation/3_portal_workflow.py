"""
=============================================================
VALIDATION 3: Portal UI — Manual Workflow Guide
=============================================================
Step-by-step instructions to visually confirm token consumption
using the Azure Portal and Content Understanding Studio.
=============================================================

PREREQUISITES:
  - Resources deployed (rg-cu-vs-di-demo)
  - gpt-4.1-mini model deployed on cu-foundry-demo-xsygf2piedpu4
  - You have access to the Azure Portal

=============================================================
STEP 1: Open Azure Monitor Metrics (BEFORE running anything)
=============================================================

  1. Go to: https://portal.azure.com
  2. Navigate to: rg-cu-vs-di-demo → cu-foundry-demo-xsygf2piedpu4
  3. Left menu → Monitoring → Metrics
  4. Configure the chart:
     - Metric Namespace: "Cognitive Services Standard Metrics"
     - Metric: "Processed Inference Tokens" (or "Azure OpenAI Processed Prompt Tokens")
     - Aggregation: Sum
     - Add splitting: "ModelDeploymentName"
     - Time range: Last 30 minutes
     - Granularity: 1 minute
  5. Note the current token count (should be 0 or flat if nothing ran recently)
  6. KEEP THIS TAB OPEN — you'll come back after running CU

=============================================================
STEP 2: Run prebuilt-layout in Content Understanding Studio
=============================================================

  1. Open new tab: https://ai.azure.com/resource/contentunderstanding
     (or go to Content Understanding Studio: https://aka.ms/cu-studio)
  2. Select your resource: cu-foundry-demo-xsygf2piedpu4
  3. Choose analyzer: "prebuilt-layout" (under Content Extraction)
  4. Upload or use sample: the sample invoice PDF
     https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/sample-invoice.pdf
  5. Run the analysis
  6. Observe: You get markdown + tables, NO fields/KVPs
  7. Go back to Metrics tab → Refresh
     ✅ EXPECTED: No token spike (prebuilt-layout doesn't use LLM)

=============================================================
STEP 3: Run prebuilt-documentFields in Content Understanding Studio
=============================================================

  1. Back in CU Studio, switch to a field-extraction analyzer:
     - Select "prebuilt-documentFields" (under Utility Analyzers)
     - OR select "prebuilt-invoice" (under Domain-Specific)
  2. Use the SAME sample invoice PDF
  3. Run the analysis
  4. Observe: You get structured fields (InvoiceNumber, Date, etc.)
  5. Go back to Metrics tab → Refresh (wait 1-2 minutes for propagation)
     🔴 EXPECTED: Token spike on gpt-4.1-mini deployment!
     You should see ~6-7K input tokens + ~1K output tokens

=============================================================
STEP 4: Compare with Document Intelligence Studio
=============================================================

  1. Open: https://documentintelligence.ai.azure.com/studio
  2. Select your DI resource: di-demo-xsygf2piedpu4
  3. Choose: "Layout" model
  4. In the features section, enable "Key-Value Pairs"
  5. Upload the same sample invoice
  6. Run analysis
  7. Observe: You get KVPs (INVOICE: INV-100, DATE: 11/15/2019, etc.)
  8. Go back to Metrics tab for the DI resource
     ✅ EXPECTED: No LLM token metrics at all (DI doesn't have model deployments)

=============================================================
STEP 5: Document Your Findings
=============================================================

  Screenshot checklist:
  [ ] Metrics chart showing 0 tokens after prebuilt-layout
  [ ] Metrics chart showing token spike after prebuilt-documentFields
  [ ] CU Studio showing fields extracted (with LLM)
  [ ] DI Studio showing KVPs extracted (without LLM)
  [ ] The response JSON showing usage.tokens block

  Evidence summary:
  ┌──────────────────────────────────┬────────┬──────────────────┐
  │ Action                           │ KVPs?  │ Token Spike?     │
  ├──────────────────────────────────┼────────┼──────────────────┤
  │ CU prebuilt-layout               │ ❌ No  │ ❌ None          │
  │ CU prebuilt-documentFields       │ ✅ Yes │ 🔴 ~7,500 tokens │
  │ DI prebuilt-layout + keyValuePairs│ ✅ Yes │ ❌ None          │
  └──────────────────────────────────┴────────┴──────────────────┘

=============================================================
PORTAL URLS (direct links for your deployment)
=============================================================

  CU Resource Metrics:
  https://portal.azure.com/#@/resource/subscriptions/9450bd3b-96c5-48b2-bfdf-3374304efbd7/resourceGroups/rg-cu-vs-di-demo/providers/Microsoft.CognitiveServices/accounts/cu-foundry-demo-xsygf2piedpu4/metrics

  DI Resource:
  https://portal.azure.com/#@/resource/subscriptions/9450bd3b-96c5-48b2-bfdf-3374304efbd7/resourceGroups/rg-cu-vs-di-demo/providers/Microsoft.CognitiveServices/accounts/di-demo-xsygf2piedpu4/overview

  Content Understanding Studio:
  https://aka.ms/cu-studio

  Document Intelligence Studio:
  https://documentintelligence.ai.azure.com/studio
"""
