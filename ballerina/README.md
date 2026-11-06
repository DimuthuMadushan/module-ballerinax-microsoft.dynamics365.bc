## Overview

[Microsoft Dynamics 365 Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/) is a cloud ERP system for small and mid-sized organisations, covering finance, sales, purchasing, inventory, projects and human resources in a single ledger-backed system of record.

The Business Central connector provides access to the Business Central Standard APIs, version 1.0 over OAuth 2.0. It covers the complete published surface spanning the business objects of a company (customers, vendors, items, employees, sales and purchase documents, journals, dimensions and general ledger entries), the bound actions that move a document through its lifecycle, the financial statement reports, the attachments, pictures and generated PDF documents, and the reference data that the documents point at.

### Key Features

- Manage the customer, vendor, item and employee master data of a company
- Raise and maintain sales quotes, orders, invoices and credit memos, including their document lines
- Drive the document lifecycle with the Business Central actions
- Record and post journals, journal lines and customer payments
- Read financial data
- Pull the financial statement reports
- Work with documents and media

## Setup guide

To use the Business Central connector, you need a Business Central environment, a user account with access to it, and an application registered in Microsoft Entra ID.

### Step 1: Register an application in Microsoft Entra ID

1. Sign in to the [Azure portal](https://portal.azure.com) with an account that can register applications, and open **Entra** from the Microsoft Cloud menu. You can also go straight to the [Microsoft Entra admin center](https://entra.microsoft.com/).

   ![Azure Portal](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/azure-portal.png)

2. Select **App registrations** from the left sidebar, then select **New registration**.

   ![Entra main page](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/entra-main-page.png)

3. Enter a name, choose **Accounts in this organizational directory only**, add `https://jwt.ms` as a **Web** redirect URI, and select **Register**. Business Central is reached with a work or school account in the tenant that owns the environment, so personal Microsoft accounts cannot be used.

   ![Register an application](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/register-application.jpeg)

4. On the application's **Overview** page, note the **Application (client) ID** and the **Directory (tenant) ID**.

   ![Application overview](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/application-overview.jpeg)

### Step 2: Grant the Business Central API permissions

1. Go to **API permissions** > **Add a permission** > **Dynamics 365 Business Central**.
2. Select the delegated **Financials.ReadWrite.All** permission, which covers the operations in this connector, and select **Add permissions**.
3. Grant admin consent if your tenant requires it.

### Step 3: Create a client secret

1. Go to **Certificates & secrets** > **Client secrets** > **New client secret**.

   ![Add client secret](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/add-client-secret.png)

2. Add a description and an expiry, select **Add**, and copy the secret's **Value**. The value is shown only once.

### Step 4: Obtain a refresh token

The connector authenticates with an OAuth 2.0 refresh token from Microsoft Entra ID and renews its access token automatically.

1. Open the following URL in a browser, with your tenant ID and client ID, and sign in with a user account that has access to the Business Central environment:

    ```text
    https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/authorize?client_id=<client-id>&response_type=code&redirect_uri=https%3A%2F%2Fjwt.ms&response_mode=query&scope=https%3A%2F%2Fapi.businesscentral.dynamics.com%2FFinancials.ReadWrite.All%20offline_access
    ```

2. Accept the consent prompt. The browser opens `https://jwt.ms/?code=<authorization-code>`. Copy the `code` value, which is single-use and expires within minutes.
3. Exchange the code for a refresh token:

    ```bash
    curl -X POST "https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token" \
      --data-urlencode "client_id=<client-id>" \
      --data-urlencode "client_secret=<client-secret>" \
      --data-urlencode "scope=https://api.businesscentral.dynamics.com/Financials.ReadWrite.All offline_access" \
      --data-urlencode "code=<authorization-code>" \
      --data-urlencode "redirect_uri=https://jwt.ms" \
      --data-urlencode "grant_type=authorization_code"
    ```

4. Copy the `refresh_token` value from the JSON response.

### Step 5: Find the environment and company

The service URL carries the environment name — `https://api.businesscentral.dynamics.com/v2.0/{environment}/api/v1.0`, where `{environment}` is `production` by default and can be a sandbox name instead. The client defaults to the production environment; pass a different service URL to `init` to target a sandbox. Call `listCompanies` to obtain the identifier of the company the integration works in.

## Quickstart

To use the Business Central connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerinax/microsoft.dynamics365.bc as bc;
```

### Step 2: Instantiate a new connector

Create a `bc:Client` with the credentials from Step 4 of the setup guide.

```ballerina
configurable string tenantId = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;

final bc:OAuth2RefreshTokenGrantConfig auth = {
    clientId,
    clientSecret,
    refreshToken,
    refreshUrl: string `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token`,
    scopes: ["https://api.businesscentral.dynamics.com/Financials.ReadWrite.All", "offline_access"]
};

final bc:Client dynamics365 = check new ({auth});
```

> **Note:** The connector's default token URL is the multi-tenant `https://login.microsoftonline.com/common/oauth2/v2.0/token` endpoint. It works only for applications that accept accounts from any organization, so change it to your tenant's endpoint, as `refreshUrl` does above.

Provide the values in a `Config.toml` file:

```toml
tenantId = "<tenant-id>"
clientId = "<client-id>"
clientSecret = "<client-secret>"
refreshToken = "<refresh-token>"
```

To work against a sandbox environment, pass the service URL explicitly:

```ballerina
final bc:Client sandboxClient = check new (
    {auth},
    "https://api.businesscentral.dynamics.com/v2.0/sandbox/api/v1.0"
);
```

### Step 3: Invoke the connector operation

```ballerina
public function main() returns error? {
    bc:CompanyCollection _ = check dynamics365->listCompanies();
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The `Microsoft Dynamics 365 Business Central` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/tree/main/examples/), covering the following use cases:

1. [Customer invoice workflow](../examples/customer_invoice_workflow/customer_invoice_workflow.md) — Onboard a customer, raise a sales invoice with a line, and post it to the general ledger.
2. [Item catalog management](../examples/item_catalog_management/item_catalog_management.md) — Review the item catalog, register a new stocked item, and correct its price with an `If-Match` guarded update.
3. [Sales order processing](../examples/sales_order_processing/sales_order_processing.md) — Open a sales order for an existing customer and read back the lines that belong to it.
4. [Financial ledger review](../examples/financial_ledger_review/financial_ledger_review.md) — Take a month-end snapshot of the chart of accounts, the bank accounts, and the posted ledger entries.
