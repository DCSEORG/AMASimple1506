-- Create user for managed identity and grant permissions
-- This script grants the mid-AppModAssist managed identity the necessary permissions
-- to read and write data in the ExpenseManagementDB database

CREATE USER [mid-AppModAssist] FROM EXTERNAL PROVIDER;
GO

ALTER ROLE db_datareader ADD MEMBER [mid-AppModAssist];
GO

ALTER ROLE db_datawriter ADD MEMBER [mid-AppModAssist];
GO
