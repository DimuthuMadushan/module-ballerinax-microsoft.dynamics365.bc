// Keeps a product catalog current: reviews the items already registered in a Business
// Central company, adds a new stocked item, and corrects its price with a conditional
// update guarded by the entity ETag.

import ballerina/io;
import ballerinax/microsoft.dynamics365.bc as bc;

// Create a Config.toml in this directory with these values before running.
configurable string token = ?;
configurable string companyId = ?;

public function main() returns error? {
    bc:Client dynamics365 = check new ({auth: {token}});

    // Step 1: review the catalog, newest changes first.
    bc:ItemCollection catalog = check dynamics365->listItems(companyId, top = 10);
    bc:Item[] items = catalog.value ?: [];
    io:println("Items already in the catalog: ", items.length());

    // Step 2: register a new stocked item.
    bc:Item created = check dynamics365->createItem(companyId, {
        displayName: "BERLIN Guest Chair, yellow",
        'type: "Inventory",
        unitPrice: 189.5d,
        unitCost: 121.3d,
        priceIncludesTax: false
    });
    string itemId = created.id ?: "";
    if itemId == "" {
        return error("the created item did not return an id");
    }
    io:println("Registered item: ", created?.displayName, " (", created?.number, ")");

    // Step 3: correct the price. `ifMatch` normally carries the ETag read with the entity;
    // "*" only requires the item to exist and does not compare ETags, so a concurrent
    // edit made since the read can be overwritten.
    bc:Item updated = check dynamics365->updateItem(companyId, itemId, {ifMatch: "*"}, {
        unitPrice: 199d
    });
    io:println("Updated unit price to: ", updated?.unitPrice);
}
