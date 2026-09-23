// Onboards a new customer in a Business Central company, raises a sales invoice with a
// single line for that customer, and posts the invoice so it reaches the general ledger.

import ballerina/io;
import ballerinax/microsoft.dynamics365.bc as bc;

// Create a Config.toml in this directory with these values before running.
configurable string token = ?;
configurable string companyId = ?;
configurable string itemId = ?;

public function main() returns error? {
    bc:Client dynamics365 = check new ({auth: {token}});

    // Step 1: onboard the customer the invoice will be raised against.
    bc:Customer customer = check dynamics365->createCustomer(companyId, {
        displayName: "Northwind Traders",
        'type: "Company",
        email: "accounts.payable@northwind.example",
        phoneNumber: "+1 425 555 0114",
        taxLiable: true
    });
    string customerId = customer.id ?: "";
    if customerId == "" {
        return error("the created customer did not return an id");
    }
    io:println("Created customer: ", customer?.displayName, " (", customerId, ")");

    // Step 2: raise a draft sales invoice for that customer.
    bc:SalesInvoice invoice = check dynamics365->createSalesInvoice(companyId, {
        customerId: customerId,
        invoiceDate: "2026-04-01",
        externalDocumentNumber: "PO-2026-0412"
    });
    string invoiceId = invoice.id ?: "";
    if invoiceId == "" {
        return error("the created sales invoice did not return an id");
    }
    io:println("Created sales invoice: ", invoice?.number);

    // Step 3: add the item being sold as an invoice line.
    bc:SalesInvoiceLine line = check dynamics365->createSalesInvoiceLineForSalesInvoice(
        companyId, invoiceId, {
            lineType: "Item",
            itemId: itemId,
            quantity: 3d
        });
    io:println("Added invoice line for quantity: ", line?.quantity);

    // Step 4: post the invoice, which creates the posted document and ledger entries.
    check dynamics365->postSalesInvoice(companyId, invoiceId);
    io:println("Posted sales invoice ", invoice?.number, " for ", customer?.displayName);
}
