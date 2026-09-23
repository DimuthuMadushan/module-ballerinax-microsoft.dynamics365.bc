# Financial ledger review

Pulls a month-end financial snapshot out of a Microsoft Dynamics 365 Business Central
company: the chart of accounts, the bank accounts the company settles through, and the
general ledger entries posted in the period, totalled by debit and credit.

The ledger read uses an OData `$filter` expression to restrict the entries to one posting
period, which is how any reporting integration should page a large ledger.

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
