# Tests

The test suite exercises a representative slice of the connector's 324 operations,
covering every group in the surface:

- **Company scope** — `listCompanies`, `getCompany`.
- **Master data CRUD** — `listItems`/`createItem`/`getItem`/`updateItem`/`deleteItem` and
  the customer equivalents.
- **Documents and journals** — the read paths for vendors, employees, sales invoices, sales
  orders, sales quotes, purchase invoices, journals, general ledger accounts, bank accounts,
  general ledger entries and projects, plus the nested line collection
  (`listSalesInvoiceLinesForSalesInvoice`).
- **Bound actions** — the no-content lifecycle actions `postSalesInvoice` and `postJournal`.
  Each posting test creates its own draft first (a sales invoice with one item line, and a
  journal batch with a balanced pair of lines), so a run never posts a shared record.
- **Financial reports** — `listBalanceSheetLines`, `listIncomeStatementLines`,
  `listCashFlowStatementLines`, `listRetainedEarningsStatementLines`,
  `listTrialBalanceLines`, `listAgedAccountsReceivable` and `listAgedAccountsPayable`.
- **Documents and media** — `listAttachments`, `listGeneralLedgerEntryAttachments`,
  `listPictures` and `listPdfDocuments`. The `picture` entity carries
  `content@odata.mediaReadLink` rather than the image bytes, so the test asserts on the
  media link; `pdfDocument` and the attachment entities carry the content inline as
  `byte[]` plus a file name.
- **Reference data** — `listCurrencies`, `listPaymentTerms`, `listPaymentMethods`,
  `listShipmentMethods`, `listItemCategories`, `listCountriesRegions`, `listTaxAreas`,
  `listTaxGroups`, `listUnitsOfMeasure`, and the key-segment reads `getTaxGroup` and
  `getUnitOfMeasure`.

Each delete test creates the record it removes, because tests execute in alphabetical
order and a shared fixture would otherwise disappear before the tests that read it.

## Running tests

```bash
bal test
```

The suite runs against the mock server in `tests/mock_service.bal`, which listens on
`localhost:9090` and serves the OData key segments (`companies(<id>)/items(<id>)`) the
client produces. No credentials are required.

## Running tests against a live environment

Use an isolated **sandbox** environment, never production. Set `IS_LIVE_SERVER` and supply
the sandbox's service URL, an OAuth 2.0 access token and identifiers that exist in the
target company:

```bash
export IS_LIVE_SERVER=true
export BC_SERVICE_URL="https://api.businesscentral.dynamics.com/v2.0/<sandbox environment>/api/v1.0"
export BC_ACCESS_TOKEN="<access token>"
export BC_COMPANY_ID="<company id>"
export BC_ITEM_ID="<item id>"
export BC_CUSTOMER_ID="<customer id>"
export BC_EMPLOYEE_ID="<employee id>"
export BC_SALES_INVOICE_ID="<sales invoice id>"
export BC_TAX_GROUP_ID="<tax group id>"
export BC_UNIT_OF_MEASURE_ID="<unit of measure id>"
bal test --groups live_tests
```

The posting tests are in a separate `sandbox_posting_tests` group, because posting writes
ledger entries that cannot be undone. They also refuse to run against a live environment
unless `BC_SANDBOX_POSTING=true` confirms that the target is an isolated sandbox, and they
need a general ledger account that allows direct posting:

```bash
export BC_SANDBOX_POSTING=true
export BC_GL_ACCOUNT_ID="<direct-posting G/L account id>"
bal test --groups sandbox_posting_tests
```
