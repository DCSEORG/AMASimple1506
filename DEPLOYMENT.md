# Expense Management App - Deployment Guide

![Header image](https://github.com/DougChisholm/App-Mod-Assist/blob/main/repo-header.png)

## Overview

This is a modernized Expense Management application built with ASP.NET Core and deployed to Azure App Service. It uses Azure SQL Database for data storage and Azure Managed Identity for secure, password-less authentication.

## Architecture

- **Frontend/Backend**: ASP.NET Core Razor Pages (.NET 8)
- **Database**: Azure SQL Database
- **Authentication**: Azure Managed Identity (mid-AppModAssist)
- **Hosting**: Azure App Service (Linux, Free tier for development)
- **Infrastructure**: Bicep templates for repeatable deployments

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az --version
   ```

2. **Azure Subscription** with appropriate permissions
   ```bash
   az login
   az account list
   az account set --subscription "<your-subscription-id>"
   ```

3. **Python 3** with pip (for database setup)
   ```bash
   python3 --version
   ```

4. **jq** (JSON processor - used by deployment script)
   ```bash
   # Install on Ubuntu/Debian
   sudo apt-get install jq
   
   # Install on macOS
   brew install jq
   ```

## Quick Start Deployment

### Option 1: One-Command Deployment

Run the master deployment script:

```bash
./deploy.sh
```

This script will:
1. Create the resource group
2. Deploy infrastructure (App Service + Managed Identity)
3. Deploy the application code
4. Configure database permissions
5. Display the application URL

### Option 2: Manual Step-by-Step Deployment

If you prefer to run each step manually:

#### Step 1: Create Resource Group

```bash
az group create \
  --name rg-expense-mgmt-dev \
  --location uksouth
```

#### Step 2: Deploy Infrastructure

```bash
az deployment group create \
  --resource-group rg-expense-mgmt-dev \
  --template-file infrastructure/main.bicep \
  --parameters location=uksouth baseName=expensemgmt environment=dev
```

#### Step 3: Get Deployment Outputs

```bash
az deployment group show \
  --resource-group rg-expense-mgmt-dev \
  --name main \
  --query 'properties.outputs'
```

#### Step 4: Deploy Application

```bash
az webapp deploy \
  --resource-group rg-expense-mgmt-dev \
  --name <web-app-name-from-output> \
  --src-path ExpenseApp/app.zip \
  --type zip
```

#### Step 5: Configure Database Permissions

```bash
# Install Python packages
pip3 install pyodbc azure-identity

# Run SQL script
python3 run-sql.py
```

## Accessing the Application

⚠️ **IMPORTANT**: The application is accessible at the `/Index` endpoint, not the root URL.

Your application URL will be:
```
https://<your-app-name>.azurewebsites.net/Index
```

The root URL (`/`) will not display the application correctly.

## Testing the Application

Once deployed:

1. Navigate to `https://<your-app-name>.azurewebsites.net/Index`
2. You should see the "Expense Management System - Database Test" page
3. Click the **"Insert Test Record into Roles Table"** button
4. The app will insert a test record using Managed Identity authentication
5. Success message confirms database connectivity

## Configuration

### Database Settings

The application connects to:
- **Server**: `sql-expense-mgmt-xyz.database.windows.net`
- **Database**: `ExpenseManagementDB`

To change these, update:
- `infrastructure/main.bicep` (appSettings)
- `ExpenseApp/appsettings.json`
- `run-sql.py` (SERVER and DATABASE variables)

### Azure Resources Created

The deployment creates:

1. **App Service Plan**: `asp-expensemgmt-dev`
   - SKU: F1 (Free tier)
   - OS: Linux
   - Runtime: .NET 8

2. **Web App**: `app-expensemgmt-dev-<unique-id>`
   - Managed Identity: mid-AppModAssist
   - HTTPS only: Enabled

3. **Managed Identity**: `mid-AppModAssist`
   - Type: User Assigned
   - Permissions: db_datareader, db_datawriter on ExpenseManagementDB

## Project Structure

```
.
├── infrastructure/
│   └── main.bicep              # Azure infrastructure as code
├── ExpenseApp/
│   ├── Pages/
│   │   ├── Index.cshtml        # Main test page
│   │   └── Index.cshtml.cs     # Page model with SQL logic
│   ├── Program.cs              # App configuration with Managed Identity
│   ├── ExpenseApp.csproj       # Project file with dependencies
│   ├── appsettings.json        # Configuration settings
│   └── app.zip                 # Deployment package
├── Database-Schema/
│   └── database_schema.sql     # Full database schema
├── deploy.sh                   # Master deployment script
├── run-sql.py                  # Python script for SQL execution
├── script.sql                  # Database permissions script
└── README.md                   # This file
```

## Security Features

✅ **Managed Identity Authentication**: No passwords stored or transmitted
✅ **HTTPS Only**: All traffic encrypted in transit
✅ **TLS 1.2**: Minimum TLS version enforced
✅ **FTPS Disabled**: Secure deployment methods only
✅ **No Vulnerabilities**: Latest package versions without known CVEs

## Troubleshooting

### Application Won't Start

Check logs:
```bash
az webapp log tail \
  --name <web-app-name> \
  --resource-group rg-expense-mgmt-dev
```

Restart the app:
```bash
az webapp restart \
  --name <web-app-name> \
  --resource-group rg-expense-mgmt-dev
```

### Database Connection Issues

1. Verify managed identity has permissions:
   ```bash
   python3 run-sql.py
   ```

2. Check if you're logged in to Azure CLI:
   ```bash
   az account show
   ```

3. Verify the SQL Server exists and is accessible

### Python Script Errors

Install ODBC drivers (if not present):
```bash
# Ubuntu/Debian
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
```

## Clean Up Resources

To delete all resources:

```bash
az group delete \
  --name rg-expense-mgmt-dev \
  --yes \
  --no-wait
```

## Database Schema

The application uses an Expense Management system with the following tables:

- **Roles**: User roles (Employee, Manager)
- **Users**: System users with role assignments
- **ExpenseCategories**: Expense classification
- **ExpenseStatus**: Expense workflow states
- **Expenses**: Expense claims with amounts, receipts, and approval tracking

See `Database-Schema/database_schema.sql` for the complete schema and sample data.

## Development

To modify the application:

1. Edit files in `ExpenseApp/`
2. Rebuild: `cd ExpenseApp && dotnet build`
3. Republish: `dotnet publish --configuration Release --output ./app`
4. Repackage: `cd app && zip -r ../app.zip . && cd ..`
5. Redeploy: Run `deploy.sh` or use `az webapp deploy`

## Azure Best Practices

This implementation follows Azure best practices:

- ✅ Infrastructure as Code (Bicep)
- ✅ Managed Identity for secure authentication
- ✅ Resource naming conventions
- ✅ Appropriate SKUs for development/production
- ✅ HTTPS enforcement
- ✅ Minimal permissions (least privilege)
- ✅ Tagged resources for cost management

For production deployments, consider:
- Upgrading to paid App Service SKU
- Implementing Application Insights
- Adding backup and disaster recovery
- Configuring auto-scaling
- Implementing CI/CD pipelines

## Support & Documentation

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Managed Identity Documentation](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)

## License

See LICENSE file for details.
