// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

listener http:Listener ep0 = new (9090);

final Company mockCompany = {
    id: "a1b2c3d4-1111-4a2b-9c3d-0e1f2a3b4c5d",
    systemVersion: "26.0.0.0",
    name: "CRONUS International Ltd.",
    displayName: "CRONUS International Ltd.",
    businessProfileId: "BP-0001"
};

final Item mockItem = {
    id: "b2c3d4e5-2222-4b3c-8d4e-1f2a3b4c5d6e",
    number: "1896-S",
    displayName: "ATHENS Desk",
    'type: "Inventory",
    itemCategoryId: "c3d4e5f6-3333-4c4d-9e5f-2a3b4c5d6e7f",
    itemCategoryCode: "FURNITURE",
    blocked: false,
    baseUnitOfMeasureId: "d4e5f6a7-4444-4d5e-8f6a-3b4c5d6e7f80",
    gtin: "07350040900001",
    inventory: 12.0d,
    unitPrice: 1000.8d,
    priceIncludesTax: false,
    unitCost: 780.7d,
    taxGroupId: "e5f6a7b8-5555-4e6f-9a7b-4c5d6e7f8091",
    taxGroupCode: "FURNITURE",
    lastModifiedDateTime: "2026-03-11T08:42:17Z"
};

final Customer mockCustomer = {
    id: "f6a7b8c9-6666-4f70-8b8c-5d6e7f809102",
    number: "10000",
    displayName: "Adatum Corporation",
    'type: "Company",
    address: {
        street: "192 Market Square",
        city: "Atlanta",
        state: "GA",
        countryLetterCode: "US",
        postalCode: "31772"
    },
    phoneNumber: "+1 425 555 0100",
    email: "robert.townes@contoso.com",
    website: "https://www.adatum.com",
    taxLiable: true,
    currencyCode: "USD",
    paymentTermsId: "a7b8c9d0-7777-4081-9c9d-6e7f80910213",
    blocked: " ",
    lastModifiedDateTime: "2026-03-09T14:05:02Z"
};

final Vendor mockVendor = {
    id: "b8c9d0e1-8888-4192-8d0e-7f8091021324",
    number: "10000",
    displayName: "Fabrikam, Inc.",
    address: {
        street: "10 Ferry Road",
        city: "Redmond",
        state: "WA",
        countryLetterCode: "US",
        postalCode: "98052"
    },
    phoneNumber: "+1 425 555 0182",
    taxLiable: true,
    currencyCode: "USD",
    balance: 1820.4d,
    blocked: " ",
    lastModifiedDateTime: "2026-02-27T09:13:44Z"
};

final Employee mockEmployee = {
    id: "c9d0e1f2-9999-42a3-9e1f-80910213243546",
    number: "MH",
    displayName: "Mark Hanson",
    givenName: "Mark",
    surname: "Hanson",
    jobTitle: "Sales Manager",
    address: {
        street: "5 Wellington Road",
        city: "Birmingham",
        countryLetterCode: "GB",
        postalCode: "B1 1AA"
    },
    phoneNumber: "+44 121 555 0143",
    email: "mark.hanson@cronus.example",
    employmentDate: "2021-06-01",
    status: "Active",
    lastModifiedDateTime: "2026-01-19T11:27:35Z"
};

final SalesInvoiceLine mockSalesInvoiceLine = {
    id: "d0e1f2a3-aaaa-43b4-8f20-910213243546",
    documentId: "e1f2a3b4-bbbb-44c5-9031-a21324354657",
    sequence: 10000,
    lineType: "Item",
    itemId: "b2c3d4e5-2222-4b3c-8d4e-1f2a3b4c5d6e",
    description: "ATHENS Desk",
    unitOfMeasureId: "d4e5f6a7-4444-4d5e-8f6a-3b4c5d6e7f80",
    quantity: 3.0d,
    unitPrice: 1000.8d,
    discountAmount: 0d,
    discountPercent: 0d,
    discountAppliedBeforeTax: false,
    amountExcludingTax: 3002.4d,
    taxCode: "FURNITURE",
    taxPercent: 10.0d,
    totalTaxAmount: 300.24d,
    amountIncludingTax: 3302.64d,
    netAmount: 3002.4d,
    netTaxAmount: 300.24d,
    netAmountIncludingTax: 3302.64d,
    shipmentDate: "2026-04-02"
};

