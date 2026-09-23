# Ballerina Microsoft Dynamics 365 Business Central connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc.svg)](https://github.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/microsoft.dynamics365.bc.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%microsoft.dynamics365.bc)

## Overview

[Microsoft Dynamics 365 Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/) is a cloud ERP system for small and mid-sized organisations, covering finance, sales, purchasing, inventory, projects and human resources in a single ledger-backed system of record.

The Business Central connector provides access to the Business Central Standard APIs, version 1.0 over OAuth 2.0. It covers the complete published surface spanning the business objects of a company (customers, vendors, items, employees, sales and purchase documents, journals, dimensions and general ledger entries), the bound actions that move a document through its lifecycle, the financial statement reports, the attachments, pictures and generated PDF documents, and the reference data that the documents point at.

Every operation is scoped to a company within a Business Central environment, so a typical integration reads the companies available to the signed-in user first and then works within one of them.

## Setup guide

The connector authenticates with an OAuth 2.0 bearer token issued by Microsoft Entra ID for the Business Central API.

### Step 1: Register an application in Microsoft Entra ID

1. Sign in to the [Azure Portal](https://portal.azure.com) with an account that can register applications, and open **Entra** from the Microsoft Cloud menu. You can also go straight to the [Microsoft Entra admin center](https://entra.microsoft.com/).

   ![Azure Portal](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/azure-portal.png)

2. In the Microsoft Entra admin center, select **App registrations** from the left sidebar, then select **New registration**.

   ![Entra main page](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/entra-main-page.png)

3. Give the application a name, and add a redirect URI that matches how you will acquire tokens (for example `http://localhost` for local testing). For **Supported account types**, choose **Accounts in this organizational directory only** — Business Central is reached with a work or school account in the tenant that owns the environment, so personal Microsoft accounts cannot be used.

   ![Register an application](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/register-application.jpeg)

4. Select **Register**, then note the **Application (client) ID** and the **Directory (tenant) ID**.

   ![Application overview](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/application-overview.jpeg)

### Step 2: Grant the Business Central API permissions

1. Open the registered application and go to **API permissions** > **Add a permission**.
2. Select **Dynamics 365 Business Central**, then choose the permission set your integration needs — `Financials.ReadWrite.All` covers the operations in this connector.
3. Select **Add permissions**, then **Grant admin consent** for the tenant.

### Step 3: Create a client secret

1. In the registered application, go to **Certificates & secrets** > **Client secrets** > **New client secret**.

   ![Add client secret](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-microsoft.dynamics365.bc/refs/heads/main/docs/resources/add-client-secret.png)

2. Add a description and an expiry, select **Add**, and copy the secret **Value** immediately — it is shown only once.

### Step 4: Register the application in Business Central

1. Sign in to your Business Central environment and open the **Microsoft Entra Applications** page.
2. Create an entry for the client ID from step 1, set its state to **Enabled**, and assign the permission sets the integration needs (for example `D365 BUS FULL ACCESS`).

### Step 5: Obtain an access token

Request a token from the Microsoft identity platform for the scope `https://api.businesscentral.dynamics.com/.default`, using the tenant ID, client ID and client secret from the steps above. The resulting access token is what the connector sends as its bearer token.

### Step 6: Find the environment and company

The service URL carries the environment name — `https://api.businesscentral.dynamics.com/v2.0/{environment}/api/v1.0`, where `{environment}` is `production` by default and can be a sandbox name instead. The client defaults to the production environment; pass a different service URL to `init` to target a sandbox. Call `listCompanies` to obtain the identifier of the company the integration works in.

## Quickstart

To use the Business Central connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerinax/microsoft.dynamics365.bc as bc;
```

### Step 2: Instantiate a new connector

Create a `Config.toml` file with the access token obtained in the setup guide:

```toml
token = "<access token>"
```

Then initialise the client:

```ballerina
configurable string token = ?;

final bc:Client dynamics365 = check new ({auth: {token}});
```

To work against a sandbox environment, pass the service URL explicitly:

```ballerina
final bc:Client sandboxClient = check new (
    {auth: {token}},
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

1. [Customer invoice workflow](examples/customer_invoice_workflow/customer_invoice_workflow.md) — Onboard a customer, raise a sales invoice with a line, and post it to the general ledger.
2. [Item catalog management](examples/item_catalog_management/item_catalog_management.md) — Review the item catalog, register a new stocked item, and correct its price with an `If-Match` guarded update.
3. [Sales order processing](examples/sales_order_processing/sales_order_processing.md) — Open a sales order for an existing customer and read back the lines that belong to it.
4. [Financial ledger review](examples/financial_ledger_review/financial_ledger_review.md) — Take a month-end snapshot of the chart of accounts, the bank accounts, and the posted ledger entries.

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`microsoft.dynamics365.bc` package](https://central.ballerina.io/ballerinax/microsoft.dynamics365.bc/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
