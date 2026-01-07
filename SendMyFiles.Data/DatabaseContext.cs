using System;
using System.Configuration;
using System.Data.SqlClient;
using SendMyFiles.Models;

namespace SendMyFiles.Data
{
    public class DatabaseContext : IDisposable
    {
        private SqlConnection _connection;

        public DatabaseContext()
        {
            string connectionString = ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString;
            _connection = new SqlConnection(connectionString);
            _connection.Open();
        }

        public SqlConnection Connection => _connection;

        public void Dispose()
        {
            if (_connection != null && _connection.State != System.Data.ConnectionState.Closed)
            {
                _connection.Close();
                _connection.Dispose();
            }
        }
    }
}

