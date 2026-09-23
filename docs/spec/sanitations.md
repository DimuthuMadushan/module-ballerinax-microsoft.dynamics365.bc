_Author_:  DimuthuMadushan \
_Created_: 2026/09/22 \
_Updated_: 2026/09/23 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Microsoft Dynamics 365 Business Central. 
The OpenAPI specification is obtained from the [Microsoft Dynamics 365 Business Central API (v1.0) reference](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/api-reference/v1.0/).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

1. Template the service URL with an `environment` server variable
- **Original**: The specification declared two hardcoded servers that differ only in one path segment: `https://api.businesscentral.dynamics.com/v2.0/sandbox/api/v1.0` and `https://api.businesscentral.dynamics.com/v2.0/production/api/v1.0`.
- **Updated**: Both were replaced by a single templated server, `https://api.businesscentral.dynamics.com/v2.0/{environment}/api/v1.0`, with the variable `environment` defaulting to `production` and enumerating `production` and `sandbox`.
- **Reason**: Two servers differing only in a path segment strand the environment choice on whichever server is listed first, because the generator only reads `servers[0]`. The templated form keeps the canonical service root in one place. `bal openapi` resolves the variable to its default, so the generated client defaults to `https://api.businesscentral.dynamics.com/v2.0/production/api/v1.0`; a sandbox is reached by passing a different `serviceUrl` to `init`.

2. Remove the redundant `Content-Type` header parameter
- **Original**: Every one of the 102 operations that carries a request body — 48 `POST` and 54 `PATCH` — referenced `components/parameters/ContentTypeParam`, a `required: true` header parameter whose description was the literal `application/json`.
- **Updated**: The reference was removed from every operation and the parameter component was deleted.
- **Reason**: The generated client already sets `Content-Type` from the request body's media type. Keeping the parameter forces the caller to pass the constant `"application/json"` on every write operation.

3. Map reserved-word parameters with `x-ballerina-name`
- **Original**: Under Ballerina 2201.13.4, `align` maps the `$select`, `$expand`, `$filter`, `$top`, `$skip` and `$limit` query parameters to the transliterated identifiers `dollarSelect`, `dollarExpand`, `dollarFilter`, `dollarTop`, `dollarSkip` and `dollarLimit`.
- **Updated**: The `x-ballerina-name` extension carries the bare names `select` (152 occurrences), `expand` (74), and `filter`, `top`, `skip` and `limit` (1 each, on the shared `components/parameters` entries).
- **Reason**: The `dollar*` transliteration is safe but does not read as the OData parameter it stands for. `select` and `limit` are Ballerina keywords, and 2201.13.4's generator quotes them automatically, emitting `'select` and `'limit` with the `@http:Query {name: "$select"}` annotations intact. Do **not** pre-quote the value in the specification: under 2201.13.4 an `x-ballerina-name` of `'select` is escaped to the identifier `\'select`, which is a different field name and breaks every record literal that uses it. Pre-quoting was required under 2201.12.0, which emitted the bare keyword and failed to compile with `invalid token 'select'`.

4. Give the request bodies a type and a name
- **Original**: The 36 request bodies under `components/requestBodies` declared `properties` without `type: object`, and were defined inline.
- **Updated**: Each schema was given `type: object` and moved into `components/schemas` as `<Entity>Request`, with the request body referencing it.
- **Reason**: Without `type: object` the generator emits an untyped `json` payload parameter; inline schemas produce an anonymous record spelled out in the method signature. Named schemas produce `ItemRequest`, `CustomerRequest` and so on.

5. Rename generated and vendor-shaped schema names
- **Original**: Flattening produced 52 `InlineResponse200*` collection wrappers, and the specification carried the lowercase compound names `Dimensiontype`, `Documentlineobjectdetailstype`, `Itemunitofmeasureconversiontype`, `Postaladdresstype` and `Unitofmeasuretype`, plus a singular record named `Attachments`.
- **Updated**: The wrappers were renamed after the entity they carry (`CompanyCollection`, `ItemCollection`, `BalanceSheetCollection`, …), the compound names became `DimensionType`, `DocumentLineObjectDetails`, `ItemUnitOfMeasureConversion`, `PostalAddress` and `UnitOfMeasureDetail`, and `Attachments` became `Attachment`. The aligned specification now declares 145 schemas: 52 collection wrappers, 36 request payloads and 57 entity records.
- **Reason**: Response wrappers must be named after the operations that use them, and record names must read as Ballerina type names.

6. Normalise the operation identifiers
- **Original**: Create and update operations were named `post*` and `patch*`, and the bound OData actions were named after the path, for example `postActionSalesInvoices` and `makeCorrectiveCreditMemoActionSalesInvoices`.
- **Updated**: 149 of the 324 identifiers were renamed. All 54 `post*` identifiers were rewritten — 48 to `create*`, and 6 to the Business Central `post` action (`postJournal`, `postPurchaseInvoice`, `postSalesInvoice`, `postSalesCreditMemo`, `postAndSendSalesInvoice`, `postAndSendSalesCreditMemo`). All 54 `patch*` became `update*`. The remaining 11 bound actions took the API's own verb and the singular entity, for example `cancelSalesInvoice`, `sendSalesCreditMemo`, `makeInvoiceFromSalesQuote` and `shipAndInvoiceSalesOrder`, giving 17 bound actions in total. A further 30 read and delete identifiers were corrected: 18 for number agreement (`listPicture*` → `listPictures*`, `listPdfDocument*` → `listPdfDocuments*`, `getAttachments*`/`deleteAttachments*` → `getAttachment*`/`deleteAttachment*`), 10 because a financial statement is read a row at a time (`listBalanceSheet` → `listBalanceSheetLines`, `getTrialBalance` → `getTrialBalanceLine`), and 2 to name the key the ageing reports are addressed by (`getAgedAccountsPayable` → `getAgedAccountsPayableByVendor`, `getAgedAccountsReceivable` → `getAgedAccountsReceivableByCustomer`). The resulting surface is 76 `list*`, 76 `get*`, 48 `create*`, 54 `update*`, 53 `delete*` and 17 bound actions. Nested collections keep the `For<Parent>` suffix — `listSalesInvoiceLinesForSalesInvoice` against the company-wide `listSalesInvoiceLines` — because the same collection exists at two levels.
- **Reason**: The house convention is `list` / `get` / `create` / `update` / `delete` plus the API's own action verb. Renaming the create operations also frees `post*` for the Business Central `post` action, which has a different meaning. Some nested identifiers exceed the 37-character guidance; the parent qualifier is what keeps them unambiguous, so it was kept.

7. Rewrite the operation, parameter and schema documentation
- **Original**: Every description carried a `(v1.0)` prefix and the misspelling `Succesfully`, and the text was generated boilerplate — `Updates an object of type salesInvoiceLine in Dynamics 365 Business Central`, `(v1.0) The unitPrice property for the Dynamics 365 Business Central item entity`, `(v1.0) id for company`. The document title was `(v1.0) Dynamics 365 Business Central`. Request bodies and schemas had no description at all.
- **Updated**: The prefix and the misspelling were removed everywhere except `info.description`, which became `Business Central Standard APIs (v1.0) for Microsoft Dynamics 365 Business Central.` — there the version is part of the sentence rather than a prefix, and it is the doc comment of the generated `Client` class. `info.title` became `Dynamics 365 Business Central`. In the body, 324 operation summaries, 324 response descriptions, 550 parameter descriptions, 1,331 property descriptions, 36 request-body descriptions and 145 schema descriptions were rewritten in terms of the business object and its scope. Summaries are distinct for all 324 operations. A property that was a bare `$ref` cannot carry a sibling `description` under OpenAPI 3.0, so the 118 navigation properties were rewrapped as `allOf: [{$ref: …}]` with the description alongside.
- **Reason**: These strings become the doc comments of the generated client, and the generated boilerplate repeated the field name without explaining it. The bare-`$ref` rewrap is what keeps the doc comment on the 118 navigation properties.

8. Generated with Ballerina 2201.13.4
- **Original**: —
- **Updated**: The client, types and mock service were generated with Ballerina 2201.13.4, the distribution the package declares in `ballerina/Ballerina.toml`, `build-config/resources/Ballerina.toml` and `gradle.properties`.
- **Reason**: `bal openapi` is deterministic within a distribution but not across distributions. Under 2201.13.4 the 70 no-content operations generate as `returns error?`, and the tool carries parameter descriptions into the `*Queries` and `*Headers` records natively, so no post-generation documentation pass is needed. Regenerate only under 2201.13.4.

9. Change `TimeRegistrationEntry date` to nullable
- **Original**: The `date` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `date` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

10. Change `TimeRegistrationEntry quantity` to nullable
- **Original**: The `quantity` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

11. Change `TimeRegistrationEntry absence` to nullable
- **Original**: The `absence` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `absence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

12. Change `TimeRegistrationEntry employeeId` to nullable
- **Original**: The `employeeId` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `employeeId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

13. Change `TimeRegistrationEntry unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

14. Change `TimeRegistrationEntry employeeNumber` to nullable
- **Original**: The `employeeNumber` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `employeeNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

15. Change `TimeRegistrationEntry lastModfiedDateTime` to nullable
- **Original**: The `lastModfiedDateTime` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `lastModfiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

16. Change `TimeRegistrationEntry jobId` to nullable
- **Original**: The `jobId` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `jobId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

17. Change `TimeRegistrationEntry lineNumber` to nullable
- **Original**: The `lineNumber` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `lineNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

18. Change `TimeRegistrationEntry jobNumber` to nullable
- **Original**: The `jobNumber` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `jobNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

19. Change `TimeRegistrationEntry status` to nullable
- **Original**: The `status` field in `TimeRegistrationEntry` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

20. Change `Account number` to nullable
- **Original**: The `number` field in `Account` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

21. Change `Account subCategory` to nullable
- **Original**: The `subCategory` field in `Account` was `not nullable`.
- **Updated**: The `subCategory` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

22. Change `Account lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `Account` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

23. Change `Account blocked` to nullable
- **Original**: The `blocked` field in `Account` was `not nullable`.
- **Updated**: The `blocked` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

24. Change `Account displayName` to nullable
- **Original**: The `displayName` field in `Account` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

25. Change `Account category` to nullable
- **Original**: The `category` field in `Account` was `not nullable`.
- **Updated**: The `category` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

26. Change `GeneralLedgerEntry accountId` to nullable
- **Original**: The `accountId` field in `GeneralLedgerEntry` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

27. Change `GeneralLedgerEntry lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `GeneralLedgerEntry` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

28. Change `GeneralLedgerEntry documentType` to nullable
- **Original**: The `documentType` field in `GeneralLedgerEntry` was `not nullable`.
- **Updated**: The `documentType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

29. Change `GeneralLedgerEntry documentNumber` to nullable
- **Original**: The `documentNumber` field in `GeneralLedgerEntry` was `not nullable`.
- **Updated**: The `documentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

30. Change `GeneralLedgerEntry description` to nullable
- **Original**: The `description` field in `GeneralLedgerEntry` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

31. Change `GeneralLedgerEntry postingDate` to nullable
- **Original**: The `postingDate` field in `GeneralLedgerEntry` was `not nullable`.
- **Updated**: The `postingDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

32. Change `GeneralLedgerEntry debitAmount` to nullable
- **Original**: The `debitAmount` field in `GeneralLedgerEntry` was `not nullable`.
- **Updated**: The `debitAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

33. Change `GeneralLedgerEntry accountNumber` to nullable
- **Original**: The `accountNumber` field in `GeneralLedgerEntry` was `not nullable`.
- **Updated**: The `accountNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

34. Change `GeneralLedgerEntry creditAmount` to nullable
- **Original**: The `creditAmount` field in `GeneralLedgerEntry` was `not nullable`.
- **Updated**: The `creditAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

35. Change `Customer lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `Customer` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

36. Change `Customer shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `Customer` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

37. Change `Customer taxLiable` to nullable
- **Original**: The `taxLiable` field in `Customer` was `not nullable`.
- **Updated**: The `taxLiable` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

38. Change `Customer type` to nullable
- **Original**: The `type` field in `Customer` was `not nullable`.
- **Updated**: The `type` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

39. Change `Customer number` to nullable
- **Original**: The `number` field in `Customer` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

40. Change `Customer paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `Customer` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

41. Change `Customer blocked` to nullable
- **Original**: The `blocked` field in `Customer` was `not nullable`.
- **Updated**: The `blocked` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

42. Change `Customer paymentMethodId` to nullable
- **Original**: The `paymentMethodId` field in `Customer` was `not nullable`.
- **Updated**: The `paymentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

43. Change `Customer currencyId` to nullable
- **Original**: The `currencyId` field in `Customer` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

44. Change `Customer taxAreaDisplayName` to nullable
- **Original**: The `taxAreaDisplayName` field in `Customer` was `not nullable`.
- **Updated**: The `taxAreaDisplayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

45. Change `Customer email` to nullable
- **Original**: The `email` field in `Customer` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

46. Change `Customer website` to nullable
- **Original**: The `website` field in `Customer` was `not nullable`.
- **Updated**: The `website` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

47. Change `Customer picture` to nullable
- **Original**: The `picture` field in `Customer` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

48. Change `Customer phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `Customer` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

49. Change `Customer taxAreaId` to nullable
- **Original**: The `taxAreaId` field in `Customer` was `not nullable`.
- **Updated**: The `taxAreaId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

50. Change `Customer taxRegistrationNumber` to nullable
- **Original**: The `taxRegistrationNumber` field in `Customer` was `not nullable`.
- **Updated**: The `taxRegistrationNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

51. Change `Customer defaultDimensions` to nullable
- **Original**: The `defaultDimensions` field in `Customer` was `not nullable`.
- **Updated**: The `defaultDimensions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

52. Change `Customer currencyCode` to nullable
- **Original**: The `currencyCode` field in `Customer` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

53. Change `Customer customerFinancialDetails` to nullable
- **Original**: The `customerFinancialDetails` field in `Customer` was `not nullable`.
- **Updated**: The `customerFinancialDetails` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

54. Change `CustomerPayment amount` to nullable
- **Original**: The `amount` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

55. Change `CustomerPayment lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

56. Change `CustomerPayment contactId` to nullable
- **Original**: The `contactId` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

57. Change `CustomerPayment documentNumber` to nullable
- **Original**: The `documentNumber` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `documentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

58. Change `CustomerPayment description` to nullable
- **Original**: The `description` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

59. Change `CustomerPayment postingDate` to nullable
- **Original**: The `postingDate` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `postingDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

60. Change `CustomerPayment customerNumber` to nullable
- **Original**: The `customerNumber` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

61. Change `CustomerPayment journalDisplayName` to nullable
- **Original**: The `journalDisplayName` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `journalDisplayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

62. Change `CustomerPayment appliesToInvoiceNumber` to nullable
- **Original**: The `appliesToInvoiceNumber` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `appliesToInvoiceNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

63. Change `CustomerPayment appliesToInvoiceId` to nullable
- **Original**: The `appliesToInvoiceId` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `appliesToInvoiceId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

64. Change `CustomerPayment customerId` to nullable
- **Original**: The `customerId` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

65. Change `CustomerPayment externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

66. Change `CustomerPayment comment` to nullable
- **Original**: The `comment` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `comment` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

67. Change `CustomerPayment lineNumber` to nullable
- **Original**: The `lineNumber` field in `CustomerPayment` was `not nullable`.
- **Updated**: The `lineNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

68. Change `Item unitPrice` to nullable
- **Original**: The `unitPrice` field in `Item` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

69. Change `Item gtin` to nullable
- **Original**: The `gtin` field in `Item` was `not nullable`.
- **Updated**: The `gtin` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

70. Change `Item lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `Item` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

71. Change `Item displayName` to nullable
- **Original**: The `displayName` field in `Item` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

72. Change `Item itemCategoryId` to nullable
- **Original**: The `itemCategoryId` field in `Item` was `not nullable`.
- **Updated**: The `itemCategoryId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

73. Change `Item priceIncludesTax` to nullable
- **Original**: The `priceIncludesTax` field in `Item` was `not nullable`.
- **Updated**: The `priceIncludesTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

