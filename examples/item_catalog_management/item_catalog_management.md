# Item catalog management

Keeps a product catalog in Microsoft Dynamics 365 Business Central current. The example
reads the items already registered in a company, adds a new stocked item, and then corrects
its unit price with an update.

Business Central requires an `If-Match` header on updates. The example sends the wildcard
`If-Match: *`, which only checks that the item exists — it does not compare ETags, so an
edit made by someone else since the item was read can be overwritten. To detect concurrent
changes, send the `@odata.etag` value returned with the item instead.

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
