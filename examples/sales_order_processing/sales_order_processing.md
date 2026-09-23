# Sales order processing

Processes sales orders for a Microsoft Dynamics 365 Business Central company. The example
picks the customer to sell to, opens a sales order for them, reads back the lines that
belong to that order, and reports how many orders the company is currently carrying.

It shows how a child collection is addressed through its parent — order lines are read from
the order they belong to, not from the company-wide collection.

## Prerequisites

- Ballerina Swan Lake 2201.13.4 or later
- Push the connector to the local repository:
  ```bash
  cd ballerina
  bal pack && bal push --repository=local
  ```
- An OAuth 2.0 access token for the Business Central API and the identifier of the target
  company. See the [setup guide](../../ballerina/README.md#setup-guide).
- Create a `Config.toml` in this directory:
  ```toml
  token = "<access token>"
  companyId = "<company id>"
  ```

## Run the example

```bash
bal run
```
