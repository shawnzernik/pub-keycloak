using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

[Route("api/debug")]
[ApiController]
public class DebugController : ControllerBase
{
    private readonly IConfiguration _configuration;
    public DebugController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpGet]
    public IActionResult DebugInfo()
    {
        string? user = HttpContext.Session.GetString("User");

        if (string.IsNullOrEmpty(user))
        {
            // Redirect user to Keycloak login
            return Redirect($"{_configuration["Server:BaseUrl"]}/api/auth/login");
        }

        return Ok(new
        {
            User = user,
            SessionData = HttpContext.Session.Keys
        });
    }
}