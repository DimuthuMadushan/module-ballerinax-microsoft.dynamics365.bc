# Financial ledger review

Pulls a month-end financial snapshot out of a Microsoft Dynamics 365 Business Central
company: the chart of accounts, the bank accounts the company settles through, and the
general ledger entries posted in the period, totalled by debit and credit.

The ledger read uses an OData `$filter` expression to restrict the entries to one posting
period. Filtering narrows the result but does not page through it: the example reads a
single response and does not follow `@odata.nextLink` to continuation pages, so the entry
count and the debit and credit totals cover only the entries returned in that response, not
every entry that matches the filter.

## Prerequisites

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
