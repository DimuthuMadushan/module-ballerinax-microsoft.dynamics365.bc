# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The initial Microsoft Dynamics 365 Business Central connector, for the Business Central standard API v1.0. Its `Client` connects to `https://api.businesscentral.dynamics.com/v2.0/production/api/v1.0` by default and authenticates with an OAuth 2.0 bearer token (`http:BearerTokenConfig`) set in `ConnectionConfig.auth`.
- 324 remote methods covering companies and company information; items, customers, vendors and employees, with their pictures and default dimensions; sales quotes, orders, invoices and credit memos, purchase invoices, and their lines and PDF documents; journals, journal lines, attachments and customer payments; accounts, general ledger entries and dimensions; financial reports such as balance sheet, trial balance, income statement, cash flow and aged receivables and payables; and setup entities such as currencies, payment methods and terms, tax areas and groups, units of measure, projects and bank accounts.
- Bound actions on sales and purchase documents, such as `postSalesInvoice`, `sendSalesInvoice`, `cancelSalesCreditMemo`, `makeOrderFromSalesQuote`, `shipAndInvoiceSalesOrder`, `postPurchaseInvoice` and `postJournal`.
- A `*Queries` record for each operation that takes OData query options, such as `ListCustomersQueries`, for `$filter`, `$select`, `$expand`, `$top` and `$skip`.
- A `headers` parameter on every remote method. The update methods take a typed headers record, such as `UpdateCustomerHeaders`, with the required `ifMatch` ETag.
