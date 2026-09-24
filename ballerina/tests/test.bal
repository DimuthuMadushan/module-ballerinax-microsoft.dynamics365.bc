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

import ballerina/os;
import ballerina/test;
import ballerina/time;

final boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";

final string serviceUrl = isLiveServer
    ? os:getEnv("BC_SERVICE_URL")
    : "http://localhost:9090";

final string token = isLiveServer ? os:getEnv("BC_ACCESS_TOKEN") : "test_token";

// Fixtures. Against the mock these are the identifiers the mock service answers for;
// against a live environment they must name records that exist in the target company.
final string companyId = isLiveServer
    ? os:getEnv("BC_COMPANY_ID")
    : "a1b2c3d4-1111-4a2b-9c3d-0e1f2a3b4c5d";
final string itemId = isLiveServer
    ? os:getEnv("BC_ITEM_ID")
    : "b2c3d4e5-2222-4b3c-8d4e-1f2a3b4c5d6e";
final string customerId = isLiveServer
    ? os:getEnv("BC_CUSTOMER_ID")
    : "f6a7b8c9-6666-4f70-8b8c-5d6e7f809102";
final string employeeId = isLiveServer
    ? os:getEnv("BC_EMPLOYEE_ID")
    : "c9d0e1f2-9999-42a3-9e1f-80910213243546";
final string salesInvoiceId = isLiveServer
    ? os:getEnv("BC_SALES_INVOICE_ID")
    : "e1f2a3b4-bbbb-44c5-9031-a21324354657";
final string glAccountId = isLiveServer
    ? os:getEnv("BC_GL_ACCOUNT_ID")
    : "d6e7f8a9-0a0a-491a-8586-f6879a0b1c2d";

// Posting writes ledger entries that cannot be undone, so against a live environment the
// posting tests run only when the operator confirms the target is an isolated sandbox.
final boolean isSandboxPostingConfirmed = os:getEnv("BC_SANDBOX_POSTING") == "true";

isolated function ensurePostingAllowed() returns error? {
    if isLiveServer && !isSandboxPostingConfirmed {
        return error("posting tests run only against an isolated sandbox; set BC_SANDBOX_POSTING=true to confirm");
    }
}

final string taxGroupId = isLiveServer
    ? os:getEnv("BC_TAX_GROUP_ID")
    : "e5f6a7b8-5555-4e6f-9a7b-4c5d6e7f8091";
final string unitOfMeasureId = isLiveServer
    ? os:getEnv("BC_UNIT_OF_MEASURE_ID")
    : "d4e5f6a7-4444-4d5e-8f6a-3b4c5d6e7f80";

