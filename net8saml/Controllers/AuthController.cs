using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.IO.Compression;
using System.Text;
using System.Web;
using System.Xml;

[Route("api/auth")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _configuration;
    public AuthController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpGet("login")]
    public IActionResult Login()
    {
        string samlRequest = CreateSamlAuthnRequest();
        Console.WriteLine("Raw SAML Request:\n" + samlRequest);

        // ✅ Deflate-compress and Base64-encode the SAML request
        string encodedRequest = DeflateAndBase64Encode(samlRequest);

        // ✅ Generate the signature
        string relayState = "SomeRelayState";  // Optional
        string signature = SignSamlRequest(encodedRequest, relayState);

        // ✅ Append signature and algorithm
        string redirectUrl = $"{_configuration["SAML:IdpSsoUrl"]}?SAMLRequest={HttpUtility.UrlEncode(encodedRequest)}"
                             + $"&RelayState={HttpUtility.UrlEncode(relayState)}"
                             + $"&SigAlg={HttpUtility.UrlEncode("http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")}"
                             + $"&Signature={HttpUtility.UrlEncode(signature)}";

        Console.WriteLine($"Redirecting to Keycloak: {redirectUrl}");
        return Redirect(redirectUrl);
    }

    private string SignSamlRequest(string samlRequest, string relayState)
    {
        string privateKeyPath = _configuration["SAML:PrivateKeyPath"]!;

        if (string.IsNullOrEmpty(privateKeyPath) || !System.IO.File.Exists(privateKeyPath))
        {
            throw new FileNotFoundException($"Private key not found at: {privateKeyPath}");
        }

        // Read the private key from the file
        string privateKeyPem = System.IO.File.ReadAllText(privateKeyPath);
        if (!privateKeyPem.Contains("-----BEGIN PRIVATE KEY-----"))
            throw new Exception("Missing -----BEGIN PRIVATE KEY-----!");

        using RSA rsa = RSA.Create();
        rsa.ImportFromPem(privateKeyPem);  // ✅ Correct method in .NET 7+

        string query = $"SAMLRequest={HttpUtility.UrlEncode(samlRequest)}&RelayState={HttpUtility.UrlEncode(relayState)}&SigAlg={HttpUtility.UrlEncode("http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")}";
        byte[] signatureBytes = rsa.SignData(Encoding.UTF8.GetBytes(query), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);

        return Convert.ToBase64String(signatureBytes);
    }

    private string CreateSamlAuthnRequest()
    {
        return $@"
        <samlp:AuthnRequest 
            xmlns:samlp='urn:oasis:names:tc:SAML:2.0:protocol' 
            ID='{Guid.NewGuid().ToString()}'
            Version='2.0' 
            IssueInstant='{DateTime.UtcNow:yyyy-MM-ddTHH:mm:ssZ}' 
            ProtocolBinding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'
            AssertionConsumerServiceURL='{_configuration["SAML:AssertionConsumerServiceUrl"]}'
            Destination='{_configuration["SAML:IdpSsoUrl"]}'
        >
            <saml:Issuer xmlns:saml='urn:oasis:names:tc:SAML:2.0:assertion'>
                {_configuration["SAML:EntityId"]}
            </saml:Issuer>
            <samlp:NameIDPolicy 
                AllowCreate='true' 
                Format='urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
            />
        </samlp:AuthnRequest>
        ";
    }

    private string DeflateAndBase64Encode(string input)
    {
        byte[] inputBytes = Encoding.UTF8.GetBytes(input);

        using (var outputStream = new MemoryStream())
        {
            using (var deflateStream = new DeflateStream(outputStream, CompressionMode.Compress, true))
            {
                deflateStream.Write(inputBytes, 0, inputBytes.Length);
            }

            byte[] compressedData = outputStream.ToArray();
            return Convert.ToBase64String(compressedData);
        }
    }

    // ✅ New Callback Endpoint to Handle Keycloak SAML Response
    [HttpPost("callback")]
    public IActionResult Callback([FromForm] string SAMLResponse)
    {
        Console.WriteLine("Received SAML Response from Keycloak");

        if (string.IsNullOrEmpty(SAMLResponse))
        {
            Console.WriteLine("Error: SAML Response is missing");
            return BadRequest("Invalid SAML Response");
        }

        try
        {
            // Decode the Base64-encoded SAML Response
            byte[] samlBytes = Convert.FromBase64String(SAMLResponse);
            string samlXml = Encoding.UTF8.GetString(samlBytes);

            Console.WriteLine("Decoded SAML Response:\n" + samlXml);

            // Parse the XML response
            XmlDocument xmlDoc = new XmlDocument();
            xmlDoc.LoadXml(samlXml);

            // Extract the NameID (user identity)
            XmlNamespaceManager nsManager = new XmlNamespaceManager(xmlDoc.NameTable);
            nsManager.AddNamespace("saml", "urn:oasis:names:tc:SAML:2.0:assertion");

            XmlNode nameIdNode = xmlDoc.SelectSingleNode("//saml:Assertion/saml:Subject/saml:NameID", nsManager)!;

            if (nameIdNode == null)
            {
                Console.WriteLine("Error: NameID not found in SAML Response");
                return Unauthorized("Invalid SAML Response");
            }

            string userId = nameIdNode.InnerText;
            Console.WriteLine($"Authenticated User: {userId}");

            // Store user session
            HttpContext.Session.SetString("User", userId);

            // Redirect to frontend (or return success message)
            return Redirect("/");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error processing SAML Response: {ex.Message}");
            return StatusCode(500, "Error processing SAML Response");
        }
    }

    [HttpGet("status")]
    public IActionResult Status()
    {
        // ✅ Retrieve user from session
        string? user = HttpContext.Session.GetString("User");

        if (string.IsNullOrEmpty(user))
        {
            return Unauthorized(new { message = "User not authenticated" });
        }

        return Ok(new { Username = user });
    }
}