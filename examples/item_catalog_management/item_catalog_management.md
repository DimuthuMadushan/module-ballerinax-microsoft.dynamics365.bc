# Item catalog management

Keeps a product catalog in Microsoft Dynamics 365 Business Central current. The example
reads the items already registered in a company, adds a new stocked item, and then corrects
its unit price with a conditional update.

The update sends an `If-Match` header, which is how Business Central guards against lost
updates: the request is rejected when the record has changed since it was read.

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