74. Change `Item itemCategoryCode` to nullable
- **Original**: The `itemCategoryCode` field in `Item` was `not nullable`.
- **Updated**: The `itemCategoryCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

75. Change `Item type` to nullable
- **Original**: The `type` field in `Item` was `not nullable`.
- **Updated**: The `type` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

76. Change `Item baseUnitOfMeasureId` to nullable
- **Original**: The `baseUnitOfMeasureId` field in `Item` was `not nullable`.
- **Updated**: The `baseUnitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

77. Change `Item inventory` to nullable
- **Original**: The `inventory` field in `Item` was `not nullable`.
- **Updated**: The `inventory` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

78. Change `Item picture` to nullable
- **Original**: The `picture` field in `Item` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

79. Change `Item number` to nullable
- **Original**: The `number` field in `Item` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

80. Change `Item blocked` to nullable
- **Original**: The `blocked` field in `Item` was `not nullable`.
- **Updated**: The `blocked` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

81. Change `Item unitCost` to nullable
- **Original**: The `unitCost` field in `Item` was `not nullable`.
- **Updated**: The `unitCost` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

82. Change `Item taxGroupId` to nullable
- **Original**: The `taxGroupId` field in `Item` was `not nullable`.
- **Updated**: The `taxGroupId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

83. Change `Item taxGroupCode` to nullable
- **Original**: The `taxGroupCode` field in `Item` was `not nullable`.
- **Updated**: The `taxGroupCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

84. Change `Item defaultDimensions` to nullable
- **Original**: The `defaultDimensions` field in `Item` was `not nullable`.
- **Updated**: The `defaultDimensions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

85. Change `CustomerSale dateFilter_FilterOnly` to nullable
- **Original**: The `dateFilter_FilterOnly` field in `CustomerSale` was `not nullable`.
- **Updated**: The `dateFilter_FilterOnly` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

86. Change `CustomerSale totalSalesAmount` to nullable
- **Original**: The `totalSalesAmount` field in `CustomerSale` was `not nullable`.
- **Updated**: The `totalSalesAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

87. Change `ItemCategory lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `ItemCategory` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

88. Change `ItemCategory displayName` to nullable
- **Original**: The `displayName` field in `ItemCategory` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

89. Change `Picture content@odata.mediaEditLink` to nullable
- **Original**: The `content@odata.mediaEditLink` field in `Picture` was `not nullable`.
- **Updated**: The `content@odata.mediaEditLink` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

90. Change `Picture content@odata.mediaReadLink` to nullable
- **Original**: The `content@odata.mediaReadLink` field in `Picture` was `not nullable`.
- **Updated**: The `content@odata.mediaReadLink` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

91. Change `Picture width` to nullable
- **Original**: The `width` field in `Picture` was `not nullable`.
- **Updated**: The `width` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

92. Change `Picture contentType` to nullable
- **Original**: The `contentType` field in `Picture` was `not nullable`.
- **Updated**: The `contentType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

93. Change `Picture height` to nullable
- **Original**: The `height` field in `Picture` was `not nullable`.
- **Updated**: The `height` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

94. Change `Currency symbol` to nullable
- **Original**: The `symbol` field in `Currency` was `not nullable`.
- **Updated**: The `symbol` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

95. Change `Currency lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `Currency` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

96. Change `Currency displayName` to nullable
- **Original**: The `displayName` field in `Currency` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

97. Change `Currency amountDecimalPlaces` to nullable
- **Original**: The `amountDecimalPlaces` field in `Currency` was `not nullable`.
- **Updated**: The `amountDecimalPlaces` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

98. Change `Currency amountRoundingPrecision` to nullable
- **Original**: The `amountRoundingPrecision` field in `Currency` was `not nullable`.
- **Updated**: The `amountRoundingPrecision` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

99. Change `CustomerPaymentJournal balancingAccountNumber` to nullable
- **Original**: The `balancingAccountNumber` field in `CustomerPaymentJournal` was `not nullable`.
- **Updated**: The `balancingAccountNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

100. Change `CustomerPaymentJournal lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CustomerPaymentJournal` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

101. Change `CustomerPaymentJournal customerPayments` to nullable
- **Original**: The `customerPayments` field in `CustomerPaymentJournal` was `not nullable`.
- **Updated**: The `customerPayments` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

102. Change `CustomerPaymentJournal displayName` to nullable
- **Original**: The `displayName` field in `CustomerPaymentJournal` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

103. Change `CustomerPaymentJournal balancingAccountId` to nullable
- **Original**: The `balancingAccountId` field in `CustomerPaymentJournal` was `not nullable`.
- **Updated**: The `balancingAccountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

104. Change `SalesOrderLine discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

105. Change `SalesOrderLine description` to nullable
- **Original**: The `description` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

106. Change `SalesOrderLine discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

107. Change `SalesOrderLine invoiceDiscountAllocation` to nullable
- **Original**: The `invoiceDiscountAllocation` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `invoiceDiscountAllocation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

108. Change `SalesOrderLine lineType` to nullable
- **Original**: The `lineType` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

109. Change `SalesOrderLine shippedQuantity` to nullable
- **Original**: The `shippedQuantity` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `shippedQuantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

110. Change `SalesOrderLine taxPercent` to nullable
- **Original**: The `taxPercent` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

111. Change `SalesOrderLine shipmentDate` to nullable
- **Original**: The `shipmentDate` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `shipmentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

112. Change `SalesOrderLine unitPrice` to nullable
- **Original**: The `unitPrice` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

113. Change `SalesOrderLine quantity` to nullable
- **Original**: The `quantity` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

114. Change `SalesOrderLine discountPercent` to nullable
- **Original**: The `discountPercent` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

115. Change `SalesOrderLine netAmount` to nullable
- **Original**: The `netAmount` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

116. Change `SalesOrderLine amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

117. Change `SalesOrderLine unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

118. Change `SalesOrderLine taxCode` to nullable
- **Original**: The `taxCode` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

119. Change `SalesOrderLine netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

120. Change `SalesOrderLine invoicedQuantity` to nullable
- **Original**: The `invoicedQuantity` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `invoicedQuantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

121. Change `SalesOrderLine shipQuantity` to nullable
- **Original**: The `shipQuantity` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `shipQuantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

122. Change `SalesOrderLine sequence` to nullable
- **Original**: The `sequence` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

123. Change `SalesOrderLine itemId` to nullable
- **Original**: The `itemId` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

124. Change `SalesOrderLine accountId` to nullable
- **Original**: The `accountId` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

125. Change `SalesOrderLine invoiceQuantity` to nullable
- **Original**: The `invoiceQuantity` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `invoiceQuantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

126. Change `SalesOrderLine netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

127. Change `SalesOrderLine documentId` to nullable
- **Original**: The `documentId` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

128. Change `SalesOrderLine totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

129. Change `SalesOrderLine amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `SalesOrderLine` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

130. Change `UnitOfMeasureDetail symbol` to nullable
- **Original**: The `symbol` field in `UnitOfMeasureDetail` was `not nullable`.
- **Updated**: The `symbol` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

131. Change `UnitOfMeasureDetail code` to nullable
- **Original**: The `code` field in `UnitOfMeasureDetail` was `not nullable`.
- **Updated**: The `code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

132. Change `UnitOfMeasureDetail displayName` to nullable
- **Original**: The `displayName` field in `UnitOfMeasureDetail` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

133. Change `UnitOfMeasureDetail defaultDimensions` to nullable
- **Original**: The `defaultDimensions` field in `UnitOfMeasureDetail` was `not nullable`.
- **Updated**: The `defaultDimensions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

134. Change `UnitOfMeasureDetail picture` to nullable
- **Original**: The `picture` field in `UnitOfMeasureDetail` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

135. Change `CountryRegion lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CountryRegion` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

136. Change `CountryRegion displayName` to nullable
- **Original**: The `displayName` field in `CountryRegion` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

137. Change `CountryRegion addressFormat` to nullable
- **Original**: The `addressFormat` field in `CountryRegion` was `not nullable`.
- **Updated**: The `addressFormat` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

138. Change `TrialBalance accountId` to nullable
- **Original**: The `accountId` field in `TrialBalance` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

139. Change `TrialBalance totalCredit` to nullable
- **Original**: The `totalCredit` field in `TrialBalance` was `not nullable`.
- **Updated**: The `totalCredit` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

140. Change `TrialBalance accountType` to nullable
- **Original**: The `accountType` field in `TrialBalance` was `not nullable`.
- **Updated**: The `accountType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

141. Change `TrialBalance display` to nullable
- **Original**: The `display` field in `TrialBalance` was `not nullable`.
- **Updated**: The `display` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

142. Change `TrialBalance balanceAtDateCredit` to nullable
- **Original**: The `balanceAtDateCredit` field in `TrialBalance` was `not nullable`.
- **Updated**: The `balanceAtDateCredit` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

143. Change `TrialBalance totalDebit` to nullable
- **Original**: The `totalDebit` field in `TrialBalance` was `not nullable`.
- **Updated**: The `totalDebit` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

144. Change `TrialBalance balanceAtDateDebit` to nullable
- **Original**: The `balanceAtDateDebit` field in `TrialBalance` was `not nullable`.
- **Updated**: The `balanceAtDateDebit` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

145. Change `TrialBalance dateFilter` to nullable
- **Original**: The `dateFilter` field in `TrialBalance` was `not nullable`.
- **Updated**: The `dateFilter` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

146. Change `DimensionType valueDisplayName` to nullable
- **Original**: The `valueDisplayName` field in `DimensionType` was `not nullable`.
- **Updated**: The `valueDisplayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

147. Change `DimensionType displayName` to nullable
- **Original**: The `displayName` field in `DimensionType` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

148. Change `Project number` to nullable
- **Original**: The `number` field in `Project` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

149. Change `Project displayName` to nullable
- **Original**: The `displayName` field in `Project` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

150. Change `Employee statisticsGroupCode` to nullable
- **Original**: The `statisticsGroupCode` field in `Employee` was `not nullable`.
- **Updated**: The `statisticsGroupCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

151. Change `Employee lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `Employee` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

152. Change `Employee displayName` to nullable
- **Original**: The `displayName` field in `Employee` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

153. Change `Employee employmentDate` to nullable
- **Original**: The `employmentDate` field in `Employee` was `not nullable`.
- **Updated**: The `employmentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

154. Change `Employee givenName` to nullable
- **Original**: The `givenName` field in `Employee` was `not nullable`.
- **Updated**: The `givenName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

155. Change `Employee jobTitle` to nullable
- **Original**: The `jobTitle` field in `Employee` was `not nullable`.
- **Updated**: The `jobTitle` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

156. Change `Employee birthDate` to nullable
- **Original**: The `birthDate` field in `Employee` was `not nullable`.
- **Updated**: The `birthDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

157. Change `Employee picture` to nullable
- **Original**: The `picture` field in `Employee` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

158. Change `Employee personalEmail` to nullable
- **Original**: The `personalEmail` field in `Employee` was `not nullable`.
- **Updated**: The `personalEmail` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

159. Change `Employee terminationDate` to nullable
- **Original**: The `terminationDate` field in `Employee` was `not nullable`.
- **Updated**: The `terminationDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

160. Change `Employee number` to nullable
- **Original**: The `number` field in `Employee` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

161. Change `Employee phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `Employee` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

162. Change `Employee mobilePhone` to nullable
- **Original**: The `mobilePhone` field in `Employee` was `not nullable`.
- **Updated**: The `mobilePhone` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

163. Change `Employee surname` to nullable
- **Original**: The `surname` field in `Employee` was `not nullable`.
- **Updated**: The `surname` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

164. Change `Employee timeRegistrationEntries` to nullable
- **Original**: The `timeRegistrationEntries` field in `Employee` was `not nullable`.
- **Updated**: The `timeRegistrationEntries` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

165. Change `Employee middleName` to nullable
- **Original**: The `middleName` field in `Employee` was `not nullable`.
- **Updated**: The `middleName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

166. Change `Employee defaultDimensions` to nullable
- **Original**: The `defaultDimensions` field in `Employee` was `not nullable`.
- **Updated**: The `defaultDimensions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

167. Change `Employee email` to nullable
- **Original**: The `email` field in `Employee` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

168. Change `Employee status` to nullable
- **Original**: The `status` field in `Employee` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

169. Change `DocumentLineObjectDetails number` to nullable
- **Original**: The `number` field in `DocumentLineObjectDetails` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

170. Change `DocumentLineObjectDetails displayName` to nullable
- **Original**: The `displayName` field in `DocumentLineObjectDetails` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

171. Change `BalanceSheet indentation` to nullable
- **Original**: The `indentation` field in `BalanceSheet` was `not nullable`.
- **Updated**: The `indentation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

172. Change `BalanceSheet balance` to nullable
- **Original**: The `balance` field in `BalanceSheet` was `not nullable`.
- **Updated**: The `balance` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

173. Change `BalanceSheet display` to nullable
- **Original**: The `display` field in `BalanceSheet` was `not nullable`.
- **Updated**: The `display` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

174. Change `BalanceSheet lineType` to nullable
- **Original**: The `lineType` field in `BalanceSheet` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

175. Change `BalanceSheet dateFilter` to nullable
- **Original**: The `dateFilter` field in `BalanceSheet` was `not nullable`.
- **Updated**: The `dateFilter` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

176. Change `GeneralLedgerEntryAttachments fileName` to nullable
- **Original**: The `fileName` field in `GeneralLedgerEntryAttachments` was `not nullable`.
- **Updated**: The `fileName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

177. Change `GeneralLedgerEntryAttachments byteSize` to nullable
- **Original**: The `byteSize` field in `GeneralLedgerEntryAttachments` was `not nullable`.
- **Updated**: The `byteSize` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

178. Change `GeneralLedgerEntryAttachments createdDateTime` to nullable
- **Original**: The `createdDateTime` field in `GeneralLedgerEntryAttachments` was `not nullable`.
- **Updated**: The `createdDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

179. Change `GeneralLedgerEntryAttachments content` to nullable
- **Original**: The `content` field in `GeneralLedgerEntryAttachments` was `not nullable`.
- **Updated**: The `content` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

180. Change `DimensionValue code` to nullable
- **Original**: The `code` field in `DimensionValue` was `not nullable`.
- **Updated**: The `code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

181. Change `DimensionValue lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `DimensionValue` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

182. Change `DimensionValue displayName` to nullable
- **Original**: The `displayName` field in `DimensionValue` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

183. Change `BankAccount number` to nullable
- **Original**: The `number` field in `BankAccount` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

184. Change `BankAccount displayName` to nullable
- **Original**: The `displayName` field in `BankAccount` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

185. Change `Dimension code` to nullable
- **Original**: The `code` field in `Dimension` was `not nullable`.
- **Updated**: The `code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

186. Change `Dimension lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `Dimension` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

187. Change `Dimension dimensionValues` to nullable
- **Original**: The `dimensionValues` field in `Dimension` was `not nullable`.
- **Updated**: The `dimensionValues` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

188. Change `Dimension displayName` to nullable
- **Original**: The `displayName` field in `Dimension` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

189. Change `TaxArea code` to nullable
- **Original**: The `code` field in `TaxArea` was `not nullable`.
- **Updated**: The `code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

190. Change `TaxArea lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `TaxArea` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

191. Change `TaxArea displayName` to nullable
- **Original**: The `displayName` field in `TaxArea` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

192. Change `TaxArea taxType` to nullable
- **Original**: The `taxType` field in `TaxArea` was `not nullable`.
- **Updated**: The `taxType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

193. Change `CompanyInformation website` to nullable
- **Original**: The `website` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `website` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

194. Change `CompanyInformation lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

195. Change `CompanyInformation displayName` to nullable
- **Original**: The `displayName` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

196. Change `CompanyInformation industry` to nullable
- **Original**: The `industry` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `industry` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

197. Change `CompanyInformation picture` to nullable
- **Original**: The `picture` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

198. Change `CompanyInformation phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

199. Change `CompanyInformation currentFiscalYearStartDate` to nullable
- **Original**: The `currentFiscalYearStartDate` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `currentFiscalYearStartDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

200. Change `CompanyInformation faxNumber` to nullable
- **Original**: The `faxNumber` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `faxNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

