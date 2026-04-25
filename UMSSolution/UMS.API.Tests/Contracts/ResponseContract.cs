namespace UMS.API.Tests.Contracts;

public sealed class ResponseContract<T>
{
    public IReadOnlyList<string> Messages { get; init; } = [];
    public bool IsSuccessful { get; init; }
    public int StatusCode { get; init; }
    public T? Data { get; init; }
}

public sealed record TokenResponseContract(
    string Token,
    string RefreshToken,
    DateTime RefreshTokenExpiryTime);

public sealed record CategoryResponseContract(
    int Id,
    string Name,
    string Slug,
    int? ParentId,
    int SortOrder);

public sealed record CategoryDetailsResponseContract(
    int Id,
    string Name,
    string Slug,
    string? ParentName);

public sealed record CategoryLookupContract(
    int Id,
    string Name);

public sealed class PagedResultContract<T>
{
    public List<T> Data { get; init; } = [];
    public int CurrentPage { get; init; }
    public int PageSize { get; init; }
    public int TotalCount { get; init; }
}

public sealed record RoleResponseContract(
    int Id,
    string Name,
    string? Description);

public sealed record RoleClaimContract(
    string ClaimType,
    string ClaimValue,
    string Description);

public sealed class RoleClaimResponseContract
{
    public RoleResponseContract Role { get; init; } = default!;
    public List<RoleClaimContract> RoleClaims { get; init; } = [];
}

public sealed record UserResponseContract(
    int Id,
    string FullName,
    string UserName,
    string Email,
    bool IsActive,
    bool EmailConfirmed,
    string? PhoneNumber);

public sealed record UserRoleContract(
    string RoleName,
    string RoleDescription);
