using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;

public class IndexModel : PageModel
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly IConfiguration _configuration;

    public string Message { get; set; } = string.Empty;
    public bool IsSuccess { get; set; }
    public string Server { get; set; } = string.Empty;
    public string Database { get; set; } = string.Empty;

    public IndexModel(SqlConnectionFactory connectionFactory, IConfiguration configuration)
    {
        _connectionFactory = connectionFactory;
        _configuration = configuration;
    }

    public void OnGet()
    {
        Server = _configuration["SQL_SERVER"] ?? "sql-expense-mgmt-xyz.database.windows.net";
        Database = _configuration["SQL_DATABASE"] ?? "ExpenseManagementDB";
    }

    public async Task<IActionResult> OnPostAsync()
    {
        Server = _configuration["SQL_SERVER"] ?? "sql-expense-mgmt-xyz.database.windows.net";
        Database = _configuration["SQL_DATABASE"] ?? "ExpenseManagementDB";

        try
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            await connection.OpenAsync();

            // Insert test record into Roles table
            var sql = "INSERT INTO Roles (RoleName, Description) VALUES ('mid-test-1506', 'Mid-level test user with read and write access from 1506 test');";
            
            using var command = new SqlCommand(sql, connection);
            var rowsAffected = await command.ExecuteNonQueryAsync();

            IsSuccess = true;
            Message = $"✓ Successfully inserted test record into Roles table! ({rowsAffected} row(s) affected)";
        }
        catch (SqlException ex)
        {
            IsSuccess = false;
            Message = $"✗ SQL Error: {ex.Message}";
        }
        catch (Exception ex)
        {
            IsSuccess = false;
            Message = $"✗ Error: {ex.Message}";
        }

        return Page();
    }
}
