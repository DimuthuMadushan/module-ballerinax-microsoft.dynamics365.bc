# Customer invoice workflow

Onboards a new customer in a Microsoft Dynamics 365 Business Central company and bills them
end to end: the customer record is created, a draft sales invoice is raised against it, an
item line is added, and the invoice is posted so the posted document and the matching
general ledger entries are produced.

This is the shape of an order-to-cash integration — a system of record outside Business
Central creates the customer and the invoice, and hands the posting step to Business Central.

## Prerequisites

- Ballerina Swan Lake 2201.13.4 or later
- Push the connector to the local repository:
  ```bash
  cd ballerina
  bal pack && bal push --repository=local
  ```
- An OAuth 2.0 access token for the Business Central API, and the identifiers of the target
  company and of an item to invoice. See the [setup guide](../../ballerina/README.md#setup-guide).
- Create a `Config.toml` in this directory:
  ```toml
  token = "<access token>"
  companyId = "<company id>"
  itemId = "<item id>"
  ```

## Run the example

```bash
bal run
```