201. Change `CompanyInformation taxRegistrationNumber` to nullable
- **Original**: The `taxRegistrationNumber` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `taxRegistrationNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

202. Change `CompanyInformation currencyCode` to nullable
- **Original**: The `currencyCode` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

203. Change `CompanyInformation email` to nullable
- **Original**: The `email` field in `CompanyInformation` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

204. Change `VendorPurchase dateFilter_FilterOnly` to nullable
- **Original**: The `dateFilter_FilterOnly` field in `VendorPurchase` was `not nullable`.
- **Updated**: The `dateFilter_FilterOnly` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

205. Change `VendorPurchase totalPurchaseAmount` to nullable
- **Original**: The `totalPurchaseAmount` field in `VendorPurchase` was `not nullable`.
- **Updated**: The `totalPurchaseAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

206. Change `SalesCreditMemoLine discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

207. Change `SalesCreditMemoLine description` to nullable
- **Original**: The `description` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

208. Change `SalesCreditMemoLine discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

209. Change `SalesCreditMemoLine invoiceDiscountAllocation` to nullable
- **Original**: The `invoiceDiscountAllocation` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `invoiceDiscountAllocation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

210. Change `SalesCreditMemoLine lineType` to nullable
- **Original**: The `lineType` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

211. Change `SalesCreditMemoLine taxPercent` to nullable
- **Original**: The `taxPercent` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

212. Change `SalesCreditMemoLine shipmentDate` to nullable
- **Original**: The `shipmentDate` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `shipmentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

213. Change `SalesCreditMemoLine unitPrice` to nullable
- **Original**: The `unitPrice` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

214. Change `SalesCreditMemoLine quantity` to nullable
- **Original**: The `quantity` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

215. Change `SalesCreditMemoLine discountPercent` to nullable
- **Original**: The `discountPercent` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

216. Change `SalesCreditMemoLine netAmount` to nullable
- **Original**: The `netAmount` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

217. Change `SalesCreditMemoLine amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

218. Change `SalesCreditMemoLine unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

219. Change `SalesCreditMemoLine taxCode` to nullable
- **Original**: The `taxCode` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

220. Change `SalesCreditMemoLine netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

221. Change `SalesCreditMemoLine sequence` to nullable
- **Original**: The `sequence` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

222. Change `SalesCreditMemoLine itemId` to nullable
- **Original**: The `itemId` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

223. Change `SalesCreditMemoLine accountId` to nullable
- **Original**: The `accountId` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

224. Change `SalesCreditMemoLine netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

225. Change `SalesCreditMemoLine documentId` to nullable
- **Original**: The `documentId` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

226. Change `SalesCreditMemoLine totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

227. Change `SalesCreditMemoLine amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `SalesCreditMemoLine` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

228. Change `Company projects` to nullable
- **Original**: The `projects` field in `Company` was `not nullable`.
- **Updated**: The `projects` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

229. Change `Company trialBalance` to nullable
- **Original**: The `trialBalance` field in `Company` was `not nullable`.
- **Updated**: The `trialBalance` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

230. Change `Company bankAccounts` to nullable
- **Original**: The `bankAccounts` field in `Company` was `not nullable`.
- **Updated**: The `bankAccounts` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

231. Change `Company generalLedgerEntryAttachments` to nullable
- **Original**: The `generalLedgerEntryAttachments` field in `Company` was `not nullable`.
- **Updated**: The `generalLedgerEntryAttachments` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

232. Change `Company dimensionValues` to nullable
- **Original**: The `dimensionValues` field in `Company` was `not nullable`.
- **Updated**: The `dimensionValues` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

233. Change `Company pdfDocument` to nullable
- **Original**: The `pdfDocument` field in `Company` was `not nullable`.
- **Updated**: The `pdfDocument` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

234. Change `Company balanceSheet` to nullable
- **Original**: The `balanceSheet` field in `Company` was `not nullable`.
- **Updated**: The `balanceSheet` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

235. Change `Company vendors` to nullable
- **Original**: The `vendors` field in `Company` was `not nullable`.
- **Updated**: The `vendors` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

236. Change `Company paymentTerms` to nullable
- **Original**: The `paymentTerms` field in `Company` was `not nullable`.
- **Updated**: The `paymentTerms` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

237. Change `Company businessProfileId` to nullable
- **Original**: The `businessProfileId` field in `Company` was `not nullable`.
- **Updated**: The `businessProfileId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

238. Change `Company purchaseInvoices` to nullable
- **Original**: The `purchaseInvoices` field in `Company` was `not nullable`.
- **Updated**: The `purchaseInvoices` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

239. Change `Company salesQuotes` to nullable
- **Original**: The `salesQuotes` field in `Company` was `not nullable`.
- **Updated**: The `salesQuotes` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

240. Change `Company journals` to nullable
- **Original**: The `journals` field in `Company` was `not nullable`.
- **Updated**: The `journals` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

241. Change `Company shipmentMethods` to nullable
- **Original**: The `shipmentMethods` field in `Company` was `not nullable`.
- **Updated**: The `shipmentMethods` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

242. Change `Company salesCreditMemoLines` to nullable
- **Original**: The `salesCreditMemoLines` field in `Company` was `not nullable`.
- **Updated**: The `salesCreditMemoLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

243. Change `Company cashFlowStatement` to nullable
- **Original**: The `cashFlowStatement` field in `Company` was `not nullable`.
- **Updated**: The `cashFlowStatement` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

244. Change `Company name` to nullable
- **Original**: The `name` field in `Company` was `not nullable`.
- **Updated**: The `name` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

245. Change `Company salesInvoices` to nullable
- **Original**: The `salesInvoices` field in `Company` was `not nullable`.
- **Updated**: The `salesInvoices` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

246. Change `Company defaultDimensions` to nullable
- **Original**: The `defaultDimensions` field in `Company` was `not nullable`.
- **Updated**: The `defaultDimensions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

247. Change `Company employees` to nullable
- **Original**: The `employees` field in `Company` was `not nullable`.
- **Updated**: The `employees` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

248. Change `Company items` to nullable
- **Original**: The `items` field in `Company` was `not nullable`.
- **Updated**: The `items` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

249. Change `Company taxGroups` to nullable
- **Original**: The `taxGroups` field in `Company` was `not nullable`.
- **Updated**: The `taxGroups` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

250. Change `Company customerFinancialDetails` to nullable
- **Original**: The `customerFinancialDetails` field in `Company` was `not nullable`.
- **Updated**: The `customerFinancialDetails` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

251. Change `Company attachments` to nullable
- **Original**: The `attachments` field in `Company` was `not nullable`.
- **Updated**: The `attachments` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

252. Change `Company displayName` to nullable
- **Original**: The `displayName` field in `Company` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

253. Change `Company incomeStatement` to nullable
- **Original**: The `incomeStatement` field in `Company` was `not nullable`.
- **Updated**: The `incomeStatement` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

254. Change `Company customerSales` to nullable
- **Original**: The `customerSales` field in `Company` was `not nullable`.
- **Updated**: The `customerSales` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

255. Change `Company taxAreas` to nullable
- **Original**: The `taxAreas` field in `Company` was `not nullable`.
- **Updated**: The `taxAreas` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

256. Change `Company retainedEarningsStatement` to nullable
- **Original**: The `retainedEarningsStatement` field in `Company` was `not nullable`.
- **Updated**: The `retainedEarningsStatement` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

257. Change `Company systemVersion` to nullable
- **Original**: The `systemVersion` field in `Company` was `not nullable`.
- **Updated**: The `systemVersion` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

258. Change `Company agedAccountsPayable` to nullable
- **Original**: The `agedAccountsPayable` field in `Company` was `not nullable`.
- **Updated**: The `agedAccountsPayable` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

259. Change `Company agedAccountsReceivable` to nullable
- **Original**: The `agedAccountsReceivable` field in `Company` was `not nullable`.
- **Updated**: The `agedAccountsReceivable` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

260. Change `Company companyInformation` to nullable
- **Original**: The `companyInformation` field in `Company` was `not nullable`.
- **Updated**: The `companyInformation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

261. Change `Company customerPaymentJournals` to nullable
- **Original**: The `customerPaymentJournals` field in `Company` was `not nullable`.
- **Updated**: The `customerPaymentJournals` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

262. Change `Company timeRegistrationEntries` to nullable
- **Original**: The `timeRegistrationEntries` field in `Company` was `not nullable`.
- **Updated**: The `timeRegistrationEntries` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

263. Change `Company paymentMethods` to nullable
- **Original**: The `paymentMethods` field in `Company` was `not nullable`.
- **Updated**: The `paymentMethods` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

264. Change `Company customers` to nullable
- **Original**: The `customers` field in `Company` was `not nullable`.
- **Updated**: The `customers` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

265. Change `Company salesCreditMemos` to nullable
- **Original**: The `salesCreditMemos` field in `Company` was `not nullable`.
- **Updated**: The `salesCreditMemos` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

266. Change `Company journalLines` to nullable
- **Original**: The `journalLines` field in `Company` was `not nullable`.
- **Updated**: The `journalLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

267. Change `Company countriesRegions` to nullable
- **Original**: The `countriesRegions` field in `Company` was `not nullable`.
- **Updated**: The `countriesRegions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

268. Change `Company customerPayments` to nullable
- **Original**: The `customerPayments` field in `Company` was `not nullable`.
- **Updated**: The `customerPayments` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

269. Change `Company salesOrders` to nullable
- **Original**: The `salesOrders` field in `Company` was `not nullable`.
- **Updated**: The `salesOrders` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

270. Change `Company itemCategories` to nullable
- **Original**: The `itemCategories` field in `Company` was `not nullable`.
- **Updated**: The `itemCategories` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

271. Change `Company salesQuoteLines` to nullable
- **Original**: The `salesQuoteLines` field in `Company` was `not nullable`.
- **Updated**: The `salesQuoteLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

272. Change `Company salesInvoiceLines` to nullable
- **Original**: The `salesInvoiceLines` field in `Company` was `not nullable`.
- **Updated**: The `salesInvoiceLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

273. Change `Company generalLedgerEntries` to nullable
- **Original**: The `generalLedgerEntries` field in `Company` was `not nullable`.
- **Updated**: The `generalLedgerEntries` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

274. Change `Company picture` to nullable
- **Original**: The `picture` field in `Company` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

275. Change `Company purchaseInvoiceLines` to nullable
- **Original**: The `purchaseInvoiceLines` field in `Company` was `not nullable`.
- **Updated**: The `purchaseInvoiceLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

276. Change `Company dimensionLines` to nullable
- **Original**: The `dimensionLines` field in `Company` was `not nullable`.
- **Updated**: The `dimensionLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

277. Change `Company vendorPurchases` to nullable
- **Original**: The `vendorPurchases` field in `Company` was `not nullable`.
- **Updated**: The `vendorPurchases` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

278. Change `Company salesOrderLines` to nullable
- **Original**: The `salesOrderLines` field in `Company` was `not nullable`.
- **Updated**: The `salesOrderLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

279. Change `Company unitsOfMeasure` to nullable
- **Original**: The `unitsOfMeasure` field in `Company` was `not nullable`.
- **Updated**: The `unitsOfMeasure` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

280. Change `Company accounts` to nullable
- **Original**: The `accounts` field in `Company` was `not nullable`.
- **Updated**: The `accounts` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

281. Change `Company currencies` to nullable
- **Original**: The `currencies` field in `Company` was `not nullable`.
- **Updated**: The `currencies` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

282. Change `Company dimensions` to nullable
- **Original**: The `dimensions` field in `Company` was `not nullable`.
- **Updated**: The `dimensions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

283. Change `ItemUnitOfMeasureConversion toUnitOfMeasure` to nullable
- **Original**: The `toUnitOfMeasure` field in `ItemUnitOfMeasureConversion` was `not nullable`.
- **Updated**: The `toUnitOfMeasure` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

284. Change `ItemUnitOfMeasureConversion fromToConversionRate` to nullable
- **Original**: The `fromToConversionRate` field in `ItemUnitOfMeasureConversion` was `not nullable`.
- **Updated**: The `fromToConversionRate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

285. Change `ItemUnitOfMeasureConversion defaultDimensions` to nullable
- **Original**: The `defaultDimensions` field in `ItemUnitOfMeasureConversion` was `not nullable`.
- **Updated**: The `defaultDimensions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

286. Change `ItemUnitOfMeasureConversion picture` to nullable
- **Original**: The `picture` field in `ItemUnitOfMeasureConversion` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

287. Change `Journal balancingAccountNumber` to nullable
- **Original**: The `balancingAccountNumber` field in `Journal` was `not nullable`.
- **Updated**: The `balancingAccountNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

288. Change `Journal lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `Journal` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

289. Change `Journal journalLines` to nullable
- **Original**: The `journalLines` field in `Journal` was `not nullable`.
- **Updated**: The `journalLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

290. Change `Journal displayName` to nullable
- **Original**: The `displayName` field in `Journal` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

291. Change `Journal balancingAccountId` to nullable
- **Original**: The `balancingAccountId` field in `Journal` was `not nullable`.
- **Updated**: The `balancingAccountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

292. Change `SalesQuote documentDate` to nullable
- **Original**: The `documentDate` field in `SalesQuote` was `not nullable`.
- **Updated**: The `documentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

293. Change `SalesQuote lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `SalesQuote` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

294. Change `SalesQuote shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `SalesQuote` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

295. Change `SalesQuote dueDate` to nullable
- **Original**: The `dueDate` field in `SalesQuote` was `not nullable`.
- **Updated**: The `dueDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

296. Change `SalesQuote discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesQuote` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

297. Change `SalesQuote validUntilDate` to nullable
- **Original**: The `validUntilDate` field in `SalesQuote` was `not nullable`.
- **Updated**: The `validUntilDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

298. Change `SalesQuote acceptedDate` to nullable
- **Original**: The `acceptedDate` field in `SalesQuote` was `not nullable`.
- **Updated**: The `acceptedDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

299. Change `SalesQuote number` to nullable
- **Original**: The `number` field in `SalesQuote` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

300. Change `SalesQuote paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `SalesQuote` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

301. Change `SalesQuote sentDate` to nullable
- **Original**: The `sentDate` field in `SalesQuote` was `not nullable`.
- **Updated**: The `sentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

302. Change `SalesQuote pdfDocument` to nullable
- **Original**: The `pdfDocument` field in `SalesQuote` was `not nullable`.
- **Updated**: The `pdfDocument` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

303. Change `SalesQuote totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `SalesQuote` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

304. Change `SalesQuote customerId` to nullable
- **Original**: The `customerId` field in `SalesQuote` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

305. Change `SalesQuote currencyId` to nullable
- **Original**: The `currencyId` field in `SalesQuote` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

306. Change `SalesQuote totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `SalesQuote` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

307. Change `SalesQuote email` to nullable
- **Original**: The `email` field in `SalesQuote` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

308. Change `SalesQuote contactId` to nullable
- **Original**: The `contactId` field in `SalesQuote` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

309. Change `SalesQuote billToCustomerId` to nullable
- **Original**: The `billToCustomerId` field in `SalesQuote` was `not nullable`.
- **Updated**: The `billToCustomerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

310. Change `SalesQuote salesQuoteLines` to nullable
- **Original**: The `salesQuoteLines` field in `SalesQuote` was `not nullable`.
- **Updated**: The `salesQuoteLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

311. Change `SalesQuote billToName` to nullable
- **Original**: The `billToName` field in `SalesQuote` was `not nullable`.
- **Updated**: The `billToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

312. Change `SalesQuote customerNumber` to nullable
- **Original**: The `customerNumber` field in `SalesQuote` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

313. Change `SalesQuote customerName` to nullable
- **Original**: The `customerName` field in `SalesQuote` was `not nullable`.
- **Updated**: The `customerName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

314. Change `SalesQuote phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `SalesQuote` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

315. Change `SalesQuote billToCustomerNumber` to nullable
- **Original**: The `billToCustomerNumber` field in `SalesQuote` was `not nullable`.
- **Updated**: The `billToCustomerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

