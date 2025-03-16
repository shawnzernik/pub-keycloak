using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Logging;
using System.IO;

var builder = WebApplication.CreateBuilder(args);

// Load Configuration
var configuration = builder.Configuration;

// Enable Logging
Console.WriteLine("Starting Net8SAML API...");

// Register Services
builder.Services.AddControllers();
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Ensure Static Files Directory Exists
string staticFilesPath = Path.GetFullPath(configuration["StaticFiles:RootPath"]!);
if (!Directory.Exists(staticFilesPath))
{
    Console.WriteLine($"Static files directory '{staticFilesPath}' does not exist.");
}

// Enable Swagger
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint($"{configuration["Server:BaseUrl"]}/swagger/v1/swagger.json", "Net8SAML API v1");
    c.RoutePrefix = "swagger"; // Swagger available at /swagger
});

// Middleware Order (IMPORTANT)
app.UseSession();
app.UseRouting();
app.UseAuthorization();
app.MapControllers(); // ✅ This ensures API controllers handle routes

// Serve static files (React frontend)
app.UseDefaultFiles();
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(staticFilesPath),
    RequestPath = ""
});

// Ensure React frontend is served for non-API routes
app.Use(async (context, next) =>
{
    if (!context.Request.Path.StartsWithSegments("/api") &&
        !Path.HasExtension(context.Request.Path.Value))
    {
        var indexPath = Path.Combine(staticFilesPath, "index.html");
        if (File.Exists(indexPath))
        {
            context.Response.ContentType = "text/html";
            await context.Response.SendFileAsync(indexPath);
            return;
        }
    }
    await next();
});

Console.WriteLine($"Net8SAML API is running on {configuration["Server:BaseUrl"]}");

app.Run();