using Azure.Core;
using Azure.Identity;
using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

// Register SQL connection as a singleton service
builder.Services.AddSingleton<SqlConnectionFactory>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();

// SQL Connection Factory using Managed Identity
public class SqlConnectionFactory
{
    private readonly string _server;
    private readonly string _database;
    private readonly string? _clientId;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        _server = configuration["SQL_SERVER"] ?? "sql-expense-mgmt-xyz.database.windows.net";
        _database = configuration["SQL_DATABASE"] ?? "ExpenseManagementDB";
        _clientId = configuration["AZURE_CLIENT_ID"];
    }

    public async Task<SqlConnection> CreateConnectionAsync()
    {
        var connectionString = $"Server={_server};Database={_database};Encrypt=True;TrustServerCertificate=False;";
        var connection = new SqlConnection(connectionString);

        // Get access token using Managed Identity
        var credential = string.IsNullOrEmpty(_clientId) 
            ? new DefaultAzureCredential()
            : new DefaultAzureCredential(new DefaultAzureCredentialOptions 
            { 
                ManagedIdentityClientId = _clientId 
            });

        var tokenRequestContext = new TokenRequestContext(new[] { "https://database.windows.net/.default" });
        var token = await credential.GetTokenAsync(tokenRequestContext);
        connection.AccessToken = token.Token;

        return connection;
    }
}
