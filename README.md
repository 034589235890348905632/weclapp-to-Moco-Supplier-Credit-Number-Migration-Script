# weclapp to Moco Supplier Credit Number Migration Script

This PowerShell script helps migrate supplier credit numbers from weclapp to Moco. It reads an exported CSV file from Weclapp, searches for corresponding suppliers in Moco, and updates their creditor account numbers.

## Prerequisites
- PowerShell 5.0 or higher
- API access to **Moco**
- Supplier Export CSV from **weclapp**

## Required Variables
Before running the script, update the following variables in the script:

1. **$firstCSV**: Path to the CSV export file from weclapp containing the supplier data.
    - The CSV should include a column for company names and their respective "Old Supplier Number" (Creditor Account ID).
  
2. **$outputCsvFile**: Path where companies that couldn't be found in Moco will be saved (as CSV).

3. **$apiKey**: Your Moco API key for authentication.

4. **$domain**: Your Moco domain (e.g., `yourcompany.mocoapp.com`).

## How to Use
1. Update the required variables as mentioned above.
2. Run the script in PowerShell.
3. The script will process the suppliers, update creditor account numbers in Moco, and save unmatched companies to the output CSV.

## Example of Input CSV Structure:
The input CSV file should have at least the following columns:
- `Firma`: Supplier company name
- `Alte Lieferantennummer`: The old supplier credit number (Creditor Account ID)

## Notes
- The script handles API rate limiting (e.g., waiting 60 seconds if too many requests are made).
- Companies not found in Moco are stored in the specified output CSV file for review.
