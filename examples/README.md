# Examples

The `ballerinax/microsoft.dynamics365.bc` connector provides practical examples illustrating usage in various scenarios.

The examples below work through the transactional surface — master data, sales documents
and the ledger. The connector also exposes the financial statement reports (balance sheet,
income statement, cash flow statement, retained earnings statement, trial balance and the
two ageing reports), the document attachments, pictures and PDF documents, and the
reference data (currencies, payment terms and methods, shipment methods, item categories,
units of measure, countries/regions, tax areas and tax groups); those are read with the
same client and the same OData query options.

| Example | Description |
|---------|-------------|
| [`customer_invoice_workflow`](./customer_invoice_workflow/customer_invoice_workflow.md) | Onboard a customer, raise a sales invoice with a line, and post it to the general ledger. |
| [`item_catalog_management`](./item_catalog_management/item_catalog_management.md) | Review the item catalog, register a new stocked item, and correct its price with an update sent with `If-Match: *`. |
| [`sales_order_processing`](./sales_order_processing/sales_order_processing.md) | Open a sales order for an existing customer, add an item line, and read back the lines that belong to it. |
| [`financial_ledger_review`](./financial_ledger_review/financial_ledger_review.md) | Take a month-end snapshot of the chart of accounts, the bank accounts, and the posted ledger entries returned in one response. |

## Prerequisites

1. Obtain an OAuth 2.0 access token for the Business Central API, as described in the
   [setup guide](../ballerina/README.md#setup-guide), and note the identifier of the
   company the example should run against.

2. Build and push the connector to your local Ballerina repository. Starting from this
   `examples` directory, push the connector and then enter the example to run:

    ```bash
    cd ../ballerina
    bal pack && bal push --repository=local
    cd ../examples/<example>
    ```

3. For each example, create a `Config.toml` in that example's directory with the values it
   declares as `configurable` — every example needs `token` and `companyId`, and
   `customer_invoice_workflow` also needs `itemId` and `invoiceDate`, and
   `sales_order_processing` also needs `itemId`:

    ```toml
    token = "<access token>"
    companyId = "<company id>"
    ```

## Running an example

Execute the following commands from the example's directory to build it from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
