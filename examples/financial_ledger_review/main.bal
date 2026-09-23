// Pulls a month-end financial snapshot out of a Business Central company: the chart of
// accounts, the bank accounts on file, and the general ledger entries posted in the period.

import ballerina/io;
import ballerinax/microsoft.dynamics365.bc as bc;

// Create a Config.toml in this directory with these values before running.
configurable string token = ?;
configurable string companyId = ?;

public function main() returns error? {
    bc:Client dynamics365 = check new ({auth: {token}});

    // Step 1: confirm which company the snapshot is taken from.
    bc:Company company = check dynamics365->getCompany(companyId);
    io:println("Company: ", company?.displayName);

    // Step 2: read the chart of accounts.
    bc:AccountCollection accounts = check dynamics365->listAccounts(companyId, top = 50);
    bc:Account[] chartOfAccounts = accounts.value ?: [];
    io:println("General ledger accounts: ", chartOfAccounts.length());

    // Step 3: read the bank accounts the company settles through.
    bc:BankAccountCollection bankAccounts = check dynamics365->listBankAccounts(companyId);
    bc:BankAccount[] banks = bankAccounts.value ?: [];
    foreach bc:BankAccount bank in banks {
        io:println("Bank account ", bank?.number, " - ", bank?.displayName);
    }

    // Step 4: read the entries posted in the period. `filter` takes an OData expression.
    bc:GeneralLedgerEntryCollection ledger = check dynamics365->listGeneralLedgerEntries(
        companyId, filter = "postingDate ge 2026-03-01 and postingDate le 2026-03-31");
    bc:GeneralLedgerEntry[] entries = ledger.value ?: [];
    decimal debits = 0;
    decimal credits = 0;
    foreach bc:GeneralLedgerEntry entry in entries {
        debits += entry?.debitAmount ?: 0d;
        credits += entry?.creditAmount ?: 0d;
    }
    io:println("Entries in the period: ", entries.length());
    io:println("Total debits: ", debits, " total credits: ", credits);
}