final SalesInvoice mockSalesInvoice = {
    id: "e1f2a3b4-bbbb-44c5-9031-a21324354657",
    number: "103001",
    externalDocumentNumber: "PO-88213",
    invoiceDate: "2026-03-30",
    dueDate: "2026-04-29",
    customerId: "f6a7b8c9-6666-4f70-8b8c-5d6e7f809102",
    customerNumber: "10000",
    customerName: "Adatum Corporation",
    billToName: "Adatum Corporation",
    shipToName: "Adatum Corporation",
    currencyCode: "USD",
    pricesIncludeTax: false,
    discountAmount: 0d,
    totalAmountExcludingTax: 3002.4d,
    totalTaxAmount: 300.24d,
    totalAmountIncludingTax: 3302.64d,
    remainingAmount: 3302.64d,
    status: "Draft",
    lastModifiedDateTime: "2026-03-30T16:21:09Z",
    salesInvoiceLines: [mockSalesInvoiceLine]
};

final SalesOrder mockSalesOrder = {
    id: "f2a3b4c5-cccc-45d6-8142-b32435465768",
    number: "101005",
    orderDate: "2026-03-18",
    customerId: "f6a7b8c9-6666-4f70-8b8c-5d6e7f809102",
    customerNumber: "10000",
    customerName: "Adatum Corporation",
    currencyCode: "USD",
    pricesIncludeTax: false,
    totalAmountExcludingTax: 1500.0d,
    totalTaxAmount: 150.0d,
    totalAmountIncludingTax: 1650.0d,
    fullyShipped: false,
    status: "Open",
    lastModifiedDateTime: "2026-03-18T10:02:55Z"
};

final SalesQuote mockSalesQuote = {
    id: "a3b4c5d6-dddd-46e7-9253-c43546576879",
    number: "1001",
    documentDate: "2026-03-05",
    validUntilDate: "2026-04-05",
    customerId: "f6a7b8c9-6666-4f70-8b8c-5d6e7f809102",
    customerNumber: "10000",
    customerName: "Adatum Corporation",
    currencyCode: "USD",
    totalAmountExcludingTax: 980.0d,
    totalTaxAmount: 98.0d,
    totalAmountIncludingTax: 1078.0d,
    status: "Draft",
    lastModifiedDateTime: "2026-03-05T12:44:10Z"
};

final PurchaseInvoice mockPurchaseInvoice = {
    id: "b4c5d6e7-eeee-47f8-8364-d4657687980a",
    number: "108001",
    invoiceDate: "2026-03-21",
    dueDate: "2026-04-20",
    vendorId: "b8c9d0e1-8888-4192-8d0e-7f8091021324",
    vendorNumber: "10000",
    vendorName: "Fabrikam, Inc.",
    vendorInvoiceNumber: "FAB-55231",
    currencyCode: "USD",
    totalAmountExcludingTax: 1820.4d,
    totalTaxAmount: 182.04d,
    totalAmountIncludingTax: 2002.44d,
    status: "Draft",
    lastModifiedDateTime: "2026-03-21T07:55:31Z"
};

final Journal mockJournal = {
    id: "c5d6e7f8-ffff-4809-9475-e576879a0b1c",
    code: "DEFAULT",
    displayName: "Default Journal Batch",
    balancingAccountId: "d6e7f8a9-0a0a-491a-8586-f6879a0b1c2d",
    balancingAccountNumber: "10100",
    lastModifiedDateTime: "2026-02-14T13:36:48Z"
};

final Account mockAccount = {
    id: "d6e7f8a9-0a0a-491a-8586-f6879a0b1c2d",
    number: "10100",
    displayName: "Bank Current Account",
    category: "Assets",
    subCategory: "Cash",
    blocked: false,
    lastModifiedDateTime: "2026-01-08T09:00:00Z"
};

final BankAccount mockBankAccount = {
    id: "e7f8a9b0-1b1b-4a2b-9697-0789ab1c2d3e",
    number: "NBL",
    displayName: "New Business Local Bank"
};

final Project mockProject = {
    id: "f8a9b0c1-2c2c-4b3c-87a8-189abc2d3e4f",
    number: "JOB-1001",
    displayName: "Deerfield Office Fit-out"
};

