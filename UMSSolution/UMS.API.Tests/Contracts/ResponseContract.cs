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

public sealed record RoleResponseContract(
    int Id,
    string Name,
    string? Description);

public sealed record UserResponseContract(
    int Id,
    string FirstName,
    string LastName,
    string UserName,
    string Email,
    string? PhoneNumber,
    string? ProfilePicture,
    bool IsActive);