316. Change `SalesQuote salesperson` to nullable
- **Original**: The `salesperson` field in `SalesQuote` was `not nullable`.
- **Updated**: The `salesperson` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

317. Change `SalesQuote shipToContact` to nullable
- **Original**: The `shipToContact` field in `SalesQuote` was `not nullable`.
- **Updated**: The `shipToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

318. Change `SalesQuote externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `SalesQuote` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

319. Change `SalesQuote shipToName` to nullable
- **Original**: The `shipToName` field in `SalesQuote` was `not nullable`.
- **Updated**: The `shipToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

320. Change `SalesQuote totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesQuote` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

321. Change `SalesQuote currencyCode` to nullable
- **Original**: The `currencyCode` field in `SalesQuote` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

322. Change `SalesQuote status` to nullable
- **Original**: The `status` field in `SalesQuote` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

323. Change `PostalAddress city` to nullable
- **Original**: The `city` field in `PostalAddress` was `not nullable`.
- **Updated**: The `city` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

324. Change `PostalAddress street` to nullable
- **Original**: The `street` field in `PostalAddress` was `not nullable`.
- **Updated**: The `street` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

325. Change `PostalAddress countryLetterCode` to nullable
- **Original**: The `countryLetterCode` field in `PostalAddress` was `not nullable`.
- **Updated**: The `countryLetterCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

326. Change `PostalAddress postalCode` to nullable
- **Original**: The `postalCode` field in `PostalAddress` was `not nullable`.
- **Updated**: The `postalCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

327. Change `PostalAddress state` to nullable
- **Original**: The `state` field in `PostalAddress` was `not nullable`.
- **Updated**: The `state` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

328. Change `PostalAddress defaultDimensions` to nullable
- **Original**: The `defaultDimensions` field in `PostalAddress` was `not nullable`.
- **Updated**: The `defaultDimensions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

329. Change `PostalAddress customerFinancialDetails` to nullable
- **Original**: The `customerFinancialDetails` field in `PostalAddress` was `not nullable`.
- **Updated**: The `customerFinancialDetails` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

330. Change `PostalAddress picture` to nullable
- **Original**: The `picture` field in `PostalAddress` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

331. Change `PurchaseInvoice payToContact` to nullable
- **Original**: The `payToContact` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `payToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

332. Change `PurchaseInvoice payToName` to nullable
- **Original**: The `payToName` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `payToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

333. Change `PurchaseInvoice payToVendorId` to nullable
- **Original**: The `payToVendorId` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `payToVendorId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

334. Change `PurchaseInvoice lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

335. Change `PurchaseInvoice discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

336. Change `PurchaseInvoice dueDate` to nullable
- **Original**: The `dueDate` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `dueDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

337. Change `PurchaseInvoice vendorId` to nullable
- **Original**: The `vendorId` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `vendorId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

338. Change `PurchaseInvoice discountAmount` to nullable
- **Original**: The `discountAmount` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

339. Change `PurchaseInvoice vendorInvoiceNumber` to nullable
- **Original**: The `vendorInvoiceNumber` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `vendorInvoiceNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

340. Change `PurchaseInvoice number` to nullable
- **Original**: The `number` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

341. Change `PurchaseInvoice pdfDocument` to nullable
- **Original**: The `pdfDocument` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `pdfDocument` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

342. Change `PurchaseInvoice totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

343. Change `PurchaseInvoice currencyId` to nullable
- **Original**: The `currencyId` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

344. Change `PurchaseInvoice totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

345. Change `PurchaseInvoice invoiceDate` to nullable
- **Original**: The `invoiceDate` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `invoiceDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

346. Change `PurchaseInvoice vendorName` to nullable
- **Original**: The `vendorName` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `vendorName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

347. Change `PurchaseInvoice pricesIncludeTax` to nullable
- **Original**: The `pricesIncludeTax` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `pricesIncludeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

348. Change `PurchaseInvoice payToVendorNumber` to nullable
- **Original**: The `payToVendorNumber` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `payToVendorNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

349. Change `PurchaseInvoice purchaseInvoiceLines` to nullable
- **Original**: The `purchaseInvoiceLines` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `purchaseInvoiceLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

350. Change `PurchaseInvoice shipToContact` to nullable
- **Original**: The `shipToContact` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `shipToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

351. Change `PurchaseInvoice shipToName` to nullable
- **Original**: The `shipToName` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `shipToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

352. Change `PurchaseInvoice vendorNumber` to nullable
- **Original**: The `vendorNumber` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `vendorNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

353. Change `PurchaseInvoice totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

354. Change `PurchaseInvoice currencyCode` to nullable
- **Original**: The `currencyCode` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

355. Change `PurchaseInvoice status` to nullable
- **Original**: The `status` field in `PurchaseInvoice` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

356. Change `SalesOrder lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `SalesOrder` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

357. Change `SalesOrder shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `SalesOrder` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

358. Change `SalesOrder discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesOrder` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

359. Change `SalesOrder fullyShipped` to nullable
- **Original**: The `fullyShipped` field in `SalesOrder` was `not nullable`.
- **Updated**: The `fullyShipped` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

360. Change `SalesOrder discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesOrder` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

361. Change `SalesOrder number` to nullable
- **Original**: The `number` field in `SalesOrder` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

362. Change `SalesOrder paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `SalesOrder` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

363. Change `SalesOrder totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `SalesOrder` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

364. Change `SalesOrder customerId` to nullable
- **Original**: The `customerId` field in `SalesOrder` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

365. Change `SalesOrder currencyId` to nullable
- **Original**: The `currencyId` field in `SalesOrder` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

366. Change `SalesOrder totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `SalesOrder` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

367. Change `SalesOrder email` to nullable
- **Original**: The `email` field in `SalesOrder` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

368. Change `SalesOrder contactId` to nullable
- **Original**: The `contactId` field in `SalesOrder` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

369. Change `SalesOrder billToCustomerId` to nullable
- **Original**: The `billToCustomerId` field in `SalesOrder` was `not nullable`.
- **Updated**: The `billToCustomerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

370. Change `SalesOrder billToName` to nullable
- **Original**: The `billToName` field in `SalesOrder` was `not nullable`.
- **Updated**: The `billToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

371. Change `SalesOrder customerNumber` to nullable
- **Original**: The `customerNumber` field in `SalesOrder` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

372. Change `SalesOrder pricesIncludeTax` to nullable
- **Original**: The `pricesIncludeTax` field in `SalesOrder` was `not nullable`.
- **Updated**: The `pricesIncludeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

373. Change `SalesOrder customerName` to nullable
- **Original**: The `customerName` field in `SalesOrder` was `not nullable`.
- **Updated**: The `customerName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

374. Change `SalesOrder phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `SalesOrder` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

375. Change `SalesOrder billToCustomerNumber` to nullable
- **Original**: The `billToCustomerNumber` field in `SalesOrder` was `not nullable`.
- **Updated**: The `billToCustomerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

376. Change `SalesOrder salesperson` to nullable
- **Original**: The `salesperson` field in `SalesOrder` was `not nullable`.
- **Updated**: The `salesperson` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

377. Change `SalesOrder shipToContact` to nullable
- **Original**: The `shipToContact` field in `SalesOrder` was `not nullable`.
- **Updated**: The `shipToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

378. Change `SalesOrder salesOrderLines` to nullable
- **Original**: The `salesOrderLines` field in `SalesOrder` was `not nullable`.
- **Updated**: The `salesOrderLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

379. Change `SalesOrder requestedDeliveryDate` to nullable
- **Original**: The `requestedDeliveryDate` field in `SalesOrder` was `not nullable`.
- **Updated**: The `requestedDeliveryDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

380. Change `SalesOrder externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `SalesOrder` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

381. Change `SalesOrder shipToName` to nullable
- **Original**: The `shipToName` field in `SalesOrder` was `not nullable`.
- **Updated**: The `shipToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

382. Change `SalesOrder partialShipping` to nullable
- **Original**: The `partialShipping` field in `SalesOrder` was `not nullable`.
- **Updated**: The `partialShipping` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

383. Change `SalesOrder totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesOrder` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

384. Change `SalesOrder orderDate` to nullable
- **Original**: The `orderDate` field in `SalesOrder` was `not nullable`.
- **Updated**: The `orderDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

385. Change `SalesOrder currencyCode` to nullable
- **Original**: The `currencyCode` field in `SalesOrder` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

386. Change `SalesOrder status` to nullable
- **Original**: The `status` field in `SalesOrder` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

387. Change `JournalLine amount` to nullable
- **Original**: The `amount` field in `JournalLine` was `not nullable`.
- **Updated**: The `amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

388. Change `JournalLine lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `JournalLine` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

389. Change `JournalLine attachments` to nullable
- **Original**: The `attachments` field in `JournalLine` was `not nullable`.
- **Updated**: The `attachments` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

390. Change `JournalLine documentNumber` to nullable
- **Original**: The `documentNumber` field in `JournalLine` was `not nullable`.
- **Updated**: The `documentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

391. Change `JournalLine accountType` to nullable
- **Original**: The `accountType` field in `JournalLine` was `not nullable`.
- **Updated**: The `accountType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

392. Change `JournalLine description` to nullable
- **Original**: The `description` field in `JournalLine` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

393. Change `JournalLine postingDate` to nullable
- **Original**: The `postingDate` field in `JournalLine` was `not nullable`.
- **Updated**: The `postingDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

394. Change `JournalLine accountNumber` to nullable
- **Original**: The `accountNumber` field in `JournalLine` was `not nullable`.
- **Updated**: The `accountNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

395. Change `JournalLine journalDisplayName` to nullable
- **Original**: The `journalDisplayName` field in `JournalLine` was `not nullable`.
- **Updated**: The `journalDisplayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

396. Change `JournalLine accountId` to nullable
- **Original**: The `accountId` field in `JournalLine` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

397. Change `JournalLine externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `JournalLine` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

398. Change `JournalLine comment` to nullable
- **Original**: The `comment` field in `JournalLine` was `not nullable`.
- **Updated**: The `comment` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

399. Change `JournalLine lineNumber` to nullable
- **Original**: The `lineNumber` field in `JournalLine` was `not nullable`.
- **Updated**: The `lineNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

400. Change `UnitOfMeasure internationalStandardCode` to nullable
- **Original**: The `internationalStandardCode` field in `UnitOfMeasure` was `not nullable`.
- **Updated**: The `internationalStandardCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

401. Change `UnitOfMeasure lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `UnitOfMeasure` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

402. Change `UnitOfMeasure displayName` to nullable
- **Original**: The `displayName` field in `UnitOfMeasure` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

403. Change `RetainedEarningsStatement netChange` to nullable
- **Original**: The `netChange` field in `RetainedEarningsStatement` was `not nullable`.
- **Updated**: The `netChange` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

404. Change `RetainedEarningsStatement indentation` to nullable
- **Original**: The `indentation` field in `RetainedEarningsStatement` was `not nullable`.
- **Updated**: The `indentation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

405. Change `RetainedEarningsStatement display` to nullable
- **Original**: The `display` field in `RetainedEarningsStatement` was `not nullable`.
- **Updated**: The `display` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

406. Change `RetainedEarningsStatement lineType` to nullable
- **Original**: The `lineType` field in `RetainedEarningsStatement` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

407. Change `RetainedEarningsStatement dateFilter` to nullable
- **Original**: The `dateFilter` field in `RetainedEarningsStatement` was `not nullable`.
- **Updated**: The `dateFilter` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

408. Change `ShipmentMethod lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `ShipmentMethod` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

409. Change `ShipmentMethod displayName` to nullable
- **Original**: The `displayName` field in `ShipmentMethod` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

410. Change `SalesCreditMemo lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

411. Change `SalesCreditMemo shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

412. Change `SalesCreditMemo discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

413. Change `SalesCreditMemo dueDate` to nullable
- **Original**: The `dueDate` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `dueDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

414. Change `SalesCreditMemo discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

415. Change `SalesCreditMemo number` to nullable
- **Original**: The `number` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

416. Change `SalesCreditMemo paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

417. Change `SalesCreditMemo pdfDocument` to nullable
- **Original**: The `pdfDocument` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `pdfDocument` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

418. Change `SalesCreditMemo totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

419. Change `SalesCreditMemo customerId` to nullable
- **Original**: The `customerId` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

420. Change `SalesCreditMemo invoiceNumber` to nullable
- **Original**: The `invoiceNumber` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `invoiceNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

421. Change `SalesCreditMemo creditMemoDate` to nullable
- **Original**: The `creditMemoDate` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `creditMemoDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

422. Change `SalesCreditMemo currencyId` to nullable
- **Original**: The `currencyId` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

423. Change `SalesCreditMemo totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

424. Change `SalesCreditMemo email` to nullable
- **Original**: The `email` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

425. Change `SalesCreditMemo contactId` to nullable
- **Original**: The `contactId` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

426. Change `SalesCreditMemo billToCustomerId` to nullable
- **Original**: The `billToCustomerId` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `billToCustomerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

427. Change `SalesCreditMemo billToName` to nullable
- **Original**: The `billToName` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `billToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

428. Change `SalesCreditMemo customerNumber` to nullable
- **Original**: The `customerNumber` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

429. Change `SalesCreditMemo pricesIncludeTax` to nullable
- **Original**: The `pricesIncludeTax` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `pricesIncludeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

430. Change `SalesCreditMemo customerName` to nullable
- **Original**: The `customerName` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `customerName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

431. Change `SalesCreditMemo salesCreditMemoLines` to nullable
- **Original**: The `salesCreditMemoLines` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `salesCreditMemoLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

432. Change `SalesCreditMemo phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

433. Change `SalesCreditMemo billToCustomerNumber` to nullable
- **Original**: The `billToCustomerNumber` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `billToCustomerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

434. Change `SalesCreditMemo salesperson` to nullable
- **Original**: The `salesperson` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `salesperson` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

435. Change `SalesCreditMemo externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

436. Change `SalesCreditMemo invoiceId` to nullable
- **Original**: The `invoiceId` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `invoiceId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

437. Change `SalesCreditMemo totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

438. Change `SalesCreditMemo currencyCode` to nullable
- **Original**: The `currencyCode` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

439. Change `SalesCreditMemo status` to nullable
- **Original**: The `status` field in `SalesCreditMemo` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

440. Change `PdfDocument content` to nullable
- **Original**: The `content` field in `PdfDocument` was `not nullable`.
- **Updated**: The `content` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

441. Change `IncomeStatement netChange` to nullable
- **Original**: The `netChange` field in `IncomeStatement` was `not nullable`.
- **Updated**: The `netChange` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

442. Change `IncomeStatement indentation` to nullable
- **Original**: The `indentation` field in `IncomeStatement` was `not nullable`.
- **Updated**: The `indentation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

443. Change `IncomeStatement display` to nullable
- **Original**: The `display` field in `IncomeStatement` was `not nullable`.
- **Updated**: The `display` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

444. Change `IncomeStatement lineType` to nullable
- **Original**: The `lineType` field in `IncomeStatement` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

445. Change `IncomeStatement dateFilter` to nullable
- **Original**: The `dateFilter` field in `IncomeStatement` was `not nullable`.
- **Updated**: The `dateFilter` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

446. Change `TaxGroup code` to nullable
- **Original**: The `code` field in `TaxGroup` was `not nullable`.
- **Updated**: The `code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

447. Change `TaxGroup lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `TaxGroup` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

448. Change `TaxGroup displayName` to nullable
- **Original**: The `displayName` field in `TaxGroup` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

449. Change `TaxGroup taxType` to nullable
- **Original**: The `taxType` field in `TaxGroup` was `not nullable`.
- **Updated**: The `taxType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

450. Change `SalesInvoiceLine discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

451. Change `SalesInvoiceLine description` to nullable
- **Original**: The `description` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

452. Change `SalesInvoiceLine discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

453. Change `SalesInvoiceLine invoiceDiscountAllocation` to nullable
- **Original**: The `invoiceDiscountAllocation` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `invoiceDiscountAllocation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

454. Change `SalesInvoiceLine lineType` to nullable
- **Original**: The `lineType` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