final GeneralLedgerEntry mockGeneralLedgerEntry = {
    id: 10231,
    postingDate: "2026-03-30",
    documentNumber: "103001",
    documentType: "Invoice",
    accountId: "d6e7f8a9-0a0a-491a-8586-f6879a0b1c2d",
    accountNumber: "10100",
    description: "Sales invoice 103001",
    debitAmount: 3302.64d,
    creditAmount: 0d,
    lastModifiedDateTime: "2026-03-30T16:21:09Z"
};

final Currency mockCurrency = {
    id: "0a1b2c3d-4e5f-4061-9273-8495a6b7c8d9",
    code: "USD",
    displayName: "US Dollar",
    symbol: "$",
    amountDecimalPlaces: "2:2",
    amountRoundingPrecision: 0.01d,
    lastModifiedDateTime: "2026-01-04T10:15:00Z"
};

final PaymentTerm mockPaymentTerm = {
    id: "1b2c3d4e-5f60-4172-8384-95a6b7c8d9e0",
    code: "1M(8D)",
    displayName: "Net 30 days / 2% 8 days",
    dueDateCalculation: "1M",
    discountDateCalculation: "8D",
    discountPercent: 2.0d,
    calculateDiscountOnCreditMemos: false,
    lastModifiedDateTime: "2026-01-04T10:16:00Z"
};

final PaymentMethod mockPaymentMethod = {
    id: "2c3d4e5f-6071-4283-9495-a6b7c8d9e0f1",
    code: "BANK",
    displayName: "Bank transfer",
    lastModifiedDateTime: "2026-01-04T10:17:00Z"
};

final ShipmentMethod mockShipmentMethod = {
    id: "3d4e5f60-7182-4394-85a6-b7c8d9e0f102",
    code: "CIF",
    displayName: "Cost, insurance and freight",
    lastModifiedDateTime: "2026-01-04T10:18:00Z"
};

final ItemCategory mockItemCategory = {
    id: "c3d4e5f6-3333-4c4d-9e5f-2a3b4c5d6e7f",
    code: "FURNITURE",
    displayName: "Furniture",
    lastModifiedDateTime: "2026-01-04T10:19:00Z"
};

final CountryRegion mockCountryRegion = {
    id: "4e5f6071-8293-44a5-96b7-c8d9e0f10213",
    code: "US",
    displayName: "United States",
    addressFormat: "City+County+PostCode",
    lastModifiedDateTime: "2026-01-04T10:20:00Z"
};

final TaxArea mockTaxArea = {
    id: "5f607182-93a4-45b6-87c8-d9e0f1021324",
    code: "ATLANTA, GA",
    displayName: "Atlanta, GA",
    taxType: "Sales Tax",
    lastModifiedDateTime: "2026-01-04T10:21:00Z"
};

final TaxGroup mockTaxGroup = {
    id: "e5f6a7b8-5555-4e6f-9a7b-4c5d6e7f8091",
    code: "FURNITURE",
    displayName: "Furniture",
    taxType: "Sales Tax",
    lastModifiedDateTime: "2026-01-04T10:22:00Z"
};

final UnitOfMeasure mockUnitOfMeasure = {
    id: "d4e5f6a7-4444-4d5e-8f6a-3b4c5d6e7f80",
    code: "PCS",
    displayName: "Piece",
    internationalStandardCode: "EA",
    lastModifiedDateTime: "2026-01-04T10:23:00Z"
};

final Attachment mockAttachment = {
    id: "60718293-a4b5-46c7-98d9-e0f102132435",
    parentId: "aa112233-4455-4667-8899-aabbccddeeff",
    fileName: "delivery-note.pdf",
    byteSize: 20480,
    lastModifiedDateTime: "2026-03-12T11:45:00Z"
};

final GeneralLedgerEntryAttachments mockGeneralLedgerEntryAttachment = {
    id: "718293a4-b5c6-47d8-89e0-f10213243546",
    generalLedgerEntryNumber: 10231,
    fileName: "posting-voucher.pdf",
    byteSize: 15360,
    createdDateTime: "2026-03-30T16:25:00Z"
};

