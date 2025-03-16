using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

[Route("api/user")]
[ApiController]
public class UserController : ControllerBase
{
    private readonly IConfiguration _configuration;
    public UserController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpGet("hello")]
    public IActionResult Hello()
    {
        string? user = HttpContext.Session.GetString("User");

        if (string.IsNullOrEmpty(user))
        {
            // Redirect user to Keycloak login
            return Redirect($"{_configuration["Server:BaseUrl"]}/api/auth/login");
        }

        return Ok($"Hello {user}");
    }
}