455. Change `SalesInvoiceLine taxPercent` to nullable
- **Original**: The `taxPercent` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

456. Change `SalesInvoiceLine shipmentDate` to nullable
- **Original**: The `shipmentDate` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `shipmentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

457. Change `SalesInvoiceLine unitPrice` to nullable
- **Original**: The `unitPrice` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

458. Change `SalesInvoiceLine quantity` to nullable
- **Original**: The `quantity` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

459. Change `SalesInvoiceLine discountPercent` to nullable
- **Original**: The `discountPercent` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

460. Change `SalesInvoiceLine netAmount` to nullable
- **Original**: The `netAmount` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

461. Change `SalesInvoiceLine amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

462. Change `SalesInvoiceLine unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

463. Change `SalesInvoiceLine taxCode` to nullable
- **Original**: The `taxCode` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

464. Change `SalesInvoiceLine netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

465. Change `SalesInvoiceLine sequence` to nullable
- **Original**: The `sequence` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

466. Change `SalesInvoiceLine itemId` to nullable
- **Original**: The `itemId` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

467. Change `SalesInvoiceLine accountId` to nullable
- **Original**: The `accountId` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

468. Change `SalesInvoiceLine netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

469. Change `SalesInvoiceLine documentId` to nullable
- **Original**: The `documentId` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

470. Change `SalesInvoiceLine totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

471. Change `SalesInvoiceLine amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `SalesInvoiceLine` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

472. Change `PaymentMethod lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `PaymentMethod` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

473. Change `PaymentMethod displayName` to nullable
- **Original**: The `displayName` field in `PaymentMethod` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

474. Change `AgedAccountsPayable period2Amount` to nullable
- **Original**: The `period2Amount` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `period2Amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

475. Change `AgedAccountsPayable agedAsOfDate` to nullable
- **Original**: The `agedAsOfDate` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `agedAsOfDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

476. Change `AgedAccountsPayable period3Amount` to nullable
- **Original**: The `period3Amount` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `period3Amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

477. Change `AgedAccountsPayable balanceDue` to nullable
- **Original**: The `balanceDue` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `balanceDue` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

478. Change `AgedAccountsPayable name` to nullable
- **Original**: The `name` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `name` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

479. Change `AgedAccountsPayable currentAmount` to nullable
- **Original**: The `currentAmount` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `currentAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

480. Change `AgedAccountsPayable period1Amount` to nullable
- **Original**: The `period1Amount` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `period1Amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

481. Change `AgedAccountsPayable vendorNumber` to nullable
- **Original**: The `vendorNumber` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `vendorNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

482. Change `AgedAccountsPayable currencyCode` to nullable
- **Original**: The `currencyCode` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

483. Change `AgedAccountsPayable periodLengthFilter` to nullable
- **Original**: The `periodLengthFilter` field in `AgedAccountsPayable` was `not nullable`.
- **Updated**: The `periodLengthFilter` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

484. Change `AgedAccountsReceivable period2Amount` to nullable
- **Original**: The `period2Amount` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `period2Amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

485. Change `AgedAccountsReceivable agedAsOfDate` to nullable
- **Original**: The `agedAsOfDate` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `agedAsOfDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

486. Change `AgedAccountsReceivable period3Amount` to nullable
- **Original**: The `period3Amount` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `period3Amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

487. Change `AgedAccountsReceivable balanceDue` to nullable
- **Original**: The `balanceDue` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `balanceDue` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

488. Change `AgedAccountsReceivable name` to nullable
- **Original**: The `name` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `name` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

489. Change `AgedAccountsReceivable currentAmount` to nullable
- **Original**: The `currentAmount` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `currentAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

490. Change `AgedAccountsReceivable period1Amount` to nullable
- **Original**: The `period1Amount` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `period1Amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

491. Change `AgedAccountsReceivable customerNumber` to nullable
- **Original**: The `customerNumber` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

492. Change `AgedAccountsReceivable currencyCode` to nullable
- **Original**: The `currencyCode` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

493. Change `AgedAccountsReceivable periodLengthFilter` to nullable
- **Original**: The `periodLengthFilter` field in `AgedAccountsReceivable` was `not nullable`.
- **Updated**: The `periodLengthFilter` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

494. Change `SalesQuoteLine discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

495. Change `SalesQuoteLine description` to nullable
- **Original**: The `description` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

496. Change `SalesQuoteLine discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

497. Change `SalesQuoteLine lineType` to nullable
- **Original**: The `lineType` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

498. Change `SalesQuoteLine taxPercent` to nullable
- **Original**: The `taxPercent` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

499. Change `SalesQuoteLine unitPrice` to nullable
- **Original**: The `unitPrice` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

500. Change `SalesQuoteLine quantity` to nullable
- **Original**: The `quantity` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

501. Change `SalesQuoteLine discountPercent` to nullable
- **Original**: The `discountPercent` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

502. Change `SalesQuoteLine netAmount` to nullable
- **Original**: The `netAmount` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

503. Change `SalesQuoteLine amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

504. Change `SalesQuoteLine unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

505. Change `SalesQuoteLine taxCode` to nullable
- **Original**: The `taxCode` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

506. Change `SalesQuoteLine netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

507. Change `SalesQuoteLine sequence` to nullable
- **Original**: The `sequence` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

508. Change `SalesQuoteLine itemId` to nullable
- **Original**: The `itemId` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

509. Change `SalesQuoteLine accountId` to nullable
- **Original**: The `accountId` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

510. Change `SalesQuoteLine netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

511. Change `SalesQuoteLine documentId` to nullable
- **Original**: The `documentId` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

512. Change `SalesQuoteLine totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

513. Change `SalesQuoteLine amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `SalesQuoteLine` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

514. Change `DimensionLine valueId` to nullable
- **Original**: The `valueId` field in `DimensionLine` was `not nullable`.
- **Updated**: The `valueId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

515. Change `DimensionLine valueDisplayName` to nullable
- **Original**: The `valueDisplayName` field in `DimensionLine` was `not nullable`.
- **Updated**: The `valueDisplayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

516. Change `DimensionLine code` to nullable
- **Original**: The `code` field in `DimensionLine` was `not nullable`.
- **Updated**: The `code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

517. Change `DimensionLine displayName` to nullable
- **Original**: The `displayName` field in `DimensionLine` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

518. Change `DimensionLine valueCode` to nullable
- **Original**: The `valueCode` field in `DimensionLine` was `not nullable`.
- **Updated**: The `valueCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

519. Change `Attachment fileName` to nullable
- **Original**: The `fileName` field in `Attachment` was `not nullable`.
- **Updated**: The `fileName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

520. Change `Attachment lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `Attachment` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

521. Change `Attachment byteSize` to nullable
- **Original**: The `byteSize` field in `Attachment` was `not nullable`.
- **Updated**: The `byteSize` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

522. Change `Attachment content` to nullable
- **Original**: The `content` field in `Attachment` was `not nullable`.
- **Updated**: The `content` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

523. Change `SalesInvoice orderNumber` to nullable
- **Original**: The `orderNumber` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `orderNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

524. Change `SalesInvoice lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

525. Change `SalesInvoice shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

526. Change `SalesInvoice discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

527. Change `SalesInvoice orderId` to nullable
- **Original**: The `orderId` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `orderId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

528. Change `SalesInvoice dueDate` to nullable
- **Original**: The `dueDate` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `dueDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

529. Change `SalesInvoice discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

530. Change `SalesInvoice customerPurchaseOrderReference` to nullable
- **Original**: The `customerPurchaseOrderReference` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `customerPurchaseOrderReference` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

531. Change `SalesInvoice number` to nullable
- **Original**: The `number` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

532. Change `SalesInvoice paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

533. Change `SalesInvoice remainingAmount` to nullable
- **Original**: The `remainingAmount` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `remainingAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

534. Change `SalesInvoice pdfDocument` to nullable
- **Original**: The `pdfDocument` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `pdfDocument` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

535. Change `SalesInvoice totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

536. Change `SalesInvoice customerId` to nullable
- **Original**: The `customerId` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

537. Change `SalesInvoice currencyId` to nullable
- **Original**: The `currencyId` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

538. Change `SalesInvoice totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

539. Change `SalesInvoice email` to nullable
- **Original**: The `email` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

540. Change `SalesInvoice contactId` to nullable
- **Original**: The `contactId` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

541. Change `SalesInvoice billToCustomerId` to nullable
- **Original**: The `billToCustomerId` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `billToCustomerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

542. Change `SalesInvoice billToName` to nullable
- **Original**: The `billToName` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `billToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

543. Change `SalesInvoice invoiceDate` to nullable
- **Original**: The `invoiceDate` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `invoiceDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

544. Change `SalesInvoice customerNumber` to nullable
- **Original**: The `customerNumber` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

545. Change `SalesInvoice pricesIncludeTax` to nullable
- **Original**: The `pricesIncludeTax` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `pricesIncludeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

546. Change `SalesInvoice salesInvoiceLines` to nullable
- **Original**: The `salesInvoiceLines` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `salesInvoiceLines` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

547. Change `SalesInvoice customerName` to nullable
- **Original**: The `customerName` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `customerName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

548. Change `SalesInvoice phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

549. Change `SalesInvoice billToCustomerNumber` to nullable
- **Original**: The `billToCustomerNumber` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `billToCustomerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

550. Change `SalesInvoice salesperson` to nullable
- **Original**: The `salesperson` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `salesperson` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

551. Change `SalesInvoice shipToContact` to nullable
- **Original**: The `shipToContact` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `shipToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

552. Change `SalesInvoice externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

553. Change `SalesInvoice shipToName` to nullable
- **Original**: The `shipToName` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `shipToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

554. Change `SalesInvoice totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

555. Change `SalesInvoice currencyCode` to nullable
- **Original**: The `currencyCode` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

556. Change `SalesInvoice status` to nullable
- **Original**: The `status` field in `SalesInvoice` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

557. Change `DefaultDimensions dimensionValueCode` to nullable
- **Original**: The `dimensionValueCode` field in `DefaultDimensions` was `not nullable`.
- **Updated**: The `dimensionValueCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

558. Change `DefaultDimensions dimensionValueId` to nullable
- **Original**: The `dimensionValueId` field in `DefaultDimensions` was `not nullable`.
- **Updated**: The `dimensionValueId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

559. Change `DefaultDimensions dimensionCode` to nullable
- **Original**: The `dimensionCode` field in `DefaultDimensions` was `not nullable`.
- **Updated**: The `dimensionCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

560. Change `DefaultDimensions postingValidation` to nullable
- **Original**: The `postingValidation` field in `DefaultDimensions` was `not nullable`.
- **Updated**: The `postingValidation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

561. Change `Vendor website` to nullable
- **Original**: The `website` field in `Vendor` was `not nullable`.
- **Updated**: The `website` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

562. Change `Vendor lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `Vendor` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

563. Change `Vendor displayName` to nullable
- **Original**: The `displayName` field in `Vendor` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

564. Change `Vendor taxLiable` to nullable
- **Original**: The `taxLiable` field in `Vendor` was `not nullable`.
- **Updated**: The `taxLiable` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

565. Change `Vendor picture` to nullable
- **Original**: The `picture` field in `Vendor` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

566. Change `Vendor number` to nullable
- **Original**: The `number` field in `Vendor` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

567. Change `Vendor paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `Vendor` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

568. Change `Vendor phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `Vendor` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

569. Change `Vendor blocked` to nullable
- **Original**: The `blocked` field in `Vendor` was `not nullable`.
- **Updated**: The `blocked` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

570. Change `Vendor balance` to nullable
- **Original**: The `balance` field in `Vendor` was `not nullable`.
- **Updated**: The `balance` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

571. Change `Vendor paymentMethodId` to nullable
- **Original**: The `paymentMethodId` field in `Vendor` was `not nullable`.
- **Updated**: The `paymentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

572. Change `Vendor taxRegistrationNumber` to nullable
- **Original**: The `taxRegistrationNumber` field in `Vendor` was `not nullable`.
- **Updated**: The `taxRegistrationNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

573. Change `Vendor defaultDimensions` to nullable
- **Original**: The `defaultDimensions` field in `Vendor` was `not nullable`.
- **Updated**: The `defaultDimensions` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

574. Change `Vendor currencyId` to nullable
- **Original**: The `currencyId` field in `Vendor` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

575. Change `Vendor currencyCode` to nullable
- **Original**: The `currencyCode` field in `Vendor` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

576. Change `Vendor irs1099Code` to nullable
- **Original**: The `irs1099Code` field in `Vendor` was `not nullable`.
- **Updated**: The `irs1099Code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

577. Change `Vendor email` to nullable
- **Original**: The `email` field in `Vendor` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

578. Change `PaymentTerm dueDateCalculation` to nullable
- **Original**: The `dueDateCalculation` field in `PaymentTerm` was `not nullable`.
- **Updated**: The `dueDateCalculation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

579. Change `PaymentTerm discountPercent` to nullable
- **Original**: The `discountPercent` field in `PaymentTerm` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

580. Change `PaymentTerm lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `PaymentTerm` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

581. Change `PaymentTerm displayName` to nullable
- **Original**: The `displayName` field in `PaymentTerm` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

582. Change `PaymentTerm discountDateCalculation` to nullable
- **Original**: The `discountDateCalculation` field in `PaymentTerm` was `not nullable`.
- **Updated**: The `discountDateCalculation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

583. Change `PaymentTerm calculateDiscountOnCreditMemos` to nullable
- **Original**: The `calculateDiscountOnCreditMemos` field in `PaymentTerm` was `not nullable`.
- **Updated**: The `calculateDiscountOnCreditMemos` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

584. Change `CashFlowStatement netChange` to nullable
- **Original**: The `netChange` field in `CashFlowStatement` was `not nullable`.
- **Updated**: The `netChange` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

585. Change `CashFlowStatement indentation` to nullable
- **Original**: The `indentation` field in `CashFlowStatement` was `not nullable`.
- **Updated**: The `indentation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

586. Change `CashFlowStatement display` to nullable
- **Original**: The `display` field in `CashFlowStatement` was `not nullable`.
- **Updated**: The `display` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

587. Change `CashFlowStatement lineType` to nullable
- **Original**: The `lineType` field in `CashFlowStatement` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

588. Change `CashFlowStatement dateFilter` to nullable
- **Original**: The `dateFilter` field in `CashFlowStatement` was `not nullable`.
- **Updated**: The `dateFilter` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

589. Change `CustomerFinancialDetail number` to nullable
- **Original**: The `number` field in `CustomerFinancialDetail` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

590. Change `CustomerFinancialDetail totalSalesExcludingTax` to nullable
- **Original**: The `totalSalesExcludingTax` field in `CustomerFinancialDetail` was `not nullable`.
- **Updated**: The `totalSalesExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

591. Change `CustomerFinancialDetail overdueAmount` to nullable
- **Original**: The `overdueAmount` field in `CustomerFinancialDetail` was `not nullable`.
- **Updated**: The `overdueAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

592. Change `CustomerFinancialDetail balance` to nullable
- **Original**: The `balance` field in `CustomerFinancialDetail` was `not nullable`.
- **Updated**: The `balance` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

593. Change `PurchaseInvoiceLine discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

594. Change `PurchaseInvoiceLine description` to nullable
- **Original**: The `description` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

595. Change `PurchaseInvoiceLine discountAmount` to nullable
- **Original**: The `discountAmount` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

596. Change `PurchaseInvoiceLine invoiceDiscountAllocation` to nullable
- **Original**: The `invoiceDiscountAllocation` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `invoiceDiscountAllocation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

597. Change `PurchaseInvoiceLine lineType` to nullable
- **Original**: The `lineType` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

598. Change `PurchaseInvoiceLine taxPercent` to nullable
- **Original**: The `taxPercent` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

599. Change `PurchaseInvoiceLine quantity` to nullable
- **Original**: The `quantity` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

600. Change `PurchaseInvoiceLine discountPercent` to nullable
- **Original**: The `discountPercent` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

601. Change `PurchaseInvoiceLine netAmount` to nullable
- **Original**: The `netAmount` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

602. Change `PurchaseInvoiceLine amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