final Picture mockPicture = {
    id: "8293a4b5-c6d7-48e9-90f1-021324354657",
    width: 640,
    height: 480,
    contentType: "image/jpeg",
    contentOdataMediaReadLink: "companies(a1b2c3d4-1111-4a2b-9c3d-0e1f2a3b4c5d)/items(b2c3d4e5-2222-4b3c-8d4e-1f2a3b4c5d6e)/picture(8293a4b5-c6d7-48e9-90f1-021324354657)/content",
    contentOdataMediaEditLink: "companies(a1b2c3d4-1111-4a2b-9c3d-0e1f2a3b4c5d)/items(b2c3d4e5-2222-4b3c-8d4e-1f2a3b4c5d6e)/picture(8293a4b5-c6d7-48e9-90f1-021324354657)/content"
};

final PdfDocument mockPdfDocument = {
    id: "93a4b5c6-d7e8-49f0-8102-132435465768",
    content: {fileContent: [0x25, 0x50, 0x44, 0x46], fileName: "sales-invoice-103001.pdf"}
};

final BalanceSheet mockBalanceSheetLine = {
    lineNumber: 1000,
    display: "Cash",
    lineType: "Detail",
    indentation: 1,
    balance: 128455.71d,
    dateFilter: "2026-03-31"
};

final IncomeStatement mockIncomeStatementLine = {
    lineNumber: 2000,
    display: "Sales of Retail",
    lineType: "Detail",
    indentation: 1,
    netChange: 92310.5d,
    dateFilter: "2026-01-01..2026-03-31"
};

final CashFlowStatement mockCashFlowStatementLine = {
    lineNumber: 3000,
    display: "Cash Flow from Operations",
    lineType: "Total",
    indentation: 0,
    netChange: 41288.36d,
    dateFilter: "2026-01-01..2026-03-31"
};

final RetainedEarningsStatement mockRetainedEarningsStatementLine = {
    lineNumber: 4000,
    display: "Retained Earnings, Beginning Balance",
    lineType: "Detail",
    indentation: 1,
    netChange: 186420.09d,
    dateFilter: "2026-01-01..2026-03-31"
};

final TrialBalance mockTrialBalanceLine = {
    number: "10100",
    accountId: "d6e7f8a9-0a0a-491a-8586-f6879a0b1c2d",
    accountType: "Posting",
    display: "Bank Current Account",
    totalDebit: "142330.55",
    totalCredit: "13874.84",
    balanceAtDateDebit: "128455.71",
    balanceAtDateCredit: "0",
    dateFilter: "2026-01-01..2026-03-31"
};

final AgedAccountsReceivable mockAgedAccountsReceivable = {
    customerId: "f6a7b8c9-6666-4f70-8b8c-5d6e7f809102",
    customerNumber: "10000",
    name: "Adatum Corporation",
    currencyCode: "USD",
    balanceDue: 3302.64d,
    currentAmount: 1200.0d,
    period1Amount: 1102.64d,
    period2Amount: 1000.0d,
    period3Amount: 0d,
    agedAsOfDate: "2026-03-31",
    periodLengthFilter: "30D"
};

final AgedAccountsPayable mockAgedAccountsPayable = {
    vendorId: "b8c9d0e1-8888-4192-8d0e-7f8091021324",
    vendorNumber: "10000",
    name: "Fabrikam, Inc.",
    currencyCode: "USD",
    balanceDue: 1820.4d,
    currentAmount: 820.4d,
    period1Amount: 1000.0d,
    period2Amount: 0d,
    period3Amount: 0d,
    agedAsOfDate: "2026-03-31",
    periodLengthFilter: "30D"
};

