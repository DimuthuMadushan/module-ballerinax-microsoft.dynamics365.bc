# Sales order processing

Processes sales orders for a Microsoft Dynamics 365 Business Central company. The example
picks the customer to sell to, opens a sales order for them, adds an item line, reads back
the lines that belong to that order, and reports how many sales orders were returned when
listing at most 20 of the company's orders.

It shows how a child collection is addressed through its parent — order lines are read from
the order they belong to, not from the company-wide collection.

## Prerequisites

- An OAuth 2.0 access token for the Business Central API, and the identifiers of the target
  company and of an item to sell. See the [setup guide](../../ballerina/README.md#setup-guide).
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
