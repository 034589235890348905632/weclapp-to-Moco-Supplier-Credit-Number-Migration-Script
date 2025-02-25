# Define paths to the CSV files
$firstCSV = "weclapp_export.csv"
$outputCsvFile = "not_found_companies.csv"

# API configuration variables
$apiKey = "XXX"
$domain = "XXX.mocoapp.com"

# Whether the API requests should be actually executed or just displayed (True = execute, False = display only)
$waitIf = $true

# Load the CSV file with semicolon as the delimiter
$firstData = Import-Csv -Path $firstCSV -Delimiter ';'

# List for companies that were not found but have an old supplier number
$notFoundCompanies = @()

# Counters for successful updates and found companies
$updatedCount = 0
$foundCount = 0

# One-time API request to retrieve all supplier companies (with search term)
function Get-CompaniesBySearchTerm {
    param (
        [string]$searchTerm
    )

    $url = "https://$domain/api/v1/companies?type=supplier&term=$searchTerm"
    $headers = @{
        "Authorization" = "Token token=$apiKey"
        "Content-Type" = "application/json"
    }

    # Send the GET request with the search term
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
        return $response
    }
    catch {
        # Error handling for 429 Too Many Requests
        if ($_.Exception.Response.StatusCode -eq 429) {
            Write-Host "Rate limit reached. Waiting for 60 seconds..."
            Start-Sleep -Seconds 60
            return Get-CompaniesBySearchTerm -searchTerm $searchTerm
        }
        else {
            Write-Host "Error during API request: $($_.Exception.Message)"
            return $null
        }
    }
}

# Loop through all companies in the CSV file
$count = 0
foreach ($row in $firstData) {
    # Get the first part of the company name as the search term (trim spaces)
    $companyName = $row.Firma.Trim()  # Remove leading and trailing spaces
    $searchTerm = $companyName.Split(" ")[0] # First part of the company name as the search term
    Write-Host "Searching for company with the search term: $searchTerm"

    # Load all companies with the search term
    $allCompanies = Get-CompaniesBySearchTerm -searchTerm $searchTerm

    # Check the retrieved companies
    $company = $allCompanies | Where-Object { $_.name -eq $companyName }

    if ($company) {
        Write-Host "Match found for company '$companyName' with ID $($company.id)"

        $companyId = $company.id

        # Check if there is a value in the "Old Supplier Number" (Creditor Account ID) column
        $creditNumber = $row.'Alte Lieferantennummer'  # Creditor Account ID from the first CSV

        if (-not $creditNumber) {
            Write-Host "Company '$($row.Firma)' does not have a Creditor Account ID, skipping."
            continue
        }

        # PUT request to update the company (only display if $waitIf is set to True)
        $putUrl = "https://$domain/api/v1/companies/$companyId"
        $body = @{
            "credit_number" = $creditNumber
        } | ConvertTo-Json

        if ($waitIf -eq $true) {
            # Actual PUT request to update the company
            $response = Invoke-RestMethod -Uri $putUrl -Method Put -Headers $headers -Body $body
            Write-Host "Company $companyName was successfully updated with Creditor Account: $creditNumber"
            $updatedCount++
        }
        else {
            # Just display what would happen
            Write-Host "Would send API request for company '$companyName' with ID $companyId and Creditor Account $creditNumber."
        }
        $foundCount++
    }
    else {
        Write-Host "Company '$companyName' of type 'supplier' not found in the API."

        # Check if the company has a Creditor Account ID and store it if missing
        $creditNumber = $row.'Alte Lieferantennummer'
        if ($creditNumber) {
            # Add the company to the list of not found companies
            $notFoundCompanies += $row
        }
    }

    # Increment the counter
    $count++
}

# If there are companies that were not found, export them to a CSV file
if ($notFoundCompanies.Count -gt 0) {
    $notFoundCompanies | Export-Csv -Path $outputCsvFile -NoTypeInformation -Delimiter ';'
    Write-Host "The companies that were not found have been saved to '$outputCsvFile'."
}

# Additional debugging output
Write-Host "Script completed."
Write-Host "Found and updated companies: $updatedCount"
Write-Host "Total number of companies checked: $foundCount"