final Client bcClient = check new ({auth: {token}}, serviceUrl);

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListCompanies() returns error? {
    CompanyCollection response = check bcClient->listCompanies();
    Company[] companies = response.value ?: [];
    test:assertTrue(companies.length() > 0, "at least one company must be returned");
    test:assertTrue(companies[0].id != "", "a company must carry an id");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetCompany() returns error? {
    Company response = check bcClient->getCompany(companyId);
    test:assertTrue(response?.displayName !is (), "the company must carry a display name");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListItems() returns error? {
    ItemCollection response = check bcClient->listItems(companyId);
    Item[] items = response.value ?: [];
    test:assertTrue(items.length() > 0, "at least one item must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateItem() returns error? {
    Item response = check bcClient->createItem(companyId, {
        displayName: "Connector Test Desk",
        'type: "Inventory",
        unitPrice: 425.5d
    });
    test:assertTrue(response.id !is (), "the created item must carry an id");
    test:assertTrue(response?.displayName !is (), "the created item must carry a display name");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetItem() returns error? {
    Item response = check bcClient->getItem(companyId, itemId);
    test:assertTrue(response?.number !is (), "the item must carry a number");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testUpdateItem() returns error? {
    Item response = check bcClient->updateItem(companyId, itemId, {ifMatch: "*"}, {
        displayName: "ATHENS Desk (revised)"
    });
    test:assertTrue(response.id !is (), "the updated item must carry an id");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testDeleteItem() returns error? {
    // A delete test owns the record it removes: tests run in alphabetical order, so
    // deleting a shared fixture would break whichever test reads it afterwards.
    Item created = check bcClient->createItem(companyId, {
        displayName: "Connector Test Desk (disposable)",
        'type: "Inventory"
    });
    string createdId = created.id ?: "";
    test:assertTrue(createdId.length() > 0, "the created item must expose an id to delete");
    error? response = bcClient->deleteItem(companyId, createdId);
    test:assertTrue(response is (), "the delete must complete without an error");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListCustomers() returns error? {
    CustomerCollection response = check bcClient->listCustomers(companyId);
    Customer[] customers = response.value ?: [];
    test:assertTrue(customers.length() > 0, "at least one customer must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateCustomer() returns error? {
    Customer response = check bcClient->createCustomer(companyId, {
        displayName: "Connector Test Customer",
        'type: "Company",
        email: "billing@contoso.example"
    });
    test:assertTrue(response.id !is (), "the created customer must carry an id");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetCustomer() returns error? {
    Customer response = check bcClient->getCustomer(companyId, customerId);
    test:assertTrue(response?.displayName !is (), "the customer must carry a display name");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testUpdateCustomer() returns error? {
    Customer response = check bcClient->updateCustomer(companyId, customerId, {ifMatch: "*"}, {
        phoneNumber: "+1 425 555 0199"
    });
    test:assertTrue(response.id !is (), "the updated customer must carry an id");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testDeleteCustomer() returns error? {
    Customer created = check bcClient->createCustomer(companyId, {
        displayName: "Connector Test Customer (disposable)",
        'type: "Company"
    });
    string createdId = created.id ?: "";
    test:assertTrue(createdId.length() > 0, "the created customer must expose an id to delete");
    error? response = bcClient->deleteCustomer(companyId, createdId);
    test:assertTrue(response is (), "the delete must complete without an error");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListVendors() returns error? {
    VendorCollection response = check bcClient->listVendors(companyId);
    Vendor[] vendors = response.value ?: [];
    test:assertTrue(vendors.length() > 0, "at least one vendor must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListEmployees() returns error? {
    EmployeeCollection response = check bcClient->listEmployees(companyId);
    Employee[] employees = response.value ?: [];
    test:assertTrue(employees.length() > 0, "at least one employee must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetEmployee() returns error? {
    Employee response = check bcClient->getEmployee(companyId, employeeId);
    test:assertTrue(response?.displayName !is (), "the employee must carry a display name");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListSalesInvoices() returns error? {
    SalesInvoiceCollection response = check bcClient->listSalesInvoices(companyId);
    SalesInvoice[] invoices = response.value ?: [];
    test:assertTrue(invoices.length() > 0, "at least one sales invoice must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateSalesInvoice() returns error? {
    SalesInvoice response = check bcClient->createSalesInvoice(companyId, {
        customerId: customerId,
        invoiceDate: "2026-04-01"
    });
    test:assertTrue(response.id !is (), "the created sales invoice must carry an id");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetSalesInvoice() returns error? {
    SalesInvoice response = check bcClient->getSalesInvoice(companyId, salesInvoiceId);
    test:assertTrue(response?.number !is (), "the sales invoice must carry a number");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListSalesInvoiceLinesForSalesInvoice() returns error? {
    SalesInvoiceLineCollection response =
        check bcClient->listSalesInvoiceLinesForSalesInvoice(companyId, salesInvoiceId);
    SalesInvoiceLine[] lines = response.value ?: [];
    test:assertTrue(lines.length() > 0, "at least one sales invoice line must be returned");
}

@test:Config {groups: ["sandbox_posting_tests", "mock_tests"]}
isolated function testPostSalesInvoice() returns error? {
    check ensurePostingAllowed();
    // Post a test-owned draft rather than a shared fixture, so each run posts a fresh record.
    SalesInvoice invoice = check bcClient->createSalesInvoice(companyId, {customerId: customerId});
    string invoiceId = check invoice?.id.ensureType();
    _ = check bcClient->createSalesInvoiceLineForSalesInvoice(companyId, invoiceId, {
        lineType: "Item",
        itemId: itemId,
        quantity: 1
    });
    error? response = bcClient->postSalesInvoice(companyId, invoiceId);
    test:assertTrue(response is (), "posting the sales invoice must complete without an error");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListSalesOrders() returns error? {
    SalesOrderCollection response = check bcClient->listSalesOrders(companyId);
    SalesOrder[] orders = response.value ?: [];
    test:assertTrue(orders.length() > 0, "at least one sales order must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateSalesOrder() returns error? {
    SalesOrder response = check bcClient->createSalesOrder(companyId, {
        customerId: customerId,
        orderDate: "2026-04-01"
    });
    test:assertTrue(response.id !is (), "the created sales order must carry an id");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListSalesQuotes() returns error? {
    SalesQuoteCollection response = check bcClient->listSalesQuotes(companyId);
    SalesQuote[] quotes = response.value ?: [];
    test:assertTrue(quotes.length() > 0, "at least one sales quote must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListPurchaseInvoices() returns error? {
    PurchaseInvoiceCollection response = check bcClient->listPurchaseInvoices(companyId);
    PurchaseInvoice[] invoices = response.value ?: [];
    test:assertTrue(invoices.length() > 0, "at least one purchase invoice must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListJournals() returns error? {
    JournalCollection response = check bcClient->listJournals(companyId);
    Journal[] journals = response.value ?: [];
    test:assertTrue(journals.length() > 0, "at least one journal must be returned");
}

@test:Config {groups: ["sandbox_posting_tests", "mock_tests"]}
isolated function testPostJournal() returns error? {
    check ensurePostingAllowed();
    // Post a test-owned journal batch holding one balanced pair of lines on the same account.
    string code = string `BAL${time:utcNow()[0] % 10000000}`;
    Journal journal = check bcClient->createJournal(companyId, {code, displayName: "Connector test journal"});
    string journalId = check journal?.id.ensureType();
    foreach decimal amount in [10d, -10d] {
        _ = check bcClient->createJournalLineForJournal(companyId, journalId, {
            accountId: glAccountId,
            documentNumber: code,
            amount,
            description: "Connector test posting"
        });
    }
    error? response = bcClient->postJournal(companyId, journalId);
    test:assertTrue(response is (), "posting the journal must complete without an error");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListAccounts() returns error? {
    AccountCollection response = check bcClient->listAccounts(companyId);
    Account[] accounts = response.value ?: [];
    test:assertTrue(accounts.length() > 0, "at least one general ledger account must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListBankAccounts() returns error? {
    BankAccountCollection response = check bcClient->listBankAccounts(companyId);
    BankAccount[] bankAccounts = response.value ?: [];
    test:assertTrue(bankAccounts.length() > 0, "at least one bank account must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListGeneralLedgerEntries() returns error? {
    GeneralLedgerEntryCollection response = check bcClient->listGeneralLedgerEntries(companyId);
    GeneralLedgerEntry[] entries = response.value ?: [];
    test:assertTrue(entries.length() > 0, "at least one general ledger entry must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListProjects() returns error? {
    ProjectCollection response = check bcClient->listProjects(companyId);
    Project[] projects = response.value ?: [];
    test:assertTrue(projects.length() > 0, "at least one project must be returned");
}

// Reference data — the entities brought into scope by the full-surface revamp.

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListCurrencies() returns error? {
    CurrencyCollection response = check bcClient->listCurrencies(companyId);
    Currency[] currencies = response.value ?: [];
    test:assertTrue(currencies.length() > 0, "at least one currency must be returned");
    test:assertTrue(currencies[0].code != "", "a currency must carry a code");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListPaymentTerms() returns error? {
    PaymentTermCollection response = check bcClient->listPaymentTerms(companyId);
    PaymentTerm[] paymentTerms = response.value ?: [];
    test:assertTrue(paymentTerms.length() > 0, "at least one payment term must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListPaymentMethods() returns error? {
    PaymentMethodCollection response = check bcClient->listPaymentMethods(companyId);
    PaymentMethod[] paymentMethods = response.value ?: [];
    test:assertTrue(paymentMethods.length() > 0, "at least one payment method must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListShipmentMethods() returns error? {
    ShipmentMethodCollection response = check bcClient->listShipmentMethods(companyId);
    ShipmentMethod[] shipmentMethods = response.value ?: [];
    test:assertTrue(shipmentMethods.length() > 0, "at least one shipment method must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListItemCategories() returns error? {
    ItemCategoryCollection response = check bcClient->listItemCategories(companyId);
    ItemCategory[] categories = response.value ?: [];
    test:assertTrue(categories.length() > 0, "at least one item category must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListCountriesRegions() returns error? {
    CountryRegionCollection response = check bcClient->listCountriesRegions(companyId);
    CountryRegion[] countriesRegions = response.value ?: [];
    test:assertTrue(countriesRegions.length() > 0, "at least one country/region must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListTaxAreas() returns error? {
    TaxAreaCollection response = check bcClient->listTaxAreas(companyId);
    TaxArea[] taxAreas = response.value ?: [];
    test:assertTrue(taxAreas.length() > 0, "at least one tax area must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListTaxGroups() returns error? {
    TaxGroupCollection response = check bcClient->listTaxGroups(companyId);
    TaxGroup[] taxGroups = response.value ?: [];
    test:assertTrue(taxGroups.length() > 0, "at least one tax group must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListUnitsOfMeasure() returns error? {
    UnitOfMeasureCollection response = check bcClient->listUnitsOfMeasure(companyId);
    UnitOfMeasure[] unitsOfMeasure = response.value ?: [];
    test:assertTrue(unitsOfMeasure.length() > 0, "at least one unit of measure must be returned");
}

// Documents and attachments.

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListAttachments() returns error? {
    AttachmentCollection response = check bcClient->listAttachments(companyId);
    Attachment[] attachments = response.value ?: [];
    test:assertTrue(attachments.length() > 0, "at least one attachment must be returned");
    test:assertTrue(attachments[0]?.fileName !is (), "an attachment must carry a file name");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListGeneralLedgerEntryAttachments() returns error? {
    GeneralLedgerEntryAttachmentCollection response =
        check bcClient->listGeneralLedgerEntryAttachments(companyId);
    GeneralLedgerEntryAttachments[] attachments = response.value ?: [];
    test:assertTrue(attachments.length() > 0, "at least one attachment must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListPictures() returns error? {
    PictureCollection response = check bcClient->listPictures(companyId);
    Picture[] pictures = response.value ?: [];
    test:assertTrue(pictures.length() > 0, "at least one picture must be returned");
    // The picture entity carries the media links rather than the bytes; the content is
    // fetched by following `content@odata.mediaReadLink`.
    test:assertTrue(pictures[0]?.contentOdataMediaReadLink !is (),
            "a picture must carry a media read link");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListPdfDocuments() returns error? {
    PdfDocumentCollection response = check bcClient->listPdfDocuments(companyId);
    PdfDocument[] documents = response.value ?: [];
    test:assertTrue(documents.length() > 0, "at least one PDF document must be returned");
}

// Financial reports.

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListBalanceSheetLines() returns error? {
    BalanceSheetCollection response = check bcClient->listBalanceSheetLines(companyId);
    BalanceSheet[] lines = response.value ?: [];
    test:assertTrue(lines.length() > 0, "at least one balance sheet line must be returned");
    test:assertTrue(lines[0]?.display !is (), "a balance sheet line must carry a display name");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListIncomeStatementLines() returns error? {
    IncomeStatementCollection response = check bcClient->listIncomeStatementLines(companyId);
    IncomeStatement[] lines = response.value ?: [];
    test:assertTrue(lines.length() > 0, "at least one income statement line must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListCashFlowStatementLines() returns error? {
    CashFlowStatementCollection response = check bcClient->listCashFlowStatementLines(companyId);
    CashFlowStatement[] lines = response.value ?: [];
    test:assertTrue(lines.length() > 0, "at least one cash flow statement line must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListRetainedEarningsStatementLines() returns error? {
    RetainedEarningsStatementCollection response =
        check bcClient->listRetainedEarningsStatementLines(companyId);
    RetainedEarningsStatement[] lines = response.value ?: [];
    test:assertTrue(lines.length() > 0, "at least one retained earnings line must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListTrialBalanceLines() returns error? {
    TrialBalanceCollection response = check bcClient->listTrialBalanceLines(companyId);
    TrialBalance[] lines = response.value ?: [];
    test:assertTrue(lines.length() > 0, "at least one trial balance line must be returned");
    test:assertTrue(lines[0].number != "", "a trial balance line must carry an account number");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListAgedAccountsReceivable() returns error? {
    AgedAccountsReceivableCollection response = check bcClient->listAgedAccountsReceivable(companyId);
    AgedAccountsReceivable[] lines = response.value ?: [];
    test:assertTrue(lines.length() > 0, "at least one aged receivable line must be returned");
    test:assertTrue(lines[0].customerId != "", "an aged receivable line must name a customer");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListAgedAccountsPayable() returns error? {
    AgedAccountsPayableCollection response = check bcClient->listAgedAccountsPayable(companyId);
    AgedAccountsPayable[] lines = response.value ?: [];
    test:assertTrue(lines.length() > 0, "at least one aged payable line must be returned");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetTaxGroup() returns error? {
    TaxGroup response = check bcClient->getTaxGroup(companyId, taxGroupId);
    test:assertTrue(response?.displayName !is (), "the tax group must carry a display name");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetUnitOfMeasure() returns error? {
    UnitOfMeasure response = check bcClient->getUnitOfMeasure(companyId, unitOfMeasureId);
    test:assertTrue(response?.displayName !is (), "the unit of measure must carry a display name");
}
