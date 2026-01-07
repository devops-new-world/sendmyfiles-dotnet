using System;
using System.Configuration;
using System.IO;
using System.Threading.Tasks;
using Minio;
using Minio.DataModel.Args;

namespace SendMyFiles.Business.Services
{
    public class FileStorageService
    {
        private MinioClient _minioClient;
        private readonly string _bucketName;
        private readonly bool _useMinio;

        public FileStorageService()
        {
            _useMinio = bool.Parse(ConfigurationManager.AppSettings["UseMinio"] ?? "true");
            _bucketName = ConfigurationManager.AppSettings["StorageBucketName"] ?? "sendmyfiles";

            if (_useMinio)
            {
                string endpoint = ConfigurationManager.AppSettings["MinioEndpoint"] ?? "localhost:9000";
                string accessKey = ConfigurationManager.AppSettings["MinioAccessKey"] ?? "minioadmin";
                string secretKey = ConfigurationManager.AppSettings["MinioSecretKey"] ?? "minioadmin";
                bool useSSL = bool.Parse(ConfigurationManager.AppSettings["MinioUseSSL"] ?? "false");

                var clientBuilder = new MinioClient()
                    .WithEndpoint(endpoint)
                    .WithCredentials(accessKey, secretKey);

                if (useSSL)
                {
                    clientBuilder.WithSSL();
                }

                _minioClient = clientBuilder.Build();

                // Ensure bucket exists
                EnsureBucketExistsAsync().Wait();
            }
        }

        private async Task EnsureBucketExistsAsync()
        {
            try
            {
                bool found = await _minioClient.BucketExistsAsync(new BucketExistsArgs().WithBucket(_bucketName));
                if (!found)
                {
                    await _minioClient.MakeBucketAsync(new MakeBucketArgs().WithBucket(_bucketName));
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"Error ensuring bucket exists: {ex.Message}", ex);
            }
        }

        public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType)
        {
            if (_useMinio)
            {
                string objectName = $"{Guid.NewGuid()}_{fileName}";
                
                await _minioClient.PutObjectAsync(new PutObjectArgs()
                    .WithBucket(_bucketName)
                    .WithObject(objectName)
                    .WithStreamData(fileStream)
                    .WithObjectSize(fileStream.Length)
                    .WithContentType(contentType));

                return objectName;
            }
            else
            {
                // Fallback to local file system if MinIO is not configured
                string uploadPath = ConfigurationManager.AppSettings["LocalStoragePath"] ?? "~/App_Data/Uploads";
                if (!Path.IsPathRooted(uploadPath))
                {
                    uploadPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, uploadPath.Replace("~/", ""));
                }

                if (!Directory.Exists(uploadPath))
                {
                    Directory.CreateDirectory(uploadPath);
                }

                string objectName = $"{Guid.NewGuid()}_{fileName}";
                string fullPath = Path.Combine(uploadPath, objectName);

                using (var fileStream2 = File.Create(fullPath))
                {
                    fileStream.CopyTo(fileStream2);
                }

                return objectName;
            }
        }

        public async Task<Stream> DownloadFileAsync(string objectName)
        {
            if (_useMinio)
            {
                var memoryStream = new MemoryStream();
                
                await _minioClient.GetObjectAsync(new GetObjectArgs()
                    .WithBucket(_bucketName)
                    .WithObject(objectName)
                    .WithCallbackStream(stream => stream.CopyTo(memoryStream)));

                memoryStream.Position = 0;
                return memoryStream;
            }
            else
            {
                string uploadPath = ConfigurationManager.AppSettings["LocalStoragePath"] ?? "~/App_Data/Uploads";
                if (!Path.IsPathRooted(uploadPath))
                {
                    uploadPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, uploadPath.Replace("~/", ""));
                }

                string fullPath = Path.Combine(uploadPath, objectName);
                return File.OpenRead(fullPath);
            }
        }

        public async Task<string> GetPresignedUrlAsync(string objectName, int expirySeconds = 3600)
        {
            if (_useMinio)
            {
                return await _minioClient.PresignedGetObjectAsync(new PresignedGetObjectArgs()
                    .WithBucket(_bucketName)
                    .WithObject(objectName)
                    .WithExpiry(expirySeconds));
            }
            else
            {
                // For local storage, return a relative URL
                return $"/File/Download?token={objectName}";
            }
        }
    }
}

