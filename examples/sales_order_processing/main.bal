// Processes sales orders for a Business Central company: lists the customers that can be
// ordered for, opens a new sales order for the first of them, and reads back the order
// lines that belong to it.

import ballerina/io;
import ballerinax/microsoft.dynamics365.bc as bc;

// Create a Config.toml in this directory with these values before running.
configurable string token = ?;
configurable string companyId = ?;
configurable string itemId = ?;

public function main() returns error? {
    bc:Client dynamics365 = check new ({auth: {token}});

    // Step 1: find the customer to raise the order for.
    bc:CustomerCollection customers = check dynamics365->listCustomers(companyId, top = 1);
    bc:Customer[] found = customers.value ?: [];
    if found.length() == 0 {
        return error("the company has no customers to raise a sales order for");
    }
    bc:Customer customer = found[0];
    string customerId = customer.id ?: "";
    io:println("Raising a sales order for: ", customer.displayName);

    // Step 2: open the sales order.
    bc:SalesOrder salesOrder = check dynamics365->createSalesOrder(companyId, {
        customerId: customerId,
        orderDate: "2026-04-02",
        externalDocumentNumber: "WEB-3391"
    });
    string salesOrderId = salesOrder.id ?: "";
    if salesOrderId == "" {
        return error("the created sales order did not return an id");
    }
    io:println("Opened sales order: ", salesOrder?.number);

    // Step 3: add the item being sold as an order line.
    bc:SalesOrderLine line = check dynamics365->createSalesOrderLineForSalesOrder(
        companyId, salesOrderId, {
            lineType: "Item",
            itemId: itemId,
            quantity: 2d
        });
    io:println("Added order line for quantity: ", line?.quantity);

    // Step 4: read back the lines that belong to the order.
    bc:SalesOrderLineCollection lines =
        check dynamics365->listSalesOrderLinesForSalesOrder(companyId, salesOrderId);
    bc:SalesOrderLine[] orderLines = lines.value ?: [];
    io:println("Lines on the order: ", orderLines.length());

    // Step 5: show the most recent orders in the company, up to the first 20.
    bc:SalesOrderCollection open = check dynamics365->listSalesOrders(companyId, top = 20);
    bc:SalesOrder[] openOrders = open.value ?: [];
    io:println("Sales orders returned (limit 20): ", openOrders.length());
}
