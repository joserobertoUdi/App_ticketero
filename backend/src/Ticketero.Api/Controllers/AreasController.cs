using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Ticketero.Application.DTOs;
using Ticketero.Application.Interfaces;

namespace Ticketero.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AreasController : ControllerBase
{
    private readonly IAreaService _areaService;

    public AreasController(IAreaService areaService)
    {
        _areaService = areaService;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult> GetAll()
    {
        var areas = await _areaService.GetAllActiveAsync();
        return Ok(new { areas });
    }

    [HttpPost]
    [Authorize(Roles = "administrador")]
    public async Task<ActionResult<AreaDto>> Create([FromBody] CreateAreaRequest request)
    {
        try
        {
            var area = await _areaService.CreateAsync(request);
            return CreatedAtAction(nameof(GetAll), new { id = area.Id }, area);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "administrador")]
    public async Task<ActionResult<AreaDto>> Update(int id, [FromBody] UpdateAreaRequest request)
    {
        try
        {
            var area = await _areaService.UpdateAsync(id, request);
            return Ok(area);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
