#!/bin/bash
set -e

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Expense Management App Deployment${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Variables - Update these as needed
RESOURCE_GROUP="rg-expense-mgmt-dev"
LOCATION="uksouth"
BASE_NAME="expensemgmt"
ENVIRONMENT="dev"

echo -e "${GREEN}[1/5] Creating Resource Group...${NC}"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table

echo ""
echo -e "${GREEN}[2/5] Deploying Azure Infrastructure (App Service + Managed Identity)...${NC}"
DEPLOYMENT_OUTPUT=$(az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infrastructure/main.bicep \
  --parameters location="$LOCATION" baseName="$BASE_NAME" environment="$ENVIRONMENT" \
  --query 'properties.outputs' \
  --output json)

# Extract outputs
WEB_APP_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.webAppName.value')
WEB_APP_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.webAppUrl.value')
MANAGED_IDENTITY_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.managedIdentityName.value')
MANAGED_IDENTITY_PRINCIPAL_ID=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.managedIdentityPrincipalId.value')

echo ""
echo -e "${BLUE}Deployment Information:${NC}"
echo "  Web App Name: $WEB_APP_NAME"
echo "  Managed Identity: $MANAGED_IDENTITY_NAME"
echo "  Principal ID: $MANAGED_IDENTITY_PRINCIPAL_ID"
echo ""

echo -e "${GREEN}[3/5] Deploying Application Code...${NC}"
az webapp deploy \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEB_APP_NAME" \
  --src-path ExpenseApp/app.zip \
  --type zip

echo ""
echo -e "${GREEN}[4/5] Configuring Database Permissions...${NC}"
echo -e "${BLUE}Installing required Python packages...${NC}"
pip3 install --quiet pyodbc azure-identity

echo -e "${BLUE}Running SQL script to grant managed identity permissions...${NC}"
python3 run-sql.py

echo ""
echo -e "${GREEN}[5/5] Deployment Complete!${NC}"
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Access Your Application${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}Application URL:${NC} $WEB_APP_URL"
echo ""
echo -e "${BLUE}IMPORTANT:${NC} Navigate to the URL above (with /Index) to access the application."
echo -e "The root URL (/) will not work - you must use ${GREEN}/Index${NC} endpoint."
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Wait 2-3 minutes for the app to fully start"
echo "  2. Open the URL in your browser"
echo "  3. Click the button to test database connectivity"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "  - Check app logs: az webapp log tail --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP"
echo "  - Restart app: az webapp restart --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