603. Change `PurchaseInvoiceLine taxCode` to nullable
- **Original**: The `taxCode` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

604. Change `PurchaseInvoiceLine netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

605. Change `PurchaseInvoiceLine expectedReceiptDate` to nullable
- **Original**: The `expectedReceiptDate` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `expectedReceiptDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

606. Change `PurchaseInvoiceLine sequence` to nullable
- **Original**: The `sequence` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

607. Change `PurchaseInvoiceLine itemId` to nullable
- **Original**: The `itemId` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

608. Change `PurchaseInvoiceLine accountId` to nullable
- **Original**: The `accountId` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

609. Change `PurchaseInvoiceLine netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

610. Change `PurchaseInvoiceLine unitCost` to nullable
- **Original**: The `unitCost` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `unitCost` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

611. Change `PurchaseInvoiceLine documentId` to nullable
- **Original**: The `documentId` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

612. Change `PurchaseInvoiceLine totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

613. Change `PurchaseInvoiceLine amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `PurchaseInvoiceLine` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

614. Change `TaxAreaRequest code` to nullable
- **Original**: The `code` field in `TaxAreaRequest` was `not nullable`.
- **Updated**: The `code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

615. Change `TaxAreaRequest displayName` to nullable
- **Original**: The `displayName` field in `TaxAreaRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

616. Change `TaxAreaRequest taxType` to nullable
- **Original**: The `taxType` field in `TaxAreaRequest` was `not nullable`.
- **Updated**: The `taxType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

617. Change `TaxAreaRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `TaxAreaRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

618. Change `PaymentMethodRequest displayName` to nullable
- **Original**: The `displayName` field in `PaymentMethodRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

619. Change `PaymentMethodRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `PaymentMethodRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

620. Change `SalesQuoteRequest number` to nullable
- **Original**: The `number` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

621. Change `SalesQuoteRequest externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

622. Change `SalesQuoteRequest documentDate` to nullable
- **Original**: The `documentDate` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `documentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

623. Change `SalesQuoteRequest dueDate` to nullable
- **Original**: The `dueDate` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `dueDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

624. Change `SalesQuoteRequest customerId` to nullable
- **Original**: The `customerId` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

625. Change `SalesQuoteRequest contactId` to nullable
- **Original**: The `contactId` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

626. Change `SalesQuoteRequest customerNumber` to nullable
- **Original**: The `customerNumber` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

627. Change `SalesQuoteRequest customerName` to nullable
- **Original**: The `customerName` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `customerName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

628. Change `SalesQuoteRequest billToName` to nullable
- **Original**: The `billToName` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `billToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

629. Change `SalesQuoteRequest billToCustomerId` to nullable
- **Original**: The `billToCustomerId` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `billToCustomerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

630. Change `SalesQuoteRequest billToCustomerNumber` to nullable
- **Original**: The `billToCustomerNumber` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `billToCustomerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

631. Change `SalesQuoteRequest shipToName` to nullable
- **Original**: The `shipToName` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `shipToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

632. Change `SalesQuoteRequest shipToContact` to nullable
- **Original**: The `shipToContact` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `shipToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

633. Change `SalesQuoteRequest currencyId` to nullable
- **Original**: The `currencyId` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

634. Change `SalesQuoteRequest currencyCode` to nullable
- **Original**: The `currencyCode` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

635. Change `SalesQuoteRequest paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

636. Change `SalesQuoteRequest shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

637. Change `SalesQuoteRequest salesperson` to nullable
- **Original**: The `salesperson` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `salesperson` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

638. Change `SalesQuoteRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

639. Change `SalesQuoteRequest totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

640. Change `SalesQuoteRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

641. Change `SalesQuoteRequest totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

642. Change `SalesQuoteRequest status` to nullable
- **Original**: The `status` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

643. Change `SalesQuoteRequest sentDate` to nullable
- **Original**: The `sentDate` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `sentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

644. Change `SalesQuoteRequest validUntilDate` to nullable
- **Original**: The `validUntilDate` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `validUntilDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

645. Change `SalesQuoteRequest acceptedDate` to nullable
- **Original**: The `acceptedDate` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `acceptedDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

646. Change `SalesQuoteRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

647. Change `SalesQuoteRequest phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

648. Change `SalesQuoteRequest email` to nullable
- **Original**: The `email` field in `SalesQuoteRequest` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

649. Change `BankAccountRequest number` to nullable
- **Original**: The `number` field in `BankAccountRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

650. Change `BankAccountRequest displayName` to nullable
- **Original**: The `displayName` field in `BankAccountRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

651. Change `SalesQuoteLineRequest documentId` to nullable
- **Original**: The `documentId` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

652. Change `SalesQuoteLineRequest sequence` to nullable
- **Original**: The `sequence` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

653. Change `SalesQuoteLineRequest itemId` to nullable
- **Original**: The `itemId` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

654. Change `SalesQuoteLineRequest accountId` to nullable
- **Original**: The `accountId` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

655. Change `SalesQuoteLineRequest lineType` to nullable
- **Original**: The `lineType` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

656. Change `SalesQuoteLineRequest description` to nullable
- **Original**: The `description` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

657. Change `SalesQuoteLineRequest unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

658. Change `SalesQuoteLineRequest unitPrice` to nullable
- **Original**: The `unitPrice` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

659. Change `SalesQuoteLineRequest quantity` to nullable
- **Original**: The `quantity` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

660. Change `SalesQuoteLineRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

661. Change `SalesQuoteLineRequest discountPercent` to nullable
- **Original**: The `discountPercent` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

662. Change `SalesQuoteLineRequest discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

663. Change `SalesQuoteLineRequest amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

664. Change `SalesQuoteLineRequest taxCode` to nullable
- **Original**: The `taxCode` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

665. Change `SalesQuoteLineRequest taxPercent` to nullable
- **Original**: The `taxPercent` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

666. Change `SalesQuoteLineRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

667. Change `SalesQuoteLineRequest amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

668. Change `SalesQuoteLineRequest netAmount` to nullable
- **Original**: The `netAmount` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

669. Change `SalesQuoteLineRequest netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

670. Change `SalesQuoteLineRequest netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `SalesQuoteLineRequest` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

671. Change `SalesOrderRequest number` to nullable
- **Original**: The `number` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

672. Change `SalesOrderRequest externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

673. Change `SalesOrderRequest orderDate` to nullable
- **Original**: The `orderDate` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `orderDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

674. Change `SalesOrderRequest customerId` to nullable
- **Original**: The `customerId` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

675. Change `SalesOrderRequest contactId` to nullable
- **Original**: The `contactId` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

676. Change `SalesOrderRequest customerNumber` to nullable
- **Original**: The `customerNumber` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

677. Change `SalesOrderRequest customerName` to nullable
- **Original**: The `customerName` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `customerName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

678. Change `SalesOrderRequest billToName` to nullable
- **Original**: The `billToName` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `billToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

679. Change `SalesOrderRequest billToCustomerId` to nullable
- **Original**: The `billToCustomerId` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `billToCustomerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

680. Change `SalesOrderRequest billToCustomerNumber` to nullable
- **Original**: The `billToCustomerNumber` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `billToCustomerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

681. Change `SalesOrderRequest shipToName` to nullable
- **Original**: The `shipToName` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `shipToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

682. Change `SalesOrderRequest shipToContact` to nullable
- **Original**: The `shipToContact` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `shipToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

683. Change `SalesOrderRequest currencyId` to nullable
- **Original**: The `currencyId` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

684. Change `SalesOrderRequest currencyCode` to nullable
- **Original**: The `currencyCode` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

685. Change `SalesOrderRequest pricesIncludeTax` to nullable
- **Original**: The `pricesIncludeTax` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `pricesIncludeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

686. Change `SalesOrderRequest paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

687. Change `SalesOrderRequest shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

688. Change `SalesOrderRequest salesperson` to nullable
- **Original**: The `salesperson` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `salesperson` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

689. Change `SalesOrderRequest partialShipping` to nullable
- **Original**: The `partialShipping` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `partialShipping` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

690. Change `SalesOrderRequest requestedDeliveryDate` to nullable
- **Original**: The `requestedDeliveryDate` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `requestedDeliveryDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

691. Change `SalesOrderRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

692. Change `SalesOrderRequest discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

693. Change `SalesOrderRequest totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

694. Change `SalesOrderRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

695. Change `SalesOrderRequest totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

696. Change `SalesOrderRequest fullyShipped` to nullable
- **Original**: The `fullyShipped` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `fullyShipped` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

697. Change `SalesOrderRequest status` to nullable
- **Original**: The `status` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

698. Change `SalesOrderRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

699. Change `SalesOrderRequest phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

700. Change `SalesOrderRequest email` to nullable
- **Original**: The `email` field in `SalesOrderRequest` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

701. Change `AttachmentRequest fileName` to nullable
- **Original**: The `fileName` field in `AttachmentRequest` was `not nullable`.
- **Updated**: The `fileName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

702. Change `AttachmentRequest byteSize` to nullable
- **Original**: The `byteSize` field in `AttachmentRequest` was `not nullable`.
- **Updated**: The `byteSize` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

703. Change `AttachmentRequest content` to nullable
- **Original**: The `content` field in `AttachmentRequest` was `not nullable`.
- **Updated**: The `content` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

704. Change `AttachmentRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `AttachmentRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

705. Change `ItemCategoryRequest displayName` to nullable
- **Original**: The `displayName` field in `ItemCategoryRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

706. Change `ItemCategoryRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `ItemCategoryRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

707. Change `DimensionLineRequest code` to nullable
- **Original**: The `code` field in `DimensionLineRequest` was `not nullable`.
- **Updated**: The `code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

708. Change `DimensionLineRequest displayName` to nullable
- **Original**: The `displayName` field in `DimensionLineRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

709. Change `DimensionLineRequest valueId` to nullable
- **Original**: The `valueId` field in `DimensionLineRequest` was `not nullable`.
- **Updated**: The `valueId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

710. Change `DimensionLineRequest valueCode` to nullable
- **Original**: The `valueCode` field in `DimensionLineRequest` was `not nullable`.
- **Updated**: The `valueCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

711. Change `DimensionLineRequest valueDisplayName` to nullable
- **Original**: The `valueDisplayName` field in `DimensionLineRequest` was `not nullable`.
- **Updated**: The `valueDisplayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

712. Change `PictureRequest width` to nullable
- **Original**: The `width` field in `PictureRequest` was `not nullable`.
- **Updated**: The `width` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

713. Change `PictureRequest height` to nullable
- **Original**: The `height` field in `PictureRequest` was `not nullable`.
- **Updated**: The `height` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

714. Change `PictureRequest contentType` to nullable
- **Original**: The `contentType` field in `PictureRequest` was `not nullable`.
- **Updated**: The `contentType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

715. Change `PictureRequest content` to nullable
- **Original**: The `content` field in `PictureRequest` was `not nullable`.
- **Updated**: The `content` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

716. Change `SalesInvoiceLineRequest documentId` to nullable
- **Original**: The `documentId` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

717. Change `SalesInvoiceLineRequest sequence` to nullable
- **Original**: The `sequence` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

718. Change `SalesInvoiceLineRequest itemId` to nullable
- **Original**: The `itemId` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

719. Change `SalesInvoiceLineRequest accountId` to nullable
- **Original**: The `accountId` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

720. Change `SalesInvoiceLineRequest lineType` to nullable
- **Original**: The `lineType` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

721. Change `SalesInvoiceLineRequest description` to nullable
- **Original**: The `description` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

722. Change `SalesInvoiceLineRequest unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

723. Change `SalesInvoiceLineRequest unitPrice` to nullable
- **Original**: The `unitPrice` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

724. Change `SalesInvoiceLineRequest quantity` to nullable
- **Original**: The `quantity` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

725. Change `SalesInvoiceLineRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

726. Change `SalesInvoiceLineRequest discountPercent` to nullable
- **Original**: The `discountPercent` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

727. Change `SalesInvoiceLineRequest discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

728. Change `SalesInvoiceLineRequest amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

729. Change `SalesInvoiceLineRequest taxCode` to nullable
- **Original**: The `taxCode` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

730. Change `SalesInvoiceLineRequest taxPercent` to nullable
- **Original**: The `taxPercent` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

731. Change `SalesInvoiceLineRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

732. Change `SalesInvoiceLineRequest amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

733. Change `SalesInvoiceLineRequest invoiceDiscountAllocation` to nullable
- **Original**: The `invoiceDiscountAllocation` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `invoiceDiscountAllocation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

734. Change `SalesInvoiceLineRequest netAmount` to nullable
- **Original**: The `netAmount` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

735. Change `SalesInvoiceLineRequest netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

736. Change `SalesInvoiceLineRequest netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

737. Change `SalesInvoiceLineRequest shipmentDate` to nullable
- **Original**: The `shipmentDate` field in `SalesInvoiceLineRequest` was `not nullable`.
- **Updated**: The `shipmentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

738. Change `SalesCreditMemoLineRequest documentId` to nullable
- **Original**: The `documentId` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

739. Change `SalesCreditMemoLineRequest sequence` to nullable
- **Original**: The `sequence` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

740. Change `SalesCreditMemoLineRequest itemId` to nullable
- **Original**: The `itemId` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

741. Change `SalesCreditMemoLineRequest accountId` to nullable
- **Original**: The `accountId` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

742. Change `SalesCreditMemoLineRequest lineType` to nullable
- **Original**: The `lineType` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

743. Change `SalesCreditMemoLineRequest description` to nullable
- **Original**: The `description` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

744. Change `SalesCreditMemoLineRequest unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

745. Change `SalesCreditMemoLineRequest unitPrice` to nullable
- **Original**: The `unitPrice` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

746. Change `SalesCreditMemoLineRequest quantity` to nullable
- **Original**: The `quantity` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

747. Change `SalesCreditMemoLineRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

748. Change `SalesCreditMemoLineRequest discountPercent` to nullable
- **Original**: The `discountPercent` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

749. Change `SalesCreditMemoLineRequest discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

750. Change `SalesCreditMemoLineRequest amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

751. Change `SalesCreditMemoLineRequest taxCode` to nullable
- **Original**: The `taxCode` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

752. Change `SalesCreditMemoLineRequest taxPercent` to nullable
- **Original**: The `taxPercent` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

753. Change `SalesCreditMemoLineRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

754. Change `SalesCreditMemoLineRequest amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

755. Change `SalesCreditMemoLineRequest invoiceDiscountAllocation` to nullable
- **Original**: The `invoiceDiscountAllocation` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `invoiceDiscountAllocation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

756. Change `SalesCreditMemoLineRequest netAmount` to nullable
- **Original**: The `netAmount` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

757. Change `SalesCreditMemoLineRequest netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

758. Change `SalesCreditMemoLineRequest netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

759. Change `SalesCreditMemoLineRequest shipmentDate` to nullable
- **Original**: The `shipmentDate` field in `SalesCreditMemoLineRequest` was `not nullable`.
- **Updated**: The `shipmentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

760. Change `SalesCreditMemoRequest number` to nullable
- **Original**: The `number` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

761. Change `SalesCreditMemoRequest externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

762. Change `SalesCreditMemoRequest creditMemoDate` to nullable
- **Original**: The `creditMemoDate` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `creditMemoDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

763. Change `SalesCreditMemoRequest dueDate` to nullable
- **Original**: The `dueDate` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `dueDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

764. Change `SalesCreditMemoRequest customerId` to nullable
- **Original**: The `customerId` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

765. Change `SalesCreditMemoRequest contactId` to nullable
- **Original**: The `contactId` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

766. Change `SalesCreditMemoRequest customerNumber` to nullable
- **Original**: The `customerNumber` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

767. Change `SalesCreditMemoRequest customerName` to nullable
- **Original**: The `customerName` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `customerName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

768. Change `SalesCreditMemoRequest billToName` to nullable
- **Original**: The `billToName` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `billToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

769. Change `SalesCreditMemoRequest billToCustomerId` to nullable
- **Original**: The `billToCustomerId` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `billToCustomerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

