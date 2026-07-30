using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Api.Controllers;

[Route("api/clientes")]
public sealed class ClientesController(IClienteRepository repo) : CatalogoControllerBase<Cliente, ClienteRequest>(repo, "clientes");
