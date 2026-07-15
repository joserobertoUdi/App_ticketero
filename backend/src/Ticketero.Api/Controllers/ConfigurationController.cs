using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Ticketero.Application.DTOs;

namespace Ticketero.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "administrador")]
public class ConfigurationController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public ConfigurationController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    [HttpGet]
    public ActionResult<SystemConfigurationDto> Get()
    {
        return Ok(new SystemConfigurationDto
        {
            TiempoEstimadoMinutos = _configuration.GetValue<int>("TicketSettings:EstimatedWaitMinutes"),
            MaxTicketsPorDia = _configuration.GetValue<int>("TicketSettings:MaxTicketsPerDay")
        });
    }

    [HttpPut]
    public ActionResult Update([FromBody] UpdateConfigurationRequest request)
    {
        // En producci�n, guardar en base de datos (tabla Configurations)
        return Ok(new { mensaje = "Configuraci�n actualizada" });
    }

    [HttpPost("video")]
    public async Task<ActionResult> UploadVideo(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { error = "No se ha seleccionado ning�n archivo" });

        var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "videos");
        Directory.CreateDirectory(uploadsDir);

        var fileName = $"fondo_{DateTime.Now:yyyyMMddHHmmss}{Path.GetExtension(file.FileName)}";
        var filePath = Path.Combine(uploadsDir, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        return Ok(new
        {
            mensaje = "Video actualizado correctamente",
            nombreArchivo = fileName,
            url = $"/api/configuration/video/stream?file={fileName}"
        });
    }

    [HttpGet("video/stream")]
    public IActionResult StreamVideo([FromQuery] string file)
    {
        var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "videos", file);
        if (!System.IO.File.Exists(filePath))
            return NotFound();

        var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read);
        return File(stream, "video/mp4");
    }
}
