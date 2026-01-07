using System;
using System.Data;
using System.Data.SqlClient;
using SendMyFiles.Models;

namespace SendMyFiles.Data.Repositories
{
    public class UserRepository
    {
        public User GetOrCreateUser(string email)
        {
            using (var context = new DatabaseContext())
            {
                // Check if user exists
                string selectQuery = "SELECT UserId, Email, UserType, CreatedDate, UsedQuota FROM Users WHERE Email = @Email";
                using (var cmd = new SqlCommand(selectQuery, context.Connection))
                {
                    cmd.Parameters.AddWithValue("@Email", email);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return new User
                            {
                                UserId = reader.GetInt32(0),
                                Email = reader.GetString(1),
                                UserType = reader.GetString(2),
                                CreatedDate = reader.GetDateTime(3),
                                UsedQuota = reader.GetInt64(4)
                            };
                        }
                    }
                }

                // Create new user if doesn't exist
                string insertQuery = "INSERT INTO Users (Email, UserType, CreatedDate, UsedQuota) OUTPUT INSERTED.UserId VALUES (@Email, @UserType, @CreatedDate, @UsedQuota)";
                using (var cmd = new SqlCommand(insertQuery, context.Connection))
                {
                    cmd.Parameters.AddWithValue("@Email", email);
                    cmd.Parameters.AddWithValue("@UserType", "Free");
                    cmd.Parameters.AddWithValue("@CreatedDate", DateTime.Now);
                    cmd.Parameters.AddWithValue("@UsedQuota", 0);
                    
                    int userId = (int)cmd.ExecuteScalar();
                    
                    return new User
                    {
                        UserId = userId,
                        Email = email,
                        UserType = "Free",
                        CreatedDate = DateTime.Now,
                        UsedQuota = 0
                    };
                }
            }
        }

        public void UpdateUserQuota(int userId, long additionalBytes)
        {
            using (var context = new DatabaseContext())
            {
                string query = "UPDATE Users SET UsedQuota = UsedQuota + @AdditionalBytes WHERE UserId = @UserId";
                using (var cmd = new SqlCommand(query, context.Connection))
                {
                    cmd.Parameters.AddWithValue("@UserId", userId);
                    cmd.Parameters.AddWithValue("@AdditionalBytes", additionalBytes);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public User GetUserById(int userId)
        {
            using (var context = new DatabaseContext())
            {
                string query = "SELECT UserId, Email, UserType, CreatedDate, UsedQuota FROM Users WHERE UserId = @UserId";
                using (var cmd = new SqlCommand(query, context.Connection))
                {
                    cmd.Parameters.AddWithValue("@UserId", userId);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return new User
                            {
                                UserId = reader.GetInt32(0),
                                Email = reader.GetString(1),
                                UserType = reader.GetString(2),
                                CreatedDate = reader.GetDateTime(3),
                                UsedQuota = reader.GetInt64(4)
                            };
                        }
                    }
                }
            }
            return null;
        }
    }
}