770. Change `SalesCreditMemoRequest billToCustomerNumber` to nullable
- **Original**: The `billToCustomerNumber` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `billToCustomerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

771. Change `SalesCreditMemoRequest currencyId` to nullable
- **Original**: The `currencyId` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

772. Change `SalesCreditMemoRequest currencyCode` to nullable
- **Original**: The `currencyCode` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

773. Change `SalesCreditMemoRequest paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

774. Change `SalesCreditMemoRequest shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

775. Change `SalesCreditMemoRequest salesperson` to nullable
- **Original**: The `salesperson` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `salesperson` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

776. Change `SalesCreditMemoRequest pricesIncludeTax` to nullable
- **Original**: The `pricesIncludeTax` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `pricesIncludeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

777. Change `SalesCreditMemoRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

778. Change `SalesCreditMemoRequest discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

779. Change `SalesCreditMemoRequest totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

780. Change `SalesCreditMemoRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

781. Change `SalesCreditMemoRequest totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

782. Change `SalesCreditMemoRequest status` to nullable
- **Original**: The `status` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

783. Change `SalesCreditMemoRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

784. Change `SalesCreditMemoRequest invoiceId` to nullable
- **Original**: The `invoiceId` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `invoiceId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

785. Change `SalesCreditMemoRequest invoiceNumber` to nullable
- **Original**: The `invoiceNumber` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `invoiceNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

786. Change `SalesCreditMemoRequest phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

787. Change `SalesCreditMemoRequest email` to nullable
- **Original**: The `email` field in `SalesCreditMemoRequest` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

788. Change `CountryRegionRequest displayName` to nullable
- **Original**: The `displayName` field in `CountryRegionRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

789. Change `CountryRegionRequest addressFormat` to nullable
- **Original**: The `addressFormat` field in `CountryRegionRequest` was `not nullable`.
- **Updated**: The `addressFormat` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

790. Change `CountryRegionRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CountryRegionRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

791. Change `PurchaseInvoiceLineRequest documentId` to nullable
- **Original**: The `documentId` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

792. Change `PurchaseInvoiceLineRequest sequence` to nullable
- **Original**: The `sequence` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

793. Change `PurchaseInvoiceLineRequest itemId` to nullable
- **Original**: The `itemId` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

794. Change `PurchaseInvoiceLineRequest accountId` to nullable
- **Original**: The `accountId` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

795. Change `PurchaseInvoiceLineRequest lineType` to nullable
- **Original**: The `lineType` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

796. Change `PurchaseInvoiceLineRequest description` to nullable
- **Original**: The `description` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

797. Change `PurchaseInvoiceLineRequest unitCost` to nullable
- **Original**: The `unitCost` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `unitCost` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

798. Change `PurchaseInvoiceLineRequest quantity` to nullable
- **Original**: The `quantity` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

799. Change `PurchaseInvoiceLineRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

800. Change `PurchaseInvoiceLineRequest discountPercent` to nullable
- **Original**: The `discountPercent` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

801. Change `PurchaseInvoiceLineRequest discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

802. Change `PurchaseInvoiceLineRequest amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

803. Change `PurchaseInvoiceLineRequest taxCode` to nullable
- **Original**: The `taxCode` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

804. Change `PurchaseInvoiceLineRequest taxPercent` to nullable
- **Original**: The `taxPercent` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

805. Change `PurchaseInvoiceLineRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

806. Change `PurchaseInvoiceLineRequest amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

807. Change `PurchaseInvoiceLineRequest invoiceDiscountAllocation` to nullable
- **Original**: The `invoiceDiscountAllocation` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `invoiceDiscountAllocation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

808. Change `PurchaseInvoiceLineRequest netAmount` to nullable
- **Original**: The `netAmount` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

809. Change `PurchaseInvoiceLineRequest netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

810. Change `PurchaseInvoiceLineRequest netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

811. Change `PurchaseInvoiceLineRequest expectedReceiptDate` to nullable
- **Original**: The `expectedReceiptDate` field in `PurchaseInvoiceLineRequest` was `not nullable`.
- **Updated**: The `expectedReceiptDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

812. Change `VendorRequest number` to nullable
- **Original**: The `number` field in `VendorRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

813. Change `VendorRequest displayName` to nullable
- **Original**: The `displayName` field in `VendorRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

814. Change `VendorRequest phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `VendorRequest` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

815. Change `VendorRequest email` to nullable
- **Original**: The `email` field in `VendorRequest` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

816. Change `VendorRequest website` to nullable
- **Original**: The `website` field in `VendorRequest` was `not nullable`.
- **Updated**: The `website` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

817. Change `VendorRequest taxRegistrationNumber` to nullable
- **Original**: The `taxRegistrationNumber` field in `VendorRequest` was `not nullable`.
- **Updated**: The `taxRegistrationNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

818. Change `VendorRequest currencyId` to nullable
- **Original**: The `currencyId` field in `VendorRequest` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

819. Change `VendorRequest currencyCode` to nullable
- **Original**: The `currencyCode` field in `VendorRequest` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

820. Change `VendorRequest irs1099Code` to nullable
- **Original**: The `irs1099Code` field in `VendorRequest` was `not nullable`.
- **Updated**: The `irs1099Code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

821. Change `VendorRequest paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `VendorRequest` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

822. Change `VendorRequest paymentMethodId` to nullable
- **Original**: The `paymentMethodId` field in `VendorRequest` was `not nullable`.
- **Updated**: The `paymentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

823. Change `VendorRequest taxLiable` to nullable
- **Original**: The `taxLiable` field in `VendorRequest` was `not nullable`.
- **Updated**: The `taxLiable` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

824. Change `VendorRequest blocked` to nullable
- **Original**: The `blocked` field in `VendorRequest` was `not nullable`.
- **Updated**: The `blocked` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

825. Change `VendorRequest balance` to nullable
- **Original**: The `balance` field in `VendorRequest` was `not nullable`.
- **Updated**: The `balance` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

826. Change `VendorRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `VendorRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

827. Change `CustomerRequest number` to nullable
- **Original**: The `number` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

828. Change `CustomerRequest type` to nullable
- **Original**: The `type` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `type` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

829. Change `CustomerRequest phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

830. Change `CustomerRequest email` to nullable
- **Original**: The `email` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

831. Change `CustomerRequest website` to nullable
- **Original**: The `website` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `website` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

832. Change `CustomerRequest taxLiable` to nullable
- **Original**: The `taxLiable` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `taxLiable` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

833. Change `CustomerRequest taxAreaId` to nullable
- **Original**: The `taxAreaId` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `taxAreaId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

834. Change `CustomerRequest taxAreaDisplayName` to nullable
- **Original**: The `taxAreaDisplayName` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `taxAreaDisplayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

835. Change `CustomerRequest taxRegistrationNumber` to nullable
- **Original**: The `taxRegistrationNumber` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `taxRegistrationNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

836. Change `CustomerRequest currencyId` to nullable
- **Original**: The `currencyId` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

837. Change `CustomerRequest currencyCode` to nullable
- **Original**: The `currencyCode` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

838. Change `CustomerRequest paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

839. Change `CustomerRequest shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

840. Change `CustomerRequest paymentMethodId` to nullable
- **Original**: The `paymentMethodId` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `paymentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

841. Change `CustomerRequest blocked` to nullable
- **Original**: The `blocked` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `blocked` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

842. Change `CustomerRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CustomerRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

843. Change `ItemRequest number` to nullable
- **Original**: The `number` field in `ItemRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

844. Change `ItemRequest displayName` to nullable
- **Original**: The `displayName` field in `ItemRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

845. Change `ItemRequest type` to nullable
- **Original**: The `type` field in `ItemRequest` was `not nullable`.
- **Updated**: The `type` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

846. Change `ItemRequest itemCategoryId` to nullable
- **Original**: The `itemCategoryId` field in `ItemRequest` was `not nullable`.
- **Updated**: The `itemCategoryId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

847. Change `ItemRequest itemCategoryCode` to nullable
- **Original**: The `itemCategoryCode` field in `ItemRequest` was `not nullable`.
- **Updated**: The `itemCategoryCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

848. Change `ItemRequest blocked` to nullable
- **Original**: The `blocked` field in `ItemRequest` was `not nullable`.
- **Updated**: The `blocked` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

849. Change `ItemRequest baseUnitOfMeasureId` to nullable
- **Original**: The `baseUnitOfMeasureId` field in `ItemRequest` was `not nullable`.
- **Updated**: The `baseUnitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

850. Change `ItemRequest gtin` to nullable
- **Original**: The `gtin` field in `ItemRequest` was `not nullable`.
- **Updated**: The `gtin` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

851. Change `ItemRequest inventory` to nullable
- **Original**: The `inventory` field in `ItemRequest` was `not nullable`.
- **Updated**: The `inventory` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

852. Change `ItemRequest unitPrice` to nullable
- **Original**: The `unitPrice` field in `ItemRequest` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

853. Change `ItemRequest priceIncludesTax` to nullable
- **Original**: The `priceIncludesTax` field in `ItemRequest` was `not nullable`.
- **Updated**: The `priceIncludesTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

854. Change `ItemRequest unitCost` to nullable
- **Original**: The `unitCost` field in `ItemRequest` was `not nullable`.
- **Updated**: The `unitCost` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

855. Change `ItemRequest taxGroupId` to nullable
- **Original**: The `taxGroupId` field in `ItemRequest` was `not nullable`.
- **Updated**: The `taxGroupId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

856. Change `ItemRequest taxGroupCode` to nullable
- **Original**: The `taxGroupCode` field in `ItemRequest` was `not nullable`.
- **Updated**: The `taxGroupCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

857. Change `ItemRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `ItemRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

858. Change `JournalRequest displayName` to nullable
- **Original**: The `displayName` field in `JournalRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

859. Change `JournalRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `JournalRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

860. Change `JournalRequest balancingAccountId` to nullable
- **Original**: The `balancingAccountId` field in `JournalRequest` was `not nullable`.
- **Updated**: The `balancingAccountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

861. Change `JournalRequest balancingAccountNumber` to nullable
- **Original**: The `balancingAccountNumber` field in `JournalRequest` was `not nullable`.
- **Updated**: The `balancingAccountNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

862. Change `PurchaseInvoiceRequest number` to nullable
- **Original**: The `number` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

863. Change `PurchaseInvoiceRequest invoiceDate` to nullable
- **Original**: The `invoiceDate` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `invoiceDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

864. Change `PurchaseInvoiceRequest dueDate` to nullable
- **Original**: The `dueDate` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `dueDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

865. Change `PurchaseInvoiceRequest vendorInvoiceNumber` to nullable
- **Original**: The `vendorInvoiceNumber` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `vendorInvoiceNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

866. Change `PurchaseInvoiceRequest vendorId` to nullable
- **Original**: The `vendorId` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `vendorId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

867. Change `PurchaseInvoiceRequest vendorNumber` to nullable
- **Original**: The `vendorNumber` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `vendorNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

868. Change `PurchaseInvoiceRequest vendorName` to nullable
- **Original**: The `vendorName` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `vendorName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

869. Change `PurchaseInvoiceRequest payToName` to nullable
- **Original**: The `payToName` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `payToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

870. Change `PurchaseInvoiceRequest payToContact` to nullable
- **Original**: The `payToContact` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `payToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

871. Change `PurchaseInvoiceRequest payToVendorId` to nullable
- **Original**: The `payToVendorId` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `payToVendorId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

872. Change `PurchaseInvoiceRequest payToVendorNumber` to nullable
- **Original**: The `payToVendorNumber` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `payToVendorNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

873. Change `PurchaseInvoiceRequest shipToName` to nullable
- **Original**: The `shipToName` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `shipToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

874. Change `PurchaseInvoiceRequest shipToContact` to nullable
- **Original**: The `shipToContact` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `shipToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

875. Change `PurchaseInvoiceRequest currencyId` to nullable
- **Original**: The `currencyId` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

876. Change `PurchaseInvoiceRequest currencyCode` to nullable
- **Original**: The `currencyCode` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

877. Change `PurchaseInvoiceRequest pricesIncludeTax` to nullable
- **Original**: The `pricesIncludeTax` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `pricesIncludeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

878. Change `PurchaseInvoiceRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

879. Change `PurchaseInvoiceRequest discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

880. Change `PurchaseInvoiceRequest totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

881. Change `PurchaseInvoiceRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

882. Change `PurchaseInvoiceRequest totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

883. Change `PurchaseInvoiceRequest status` to nullable
- **Original**: The `status` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

884. Change `PurchaseInvoiceRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `PurchaseInvoiceRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

885. Change `SalesOrderLineRequest documentId` to nullable
- **Original**: The `documentId` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `documentId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

886. Change `SalesOrderLineRequest sequence` to nullable
- **Original**: The `sequence` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `sequence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

887. Change `SalesOrderLineRequest itemId` to nullable
- **Original**: The `itemId` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `itemId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

888. Change `SalesOrderLineRequest accountId` to nullable
- **Original**: The `accountId` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

889. Change `SalesOrderLineRequest lineType` to nullable
- **Original**: The `lineType` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `lineType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

890. Change `SalesOrderLineRequest description` to nullable
- **Original**: The `description` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

891. Change `SalesOrderLineRequest unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

892. Change `SalesOrderLineRequest quantity` to nullable
- **Original**: The `quantity` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

893. Change `SalesOrderLineRequest unitPrice` to nullable
- **Original**: The `unitPrice` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `unitPrice` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

894. Change `SalesOrderLineRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

895. Change `SalesOrderLineRequest discountPercent` to nullable
- **Original**: The `discountPercent` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

896. Change `SalesOrderLineRequest discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

897. Change `SalesOrderLineRequest amountExcludingTax` to nullable
- **Original**: The `amountExcludingTax` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `amountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

898. Change `SalesOrderLineRequest taxCode` to nullable
- **Original**: The `taxCode` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `taxCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

899. Change `SalesOrderLineRequest taxPercent` to nullable
- **Original**: The `taxPercent` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `taxPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

900. Change `SalesOrderLineRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

901. Change `SalesOrderLineRequest amountIncludingTax` to nullable
- **Original**: The `amountIncludingTax` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `amountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

902. Change `SalesOrderLineRequest invoiceDiscountAllocation` to nullable
- **Original**: The `invoiceDiscountAllocation` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `invoiceDiscountAllocation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

903. Change `SalesOrderLineRequest netAmount` to nullable
- **Original**: The `netAmount` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `netAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

904. Change `SalesOrderLineRequest netTaxAmount` to nullable
- **Original**: The `netTaxAmount` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `netTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

905. Change `SalesOrderLineRequest netAmountIncludingTax` to nullable
- **Original**: The `netAmountIncludingTax` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `netAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

906. Change `SalesOrderLineRequest shipmentDate` to nullable
- **Original**: The `shipmentDate` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `shipmentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

907. Change `SalesOrderLineRequest shippedQuantity` to nullable
- **Original**: The `shippedQuantity` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `shippedQuantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

908. Change `SalesOrderLineRequest invoicedQuantity` to nullable
- **Original**: The `invoicedQuantity` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `invoicedQuantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

909. Change `SalesOrderLineRequest invoiceQuantity` to nullable
- **Original**: The `invoiceQuantity` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `invoiceQuantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

910. Change `SalesOrderLineRequest shipQuantity` to nullable
- **Original**: The `shipQuantity` field in `SalesOrderLineRequest` was `not nullable`.
- **Updated**: The `shipQuantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

911. Change `TimeRegistrationEntryRequest employeeId` to nullable
- **Original**: The `employeeId` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `employeeId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

912. Change `TimeRegistrationEntryRequest employeeNumber` to nullable
- **Original**: The `employeeNumber` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `employeeNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

913. Change `TimeRegistrationEntryRequest jobId` to nullable
- **Original**: The `jobId` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `jobId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

914. Change `TimeRegistrationEntryRequest jobNumber` to nullable
- **Original**: The `jobNumber` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `jobNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

915. Change `TimeRegistrationEntryRequest absence` to nullable
- **Original**: The `absence` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `absence` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

916. Change `TimeRegistrationEntryRequest lineNumber` to nullable
- **Original**: The `lineNumber` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `lineNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

