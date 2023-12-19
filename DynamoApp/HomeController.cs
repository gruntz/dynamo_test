using Microsoft.AspNetCore.Mvc;

[Route("api/[controller]")]
public class HelloController : ControllerBase {

    [HttpGet]
    public IActionResult Get() {
        // Call with: curl http://52.147.195.54:5000/api/Hello
        return Ok("Hello, Dynamo!");
    }

}