service / on ep0 {

    # Returns the companies of the Business Central environment.
    #
    # + return - The mocked Business Central response.
    resource function get companies() returns CompanyCollection {
        return {value: [mockCompany]};
    }

    # Returns a single company addressed with an OData key segment.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]() returns Company {
        return mockCompany;
    }

    # Returns the items of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/items() returns ItemCollection {
        return {value: [mockItem]};
    }

    # Creates an item in a company.
    #
    # + return - The mocked Business Central response.
    resource function post [string company]/items(@http:Payload ItemRequest payload) returns Item {
        Item created = mockItem;
        return created;
    }

    # Returns the customers of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/customers() returns CustomerCollection {
        return {value: [mockCustomer]};
    }

    # Creates a customer in a company.
    #
    # + return - The mocked Business Central response.
    resource function post [string company]/customers(@http:Payload CustomerRequest payload) returns Customer {
        return mockCustomer;
    }

    # Returns the vendors of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/vendors() returns VendorCollection {
        return {value: [mockVendor]};
    }

    # Returns the employees of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/employees() returns EmployeeCollection {
        return {value: [mockEmployee]};
    }

    # Returns the sales invoices of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/salesInvoices() returns SalesInvoiceCollection {
        return {value: [mockSalesInvoice]};
    }

    # Creates a sales invoice in a company.
    #
    # + return - The mocked Business Central response.
    resource function post [string company]/salesInvoices(@http:Payload SalesInvoiceRequest payload) returns SalesInvoice {
        return mockSalesInvoice;
    }

    # Returns the sales orders of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/salesOrders() returns SalesOrderCollection {
        return {value: [mockSalesOrder]};
    }

    # Creates a sales order in a company.
    #
    # + return - The mocked Business Central response.
    resource function post [string company]/salesOrders(@http:Payload SalesOrderRequest payload) returns SalesOrder {
        return mockSalesOrder;
    }

    # Returns the sales quotes of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/salesQuotes() returns SalesQuoteCollection {
        return {value: [mockSalesQuote]};
    }

    # Returns the purchase invoices of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/purchaseInvoices() returns PurchaseInvoiceCollection {
        return {value: [mockPurchaseInvoice]};
    }

    # Returns the journals of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/journals() returns JournalCollection {
        return {value: [mockJournal]};
    }

    # Creates a journal in a company.
    #
    # + return - The mocked Business Central response.
    resource function post [string company]/journals(@http:Payload JournalRequest payload) returns Journal {
        return mockJournal;
    }

    # Returns the general ledger accounts of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/accounts() returns AccountCollection {
        return {value: [mockAccount]};
    }

    # Returns the bank accounts of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/bankAccounts() returns BankAccountCollection {
        return {value: [mockBankAccount]};
    }

    # Returns the projects of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/projects() returns ProjectCollection {
        return {value: [mockProject]};
    }

    # Returns the general ledger entries of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/generalLedgerEntries() returns GeneralLedgerEntryCollection {
        return {value: [mockGeneralLedgerEntry]};
    }

    # Returns the currencies of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/currencies() returns CurrencyCollection {
        return {value: [mockCurrency]};
    }

    # Returns the payment terms of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/paymentTerms() returns PaymentTermCollection {
        return {value: [mockPaymentTerm]};
    }

    # Returns the payment methods of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/paymentMethods() returns PaymentMethodCollection {
        return {value: [mockPaymentMethod]};
    }

    # Returns the shipment methods of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/shipmentMethods() returns ShipmentMethodCollection {
        return {value: [mockShipmentMethod]};
    }

    # Returns the item categories of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/itemCategories() returns ItemCategoryCollection {
        return {value: [mockItemCategory]};
    }

    # Returns the countries and regions of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/countriesRegions() returns CountryRegionCollection {
        return {value: [mockCountryRegion]};
    }

    # Returns the tax areas of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/taxAreas() returns TaxAreaCollection {
        return {value: [mockTaxArea]};
    }

    # Returns the tax groups of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/taxGroups() returns TaxGroupCollection {
        return {value: [mockTaxGroup]};
    }

    # Returns the units of measure of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/unitsOfMeasure() returns UnitOfMeasureCollection {
        return {value: [mockUnitOfMeasure]};
    }

    # Returns the attachments of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/attachments() returns AttachmentCollection {
        return {value: [mockAttachment]};
    }

    # Returns the general ledger entry attachments of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/generalLedgerEntryAttachments() returns GeneralLedgerEntryAttachmentCollection {
        return {value: [mockGeneralLedgerEntryAttachment]};
    }

    # Returns the pictures of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/picture() returns PictureCollection {
        return {value: [mockPicture]};
    }

    # Returns the PDF documents of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/pdfDocument() returns PdfDocumentCollection {
        return {value: [mockPdfDocument]};
    }

    # Returns the balance sheet lines of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/balanceSheet() returns BalanceSheetCollection {
        return {value: [mockBalanceSheetLine]};
    }

    # Returns the income statement lines of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/incomeStatement() returns IncomeStatementCollection {
        return {value: [mockIncomeStatementLine]};
    }

    # Returns the cash flow statement lines of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/cashFlowStatement() returns CashFlowStatementCollection {
        return {value: [mockCashFlowStatementLine]};
    }

    # Returns the retained earnings statement lines of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/retainedEarningsStatement() returns RetainedEarningsStatementCollection {
        return {value: [mockRetainedEarningsStatementLine]};
    }

    # Returns the trial balance lines of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/trialBalance() returns TrialBalanceCollection {
        return {value: [mockTrialBalanceLine]};
    }

    # Returns the aged accounts receivable of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/agedAccountsReceivable() returns AgedAccountsReceivableCollection {
        return {value: [mockAgedAccountsReceivable]};
    }

    # Returns the aged accounts payable of a company.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/agedAccountsPayable() returns AgedAccountsPayableCollection {
        return {value: [mockAgedAccountsPayable]};
    }

    # Returns a single entity addressed with an OData key segment, dispatched on the segment name.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/[string entity]() returns Item|Customer|Vendor|Employee|SalesInvoice|Currency|ItemCategory|PaymentTerm|TaxGroup|UnitOfMeasure|Picture|PdfDocument|TrialBalance|BalanceSheet|http:NotFound {
        if entity.startsWith("items(") {
            return mockItem;
        }
        if entity.startsWith("currencies(") {
            return mockCurrency;
        }
        if entity.startsWith("itemCategories(") {
            return mockItemCategory;
        }
        if entity.startsWith("paymentTerms(") {
            return mockPaymentTerm;
        }
        if entity.startsWith("taxGroups(") {
            return mockTaxGroup;
        }
        if entity.startsWith("unitsOfMeasure(") {
            return mockUnitOfMeasure;
        }
        if entity.startsWith("picture(") {
            return mockPicture;
        }
        if entity.startsWith("pdfDocument(") {
            return mockPdfDocument;
        }
        if entity.startsWith("trialBalance(") {
            return mockTrialBalanceLine;
        }
        if entity.startsWith("balanceSheet(") {
            return mockBalanceSheetLine;
        }
        if entity.startsWith("customers(") {
            return mockCustomer;
        }
        if entity.startsWith("vendors(") {
            return mockVendor;
        }
        if entity.startsWith("employees(") {
            return mockEmployee;
        }
        if entity.startsWith("salesInvoices(") {
            return mockSalesInvoice;
        }
        return http:NOT_FOUND;
    }

    # Updates a single entity addressed with an OData key segment.
    #
    # + return - The mocked Business Central response.
    resource function patch [string company]/[string entity](@http:Payload json payload) returns Item|Customer|http:NotFound {
        if entity.startsWith("items(") {
            return mockItem;
        }
        if entity.startsWith("customers(") {
            return mockCustomer;
        }
        return http:NOT_FOUND;
    }

    # Deletes a single entity addressed with an OData key segment.
    #
    # + return - The mocked Business Central response.
    resource function delete [string company]/[string entity]() returns http:NoContent {
        return http:NO_CONTENT;
    }

    # Returns the sales invoice lines of a sales invoice.
    #
    # + return - The mocked Business Central response.
    resource function get [string company]/[string salesInvoice]/salesInvoiceLines() returns SalesInvoiceLineCollection {
        return {value: [mockSalesInvoiceLine]};
    }

    # Creates a sales invoice line in a sales invoice.
    #
    # + return - The mocked Business Central response.
    resource function post [string company]/[string salesInvoice]/salesInvoiceLines(@http:Payload SalesInvoiceLineRequest payload) returns SalesInvoiceLine {
        return mockSalesInvoiceLine;
    }

    # Creates a journal line in a journal.
    #
    # + return - The mocked Business Central response.
    resource function post [string company]/[string journal]/journalLines(@http:Payload JournalLineRequest payload) returns JournalLine {
        return {accountId: payload?.accountId, documentNumber: payload?.documentNumber, amount: payload?.amount};
    }

    # Performs a Microsoft.NAV bound action on an entity and answers with no content.
    #
    # + return - The mocked Business Central response.
    resource function post [string company]/[string entity]/[string action]() returns http:NoContent {
        return http:NO_CONTENT;
    }
}