917. Change `TimeRegistrationEntryRequest date` to nullable
- **Original**: The `date` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `date` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

918. Change `TimeRegistrationEntryRequest quantity` to nullable
- **Original**: The `quantity` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `quantity` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

919. Change `TimeRegistrationEntryRequest status` to nullable
- **Original**: The `status` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

920. Change `TimeRegistrationEntryRequest unitOfMeasureId` to nullable
- **Original**: The `unitOfMeasureId` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `unitOfMeasureId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

921. Change `TimeRegistrationEntryRequest lastModfiedDateTime` to nullable
- **Original**: The `lastModfiedDateTime` field in `TimeRegistrationEntryRequest` was `not nullable`.
- **Updated**: The `lastModfiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

922. Change `PaymentTermRequest displayName` to nullable
- **Original**: The `displayName` field in `PaymentTermRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

923. Change `PaymentTermRequest dueDateCalculation` to nullable
- **Original**: The `dueDateCalculation` field in `PaymentTermRequest` was `not nullable`.
- **Updated**: The `dueDateCalculation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

924. Change `PaymentTermRequest discountDateCalculation` to nullable
- **Original**: The `discountDateCalculation` field in `PaymentTermRequest` was `not nullable`.
- **Updated**: The `discountDateCalculation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

925. Change `PaymentTermRequest discountPercent` to nullable
- **Original**: The `discountPercent` field in `PaymentTermRequest` was `not nullable`.
- **Updated**: The `discountPercent` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

926. Change `PaymentTermRequest calculateDiscountOnCreditMemos` to nullable
- **Original**: The `calculateDiscountOnCreditMemos` field in `PaymentTermRequest` was `not nullable`.
- **Updated**: The `calculateDiscountOnCreditMemos` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

927. Change `PaymentTermRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `PaymentTermRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

928. Change `CustomerPaymentRequest journalDisplayName` to nullable
- **Original**: The `journalDisplayName` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `journalDisplayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

929. Change `CustomerPaymentRequest lineNumber` to nullable
- **Original**: The `lineNumber` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `lineNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

930. Change `CustomerPaymentRequest customerId` to nullable
- **Original**: The `customerId` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

931. Change `CustomerPaymentRequest customerNumber` to nullable
- **Original**: The `customerNumber` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

932. Change `CustomerPaymentRequest contactId` to nullable
- **Original**: The `contactId` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

933. Change `CustomerPaymentRequest postingDate` to nullable
- **Original**: The `postingDate` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `postingDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

934. Change `CustomerPaymentRequest documentNumber` to nullable
- **Original**: The `documentNumber` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `documentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

935. Change `CustomerPaymentRequest externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

936. Change `CustomerPaymentRequest amount` to nullable
- **Original**: The `amount` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

937. Change `CustomerPaymentRequest appliesToInvoiceId` to nullable
- **Original**: The `appliesToInvoiceId` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `appliesToInvoiceId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

938. Change `CustomerPaymentRequest appliesToInvoiceNumber` to nullable
- **Original**: The `appliesToInvoiceNumber` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `appliesToInvoiceNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

939. Change `CustomerPaymentRequest description` to nullable
- **Original**: The `description` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

940. Change `CustomerPaymentRequest comment` to nullable
- **Original**: The `comment` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `comment` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

941. Change `CustomerPaymentRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CustomerPaymentRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

942. Change `CustomerPaymentJournalRequest displayName` to nullable
- **Original**: The `displayName` field in `CustomerPaymentJournalRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

943. Change `CustomerPaymentJournalRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CustomerPaymentJournalRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

944. Change `CustomerPaymentJournalRequest balancingAccountId` to nullable
- **Original**: The `balancingAccountId` field in `CustomerPaymentJournalRequest` was `not nullable`.
- **Updated**: The `balancingAccountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

945. Change `CustomerPaymentJournalRequest balancingAccountNumber` to nullable
- **Original**: The `balancingAccountNumber` field in `CustomerPaymentJournalRequest` was `not nullable`.
- **Updated**: The `balancingAccountNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

946. Change `JournalLineRequest journalDisplayName` to nullable
- **Original**: The `journalDisplayName` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `journalDisplayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

947. Change `JournalLineRequest lineNumber` to nullable
- **Original**: The `lineNumber` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `lineNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

948. Change `JournalLineRequest accountType` to nullable
- **Original**: The `accountType` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `accountType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

949. Change `JournalLineRequest accountId` to nullable
- **Original**: The `accountId` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `accountId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

950. Change `JournalLineRequest accountNumber` to nullable
- **Original**: The `accountNumber` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `accountNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

951. Change `JournalLineRequest postingDate` to nullable
- **Original**: The `postingDate` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `postingDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

952. Change `JournalLineRequest documentNumber` to nullable
- **Original**: The `documentNumber` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `documentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

953. Change `JournalLineRequest externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

954. Change `JournalLineRequest amount` to nullable
- **Original**: The `amount` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `amount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

955. Change `JournalLineRequest description` to nullable
- **Original**: The `description` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `description` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

956. Change `JournalLineRequest comment` to nullable
- **Original**: The `comment` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `comment` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

957. Change `JournalLineRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `JournalLineRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

958. Change `ProjectRequest number` to nullable
- **Original**: The `number` field in `ProjectRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

959. Change `ProjectRequest displayName` to nullable
- **Original**: The `displayName` field in `ProjectRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

960. Change `SalesInvoiceRequest number` to nullable
- **Original**: The `number` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

961. Change `SalesInvoiceRequest externalDocumentNumber` to nullable
- **Original**: The `externalDocumentNumber` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `externalDocumentNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

962. Change `SalesInvoiceRequest invoiceDate` to nullable
- **Original**: The `invoiceDate` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `invoiceDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

963. Change `SalesInvoiceRequest dueDate` to nullable
- **Original**: The `dueDate` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `dueDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

964. Change `SalesInvoiceRequest customerPurchaseOrderReference` to nullable
- **Original**: The `customerPurchaseOrderReference` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `customerPurchaseOrderReference` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

965. Change `SalesInvoiceRequest customerId` to nullable
- **Original**: The `customerId` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `customerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

966. Change `SalesInvoiceRequest contactId` to nullable
- **Original**: The `contactId` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `contactId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

967. Change `SalesInvoiceRequest customerNumber` to nullable
- **Original**: The `customerNumber` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `customerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

968. Change `SalesInvoiceRequest customerName` to nullable
- **Original**: The `customerName` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `customerName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

969. Change `SalesInvoiceRequest billToName` to nullable
- **Original**: The `billToName` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `billToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

970. Change `SalesInvoiceRequest billToCustomerId` to nullable
- **Original**: The `billToCustomerId` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `billToCustomerId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

971. Change `SalesInvoiceRequest billToCustomerNumber` to nullable
- **Original**: The `billToCustomerNumber` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `billToCustomerNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

972. Change `SalesInvoiceRequest shipToName` to nullable
- **Original**: The `shipToName` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `shipToName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

973. Change `SalesInvoiceRequest shipToContact` to nullable
- **Original**: The `shipToContact` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `shipToContact` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

974. Change `SalesInvoiceRequest currencyId` to nullable
- **Original**: The `currencyId` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `currencyId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

975. Change `SalesInvoiceRequest currencyCode` to nullable
- **Original**: The `currencyCode` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

976. Change `SalesInvoiceRequest orderId` to nullable
- **Original**: The `orderId` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `orderId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

977. Change `SalesInvoiceRequest orderNumber` to nullable
- **Original**: The `orderNumber` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `orderNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

978. Change `SalesInvoiceRequest paymentTermsId` to nullable
- **Original**: The `paymentTermsId` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `paymentTermsId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

979. Change `SalesInvoiceRequest shipmentMethodId` to nullable
- **Original**: The `shipmentMethodId` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `shipmentMethodId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

980. Change `SalesInvoiceRequest salesperson` to nullable
- **Original**: The `salesperson` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `salesperson` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

981. Change `SalesInvoiceRequest pricesIncludeTax` to nullable
- **Original**: The `pricesIncludeTax` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `pricesIncludeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

982. Change `SalesInvoiceRequest remainingAmount` to nullable
- **Original**: The `remainingAmount` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `remainingAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

983. Change `SalesInvoiceRequest discountAmount` to nullable
- **Original**: The `discountAmount` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `discountAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

984. Change `SalesInvoiceRequest discountAppliedBeforeTax` to nullable
- **Original**: The `discountAppliedBeforeTax` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `discountAppliedBeforeTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

985. Change `SalesInvoiceRequest totalAmountExcludingTax` to nullable
- **Original**: The `totalAmountExcludingTax` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `totalAmountExcludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

986. Change `SalesInvoiceRequest totalTaxAmount` to nullable
- **Original**: The `totalTaxAmount` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `totalTaxAmount` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

987. Change `SalesInvoiceRequest totalAmountIncludingTax` to nullable
- **Original**: The `totalAmountIncludingTax` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `totalAmountIncludingTax` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

988. Change `SalesInvoiceRequest status` to nullable
- **Original**: The `status` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

989. Change `SalesInvoiceRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

990. Change `SalesInvoiceRequest phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

991. Change `SalesInvoiceRequest email` to nullable
- **Original**: The `email` field in `SalesInvoiceRequest` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

992. Change `GeneralLedgerEntryAttachmentsRequest fileName` to nullable
- **Original**: The `fileName` field in `GeneralLedgerEntryAttachmentsRequest` was `not nullable`.
- **Updated**: The `fileName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

993. Change `GeneralLedgerEntryAttachmentsRequest byteSize` to nullable
- **Original**: The `byteSize` field in `GeneralLedgerEntryAttachmentsRequest` was `not nullable`.
- **Updated**: The `byteSize` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

994. Change `GeneralLedgerEntryAttachmentsRequest content` to nullable
- **Original**: The `content` field in `GeneralLedgerEntryAttachmentsRequest` was `not nullable`.
- **Updated**: The `content` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

995. Change `GeneralLedgerEntryAttachmentsRequest createdDateTime` to nullable
- **Original**: The `createdDateTime` field in `GeneralLedgerEntryAttachmentsRequest` was `not nullable`.
- **Updated**: The `createdDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

996. Change `UnitOfMeasureRequest displayName` to nullable
- **Original**: The `displayName` field in `UnitOfMeasureRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

997. Change `UnitOfMeasureRequest internationalStandardCode` to nullable
- **Original**: The `internationalStandardCode` field in `UnitOfMeasureRequest` was `not nullable`.
- **Updated**: The `internationalStandardCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

998. Change `UnitOfMeasureRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `UnitOfMeasureRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

999. Change `CurrencyRequest displayName` to nullable
- **Original**: The `displayName` field in `CurrencyRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1000. Change `CurrencyRequest symbol` to nullable
- **Original**: The `symbol` field in `CurrencyRequest` was `not nullable`.
- **Updated**: The `symbol` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1001. Change `CurrencyRequest amountDecimalPlaces` to nullable
- **Original**: The `amountDecimalPlaces` field in `CurrencyRequest` was `not nullable`.
- **Updated**: The `amountDecimalPlaces` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1002. Change `CurrencyRequest amountRoundingPrecision` to nullable
- **Original**: The `amountRoundingPrecision` field in `CurrencyRequest` was `not nullable`.
- **Updated**: The `amountRoundingPrecision` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1003. Change `CurrencyRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CurrencyRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1004. Change `DefaultDimensionsRequest dimensionCode` to nullable
- **Original**: The `dimensionCode` field in `DefaultDimensionsRequest` was `not nullable`.
- **Updated**: The `dimensionCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1005. Change `DefaultDimensionsRequest dimensionValueId` to nullable
- **Original**: The `dimensionValueId` field in `DefaultDimensionsRequest` was `not nullable`.
- **Updated**: The `dimensionValueId` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1006. Change `DefaultDimensionsRequest dimensionValueCode` to nullable
- **Original**: The `dimensionValueCode` field in `DefaultDimensionsRequest` was `not nullable`.
- **Updated**: The `dimensionValueCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1007. Change `DefaultDimensionsRequest postingValidation` to nullable
- **Original**: The `postingValidation` field in `DefaultDimensionsRequest` was `not nullable`.
- **Updated**: The `postingValidation` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1008. Change `ShipmentMethodRequest displayName` to nullable
- **Original**: The `displayName` field in `ShipmentMethodRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1009. Change `ShipmentMethodRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `ShipmentMethodRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1010. Change `TaxGroupRequest code` to nullable
- **Original**: The `code` field in `TaxGroupRequest` was `not nullable`.
- **Updated**: The `code` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1011. Change `TaxGroupRequest displayName` to nullable
- **Original**: The `displayName` field in `TaxGroupRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1012. Change `TaxGroupRequest taxType` to nullable
- **Original**: The `taxType` field in `TaxGroupRequest` was `not nullable`.
- **Updated**: The `taxType` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1013. Change `TaxGroupRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `TaxGroupRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1014. Change `EmployeeRequest number` to nullable
- **Original**: The `number` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `number` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1015. Change `EmployeeRequest displayName` to nullable
- **Original**: The `displayName` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1016. Change `EmployeeRequest givenName` to nullable
- **Original**: The `givenName` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `givenName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1017. Change `EmployeeRequest middleName` to nullable
- **Original**: The `middleName` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `middleName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1018. Change `EmployeeRequest surname` to nullable
- **Original**: The `surname` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `surname` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1019. Change `EmployeeRequest jobTitle` to nullable
- **Original**: The `jobTitle` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `jobTitle` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1020. Change `EmployeeRequest phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1021. Change `EmployeeRequest mobilePhone` to nullable
- **Original**: The `mobilePhone` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `mobilePhone` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1022. Change `EmployeeRequest email` to nullable
- **Original**: The `email` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1023. Change `EmployeeRequest personalEmail` to nullable
- **Original**: The `personalEmail` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `personalEmail` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1024. Change `EmployeeRequest employmentDate` to nullable
- **Original**: The `employmentDate` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `employmentDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1025. Change `EmployeeRequest terminationDate` to nullable
- **Original**: The `terminationDate` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `terminationDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1026. Change `EmployeeRequest status` to nullable
- **Original**: The `status` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `status` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1027. Change `EmployeeRequest birthDate` to nullable
- **Original**: The `birthDate` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `birthDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1028. Change `EmployeeRequest statisticsGroupCode` to nullable
- **Original**: The `statisticsGroupCode` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `statisticsGroupCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1029. Change `EmployeeRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `EmployeeRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1030. Change `CompanyInformationRequest displayName` to nullable
- **Original**: The `displayName` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `displayName` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1031. Change `CompanyInformationRequest phoneNumber` to nullable
- **Original**: The `phoneNumber` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `phoneNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1032. Change `CompanyInformationRequest faxNumber` to nullable
- **Original**: The `faxNumber` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `faxNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1033. Change `CompanyInformationRequest email` to nullable
- **Original**: The `email` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `email` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1034. Change `CompanyInformationRequest website` to nullable
- **Original**: The `website` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `website` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1035. Change `CompanyInformationRequest taxRegistrationNumber` to nullable
- **Original**: The `taxRegistrationNumber` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `taxRegistrationNumber` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1036. Change `CompanyInformationRequest currencyCode` to nullable
- **Original**: The `currencyCode` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `currencyCode` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1037. Change `CompanyInformationRequest currentFiscalYearStartDate` to nullable
- **Original**: The `currentFiscalYearStartDate` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `currentFiscalYearStartDate` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1038. Change `CompanyInformationRequest industry` to nullable
- **Original**: The `industry` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `industry` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1039. Change `CompanyInformationRequest picture` to nullable
- **Original**: The `picture` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `picture` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

1040. Change `CompanyInformationRequest lastModifiedDateTime` to nullable
- **Original**: The `lastModifiedDateTime` field in `CompanyInformationRequest` was `not nullable`.
- **Updated**: The `lastModifiedDateTime` field has been updated to be `nullable`.
- **Reason**: The API can return a null value for this field.
<!-- auto-generated -->

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/aligned_ballerina_openapi.json -o ballerina --mode client --license docs/license.txt --client-methods remote
```

Note: The license year in `docs/license.txt` is 2026; change it if necessary.
