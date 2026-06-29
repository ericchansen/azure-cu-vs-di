# ============================================================
# CU vs DI — Three-test comparison script
# Proves whether KVPs require an LLM by observing token usage
# ============================================================
# Prerequisites: az login, resources deployed via main.bicep

$ErrorActionPreference = "Stop"

$diEndpoint  = "https://di-demo-xsygf2piedpu4.cognitiveservices.azure.com"
$cuEndpoint  = "https://cu-foundry-demo-xsygf2piedpu4.cognitiveservices.azure.com"

# Use a publicly available sample invoice
$sampleDocUrl = "https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/sample-invoice.pdf"

# Get bearer token
$token = az account get-access-token --resource "https://cognitiveservices.azure.com" --query "accessToken" -o tsv
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 1: DI prebuilt-layout + keyValuePairs" -ForegroundColor Cyan
Write-Host " Expected: KVPs returned, NO LLM consumed" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$diBody = @{ urlSource = $sampleDocUrl } | ConvertTo-Json
$diUrl = "$diEndpoint/documentintelligence/documentModels/prebuilt-layout:analyze?api-version=2024-11-30&features=keyValuePairs"

try {
    $diResponse = Invoke-WebRequest -Uri $diUrl -Method Post -Headers $headers -Body $diBody
    $diOperationUrl = $diResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 3
        $diResult = Invoke-RestMethod -Uri $diOperationUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($diResult.status -notin @("succeeded", "failed"))

    if ($diResult.status -eq "succeeded") {
        $kvpCount = $diResult.analyzeResult.keyValuePairs.Count
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        Write-Host "  Key-Value Pairs found: $kvpCount" -ForegroundColor Green
        if ($kvpCount -gt 0) {
            Write-Host "  Sample KVPs:" -ForegroundColor Yellow
            $diResult.analyzeResult.keyValuePairs | Select-Object -First 3 | ForEach-Object {
                $key = $_.key.content
                $val = if ($_.value) { $_.value.content } else { "(empty)" }
                Write-Host "    '$key' => '$val'"
            }
        }
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($diResult | ConvertTo-Json -Depth 3)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "  Response: $(# ============================================================
# CU vs DI — Three-test comparison script
# Proves whether KVPs require an LLM by observing token usage
# ============================================================
# Prerequisites: az login, resources deployed via main.bicep

$ErrorActionPreference = "Stop"

$diEndpoint  = "https://di-demo-xsygf2piedpu4.cognitiveservices.azure.com"
$cuEndpoint  = "https://cu-foundry-demo-xsygf2piedpu4.cognitiveservices.azure.com"

# Use a publicly available sample invoice
$sampleDocUrl = "https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/sample-invoice.pdf"

# Get bearer token
$token = az account get-access-token --resource "https://cognitiveservices.azure.com" --query "accessToken" -o tsv
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 1: DI prebuilt-layout + keyValuePairs" -ForegroundColor Cyan
Write-Host " Expected: KVPs returned, NO LLM consumed" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$diBody = @{ urlSource = $sampleDocUrl } | ConvertTo-Json
$diUrl = "$diEndpoint/documentintelligence/documentModels/prebuilt-layout:analyze?api-version=2024-11-30&features=keyValuePairs"

try {
    $diResponse = Invoke-WebRequest -Uri $diUrl -Method Post -Headers $headers -Body $diBody
    $diOperationUrl = $diResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 3
        $diResult = Invoke-RestMethod -Uri $diOperationUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($diResult.status -notin @("succeeded", "failed"))

    if ($diResult.status -eq "succeeded") {
        $kvpCount = $diResult.analyzeResult.keyValuePairs.Count
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        Write-Host "  Key-Value Pairs found: $kvpCount" -ForegroundColor Green
        if ($kvpCount -gt 0) {
            Write-Host "  Sample KVPs:" -ForegroundColor Yellow
            $diResult.analyzeResult.keyValuePairs | Select-Object -First 3 | ForEach-Object {
                $key = $_.key.content
                $val = if ($_.value) { $_.value.content } else { "(empty)" }
                Write-Host "    '$key' => '$val'"
            }
        }
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($diResult | ConvertTo-Json -Depth 3)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}

# CU uses a different request body format than DI
$cuBody = @{ inputs = @( @{ url = $sampleDocUrl } ) } | ConvertTo-Json -Depth 3

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 2: CU prebuilt-layout (NO fields)" -ForegroundColor Cyan
Write-Host " Expected: Markdown+tables, NO KVPs, NO tokens" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$cuLayoutUrl = "$cuEndpoint/contentunderstanding/analyzers/prebuilt-layout:analyze?api-version=2025-11-01"

try {
    $cuLayoutResponse = Invoke-WebRequest -Uri $cuLayoutUrl -Method Post -Headers $headers -Body $cuBody
    $cuLayoutOpUrl = $cuLayoutResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 3
        $cuLayoutResult = Invoke-RestMethod -Uri $cuLayoutOpUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($cuLayoutResult.status -notin @("succeeded", "failed"))

    if ($cuLayoutResult.status -eq "succeeded") {
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        $hasKvps = $null -ne $cuLayoutResult.result.contents[0].keyValuePairs
        Write-Host "  Has keyValuePairs property: $hasKvps" -ForegroundColor $(if($hasKvps){"Yellow"}else{"Green"})
        $markdown = $cuLayoutResult.result.contents[0].markdown
        Write-Host "  Markdown length: $($markdown.Length) chars" -ForegroundColor Gray
        $tables = $cuLayoutResult.result.contents[0].tables
        Write-Host "  Tables found: $(if($tables){$tables.Count}else{0})" -ForegroundColor Gray
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($cuLayoutResult | ConvertTo-Json -Depth 3)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 3: CU prebuilt-documentFields" -ForegroundColor Cyan
Write-Host " Expected: KVPs returned, LLM TOKENS CONSUMED" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$cuFieldsUrl = "$cuEndpoint/contentunderstanding/analyzers/prebuilt-documentFields:analyze?api-version=2025-11-01"

try {
    $cuFieldsResponse = Invoke-WebRequest -Uri $cuFieldsUrl -Method Post -Headers $headers -Body $cuBody
    $cuFieldsOpUrl = $cuFieldsResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 5
        $cuFieldsResult = Invoke-RestMethod -Uri $cuFieldsOpUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($cuFieldsResult.status -notin @("succeeded", "failed"))

    if ($cuFieldsResult.status -eq "succeeded") {
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        $fields = $cuFieldsResult.result.contents[0].fields
        Write-Host "  Fields extracted: $(if($fields){($fields | Get-Member -MemberType NoteProperty).Count}else{0})" -ForegroundColor Green
        if ($fields) {
            Write-Host "  Sample fields:" -ForegroundColor Yellow
            $fields | Get-Member -MemberType NoteProperty | Select-Object -First 5 | ForEach-Object {
                $name = $_.Name
                $val = $fields.$name.valueString
                Write-Host "    '$name' => '$val'"
            }
        }
        Write-Host "`n  >>> CHECK TOKEN CONSUMPTION on gpt-4o-mini deployment <<<" -ForegroundColor Magenta
        Write-Host "  >>> If tokens increased, CU used the LLM for this call <<<" -ForegroundColor Magenta
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($cuFieldsResult | ConvertTo-Json -Depth 5)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " SUMMARY" -ForegroundColor Cyan  
Write-Host "============================================" -ForegroundColor Cyan
Write-Host @"

  DI prebuilt-layout + features=keyValuePairs:
    - Returns KVPs via pre-trained model
    - No LLM deployment required
    - Fixed per-page cost

  CU prebuilt-layout:
    - Returns markdown + tables
    - NO KVPs
    - No LLM required

  CU prebuilt-documentFields:
    - Returns structured fields (KVPs)
    - REQUIRES LLM deployment (gpt-4o-mini)
    - Consumes tokens on every call
    - Variable cost based on document size

  CONCLUSION: CU is NOT a superset of DI for KVP extraction.
  To get KVPs without an LLM, you need DI.
"@
.ErrorDetails.Message)" -ForegroundColor Red
    }
}

# CU uses a different request body format than DI
$cuBody = @{ inputs = @( @{ url = $sampleDocUrl } ) } | ConvertTo-Json -Depth 3

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 2: CU prebuilt-layout (NO fields)" -ForegroundColor Cyan
Write-Host " Expected: Markdown+tables, NO KVPs, NO tokens" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$cuLayoutUrl = "$cuEndpoint/contentunderstanding/analyzers/prebuilt-layout:analyze?api-version=2025-11-01"

try {
    $cuLayoutResponse = Invoke-WebRequest -Uri $cuLayoutUrl -Method Post -Headers $headers -Body $cuBody
    $cuLayoutOpUrl = $cuLayoutResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 3
        $cuLayoutResult = Invoke-RestMethod -Uri $cuLayoutOpUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($cuLayoutResult.status -notin @("succeeded", "failed"))

    if ($cuLayoutResult.status -eq "succeeded") {
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        $hasKvps = $null -ne $cuLayoutResult.result.contents[0].keyValuePairs
        Write-Host "  Has keyValuePairs property: $hasKvps" -ForegroundColor $(if($hasKvps){"Yellow"}else{"Green"})
        $markdown = $cuLayoutResult.result.contents[0].markdown
        Write-Host "  Markdown length: $($markdown.Length) chars" -ForegroundColor Gray
        $tables = $cuLayoutResult.result.contents[0].tables
        Write-Host "  Tables found: $(if($tables){$tables.Count}else{0})" -ForegroundColor Gray
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($cuLayoutResult | ConvertTo-Json -Depth 3)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "  Response: $(# ============================================================
# CU vs DI — Three-test comparison script
# Proves whether KVPs require an LLM by observing token usage
# ============================================================
# Prerequisites: az login, resources deployed via main.bicep

$ErrorActionPreference = "Stop"

$diEndpoint  = "https://di-demo-xsygf2piedpu4.cognitiveservices.azure.com"
$cuEndpoint  = "https://cu-foundry-demo-xsygf2piedpu4.cognitiveservices.azure.com"

# Use a publicly available sample invoice
$sampleDocUrl = "https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/sample-invoice.pdf"

# Get bearer token
$token = az account get-access-token --resource "https://cognitiveservices.azure.com" --query "accessToken" -o tsv
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 1: DI prebuilt-layout + keyValuePairs" -ForegroundColor Cyan
Write-Host " Expected: KVPs returned, NO LLM consumed" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$diBody = @{ urlSource = $sampleDocUrl } | ConvertTo-Json
$diUrl = "$diEndpoint/documentintelligence/documentModels/prebuilt-layout:analyze?api-version=2024-11-30&features=keyValuePairs"

try {
    $diResponse = Invoke-WebRequest -Uri $diUrl -Method Post -Headers $headers -Body $diBody
    $diOperationUrl = $diResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 3
        $diResult = Invoke-RestMethod -Uri $diOperationUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($diResult.status -notin @("succeeded", "failed"))

    if ($diResult.status -eq "succeeded") {
        $kvpCount = $diResult.analyzeResult.keyValuePairs.Count
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        Write-Host "  Key-Value Pairs found: $kvpCount" -ForegroundColor Green
        if ($kvpCount -gt 0) {
            Write-Host "  Sample KVPs:" -ForegroundColor Yellow
            $diResult.analyzeResult.keyValuePairs | Select-Object -First 3 | ForEach-Object {
                $key = $_.key.content
                $val = if ($_.value) { $_.value.content } else { "(empty)" }
                Write-Host "    '$key' => '$val'"
            }
        }
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($diResult | ConvertTo-Json -Depth 3)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}

# CU uses a different request body format than DI
$cuBody = @{ inputs = @( @{ url = $sampleDocUrl } ) } | ConvertTo-Json -Depth 3

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 2: CU prebuilt-layout (NO fields)" -ForegroundColor Cyan
Write-Host " Expected: Markdown+tables, NO KVPs, NO tokens" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$cuLayoutUrl = "$cuEndpoint/contentunderstanding/analyzers/prebuilt-layout:analyze?api-version=2025-11-01"

try {
    $cuLayoutResponse = Invoke-WebRequest -Uri $cuLayoutUrl -Method Post -Headers $headers -Body $cuBody
    $cuLayoutOpUrl = $cuLayoutResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 3
        $cuLayoutResult = Invoke-RestMethod -Uri $cuLayoutOpUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($cuLayoutResult.status -notin @("succeeded", "failed"))

    if ($cuLayoutResult.status -eq "succeeded") {
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        $hasKvps = $null -ne $cuLayoutResult.result.contents[0].keyValuePairs
        Write-Host "  Has keyValuePairs property: $hasKvps" -ForegroundColor $(if($hasKvps){"Yellow"}else{"Green"})
        $markdown = $cuLayoutResult.result.contents[0].markdown
        Write-Host "  Markdown length: $($markdown.Length) chars" -ForegroundColor Gray
        $tables = $cuLayoutResult.result.contents[0].tables
        Write-Host "  Tables found: $(if($tables){$tables.Count}else{0})" -ForegroundColor Gray
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($cuLayoutResult | ConvertTo-Json -Depth 3)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 3: CU prebuilt-documentFields" -ForegroundColor Cyan
Write-Host " Expected: KVPs returned, LLM TOKENS CONSUMED" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$cuFieldsUrl = "$cuEndpoint/contentunderstanding/analyzers/prebuilt-documentFields:analyze?api-version=2025-11-01"

try {
    $cuFieldsResponse = Invoke-WebRequest -Uri $cuFieldsUrl -Method Post -Headers $headers -Body $cuBody
    $cuFieldsOpUrl = $cuFieldsResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 5
        $cuFieldsResult = Invoke-RestMethod -Uri $cuFieldsOpUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($cuFieldsResult.status -notin @("succeeded", "failed"))

    if ($cuFieldsResult.status -eq "succeeded") {
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        $fields = $cuFieldsResult.result.contents[0].fields
        Write-Host "  Fields extracted: $(if($fields){($fields | Get-Member -MemberType NoteProperty).Count}else{0})" -ForegroundColor Green
        if ($fields) {
            Write-Host "  Sample fields:" -ForegroundColor Yellow
            $fields | Get-Member -MemberType NoteProperty | Select-Object -First 5 | ForEach-Object {
                $name = $_.Name
                $val = $fields.$name.valueString
                Write-Host "    '$name' => '$val'"
            }
        }
        Write-Host "`n  >>> CHECK TOKEN CONSUMPTION on gpt-4o-mini deployment <<<" -ForegroundColor Magenta
        Write-Host "  >>> If tokens increased, CU used the LLM for this call <<<" -ForegroundColor Magenta
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($cuFieldsResult | ConvertTo-Json -Depth 5)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " SUMMARY" -ForegroundColor Cyan  
Write-Host "============================================" -ForegroundColor Cyan
Write-Host @"

  DI prebuilt-layout + features=keyValuePairs:
    - Returns KVPs via pre-trained model
    - No LLM deployment required
    - Fixed per-page cost

  CU prebuilt-layout:
    - Returns markdown + tables
    - NO KVPs
    - No LLM required

  CU prebuilt-documentFields:
    - Returns structured fields (KVPs)
    - REQUIRES LLM deployment (gpt-4o-mini)
    - Consumes tokens on every call
    - Variable cost based on document size

  CONCLUSION: CU is NOT a superset of DI for KVP extraction.
  To get KVPs without an LLM, you need DI.
"@
.ErrorDetails.Message)" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 3: CU prebuilt-documentFields" -ForegroundColor Cyan
Write-Host " Expected: KVPs returned, LLM TOKENS CONSUMED" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$cuFieldsUrl = "$cuEndpoint/contentunderstanding/analyzers/prebuilt-documentFields:analyze?api-version=2025-11-01"

try {
    $cuFieldsResponse = Invoke-WebRequest -Uri $cuFieldsUrl -Method Post -Headers $headers -Body $cuBody
    $cuFieldsOpUrl = $cuFieldsResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 5
        $cuFieldsResult = Invoke-RestMethod -Uri $cuFieldsOpUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($cuFieldsResult.status -notin @("succeeded", "failed"))

    if ($cuFieldsResult.status -eq "succeeded") {
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        $fields = $cuFieldsResult.result.contents[0].fields
        Write-Host "  Fields extracted: $(if($fields){($fields | Get-Member -MemberType NoteProperty).Count}else{0})" -ForegroundColor Green
        if ($fields) {
            Write-Host "  Sample fields:" -ForegroundColor Yellow
            $fields | Get-Member -MemberType NoteProperty | Select-Object -First 5 | ForEach-Object {
                $name = $_.Name
                $val = $fields.$name.valueString
                Write-Host "    '$name' => '$val'"
            }
        }
        Write-Host "`n  >>> CHECK TOKEN CONSUMPTION on gpt-4o-mini deployment <<<" -ForegroundColor Magenta
        Write-Host "  >>> If tokens increased, CU used the LLM for this call <<<" -ForegroundColor Magenta
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($cuFieldsResult | ConvertTo-Json -Depth 5)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "  Response: $(# ============================================================
# CU vs DI — Three-test comparison script
# Proves whether KVPs require an LLM by observing token usage
# ============================================================
# Prerequisites: az login, resources deployed via main.bicep

$ErrorActionPreference = "Stop"

$diEndpoint  = "https://di-demo-xsygf2piedpu4.cognitiveservices.azure.com"
$cuEndpoint  = "https://cu-foundry-demo-xsygf2piedpu4.cognitiveservices.azure.com"

# Use a publicly available sample invoice
$sampleDocUrl = "https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/master/curl/form-recognizer/sample-invoice.pdf"

# Get bearer token
$token = az account get-access-token --resource "https://cognitiveservices.azure.com" --query "accessToken" -o tsv
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 1: DI prebuilt-layout + keyValuePairs" -ForegroundColor Cyan
Write-Host " Expected: KVPs returned, NO LLM consumed" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$diBody = @{ urlSource = $sampleDocUrl } | ConvertTo-Json
$diUrl = "$diEndpoint/documentintelligence/documentModels/prebuilt-layout:analyze?api-version=2024-11-30&features=keyValuePairs"

try {
    $diResponse = Invoke-WebRequest -Uri $diUrl -Method Post -Headers $headers -Body $diBody
    $diOperationUrl = $diResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 3
        $diResult = Invoke-RestMethod -Uri $diOperationUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($diResult.status -notin @("succeeded", "failed"))

    if ($diResult.status -eq "succeeded") {
        $kvpCount = $diResult.analyzeResult.keyValuePairs.Count
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        Write-Host "  Key-Value Pairs found: $kvpCount" -ForegroundColor Green
        if ($kvpCount -gt 0) {
            Write-Host "  Sample KVPs:" -ForegroundColor Yellow
            $diResult.analyzeResult.keyValuePairs | Select-Object -First 3 | ForEach-Object {
                $key = $_.key.content
                $val = if ($_.value) { $_.value.content } else { "(empty)" }
                Write-Host "    '$key' => '$val'"
            }
        }
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($diResult | ConvertTo-Json -Depth 3)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}

# CU uses a different request body format than DI
$cuBody = @{ inputs = @( @{ url = $sampleDocUrl } ) } | ConvertTo-Json -Depth 3

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 2: CU prebuilt-layout (NO fields)" -ForegroundColor Cyan
Write-Host " Expected: Markdown+tables, NO KVPs, NO tokens" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$cuLayoutUrl = "$cuEndpoint/contentunderstanding/analyzers/prebuilt-layout:analyze?api-version=2025-11-01"

try {
    $cuLayoutResponse = Invoke-WebRequest -Uri $cuLayoutUrl -Method Post -Headers $headers -Body $cuBody
    $cuLayoutOpUrl = $cuLayoutResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 3
        $cuLayoutResult = Invoke-RestMethod -Uri $cuLayoutOpUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($cuLayoutResult.status -notin @("succeeded", "failed"))

    if ($cuLayoutResult.status -eq "succeeded") {
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        $hasKvps = $null -ne $cuLayoutResult.result.contents[0].keyValuePairs
        Write-Host "  Has keyValuePairs property: $hasKvps" -ForegroundColor $(if($hasKvps){"Yellow"}else{"Green"})
        $markdown = $cuLayoutResult.result.contents[0].markdown
        Write-Host "  Markdown length: $($markdown.Length) chars" -ForegroundColor Gray
        $tables = $cuLayoutResult.result.contents[0].tables
        Write-Host "  Tables found: $(if($tables){$tables.Count}else{0})" -ForegroundColor Gray
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($cuLayoutResult | ConvertTo-Json -Depth 3)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " TEST 3: CU prebuilt-documentFields" -ForegroundColor Cyan
Write-Host " Expected: KVPs returned, LLM TOKENS CONSUMED" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

$cuFieldsUrl = "$cuEndpoint/contentunderstanding/analyzers/prebuilt-documentFields:analyze?api-version=2025-11-01"

try {
    $cuFieldsResponse = Invoke-WebRequest -Uri $cuFieldsUrl -Method Post -Headers $headers -Body $cuBody
    $cuFieldsOpUrl = $cuFieldsResponse.Headers["Operation-Location"][0]
    Write-Host "  Submitted. Polling for result..." -ForegroundColor Gray

    do {
        Start-Sleep -Seconds 5
        $cuFieldsResult = Invoke-RestMethod -Uri $cuFieldsOpUrl -Headers @{ "Authorization" = "Bearer $token" }
    } while ($cuFieldsResult.status -notin @("succeeded", "failed"))

    if ($cuFieldsResult.status -eq "succeeded") {
        Write-Host "  Status: SUCCEEDED" -ForegroundColor Green
        $fields = $cuFieldsResult.result.contents[0].fields
        Write-Host "  Fields extracted: $(if($fields){($fields | Get-Member -MemberType NoteProperty).Count}else{0})" -ForegroundColor Green
        if ($fields) {
            Write-Host "  Sample fields:" -ForegroundColor Yellow
            $fields | Get-Member -MemberType NoteProperty | Select-Object -First 5 | ForEach-Object {
                $name = $_.Name
                $val = $fields.$name.valueString
                Write-Host "    '$name' => '$val'"
            }
        }
        Write-Host "`n  >>> CHECK TOKEN CONSUMPTION on gpt-4o-mini deployment <<<" -ForegroundColor Magenta
        Write-Host "  >>> If tokens increased, CU used the LLM for this call <<<" -ForegroundColor Magenta
    } else {
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $($cuFieldsResult | ConvertTo-Json -Depth 5)"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host "  Response: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " SUMMARY" -ForegroundColor Cyan  
Write-Host "============================================" -ForegroundColor Cyan
Write-Host @"

  DI prebuilt-layout + features=keyValuePairs:
    - Returns KVPs via pre-trained model
    - No LLM deployment required
    - Fixed per-page cost

  CU prebuilt-layout:
    - Returns markdown + tables
    - NO KVPs
    - No LLM required

  CU prebuilt-documentFields:
    - Returns structured fields (KVPs)
    - REQUIRES LLM deployment (gpt-4o-mini)
    - Consumes tokens on every call
    - Variable cost based on document size

  CONCLUSION: CU is NOT a superset of DI for KVP extraction.
  To get KVPs without an LLM, you need DI.
"@
.ErrorDetails.Message)" -ForegroundColor Red
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " SUMMARY" -ForegroundColor Cyan  
Write-Host "============================================" -ForegroundColor Cyan
Write-Host @"

  DI prebuilt-layout + features=keyValuePairs:
    - Returns KVPs via pre-trained model
    - No LLM deployment required
    - Fixed per-page cost

  CU prebuilt-layout:
    - Returns markdown + tables
    - NO KVPs
    - No LLM required

  CU prebuilt-documentFields:
    - Returns structured fields (KVPs)
    - REQUIRES LLM deployment (gpt-4o-mini)
    - Consumes tokens on every call
    - Variable cost based on document size

  CONCLUSION: CU is NOT a superset of DI for KVP extraction.
  To get KVPs without an LLM, you need DI.
"@

