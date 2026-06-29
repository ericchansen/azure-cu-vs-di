// ============================================================
// CU vs DI — ARM Resource Comparison Demo
// Deploys BOTH services side-by-side so you can inspect the
// actual resource types, SKUs, and endpoints in the portal.
// ============================================================

@description('Region for all resources')
param location string = 'eastus'

@description('Unique suffix to avoid naming collisions')
param suffix string = uniqueString(resourceGroup().id)

// ─────────────────────────────────────────────────────────────
// 1. DOCUMENT INTELLIGENCE  (standalone resource)
//    ARM type: Microsoft.CognitiveServices/accounts
//    Kind:     'FormRecognizer'
// ─────────────────────────────────────────────────────────────
resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: 'di-demo-${suffix}'
  location: location
  kind: 'FormRecognizer'            // <── This is what makes it DI
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'di-demo-${suffix}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false          // Enable key-based auth for testing
  }
}

// ─────────────────────────────────────────────────────────────
// 2. CONTENT UNDERSTANDING  (requires a multi-service AI resource)
//    ARM type: Microsoft.CognitiveServices/accounts
//    Kind:     'AIServices'  (the "Foundry" / multi-service resource)
//    CU is an API surface ON this resource, not a separate one.
// ─────────────────────────────────────────────────────────────
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: 'cu-foundry-demo-${suffix}'
  location: location
  kind: 'AIServices'                // <── Multi-service Foundry resource (hosts CU + OpenAI + more)
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'cu-foundry-demo-${suffix}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false          // Enable key-based auth for testing
  }
}

// ─────────────────────────────────────────────────────────────
// 3. GPT-4o-MINI DEPLOYMENT on the AIServices resource
//    This is the LLM that CU's field extraction will consume.
//    We'll monitor its token usage before/after running CU.
// ─────────────────────────────────────────────────────────────
resource gpt4oMini 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'gpt-4o-mini'
  sku: {
    name: 'GlobalStandard'
    capacity: 10                     // 10K TPM — enough for a demo
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
  }
}

resource embedding 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'text-embedding-3-large'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-large'
      version: '1'
    }
  }
  dependsOn: [gpt4oMini]            // Serialize deployments to avoid conflicts
}

// ─────────────────────────────────────────────────────────────
// OUTPUTS — compare endpoints and resource types
// ─────────────────────────────────────────────────────────────
output comparison object = {
  documentIntelligence: {
    resourceId: documentIntelligence.id
    kind: documentIntelligence.kind
    endpoint: documentIntelligence.properties.endpoint
    armType: 'Microsoft.CognitiveServices/accounts (kind: FormRecognizer)'
    note: 'Standalone. Has ?features=keyValuePairs. No LLM needed.'
  }
  contentUnderstanding: {
    resourceId: aiServices.id
    kind: aiServices.kind
    endpoint: aiServices.properties.endpoint
    armType: 'Microsoft.CognitiveServices/accounts (kind: AIServices)'
    note: 'CU is an API on the AIServices/Foundry resource. Field extraction requires an LLM deployment on this same resource.'
  }
  summary: 'Same ARM namespace (Microsoft.CognitiveServices/accounts), different KIND values. They are separate portal resources.'
}
