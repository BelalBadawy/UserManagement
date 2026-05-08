param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [string]$OutputPath = "."
)

$ErrorActionPreference = 'Stop'

if ($ProjectName -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
    throw "ProjectName must be a valid C# root namespace: letters, digits, underscore, and not starting with a digit."
}

function Invoke-Step([string]$Command, [string[]]$Arguments) {
    Write-Host "> dotnet $Command $($Arguments -join ' ')"
    & dotnet $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "dotnet $Command failed with exit code $LASTEXITCODE" }
}

function Get-ProjectDir([string]$Suffix) { return "$ProjectName.$Suffix" }
function Get-ProjectPath([string]$Suffix) { return Join-Path (Get-ProjectDir $Suffix) "$ProjectName.$Suffix.csproj" }

$Root = Join-Path (Resolve-Path $OutputPath).Path $ProjectName
if (Test-Path $Root) { throw "Output directory already exists: $Root" }
New-Item -ItemType Directory -Force -Path $Root | Out-Null

Push-Location $Root
try {
    Invoke-Step 'new' @('sln', '-n', $ProjectName)

    Invoke-Step 'new' @('classlib', '-n', (Get-ProjectDir 'Domain'), '-f', 'net10.0')
    Invoke-Step 'new' @('classlib', '-n', (Get-ProjectDir 'Application'), '-f', 'net10.0')
    Invoke-Step 'new' @('classlib', '-n', (Get-ProjectDir 'Infrastructure'), '-f', 'net10.0')
    Invoke-Step 'new' @('webapi', '-n', (Get-ProjectDir 'API'), '-f', 'net10.0', '--no-https')
    Invoke-Step 'new' @('xunit', '-n', (Get-ProjectDir 'Domain.Tests'), '-f', 'net10.0')
    Invoke-Step 'new' @('xunit', '-n', (Get-ProjectDir 'Application.Tests'), '-f', 'net10.0')
    Invoke-Step 'new' @('xunit', '-n', (Get-ProjectDir 'Infrastructure.Tests'), '-f', 'net10.0')
    Invoke-Step 'new' @('xunit', '-n', (Get-ProjectDir 'API.Tests'), '-f', 'net10.0')

    $projectSuffixes = @('API', 'Application', 'Domain', 'Infrastructure', 'Domain.Tests', 'Application.Tests', 'Infrastructure.Tests', 'API.Tests')
    foreach ($suffix in $projectSuffixes) { Invoke-Step 'sln' @('add', (Get-ProjectPath $suffix)) }

    function Add-Package([string]$Suffix, [string]$Package, [string]$Version) {
        Invoke-Step 'add' @((Get-ProjectPath $Suffix), 'package', $Package, '--version', $Version)
    }

    Add-Package 'Domain.Tests' 'coverlet.collector' '6.0.4'
    Add-Package 'Domain.Tests' 'FluentAssertions' '8.9.0'
    Add-Package 'Domain.Tests' 'Microsoft.NET.Test.Sdk' '17.14.1'
    Add-Package 'Domain.Tests' 'xunit' '2.9.3'
    Add-Package 'Domain.Tests' 'xunit.runner.visualstudio' '3.1.4'
    Add-Package 'Application' 'FluentValidation' '12.1.1'
    Add-Package 'Application' 'FluentValidation.DependencyInjectionExtensions' '12.1.1'
    Add-Package 'Application' 'Mapster' '10.0.7'
    Add-Package 'Application' 'Mapster.DependencyInjection' '10.0.7'
    Add-Package 'Application' 'Mediator.Abstractions' '3.0.2'
    Add-Package 'Application' 'Mediator.SourceGenerator' '3.0.2'
    Add-Package 'Application' 'Microsoft.EntityFrameworkCore' '10.0.6'
    Add-Package 'Application.Tests' 'AutoFixture' '4.18.1'
    Add-Package 'Application.Tests' 'Bogus' '35.6.1'
    Add-Package 'Application.Tests' 'coverlet.collector' '6.0.4'
    Add-Package 'Application.Tests' 'FluentAssertions' '8.9.0'
    Add-Package 'Application.Tests' 'Microsoft.EntityFrameworkCore.Sqlite' '10.0.6'
    Add-Package 'Application.Tests' 'Microsoft.NET.Test.Sdk' '17.14.1'
    Add-Package 'Application.Tests' 'Moq' '4.20.72'
    Add-Package 'Application.Tests' 'xunit' '2.9.3'
    Add-Package 'Application.Tests' 'xunit.runner.visualstudio' '3.1.4'
    Add-Package 'Infrastructure' 'FluentEmail.Core' '3.0.2'
    Add-Package 'Infrastructure' 'FluentEmail.Smtp' '3.0.2'
    Add-Package 'Infrastructure' 'Microsoft.AspNetCore.Authentication.JwtBearer' '10.0.6'
    Add-Package 'Infrastructure' 'Microsoft.AspNetCore.Components.Authorization' '10.0.6'
    Add-Package 'Infrastructure' 'Microsoft.AspNetCore.Identity.EntityFrameworkCore' '10.0.6'
    Add-Package 'Infrastructure' 'Microsoft.EntityFrameworkCore.Sqlite' '10.0.6'
    Add-Package 'Infrastructure' 'Microsoft.EntityFrameworkCore.SqlServer' '10.0.6'
    Add-Package 'Infrastructure' 'Microsoft.EntityFrameworkCore.Tools' '10.0.6'
    Add-Package 'Infrastructure' 'Microsoft.EntityFrameworkCore.InMemory' '10.0.6'
    Add-Package 'Infrastructure.Tests' 'Bogus' '35.6.1'
    Add-Package 'Infrastructure.Tests' 'coverlet.collector' '6.0.4'
    Add-Package 'Infrastructure.Tests' 'FluentAssertions' '8.9.0'
    Add-Package 'Infrastructure.Tests' 'Microsoft.NET.Test.Sdk' '17.14.1'
    Add-Package 'Infrastructure.Tests' 'Moq' '4.20.72'
    Add-Package 'Infrastructure.Tests' 'xunit' '2.9.3'
    Add-Package 'Infrastructure.Tests' 'xunit.runner.visualstudio' '3.1.4'
    Add-Package 'API' 'Asp.Versioning.Mvc.ApiExplorer' '8.1.1'
    Add-Package 'API' 'Microsoft.AspNetCore.OpenApi' '10.0.6'
    Add-Package 'API' 'Microsoft.EntityFrameworkCore.SqlServer' '10.0.6'
    Add-Package 'API' 'Microsoft.EntityFrameworkCore.Tools' '10.0.6'
    Add-Package 'API' 'Microsoft.EntityFrameworkCore.Design' '10.0.6'
    Add-Package 'API' 'Scalar.AspNetCore' '2.14.1'
    Add-Package 'API.Tests' 'Bogus' '35.6.1'
    Add-Package 'API.Tests' 'coverlet.collector' '6.0.4'
    Add-Package 'API.Tests' 'FluentAssertions' '8.9.0'
    Add-Package 'API.Tests' 'Microsoft.AspNetCore.Mvc.Testing' '10.0.6'
    Add-Package 'API.Tests' 'Microsoft.EntityFrameworkCore.InMemory' '10.0.6'
    Add-Package 'API.Tests' 'Microsoft.NET.Test.Sdk' '17.14.1'
    Add-Package 'API.Tests' 'xunit' '2.9.3'
    Add-Package 'API.Tests' 'xunit.runner.visualstudio' '3.1.4'

    function Add-ProjectReference([string]$FromSuffix, [string]$ToSuffix) {
        Invoke-Step 'add' @((Get-ProjectPath $FromSuffix), 'reference', (Get-ProjectPath $ToSuffix))
    }

    Add-ProjectReference 'Domain.Tests' 'Domain'
    Add-ProjectReference 'Application' 'Domain'
    Add-ProjectReference 'Application.Tests' 'Application'
    Add-ProjectReference 'Application.Tests' 'Domain'
    Add-ProjectReference 'Infrastructure' 'Application'
    Add-ProjectReference 'Infrastructure' 'Domain'
    Add-ProjectReference 'Infrastructure.Tests' 'Infrastructure'
    Add-ProjectReference 'Infrastructure.Tests' 'Application'
    Add-ProjectReference 'API' 'Application'
    Add-ProjectReference 'API' 'Domain'
    Add-ProjectReference 'API' 'Infrastructure'
    Add-ProjectReference 'API.Tests' 'API'
    Add-ProjectReference 'API.Tests' 'Infrastructure'

    foreach ($suffix in $projectSuffixes) {
        $dir = Join-Path $Root (Get-ProjectDir $suffix)
        if ((Resolve-Path $dir).Path -notlike "$Root*") { throw "Refusing to clean outside scaffold root: $dir" }
        Get-ChildItem -LiteralPath $dir -Force | Remove-Item -Recurse -Force
    }

    function Convert-TemplatePath([string]$RelativePath) {
        return ($RelativePath -replace 'UMS', $ProjectName) -replace '\\', [System.IO.Path]::DirectorySeparatorChar
    }

    function Write-TemplateFile([string]$RelativePath, [string]$Content) {
        $target = Join-Path $Root (Convert-TemplatePath $RelativePath)
        $dir = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $rendered = [regex]::Replace($Content, '\bUMS\b', $ProjectName)
        Set-Content -LiteralPath $target -Value $rendered -NoNewline -Encoding UTF8
    }

    function Write-BinaryFile([string]$RelativePath, [string]$Base64Content) {
        $target = Join-Path $Root (Convert-TemplatePath $RelativePath)
        $dir = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        [System.IO.File]::WriteAllBytes($target, [Convert]::FromBase64String($Base64Content))
    }

    Write-TemplateFile 'UMS.API.Tests\Contracts\ResponseContract.cs' @'
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

public sealed record TwoFactorTokenResponseContract(
    string? Token,
    string? RefreshToken,
    DateTime? RefreshTokenExpiryTime,
    bool RequiresTwoFactor,
    string? TwoFactorChallengeToken);

public sealed record ProfileResponseContract(
    int Id,
    string FullName,
    string Email,
    string UserName,
    bool IsActive,
    bool EmailConfirmed,
    bool TwoFactorEnabled);

public sealed record TwoFactorSetupResponseContract(
    string? KeySecret,
    string? CodeQR);
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\AccountEndpointsTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class AccountEndpointsTests : ApiTestBase
{
    public AccountEndpointsTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task Login_should_return_token_for_seeded_user()
    {
        var email = $"login-{Guid.NewGuid():N}@example.com";
        const string password = "Admin@123";
        await Seeder.SeedUserAsync(email, password, ["Basic"]);

        var response = await Client.PostAsJsonAsync("/api/v1/account/login", new
        {
            Email = email,
            Password = password
        });

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<TokenResponseContract>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.Token.Should().NotBeNullOrWhiteSpace();
        payload.Data.RefreshToken.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public async Task Login_should_return_unsuccessful_payload_when_credentials_are_invalid()
    {
        var email = $"invalid-login-{Guid.NewGuid():N}@example.com";
        await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);

        var response = await Client.PostAsJsonAsync("/api/v1/account/login", new
        {
            Email = email,
            Password = "WrongPassword"
        });

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<TokenResponseContract>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task Forgot_password_should_return_successful_response_and_capture_reset_email()
    {
        var email = $"forgot-{Guid.NewGuid():N}@example.com";
        await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);

        var emailSink = GetRequiredService<ApiTestEmailSink>();
        emailSink.Clear();

        var response = await Client.PostAsJsonAsync($"/api/v1/account/forgot-password?email={email}", new { });

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        emailSink.FindLatestFor(email).Should().NotBeNull();
    }

    [Fact]
    public async Task RefreshToken_ValidRefreshToken_ReturnsNewToken()
    {
        // Arrange
        var email = $"refresh-{Guid.NewGuid():N}@example.com";
        const string password = "Admin@123";
        await Seeder.SeedUserAsync(email, password, ["Basic"]);

        var loginResponse = await Client.PostAsJsonAsync("/api/v1/account/login", new
        {
            Email = email,
            Password = password
        });

        var loginPayload = await loginResponse.Content.ReadFromJsonAsync<ResponseContract<TokenResponseContract>>();

        // Act
        var response = await Client.PostAsJsonAsync("/api/v1/account/refresh-token", new
        {
            Token = loginPayload!.Data!.Token,
            RefreshToken = loginPayload.Data.RefreshToken
        });

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<TokenResponseContract>>();

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.Token.Should().NotBeNullOrWhiteSpace();
        payload.Data.RefreshToken.Should().NotBeNullOrWhiteSpace();
        payload.Data.RefreshToken.Should().NotBe(loginPayload.Data.RefreshToken);
    }

    [Fact]
    public async Task RefreshToken_InvalidPayload_ReturnsUnsuccessfulPayload()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/refresh-token", new
        {
            Token = "",
            RefreshToken = ""
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<TokenResponseContract>>();

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
        payload.Messages.Should().Contain(message => !string.IsNullOrWhiteSpace(message));
    }

    [Fact]
    public async Task ResetPassword_UnknownEmail_ReturnsUnsuccessfulPayload()
    {
        // Arrange
        var request = new
        {
            Token = "invalid-token",
            Email = "missing@example.com",
            Password = "NewPassword@123",
            ConfirmPassword = "NewPassword@123"
        };

        // Act
        var response = await Client.PostAsJsonAsync("/api/v1/account/reset-password", request);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
        payload.Messages.Should().Contain(message => !string.IsNullOrWhiteSpace(message));
    }

    [Fact]
    public async Task ResetPassword_ValidToken_ResetsPasswordAndAllowsLogin()
    {
        var email = $"reset-{Guid.NewGuid():N}@example.com";
        const string oldPassword = "Admin@123";
        const string newPassword = "NewPassword@123";
        await Seeder.SeedUserAsync(email, oldPassword, ["Basic"]);

        var emailSink = GetRequiredService<ApiTestEmailSink>();
        emailSink.Clear();

        var forgotPasswordResponse = await Client.PostAsJsonAsync($"/api/v1/account/forgot-password?email={email}", new { });
        forgotPasswordResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var token = emailSink.GetLatestResetToken(email);

        var response = await Client.PostAsJsonAsync("/api/v1/account/reset-password", new
        {
            Token = token,
            Email = email,
            Password = newPassword,
            ConfirmPassword = newPassword
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();

        var loginResponse = await Client.PostAsJsonAsync("/api/v1/account/login", new
        {
            Email = email,
            Password = newPassword
        });
        var loginPayload = await loginResponse.Content.ReadFromJsonAsync<ResponseContract<TokenResponseContract>>();

        loginResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        loginPayload.Should().NotBeNull();
        loginPayload!.IsSuccessful.Should().BeTrue();
        loginPayload.Data.Should().NotBeNull();
        loginPayload.Data!.Token.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public async Task ConfirmEmail_UnknownUser_ReturnsUnsuccessfulPayload()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/confirm-email", new
        {
            UserId = 999999,
            Token = "irrelevant-token"
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task ConfirmEmail_ValidToken_ConfirmsEmailSuccessfully()
    {
        var email = $"confirm-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUnconfirmedUserAsync(email, "Admin@123");

        var emailSink = GetRequiredService<ApiTestEmailSink>();
        emailSink.Clear();

        var resendResponse = await Client.PostAsJsonAsync("/api/v1/account/resend-confirmation-email", new
        {
            Email = email
        });
        resendResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var token = emailSink.GetQueryParam(email, "token");
        var userId = int.Parse(emailSink.GetQueryParam(email, "userId"));

        var response = await Client.PostAsJsonAsync("/api/v1/account/confirm-email", new
        {
            UserId = userId,
            Token = token
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
    }

    [Fact]
    public async Task ConfirmEmailChange_UnknownUser_ReturnsUnsuccessfulPayload()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/confirm-email-change", new
        {
            UserId = 999999,
            NewEmail = "changed@example.com",
            Token = "irrelevant-token"
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task ConfirmEmailChange_InvalidToken_ReturnsUnsuccessfulPayload()
    {
        var email = $"change-email-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);

        var response = await Client.PostAsJsonAsync("/api/v1/account/confirm-email-change", new
        {
            UserId = user.Id,
            NewEmail = "newaddr@example.com",
            Token = "bad-token"
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task ResendConfirmationEmail_UnknownEmail_ReturnsSafeSuccessResponse()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/resend-confirmation-email", new
        {
            Email = $"ghost-{Guid.NewGuid():N}@example.com"
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
    }

    [Fact]
    public async Task ResendConfirmationEmail_AlreadyConfirmedEmail_ReturnsSafeSuccessResponse()
    {
        var email = $"confirmed-resend-{Guid.NewGuid():N}@example.com";
        await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);

        var response = await Client.PostAsJsonAsync("/api/v1/account/resend-confirmation-email", new
        {
            Email = email
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
    }

    [Fact]
    public async Task ResendConfirmationEmail_UnconfirmedEmail_SendsEmailAndReturnsSuccess()
    {
        var email = $"unconfirmed-resend-{Guid.NewGuid():N}@example.com";
        await Seeder.SeedUnconfirmedUserAsync(email, "Admin@123");

        var emailSink = GetRequiredService<ApiTestEmailSink>();
        emailSink.Clear();

        var response = await Client.PostAsJsonAsync("/api/v1/account/resend-confirmation-email", new
        {
            Email = email
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        emailSink.FindLatestFor(email).Should().NotBeNull();
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\CategoryEndpointsTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.Application.Authorization;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class CategoryEndpointsTests : ApiTestBase
{
    public CategoryEndpointsTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task Get_all_categories_should_return_seeded_categories_for_requested_state()
    {
        var activeName = $"Active-{Guid.NewGuid():N}";
        var activeSlug = $"active-{Guid.NewGuid():N}";
        var inactiveName = $"Inactive-{Guid.NewGuid():N}";
        var inactiveSlug = $"inactive-{Guid.NewGuid():N}";

        await Seeder.SeedCategoryAsync(activeName, activeSlug, isActive: true, sortOrder: 1);
        await Seeder.SeedCategoryAsync(inactiveName, inactiveSlug, isActive: false, sortOrder: 2);
        Seeder.ClearCategoryCaches();

        var response = await Client.GetAsync("/api/v1/categories?isActive=true");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<List<CategoryResponseContract>>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data.Should().Contain(category => category.Name == activeName && category.Slug == activeSlug);
        payload.Data.Should().NotContain(category => category.Name == inactiveName);
    }

    [Fact]
    public async Task Get_category_by_id_should_return_seeded_category()
    {
        var name = $"Details-{Guid.NewGuid():N}";
        var slug = $"details-{Guid.NewGuid():N}";
        var seededCategory = await Seeder.SeedCategoryAsync(name, slug, isActive: true, sortOrder: 3);

        var response = await Client.GetAsync($"/api/v1/categories/{seededCategory.Id}");
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<CategoryDetailsResponseContract>>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.Id.Should().Be(seededCategory.Id);
        payload.Data.Name.Should().Be(name);
        payload.Data.Slug.Should().Be(slug);
    }

    [Fact]
    public async Task Get_category_by_id_should_return_unsuccessful_payload_when_id_is_invalid()
    {
        var response = await Client.GetAsync("/api/v1/categories/99999");

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<CategoryResponseContract>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task GetCategoriesPaged_DefaultRequest_ReturnsSuccessfulPayload()
    {
        var firstName = $"Paged-A-{Guid.NewGuid():N}";
        var secondName = $"Paged-B-{Guid.NewGuid():N}";
        var inactiveName = $"Paged-Inactive-{Guid.NewGuid():N}";

        await Seeder.SeedCategoryAsync(firstName, $"paged-a-{Guid.NewGuid():N}", isActive: true, sortOrder: 1);
        await Seeder.SeedCategoryAsync(secondName, $"paged-b-{Guid.NewGuid():N}", isActive: true, sortOrder: 2);
        await Seeder.SeedCategoryAsync(inactiveName, $"paged-inactive-{Guid.NewGuid():N}", isActive: false, sortOrder: 3);
        Seeder.ClearCategoryCaches();

        const string route = "/api/v1/categories/paged?pageNumber=1&pageSize=10&sortBy=sortorder&sortDirection=asc";

        var response = await Client.GetAsync(route);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<PagedResultContract<CategoryResponseContract>>>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.PageSize.Should().Be(10);
        payload.Data.CurrentPage.Should().Be(1);
        payload.Data.Data.Should().NotBeNull();
        payload.Data.Data.Should().Contain(category => category.Name == firstName);
        payload.Data.Data.Should().Contain(category => category.Name == secondName);
        payload.Data.Data.Should().NotContain(category => category.Name == inactiveName);
        payload.Data.TotalCount.Should().BeGreaterThanOrEqualTo(2);
    }

    [Fact]
    public async Task GetCategoriesForList_AuthorizedRequest_ReturnsLookupItems()
    {
        // Arrange
        var listName = $"Lookup-{Guid.NewGuid():N}";
        var listSlug = $"lookup-{Guid.NewGuid():N}";
        await Seeder.SeedCategoryAsync(listName, listSlug, isActive: true, sortOrder: 1);
        Seeder.ClearCategoryCaches();

        UsePrivilegedClient(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Read));

        // Act
        var response = await Client.GetAsync("/api/v1/categories/for-list");
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<List<CategoryLookupContract>>>();

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data.Should().OnlyContain(item => item.Id >= 0);
        payload.Data.Should().Contain(item => item.Name == listName);
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Create_category_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var requiredPermission = AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Create);
        switch (authMode)
        {
            case "anonymous":
                UseAnonymousClient();
                break;
            case "low-privilege":
                UseLowPrivilegeClient(requiredPermission);
                break;
            case "privileged":
                UsePrivilegedClient(requiredPermission);
                break;
            default:
                throw new InvalidOperationException($"Unsupported auth mode '{authMode}'.");
        }

        var suffix = Guid.NewGuid().ToString("N")[..8];
        var request = new
        {
            Name = $"Created {suffix}",
            Slug = $"created-{suffix}",
            ParentId = (int?)null,
            IsActive = true,
            SortOrder = 1
        };

        var response = await Client.PostAsJsonAsync("/api/v1/categories", request);

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<int>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().BeGreaterThan(0);

        var createdCategory = await Verifier.GetCategoryByIdAsync(payload.Data);
        createdCategory.Should().NotBeNull();
        createdCategory!.Name.Should().Be(request.Name);
        createdCategory.Slug.Should().Be(request.Slug);
        createdCategory.IsActive.Should().BeTrue();
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Update_category_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var existingCategory = await Seeder.SeedCategoryAsync(
            $"Update-{Guid.NewGuid():N}",
            $"update-{Guid.NewGuid():N}",
            isActive: true,
            sortOrder: 5);

        var requiredPermission = AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Update);
        switch (authMode)
        {
            case "anonymous":
                UseAnonymousClient();
                break;
            case "low-privilege":
                UseLowPrivilegeClient(requiredPermission);
                break;
            case "privileged":
                UsePrivilegedClient(requiredPermission);
                break;
            default:
                throw new InvalidOperationException($"Unsupported auth mode '{authMode}'.");
        }

        var persistedCategory = await Verifier.GetCategoryByIdIncludingSoftDeletedAsync(existingCategory.Id);
        persistedCategory.Should().NotBeNull();

        var request = new
        {
            Id = existingCategory.Id,
            Name = $"Updated-{Guid.NewGuid():N}",
            Slug = $"updated-{Guid.NewGuid():N}",
            ParentId = (int?)null,
            IsActive = false,
            SortOrder = 9,
            RowVersion = persistedCategory!.RowVersion
        };

        var response = await Client.PutAsJsonAsync("/api/v1/categories", request);

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();

        var updatedCategory = await Verifier.GetCategoryByIdIncludingSoftDeletedAsync(existingCategory.Id);
        updatedCategory.Should().NotBeNull();
        updatedCategory!.Name.Should().Be(request.Name);
        updatedCategory.Slug.Should().Be(request.Slug);
        updatedCategory.IsActive.Should().BeFalse();
        updatedCategory.SortOrder.Should().Be(9);
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Delete_category_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var categoryToDelete = await Seeder.SeedCategoryAsync(
            $"Delete-{Guid.NewGuid():N}",
            $"delete-{Guid.NewGuid():N}",
            isActive: true,
            sortOrder: 7);

        var requiredPermission = AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Delete);
        switch (authMode)
        {
            case "anonymous":
                UseAnonymousClient();
                break;
            case "low-privilege":
                UseLowPrivilegeClient(requiredPermission);
                break;
            case "privileged":
                UsePrivilegedClient(requiredPermission);
                break;
            default:
                throw new InvalidOperationException($"Unsupported auth mode '{authMode}'.");
        }

        var response = await Client.DeleteAsync($"/api/v1/categories/{categoryToDelete.Id}");

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();

        var visibleCategory = await Verifier.GetCategoryByIdAsync(categoryToDelete.Id);
        visibleCategory.Should().BeNull();

        var deletedCategory = await Verifier.GetCategoryByIdIncludingSoftDeletedAsync(categoryToDelete.Id);
        deletedCategory.Should().NotBeNull();
        deletedCategory!.SoftDeleted.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\ConfirmTwoFactorAuthEndpointTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class ConfirmTwoFactorAuthEndpointTests : ApiTestBase
{
    public ConfirmTwoFactorAuthEndpointTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task ConfirmTwoFactorAuth_Unauthenticated_Returns401()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/users/confirm-2fa", new { Code = "123456" });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task ConfirmTwoFactorAuth_NonNumericCode_ReturnsValidationError()
    {
        var email = $"confirm-2fa-val-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PostAsJsonAsync("/api/v1/users/confirm-2fa", new { Code = "abcdef" });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
        payload.Messages.Should().Contain(m => !string.IsNullOrWhiteSpace(m));
    }

    [Fact]
    public async Task ConfirmTwoFactorAuth_WrongCode_WhenNotSetUp_ReturnsFailure()
    {
        var email = $"confirm-2fa-wrong-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PostAsJsonAsync("/api/v1/users/confirm-2fa", new { Code = "000000" });

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\DisableTwoFactorAuthEndpointTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class DisableTwoFactorAuthEndpointTests : ApiTestBase
{
    public DisableTwoFactorAuthEndpointTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task DisableTwoFactorAuth_Unauthenticated_Returns401()
    {
        var response = await Client.PutAsJsonAsync("/api/v1/users/disable-2fa", new
        {
            Password = "Admin@123",
            Code = (string?)null
        });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task DisableTwoFactorAuth_EmptyPassword_ReturnsValidationError()
    {
        var email = $"disable-2fa-val-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PutAsJsonAsync("/api/v1/users/disable-2fa", new
        {
            Password = "",
            Code = (string?)null
        });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
        payload.Messages.Should().Contain(m => !string.IsNullOrWhiteSpace(m));
    }

    [Fact]
    public async Task DisableTwoFactorAuth_WrongPassword_ReturnsFailure()
    {
        var email = $"disable-2fa-wrong-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PutAsJsonAsync("/api/v1/users/disable-2fa", new
        {
            Password = "WrongPassword@999",
            Code = (string?)null
        });

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task DisableTwoFactorAuth_CorrectPassword_TwoFactorNotEnabled_ReturnsFailure()
    {
        var email = $"disable-2fa-not-enabled-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PutAsJsonAsync("/api/v1/users/disable-2fa", new
        {
            Password = "Admin@123",
            Code = (string?)null
        });

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
        payload.Messages.Should().Contain(m => m.Contains("not enabled"));
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\EnableTwoFactorAuthEndpointTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class EnableTwoFactorAuthEndpointTests : ApiTestBase
{
    public EnableTwoFactorAuthEndpointTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task EnableTwoFactorAuth_Unauthenticated_Returns401()
    {
        var response = await Client.PutAsJsonAsync("/api/v1/users/enable-2fa", new { Code = "123456" });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task EnableTwoFactorAuth_InvalidCodeFormat_ReturnsValidationError()
    {
        var email = $"enable-2fa-val-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PutAsJsonAsync("/api/v1/users/enable-2fa", new { Code = "abc" });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
        payload.Messages.Should().Contain(m => !string.IsNullOrWhiteSpace(m));
    }

    [Fact]
    public async Task EnableTwoFactorAuth_WrongCode_ReturnsFailure()
    {
        var email = $"enable-2fa-wrong-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PutAsJsonAsync("/api/v1/users/enable-2fa", new { Code = "000000" });

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\LoginWith2FAEndpointTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class LoginWith2FAEndpointTests : ApiTestBase
{
    public LoginWith2FAEndpointTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task LoginWith2FA_EmptyFields_ReturnsFailure()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/login-2fa", new
        {
            TwoFactorChallengeToken = "",
            Code = ""
        });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
        payload.Messages.Should().Contain(m => !string.IsNullOrWhiteSpace(m));
    }

    [Fact]
    public async Task LoginWith2FA_InvalidChallengeToken_ReturnsFailure()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/login-2fa", new
        {
            TwoFactorChallengeToken = "not.a.valid.jwt.token",
            Code = "123456"
        });

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\LogoutEndpointTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class LogoutEndpointTests : ApiTestBase
{
    public LogoutEndpointTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task Logout_Unauthenticated_Returns401()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/account/logout", new
        {
            RefreshToken = "any-token"
        });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Logout_Authenticated_ValidRefreshToken_ReturnsSuccess()
    {
        var email = $"logout-valid-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PostAsJsonAsync("/api/v1/account/logout", new
        {
            RefreshToken = user.RefreshToken
        });

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
    }

    [Fact]
    public async Task Logout_Authenticated_InvalidRefreshToken_ReturnsFailure()
    {
        var email = $"logout-invalid-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PostAsJsonAsync("/api/v1/account/logout", new
        {
            RefreshToken = "this-token-does-not-match"
        });

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\ProfileEndpointTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class ProfileEndpointTests : ApiTestBase
{
    public ProfileEndpointTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task Profile_Unauthenticated_Returns401()
    {
        var response = await Client.GetAsync("/api/v1/account/profile");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Profile_Authenticated_ReturnsProfileData()
    {
        var email = $"profile-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.GetAsync("/api/v1/account/profile");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<ProfileResponseContract>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.Id.Should().Be(user.Id);
        payload.Data.Email.Should().Be(email);
        payload.Data.TwoFactorEnabled.Should().BeFalse();
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\RoleEndpointsTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.Application.Authorization;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class RoleEndpointsTests : ApiTestBase
{
    public RoleEndpointsTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task Get_all_roles_should_return_successful_response_when_authorized()
    {
        UsePrivilegedClient(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Read));

        var response = await Client.GetAsync("/api/v1/roles/all");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<List<RoleResponseContract>>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeEmpty();
    }

    [Fact]
    public async Task Create_role_should_return_successful_response_when_valid()
    {
        UsePrivilegedClient(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Create));

        var suffix = Guid.NewGuid().ToString("N")[..8];
        var request = new
        {
            Name = $"NewTestRole-{suffix}",
            Description = "Test Description"
        };

        var response = await Client.PostAsJsonAsync("/api/v1/roles", request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
    }

    [Fact]
    public async Task Get_role_by_id_should_return_not_found_when_id_is_invalid()
    {
        UsePrivilegedClient(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Read));

        var response = await Client.GetAsync("/api/v1/roles/9999");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Update_role_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var role = await Seeder.SeedRoleAsync($"RoleUpdate-{Guid.NewGuid():N}", "Before update");
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Update);

        switch (authMode)
        {
            case "anonymous":
                UseAnonymousClient();
                break;
            case "low-privilege":
                UseLowPrivilegeClient(requiredPermission);
                break;
            case "privileged":
                UsePrivilegedClient(requiredPermission);
                break;
            default:
                throw new InvalidOperationException($"Unsupported auth mode '{authMode}'.");
        }

        var request = new
        {
            RoleId = role.Id,
            Name = $"UpdatedRole-{Guid.NewGuid():N}",
            Description = "Updated description"
        };

        var response = await Client.PutAsJsonAsync("/api/v1/roles", request);

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();

        var updatedRole = await Verifier.GetRoleByIdAsync(role.Id);
        updatedRole.Should().NotBeNull();
        updatedRole!.Name.Should().Be(request.Name);
        updatedRole.Description.Should().Be(request.Description);
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Delete_role_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var role = await Seeder.SeedRoleAsync($"RoleDelete-{Guid.NewGuid():N}", "Delete me");
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Delete);

        switch (authMode)
        {
            case "anonymous":
                UseAnonymousClient();
                break;
            case "low-privilege":
                UseLowPrivilegeClient(requiredPermission);
                break;
            case "privileged":
                UsePrivilegedClient(requiredPermission);
                break;
            default:
                throw new InvalidOperationException($"Unsupported auth mode '{authMode}'.");
        }

        var response = await Client.DeleteAsync($"/api/v1/roles/{role.Id}");

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();

        var deletedRole = await Verifier.GetRoleByIdAsync(role.Id);
        deletedRole.Should().BeNull();
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Get_role_permissions_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var role = await Seeder.SeedRoleAsync($"RolePerms-{Guid.NewGuid():N}", "Permissions role");
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Read);

        switch (authMode)
        {
            case "anonymous":
                UseAnonymousClient();
                break;
            case "low-privilege":
                UseLowPrivilegeClient(requiredPermission);
                break;
            case "privileged":
                UsePrivilegedClient(requiredPermission);
                break;
            default:
                throw new InvalidOperationException($"Unsupported auth mode '{authMode}'.");
        }

        var response = await Client.GetAsync($"/api/v1/roles/permissions/{role.Id}");

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<RoleClaimResponseContract>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.Role.Id.Should().Be(role.Id);
        payload.Data.RoleClaims.Should().Contain(claim => claim.ClaimValue == AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Read));
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Update_role_permissions_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var role = await Seeder.SeedRoleAsync($"RolePermUpdate-{Guid.NewGuid():N}", "Update permissions");
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Update);

        switch (authMode)
        {
            case "anonymous":
                UseAnonymousClient();
                break;
            case "low-privilege":
                UseLowPrivilegeClient(requiredPermission);
                break;
            case "privileged":
                UsePrivilegedClient(requiredPermission);
                break;
            default:
                throw new InvalidOperationException($"Unsupported auth mode '{authMode}'.");
        }

        var selectedPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Read);
        var request = new
        {
            RoleId = role.Id,
            RoleClaims = new[]
            {
                new
                {
                    ClaimType = "permission",
                    ClaimValue = selectedPermission,
                    Description = "Read Roles"
                }
            }
        };

        var response = await Client.PutAsJsonAsync("/api/v1/roles/update-permissions", request);

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();

        var roleClaims = await Verifier.GetRoleClaimsAsync(role.Id);
        roleClaims.Should().Contain(roleClaim => roleClaim.ClaimValue == selectedPermission);
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\SetupTwoFactorAuthEndpointTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class SetupTwoFactorAuthEndpointTests : ApiTestBase
{
    public SetupTwoFactorAuthEndpointTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    [Fact]
    public async Task SetupTwoFactorAuth_Unauthenticated_Returns401()
    {
        var response = await Client.PostAsync("/api/v1/users/setup-2fa", null);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task SetupTwoFactorAuth_Authenticated_ReturnsSetupData()
    {
        var email = $"setup-2fa-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UseSelfServiceClient(user.Id);

        var response = await Client.PostAsync("/api/v1/users/setup-2fa", null);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<TwoFactorSetupResponseContract>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.KeySecret.Should().NotBeNullOrWhiteSpace();
        payload.Data.CodeQR.Should().NotBeNullOrWhiteSpace();
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Endpoints\UserEndpointsTests.cs' @'
using System.Net;
using System.Net.Http.Json;
using UMS.Application.Authorization;
using UMS.API.Tests.Contracts;
using UMS.API.Tests.Fixtures;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Endpoints;

[Collection("API collection")]
public class UserEndpointsTests : ApiTestBase
{
    public UserEndpointsTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    private void UseUserClient(string authMode, string requiredPermission)
    {
        switch (authMode)
        {
            case "anonymous":
                UseAnonymousClient();
                break;
            case "low-privilege":
                UseLowPrivilegeClient(requiredPermission);
                break;
            case "privileged":
                UsePrivilegedClient(requiredPermission);
                break;
            default:
                throw new InvalidOperationException($"Unsupported auth mode '{authMode}'.");
        }
    }

    [Fact]
    public async Task Get_user_by_id_should_return_successful_response_when_user_exists()
    {
        var email = $"get-user-{Guid.NewGuid():N}@example.com";
        var seededUser = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);
        UsePrivilegedClient(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read));

        var response = await Client.GetAsync($"/api/v1/users/{seededUser.Id}");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<UserResponseContract>>();

        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.Id.Should().Be(seededUser.Id);
        payload.Data.Email.Should().Be(email);
    }

    [Fact]
    public async Task Get_user_by_id_should_return_not_found_when_user_does_not_exist()
    {
        UsePrivilegedClient(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read));

        var response = await Client.GetAsync("/api/v1/users/9999");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Register_user_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Create);
        UseUserClient(authMode, requiredPermission);

        var email = $"register-{Guid.NewGuid():N}@example.com";
        var request = new
        {
            FullName = "Registered User",
            Email = email,
            Password = "Admin@123",
            ConfirmPassword = "Admin@123",
            PhoneNumber = "01000000000",
            AutoConfirmEmail = true,
            ActivateUser = true
        };

        var response = await Client.PostAsJsonAsync("/api/v1/users/register", request);

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();

        var loginResponse = await Client.PostAsJsonAsync("/api/v1/account/login", new
        {
            Email = email,
            Password = "Admin@123"
        });
        loginResponse.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Get_users_paged_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        await Seeder.SeedUserAsync($"paged-users-{Guid.NewGuid():N}@example.com", "Admin@123", ["Basic"]);
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read);
        UseUserClient(authMode, requiredPermission);

        var response = await Client.GetAsync("/api/v1/users/paged-list?pageNumber=1&pageSize=10&sortBy=fullname&sortDirection=asc");

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<PagedResultContract<UserResponseContract>>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data!.CurrentPage.Should().Be(1);
        payload.Data.PageSize.Should().Be(10);
        payload.Data.Data.Should().NotBeEmpty();
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Update_user_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var user = await Seeder.SeedUserAsync($"update-user-{Guid.NewGuid():N}@example.com", "Admin@123", ["Basic"]);
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update);
        UseUserClient(authMode, requiredPermission);

        var request = new
        {
            UserId = user.Id,
            FullName = "Updated User Name",
            PhoneNumber = "01111111111"
        };

        var response = await Client.PutAsJsonAsync("/api/v1/users/update", request);

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var updatedUser = await Verifier.GetUserByIdAsync(user.Id);
        updatedUser.Should().NotBeNull();
        updatedUser!.FullName.Should().Be(request.FullName);
        updatedUser.PhoneNumber.Should().Be(request.PhoneNumber);
    }

    [Fact]
    public async Task Change_password_returns_unauthorized_when_not_authenticated()
    {
        var email = $"password-user-{Guid.NewGuid():N}@example.com";
        var user = await Seeder.SeedUserAsync(email, "Admin@123", ["Basic"]);

        var request = new
        {
            CurrentPassword = "Admin@123",
            NewPassword = "NewPassword@123",
            ConfirmedNewPassword = "NewPassword@123"
        };

        var response = await Client.PutAsJsonAsync("/api/v1/users/change-password", request);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Change_password_succeeds_when_user_changes_own_password()
    {
        var email = $"password-self-{Guid.NewGuid():N}@example.com";
        const string currentPassword = "Admin@123";
        const string newPassword = "NewPassword@123";
        var user = await Seeder.SeedUserAsync(email, currentPassword, ["Basic"]);

        UseSelfServiceClient(user.Id);

        var request = new
        {
            CurrentPassword = currentPassword,
            NewPassword = newPassword,
            ConfirmedNewPassword = newPassword
        };

        var response = await Client.PutAsJsonAsync("/api/v1/users/change-password", request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();

        UseAnonymousClient();
        var loginResponse = await Client.PostAsJsonAsync("/api/v1/account/login", new
        {
            Email = email,
            Password = newPassword
        });
        loginResponse.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Change_user_status_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var user = await Seeder.SeedUserAsync($"status-user-{Guid.NewGuid():N}@example.com", "Admin@123", ["Basic"]);
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update);
        UseUserClient(authMode, requiredPermission);

        var request = new
        {
            UserId = user.Id,
            ActivateOrDeactivate = false
        };

        var response = await Client.PutAsJsonAsync("/api/v1/users/change-status", request);

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var updatedUser = await Verifier.GetUserByIdAsync(user.Id);
        updatedUser.Should().NotBeNull();
        updatedUser!.IsActive.Should().BeFalse();
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Update_user_roles_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var role = await Seeder.SeedRoleAsync($"UserRole-{Guid.NewGuid():N}", "Assigned role");
        var user = await Seeder.SeedUserAsync($"roles-user-{Guid.NewGuid():N}@example.com", "Admin@123", ["Basic"]);
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update);
        UseUserClient(authMode, requiredPermission);

        var request = new
        {
            UserId = user.Id,
            Roles = new[] { role.Name! }
        };

        var response = await Client.PutAsJsonAsync("/api/v1/users/user-roles", request);

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var roleNames = await Verifier.GetUserRoleNamesAsync(user.Id);
        roleNames.Should().Contain(role.Name!);
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Get_user_roles_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var role = await Seeder.SeedRoleAsync($"ReadRole-{Guid.NewGuid():N}", "Readable role");
        var user = await Seeder.SeedUserAsync($"get-roles-user-{Guid.NewGuid():N}@example.com", "Admin@123", [role.Name!]);
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read);
        UseUserClient(authMode, requiredPermission);

        var response = await Client.GetAsync($"/api/v1/users/roles/{user.Id}");

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<List<UserRoleContract>>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
        payload.Data.Should().NotBeNull();
        payload.Data.Should().Contain(roleContract => roleContract.RoleName == role.Name);
    }

    [Fact]
    public async Task Generate_change_email_token_returns_unauthorized_when_anonymous()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/users/generate-change-email-token", new
        {
            NewEmail = "new@example.com"
        });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Generate_change_email_token_returns_error_when_authenticated_user_not_in_db()
    {
        UsePrivilegedClient(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.ChangeEmail));

        var response = await Client.PostAsJsonAsync("/api/v1/users/generate-change-email-token", new
        {
            NewEmail = "new@example.com"
        });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task Generate_2fa_recovery_codes_returns_unauthorized_when_anonymous()
    {
        var response = await Client.PostAsJsonAsync("/api/v1/users/generate-2fa-recovery-codes", new { });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Generate_2fa_recovery_codes_returns_error_when_authenticated_user_not_in_db()
    {
        UsePrivilegedClient(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Manage2FA));

        var response = await Client.PostAsJsonAsync("/api/v1/users/generate-2fa-recovery-codes", new { });
        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();

        response.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeFalse();
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Lock_user_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var user = await Seeder.SeedUserAsync($"lock-user-{Guid.NewGuid():N}@example.com", "Admin@123", ["Basic"]);
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Lock);
        UseUserClient(authMode, requiredPermission);

        var response = await Client.PutAsJsonAsync("/api/v1/users/lock-user", new
        {
            UserId = user.Id
        });

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
    }

    [Theory]
    [InlineData("anonymous", HttpStatusCode.Unauthorized)]
    [InlineData("low-privilege", HttpStatusCode.Forbidden)]
    [InlineData("privileged", HttpStatusCode.OK)]
    public async Task Unlock_user_should_follow_authorization_matrix(string authMode, HttpStatusCode expectedStatusCode)
    {
        var user = await Seeder.SeedUserAsync($"unlock-user-{Guid.NewGuid():N}@example.com", "Admin@123", ["Basic"]);
        var requiredPermission = AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Unlock);
        UseUserClient(authMode, requiredPermission);

        var response = await Client.PutAsJsonAsync("/api/v1/users/unlock-user", new
        {
            UserId = user.Id
        });

        response.StatusCode.Should().Be(expectedStatusCode);

        if (expectedStatusCode != HttpStatusCode.OK)
        {
            return;
        }

        var payload = await response.Content.ReadFromJsonAsync<ResponseContract<object>>();
        payload.Should().NotBeNull();
        payload!.IsSuccessful.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Fixtures\ApiTestBase.cs' @'
using Microsoft.Extensions.DependencyInjection;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Fixtures;

public abstract class ApiTestBase : IClassFixture<CustomWebApplicationFactory>
{
    protected ApiTestBase(CustomWebApplicationFactory factory)
    {
        Factory = factory;
        Client = factory.CreateAnonymousClient();
        Verifier = new ApiStateVerifier(factory);
        Seeder = new ApiTestDataSeeder(factory);
    }

    protected CustomWebApplicationFactory Factory { get; }
    protected HttpClient Client { get; private set; }
    protected ApiStateVerifier Verifier { get; }
    protected ApiTestDataSeeder Seeder { get; }

    protected T GetRequiredService<T>() where T : notnull
    {
        using var scope = Factory.Services.CreateScope();
        return scope.ServiceProvider.GetRequiredService<T>();
    }

    protected void UseAnonymousClient()
    {
        Client.Dispose();
        Client = Factory.CreateAnonymousClient();
    }

    protected void UseLowPrivilegeClient(string requiredPermission)
    {
        Client.Dispose();
        Client = Factory.CreateLowPrivilegeClient(requiredPermission);
    }

    protected void UsePrivilegedClient(string requiredPermission)
    {
        Client.Dispose();
        Client = Factory.CreatePrivilegedClient(requiredPermission);
    }

    protected void UseSelfServiceClient(int userId)
    {
        Client.Dispose();
        Client = Factory.CreateSelfServiceClient(userId);
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Fixtures\CustomWebApplicationFactory.cs' @'
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.AspNetCore.TestHost;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Persistence.Contexts;
using UMS.API.Tests.Support;

namespace UMS.API.Tests.Fixtures;

public sealed class CustomWebApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private static readonly object InitializationLock = new();
    private static Task? _databaseInitializationTask;

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureServices(services =>
        {
            services.RemoveAll<IAuthenticationSchemeProvider>();
        });

        builder.ConfigureTestServices(services =>
        {
            services.RemoveAll<IEmailService>();
            services.AddSingleton<ApiTestEmailSink>();
            services.AddScoped<IEmailService, ApiTestEmailService>();

            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = ApiTestAuthenticationHandler.SchemeName;
                options.DefaultChallengeScheme = ApiTestAuthenticationHandler.SchemeName;
                options.DefaultScheme = ApiTestAuthenticationHandler.SchemeName;
            }).AddScheme<AuthenticationSchemeOptions, ApiTestAuthenticationHandler>(
                ApiTestAuthenticationHandler.SchemeName,
                _ => { });
        });
    }

    public async Task InitializeAsync()
    {
        await EnsureDatabaseInitializedAsync();
    }

    public new Task DisposeAsync() => base.DisposeAsync().AsTask();

    public HttpClient CreateAnonymousClient()
    {
        return CreateClient();
    }

    public HttpClient CreateLowPrivilegeClient(string requiredPermission)
    {
        var client = CreateClient();
        ApiTestAuthenticationHeaderHelper.ConfigureLowPrivilegeClient(client, requiredPermission);
        return client;
    }

    public HttpClient CreatePrivilegedClient(string requiredPermission)
    {
        var client = CreateClient();
        ApiTestAuthenticationHeaderHelper.ConfigurePrivilegedClient(client, requiredPermission);
        return client;
    }

    public HttpClient CreateSelfServiceClient(int userId)
    {
        var client = CreateClient();
        ApiTestAuthenticationHeaderHelper.ConfigureSelfServiceClient(client, userId);
        return client;
    }

    internal async Task EnsureDatabaseInitializedAsync()
    {
        Task initializationTask;

        lock (InitializationLock)
        {
            _databaseInitializationTask ??= ApiTestDatabaseInitializer.InitializeAsync(Services);
            initializationTask = _databaseInitializationTask;
        }

        await initializationTask;
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\GlobalUsings.cs' @'
global using FluentAssertions;
global using Xunit;
'@
    Write-TemplateFile 'UMS.API.Tests\Support\ApiPermissionHelper.cs' @'
using UMS.Application.Authorization;

namespace UMS.API.Tests.Support;

public static class ApiPermissionHelper
{
    public static string GetRequiredPermission(string service, string feature, string action)
    {
        return AppPermission.NameFor(service, feature, action);
    }

    public static string GetWrongPermission(string requiredPermission)
    {
        var wrongPermission = AppPermissions.AllPermissions
            .Select(permission => permission.Name)
            .FirstOrDefault(permission => !string.Equals(permission, requiredPermission, StringComparison.Ordinal));

        return wrongPermission
            ?? throw new InvalidOperationException(
                $"No wrong permission could be selected for '{requiredPermission}'. Check AppPermissions.AllPermissions.");
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Support\ApiStateVerifier.cs' @'
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using UMS.Domain.Entities;
using UMS.Infrastructure.Identity.Models;
using UMS.Infrastructure.Identity.Constants;
using UMS.Infrastructure.Persistence.Contexts;
using UMS.API.Tests.Fixtures;

namespace UMS.API.Tests.Support;

public sealed class ApiStateVerifier
{
    private readonly CustomWebApplicationFactory _factory;

    public ApiStateVerifier(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public async Task<Category?> GetCategoryByIdAsync(int categoryId, CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        return await dbContext.Categories
            .AsNoTracking()
            .SingleOrDefaultAsync(category => category.Id == categoryId, ct);
    }

    public async Task<Category?> GetCategoryByIdIncludingSoftDeletedAsync(int categoryId, CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        return await dbContext.Categories
            .IgnoreQueryFilters()
            .AsNoTracking()
            .SingleOrDefaultAsync(category => category.Id == categoryId, ct);
    }

    public async Task<ApplicationRole?> GetRoleByIdAsync(int roleId, CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        return await dbContext.Roles
            .AsNoTracking()
            .SingleOrDefaultAsync(role => role.Id == roleId, ct);
    }

    public async Task<List<ApplicationRoleClaim>> GetRoleClaimsAsync(int roleId, CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        return await dbContext.RoleClaims
            .AsNoTracking()
            .Where(roleClaim => roleClaim.RoleId == roleId && roleClaim.ClaimType == AppClaim.Permission)
            .ToListAsync(ct);
    }

    public async Task<ApplicationUser?> GetUserByIdAsync(int userId, CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        return await dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(user => user.Id == userId, ct);
    }

    public async Task<List<string>> GetUserRoleNamesAsync(int userId, CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        return await (from userRole in dbContext.UserRoles
                      join role in dbContext.Roles on userRole.RoleId equals role.Id
                      where userRole.UserId == userId
                      select role.Name!)
            .ToListAsync(ct);
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Support\ApiTestAuthenticationHandler.cs' @'
using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;
using UMS.Infrastructure.Identity.Constants;

namespace UMS.API.Tests.Support;

public sealed class ApiTestAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "ApiTest";
    public const string AuthModeHeaderName = "X-Test-Auth-Mode";
    public const string RequiredPermissionHeaderName = "X-Test-Required-Permission";
    public const string TestUserIdHeaderName = "X-Test-User-Id";
    private const string AnonymousMode = "anonymous";
    private const string LowPrivilegeMode = "low-privilege";
    private const string PrivilegedMode = "privileged";
    private const string SelfServiceMode = "self-service";

    public ApiTestAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue(AuthModeHeaderName, out var authModeValues))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var authMode = authModeValues.ToString();
        if (string.Equals(authMode, AnonymousMode, StringComparison.OrdinalIgnoreCase))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var requiredPermission = Request.Headers[RequiredPermissionHeaderName].ToString();
        if (string.IsNullOrWhiteSpace(requiredPermission))
        {
            return Task.FromResult(AuthenticateResult.Fail(
                $"{RequiredPermissionHeaderName} header is required for authenticated API test clients."));
        }

        if (string.Equals(authMode, SelfServiceMode, StringComparison.OrdinalIgnoreCase))
        {
            var userIdHeader = Request.Headers[TestUserIdHeaderName].ToString();
            if (string.IsNullOrWhiteSpace(userIdHeader))
                return Task.FromResult(AuthenticateResult.Fail(
                    $"{TestUserIdHeaderName} header is required for self-service mode."));

            var selfServiceIssuer = Context.RequestServices
                .GetRequiredService<IConfiguration>()
                .GetSection("JwtConfiguration")
                .GetValue<string>("Issuer")
                ?? "test-issuer";

            var selfClaims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, userIdHeader, ClaimValueTypes.String, selfServiceIssuer),
                new(ClaimTypes.Email, $"user{userIdHeader}@test.com", ClaimValueTypes.String, selfServiceIssuer),
                new(ClaimTypes.Name, "Self-Service Test User", ClaimValueTypes.String, selfServiceIssuer),
                new(ClaimTypes.Role, "Basic", ClaimValueTypes.String, selfServiceIssuer)
            };
            var selfIdentity = new ClaimsIdentity(selfClaims, SchemeName, ClaimTypes.Name, ClaimTypes.Role);
            var selfPrincipal = new ClaimsPrincipal(selfIdentity);
            return Task.FromResult(AuthenticateResult.Success(
                new AuthenticationTicket(selfPrincipal, SchemeName)));
        }

        var jwtIssuer = Context.RequestServices
            .GetRequiredService<IConfiguration>()
            .GetSection("JwtConfiguration")
            .GetValue<string>("Issuer")
            ?? throw new InvalidOperationException("JwtConfiguration:Issuer is required for API test authentication.");

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, "999001", ClaimValueTypes.String, jwtIssuer),
            new(ClaimTypes.Email, "api-tests@example.com", ClaimValueTypes.String, jwtIssuer),
            new(ClaimTypes.Name, "API Test User", ClaimValueTypes.String, jwtIssuer),
            new(ClaimTypes.Role, "Basic", ClaimValueTypes.String, jwtIssuer)
        };

        if (string.Equals(authMode, PrivilegedMode, StringComparison.OrdinalIgnoreCase))
        {
            claims.Add(new Claim(AppClaim.Permission, requiredPermission, ClaimValueTypes.String, jwtIssuer));
        }
        else if (string.Equals(authMode, LowPrivilegeMode, StringComparison.OrdinalIgnoreCase))
        {
            claims.Add(new Claim(
                AppClaim.Permission,
                ApiPermissionHelper.GetWrongPermission(requiredPermission),
                ClaimValueTypes.String,
                jwtIssuer));
        }
        else
        {
            return Task.FromResult(AuthenticateResult.Fail($"Unsupported API test auth mode '{authMode}'."));
        }

        var identity = new ClaimsIdentity(claims, SchemeName, ClaimTypes.Name, ClaimTypes.Role);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);

        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Support\ApiTestAuthenticationHeaderHelper.cs' @'
using System.Net.Http.Headers;

namespace UMS.API.Tests.Support;

public static class ApiTestAuthenticationHeaderHelper
{
    public static void ConfigureAnonymousClient(HttpClient client)
    {
        Clear(client);
        client.DefaultRequestHeaders.Add(ApiTestAuthenticationHandler.AuthModeHeaderName, "anonymous");
    }

    public static void ConfigureLowPrivilegeClient(HttpClient client, string requiredPermission)
    {
        Clear(client);
        client.DefaultRequestHeaders.Add(ApiTestAuthenticationHandler.AuthModeHeaderName, "low-privilege");
        client.DefaultRequestHeaders.Add(ApiTestAuthenticationHandler.RequiredPermissionHeaderName, requiredPermission);
    }

    public static void ConfigurePrivilegedClient(HttpClient client, string requiredPermission)
    {
        Clear(client);
        client.DefaultRequestHeaders.Add(ApiTestAuthenticationHandler.AuthModeHeaderName, "privileged");
        client.DefaultRequestHeaders.Add(ApiTestAuthenticationHandler.RequiredPermissionHeaderName, requiredPermission);
    }

    public static void ConfigureSelfServiceClient(HttpClient client, int userId)
    {
        Clear(client);
        client.DefaultRequestHeaders.Add(ApiTestAuthenticationHandler.AuthModeHeaderName, "self-service");
        client.DefaultRequestHeaders.Add(ApiTestAuthenticationHandler.RequiredPermissionHeaderName, "self-service");
        client.DefaultRequestHeaders.Add(ApiTestAuthenticationHandler.TestUserIdHeaderName, userId.ToString());
    }

    private static void Clear(HttpClient client)
    {
        client.DefaultRequestHeaders.Authorization = null;
        client.DefaultRequestHeaders.Remove(ApiTestAuthenticationHandler.AuthModeHeaderName);
        client.DefaultRequestHeaders.Remove(ApiTestAuthenticationHandler.RequiredPermissionHeaderName);
        client.DefaultRequestHeaders.Remove(ApiTestAuthenticationHandler.TestUserIdHeaderName);
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Support\ApiTestDatabaseInitializer.cs' @'
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using UMS.Application.Authorization;
using UMS.Infrastructure.Identity.Constants;
using UMS.Infrastructure.Identity.Models;
using UMS.Infrastructure.Persistence.Contexts;

namespace UMS.API.Tests.Support;

public static class ApiTestDatabaseInitializer
{
    public static async Task InitializeAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var serviceProvider = scope.ServiceProvider;
        var dbContext = serviceProvider.GetRequiredService<ApplicationDbContext>();

        try
        {
            await dbContext.Database.EnsureDeletedAsync();
            await dbContext.Database.MigrateAsync();
            await SeedBaselineAsync(dbContext);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException(
                "API test database setup failed. Ensure SQL Server is available for ConnectionStrings:TestConnection in UMS.API/appsettings.Testing.json.",
                ex);
        }
    }

    private static async Task SeedBaselineAsync(ApplicationDbContext dbContext)
    {
        var adminRole = await EnsureRoleAsync(dbContext, "Admin");
        await EnsureRoleAsync(dbContext, "Basic");

        var permissionsByName = await dbContext.RoleClaims
            .Where(roleClaim => roleClaim.RoleId == adminRole.Id && roleClaim.ClaimType == AppClaim.Permission)
            .Select(roleClaim => roleClaim.ClaimValue!)
            .ToListAsync();

        foreach (var permission in AppPermissions.AllPermissions)
        {
            if (permissionsByName.Contains(permission.Name, StringComparer.Ordinal))
            {
                continue;
            }

            dbContext.RoleClaims.Add(new ApplicationRoleClaim
            {
                RoleId = adminRole.Id,
                ClaimType = AppClaim.Permission,
                ClaimValue = permission.Name,
                Description = permission.Description
            });
        }

        await dbContext.SaveChangesAsync();
    }

    private static async Task<ApplicationRole> EnsureRoleAsync(ApplicationDbContext dbContext, string roleName)
    {
        var existingRole = await dbContext.Roles.SingleOrDefaultAsync(role => role.Name == roleName);
        if (existingRole is not null)
        {
            return existingRole;
        }

        var role = new ApplicationRole
        {
            Name = roleName,
            NormalizedName = roleName.ToUpperInvariant(),
            Description = $"{roleName} Role."
        };

        dbContext.Roles.Add(role);
        await dbContext.SaveChangesAsync();

        return role;
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Support\ApiTestDataSeeder.cs' @'
using Mediator;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using UMS.Application.Features.Categories;
using UMS.Application.Features.Categories.Commands.Create;
using UMS.Application.Interfaces.Common;
using UMS.Domain.Entities;
using UMS.Infrastructure.Identity.Models;
using UMS.Infrastructure.Persistence.Contexts;
using UMS.API.Tests.Fixtures;

namespace UMS.API.Tests.Support;

public sealed class ApiTestDataSeeder
{
    private readonly CustomWebApplicationFactory _factory;

    public ApiTestDataSeeder(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    public async Task<Category> SeedCategoryAsync(
        string name,
        string slug,
        bool isActive = true,
        int sortOrder = 1,
        int? parentId = null,
        CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var sender = scope.ServiceProvider.GetRequiredService<ISender>();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        var response = await sender.Send(
            new CreateCategoryCommand(name, slug, parentId, isActive, sortOrder),
            ct);

        if (!response.IsSuccessful)
        {
            throw new InvalidOperationException(
                $"Failed to seed category '{name}': {string.Join("; ", response.Messages)}");
        }

        return await dbContext.Categories
            .AsNoTracking()
            .SingleAsync(category => category.Id == response.Data, ct);
    }

    public void ClearCategoryCaches()
    {
        using var scope = _factory.Services.CreateScope();
        var cacheService = scope.ServiceProvider.GetRequiredService<ICacheService>();

        foreach (var key in CategoryCacheKeys.All)
        {
            cacheService.Remove(key);
        }
    }

    public async Task<ApplicationUser> SeedUserAsync(
        string email,
        string password,
        IEnumerable<string>? roleNames = null,
        CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

        var existingUser = await userManager.FindByEmailAsync(email);
        if (existingUser is not null)
        {
            return existingUser;
        }

        var user = new ApplicationUser
        {
            Email = email,
            UserName = email,
            FullName = "API Test Seed User",
            EmailConfirmed = true,
            PhoneNumberConfirmed = true,
            IsActive = true,
            CreatedDate = DateTime.UtcNow,
            RefreshToken = Guid.NewGuid().ToString("N"),
            RefreshTokenExpiryDate = DateTime.UtcNow.AddDays(1),
            NormalizedEmail = email.ToUpperInvariant(),
            NormalizedUserName = email.ToUpperInvariant()
        };

        var createResult = await userManager.CreateAsync(user, password);
        if (!createResult.Succeeded)
        {
            throw new InvalidOperationException(
                $"Failed to seed API test user '{email}': {string.Join("; ", createResult.Errors.Select(error => error.Description))}");
        }

        if (roleNames is not null)
        {
            var addRolesResult = await userManager.AddToRolesAsync(user, roleNames);
            if (!addRolesResult.Succeeded)
            {
                throw new InvalidOperationException(
                    $"Failed to assign roles to API test user '{email}': {string.Join("; ", addRolesResult.Errors.Select(error => error.Description))}");
            }
        }

        return await userManager.Users.SingleAsync(createdUser => createdUser.Email == email, ct);
    }

    public async Task<ApplicationUser> SeedUnconfirmedUserAsync(
        string email,
        string password,
        CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

        var existingUser = await userManager.FindByEmailAsync(email);
        if (existingUser is not null)
            return existingUser;

        var user = new ApplicationUser
        {
            Email = email,
            UserName = email,
            FullName = "Unconfirmed Test User",
            EmailConfirmed = false,
            IsActive = true,
            CreatedDate = DateTime.UtcNow,
            RefreshToken = Guid.NewGuid().ToString("N"),
            RefreshTokenExpiryDate = DateTime.UtcNow.AddDays(1),
            NormalizedEmail = email.ToUpperInvariant(),
            NormalizedUserName = email.ToUpperInvariant()
        };

        var createResult = await userManager.CreateAsync(user, password);
        if (!createResult.Succeeded)
            throw new InvalidOperationException(
                $"Failed to seed unconfirmed user '{email}': {string.Join("; ", createResult.Errors.Select(e => e.Description))}");

        return await userManager.Users.SingleAsync(u => u.Email == email, ct);
    }

    public async Task<ApplicationRole> SeedRoleAsync(
        string roleName,
        string description,
        CancellationToken ct = default)
    {
        using var scope = _factory.Services.CreateScope();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<ApplicationRole>>();

        var existingRole = await roleManager.FindByNameAsync(roleName);
        if (existingRole is not null)
        {
            return existingRole;
        }

        var role = new ApplicationRole
        {
            Name = roleName,
            NormalizedName = roleName.ToUpperInvariant(),
            Description = description
        };

        var createResult = await roleManager.CreateAsync(role);
        if (!createResult.Succeeded)
        {
            throw new InvalidOperationException(
                $"Failed to seed role '{roleName}': {string.Join("; ", createResult.Errors.Select(error => error.Description))}");
        }

        return await roleManager.FindByNameAsync(roleName)
            ?? throw new InvalidOperationException($"Seeded role '{roleName}' could not be reloaded.");
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Support\ApiTestEmailService.cs' @'
using System.Text.RegularExpressions;
using UMS.Application.Dtos.Email;
using UMS.Application.Interfaces.Common;

namespace UMS.API.Tests.Support;

public sealed class ApiTestEmailService : IEmailService
{
    private static readonly Regex ResetLinkRegex = new("href=\"(?<url>[^\"]+)\"", RegexOptions.IgnoreCase | RegexOptions.Compiled);
    private readonly ApiTestEmailSink _sink;

    public ApiTestEmailService(ApiTestEmailSink sink)
    {
        _sink = sink;
    }

    public Task<string> SendAsync(SendEmailDto request, CancellationToken ct = default)
    {
        var resetUrl = TryExtractResetUrl(request.MessageBody);

        _sink.Add(new ApiTestEmailMessage(
            request.MailTo,
            request.Subject,
            request.MessageBody,
            resetUrl));

        return Task.FromResult(string.Empty);
    }

    private static string? TryExtractResetUrl(string? messageBody)
    {
        if (string.IsNullOrWhiteSpace(messageBody))
        {
            return null;
        }

        var match = ResetLinkRegex.Match(messageBody);
        return match.Success ? match.Groups["url"].Value : null;
    }
}
'@
    Write-TemplateFile 'UMS.API.Tests\Support\ApiTestEmailSink.cs' @'
using System.Collections.Concurrent;
using System.Web;

namespace UMS.API.Tests.Support;

public sealed class ApiTestEmailSink
{
    private readonly ConcurrentQueue<ApiTestEmailMessage> _messages = new();

    public void Add(ApiTestEmailMessage message)
    {
        _messages.Enqueue(message);
    }

    public void Clear()
    {
        while (_messages.TryDequeue(out _))
        {
        }
    }

    public ApiTestEmailMessage? FindLatestFor(string email)
    {
        return _messages
            .Where(message => string.Equals(message.MailTo, email, StringComparison.OrdinalIgnoreCase))
            .LastOrDefault();
    }

    public string GetLatestResetToken(string email)
    {
        var message = FindLatestFor(email)
            ?? throw new InvalidOperationException($"No API test email was captured for '{email}'.");

        if (string.IsNullOrWhiteSpace(message.ResetUrl))
        {
            throw new InvalidOperationException($"No reset URL was captured for '{email}'.");
        }

        var uri = new Uri(message.ResetUrl);
        var query = HttpUtility.ParseQueryString(uri.Query);
        var token = query["code"];

        return token
            ?? throw new InvalidOperationException($"No reset token was found in the reset URL for '{email}'.");
    }

    public string GetQueryParam(string email, string paramName)
    {
        var message = FindLatestFor(email)
            ?? throw new InvalidOperationException($"No API test email was captured for '{email}'.");

        if (string.IsNullOrWhiteSpace(message.ResetUrl))
        {
            throw new InvalidOperationException($"No URL was captured for '{email}'.");
        }

        var uri = new Uri(message.ResetUrl);
        var query = HttpUtility.ParseQueryString(uri.Query);
        return query[paramName]
            ?? throw new InvalidOperationException($"Query param '{paramName}' not found in URL for '{email}'.");
    }
}

public sealed record ApiTestEmailMessage(
    string? MailTo,
    string? Subject,
    string? MessageBody,
    string? ResetUrl);
'@
    Write-TemplateFile 'UMS.API.Tests\Support\TestCollectionDefinitions.cs' @'
namespace UMS.API.Tests.Support;

[CollectionDefinition("API collection", DisableParallelization = true)]
public sealed class ApiCollectionDefinition
{
}
'@
    Write-TemplateFile 'UMS.API.Tests\UMS.API.Tests.csproj' @'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Bogus" Version="35.6.1" />
    <PackageReference Include="coverlet.collector" Version="6.0.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" Version="8.9.0" />
    <PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="10.0.6" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="10.0.6" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\UMS.API\UMS.API.csproj" />
    <ProjectReference Include="..\UMS.Infrastructure\UMS.Infrastructure.csproj" />
  </ItemGroup>

</Project>
'@
    Write-TemplateFile 'UMS.API\appsettings.Development.json' @'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
'@
    Write-TemplateFile 'UMS.API\appsettings.json' @'
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=UMSDb;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;"
  },
  "IdProtection": {
    "SecretKey": "UMSEntityIdProtector@3453453&^%%$#%$@$#@$%^%$%&%^#$%#$#@^&WREWREWd^%^%#$#@#@!"
  },
  "JwtConfiguration": {
    "Secret": "OQ6NPHeCv4rgLWGkSlaLf8soegJZhRrLY7OGaavJAhsdW5cN4PByKiq38W2Dn3DvYqggcTsDvGNXaLiVIw-U3hdNewXcCtEbe8f9ezgSnhpZIjAUaCUrCZswz6itxb-KEIAp-aJaF1AztCv1jG7mzn_S2YvbrLQvTE2f60i87VPUvByKkkz6yJO2ab_Vx_XSBT77BQN1hyVStPMGPcTP0IIDlGyz2XVYUygPcBnfK6cONPTptjPMbTubpxyHyUCZ6-1DpyI7gRhPXUM36IagcHsCsLmwkIQdkGgR6kpay5LAcBYGRxDjs-lXeFS2Vd9D_cv3Lzq3N4QTqHrOBnLwWg&^%$#@!#%)(*&^%",
    "Issuer": "UMSAppIssuer",
    "Audience": "UMSAppAudience",
    "TokenExpiryInMinutes": 30,
    "RefreshTokenExpiryInDays": 1,
    "TwoFactorChallengeTokenExpiryInMinutes": 5
  },
  "TwoFactor": {
    "Issuer": "UMSApp"
  },
  "EmailConfiguration": {
    "Port": 587,
    "Host": "smtp.ethereal.email",
    "Email": "kennedy99@ethereal.email",
    "Password": "CaFjjvFz5EPwXVWAp9",
    "DisplayName": "Kennedy Streich",
    "EnableSsl": true
  },
  "SeedUsers": {
    "Admin": {
      "FullName": "System Administrator",
      "Email": "admin@gmail.com",
      "Password": "Admin@123",
      "PhoneNumber": "01025387387"
    },
    "Basic": {
      "FullName": "Basic User",
      "Email": "asamy@gmail.com",
      "Password": "Admin@123",
      "PhoneNumber": "0112929333"
    }
  },
  "AllowedOrigins": [],
  "CacheConfiguration": {
    "AbsoluteExpirationInHours": 1,
    "SlidingExpirationInMinutes": 30
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
'@
    Write-TemplateFile 'UMS.API\appsettings.Testing.json' @'
{
  "ConnectionStrings": {
    "TestConnection": "Server=localhost;Database=UMSDbTest;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;"
  },
  "DbProvider": "SqlServer",
  "EnableAuditLog": false,
  "RunApplicationSeeder": false
}
'@
    Write-TemplateFile 'UMS.API\Endpoints\AccountEndpoints.cs' @'
using Mediator;
using UMS.API.Extensions;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Features.Token.Queries.LoginWith2FA;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Commands.Logout;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries.GetMyProfile;

namespace UMS.API.Endpoints;

public record ForgotPasswordRequest(string Email);

public static class AccountEndpoints
{
    public static IEndpointRouteBuilder MapAccountEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/v{version:apiVersion}/account")
                       .WithTags("Account")
                       .AllowAnonymous();

        group.MapPost("login", async (TokenRequest tokenRequest, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetTokenQuery { TokenRequest = tokenRequest }, ct);
            return response.ToApiResult();
        })
        .RequireRateLimiting("auth")
        .Produces<IResponseWrapper<TokenResponse>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest)
        .Produces(StatusCodes.Status429TooManyRequests);

        group.MapPost("refresh-token", async (RefreshTokenRequest refreshTokenRequest, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetRefreshTokenQuery { RefreshTokenRequest = refreshTokenRequest }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper<TokenResponse>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("forgot-password", async ([AsParameters] ForgotPasswordRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ForgotPasswordCommand { Email = request.Email }, ct);
            return response.ToApiResult();
        })
        .RequireRateLimiting("auth")
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest)
        .Produces(StatusCodes.Status429TooManyRequests);

        group.MapPost("reset-password", async (ResetPasswordRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ResetPasswordCommand { ResetPasswordRequest = request }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("confirm-email", async (ConfirmEmailRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ConfirmEmailCommand { ConfirmEmail = request }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("confirm-email-change", async (ConfirmEmailChangeRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ConfirmEmailChangeCommand { ConfirmEmailChange = request }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("resend-confirmation-email", async (ResendConfirmationEmailRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ResendConfirmationEmailCommand { ResendConfirmation = request }, ct);
            return response.ToApiResult();
        })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("login-2fa",
            async (TwoFactorLoginRequest request, ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(
                    new LoginWith2FAQuery { Request = request }, ct);
                return response.ToApiResult();
            })
        .RequireRateLimiting("auth")
        .Produces<IResponseWrapper<TokenResponse>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest)
        .Produces<IResponseWrapper>(StatusCodes.Status401Unauthorized)
        .Produces(StatusCodes.Status429TooManyRequests);

        var authGroup = app
            .MapGroup("api/v{version:apiVersion}/account")
            .WithTags("Account")
            .RequireAuthorization();

        authGroup.MapPost("logout",
            async (LogoutRequest request, ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(
                    new LogoutCommand { Request = request }, ct);
                return response.ToApiResult();
            })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest)
        .Produces<IResponseWrapper>(StatusCodes.Status401Unauthorized);

        authGroup.MapGet("profile",
            async (ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(new GetMyProfileQuery(), ct);
                return response.IsSuccessful
                    ? Results.Ok(response)
                    : Results.NotFound(response);
            })
        .Produces<IResponseWrapper<ProfileResponse>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status401Unauthorized);

        return app;
    }
}
'@
    Write-TemplateFile 'UMS.API\Endpoints\CategoryEndpoints.cs' @'
using Mediator;
using Microsoft.AspNetCore.Mvc;
using UMS.API.Extensions;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Categories.Commands.Create;
using UMS.Application.Features.Categories.Commands.Delete;
using UMS.Application.Features.Categories.Commands.Update;
using UMS.Application.Features.Categories.Queries.GetAllCategories;
using UMS.Application.Features.Categories.Queries.GetAllCategoriesForList;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;
using UMS.Application.Features.Categories.Queries.GetCategoryById;
using UMS.Application.Authorization;

namespace UMS.API.Endpoints
{
    public static class CategoryEndpoints
    {
        public static IEndpointRouteBuilder MapCategoryEndpoints(this IEndpointRouteBuilder app)
        {
            var group = app.MapGroup("api/v{version:apiVersion}/categories")
                .WithTags("Categories");

            group.MapGet("/", async (ISender sender, bool? isActive, CancellationToken ct) =>
            {
                var query = new GetAllCategoriesQuery(isActive);
                var response = await sender.Send(query, ct);
                  return response.ToApiResult(); 
            })
            .Produces<IResponseWrapper<List<CategoryResponse>>>()
            .WithName("GetAllCategories")
            .AllowAnonymous();

            group.MapGet("/paged", async (ISender sender, [AsParameters] PagedFilterRequest filter, CancellationToken ct) =>
            {
                // Use object initializer syntax instead of a constructor
                var query = new GetCategoriesPagedQuery { PagedFilterRequest = filter };
                var response = await sender.Send(query, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper<PagedResult<CategoryResponse>>>()
            .WithName("GetCategoriesPaged")
            .AllowAnonymous();

            group.MapGet("/for-list", async (ISender sender, CancellationToken ct) =>
            {
                var query = new GetAllCategoriesForListQuery();
                var response = await sender.Send(query, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper<List<CategoryLookupDto>>>()
            .WithName("GetCategoriesForList")
            .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Read));

            group.MapGet("/{categoryId:int}", async (ISender sender, int categoryId, CancellationToken ct) =>
            {
                var query = new GetCategoryByIdQuery(categoryId);
                var response = await sender.Send(query, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper<CategoryResponse>>()
            .WithName("GetCategoryById")
            .AllowAnonymous();

            group.MapPost("/", async (ISender sender, CreateCategoryRequest request, CancellationToken ct) =>
            {
                var command = new CreateCategoryCommand(
                    request.Name,
                    request.Slug,
                    request.ParentId,
                    request.IsActive,
                    request.SortOrder);
                var response = await sender.Send(command, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper>()
            .WithName("CreateCategory")
            .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Create));

            group.MapPut("/", async (ISender sender, UpdateCategoryCommand request, CancellationToken ct) =>
            {
                var response = await sender.Send(request, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper>()
            .WithName("UpdateCategory")
            .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Update));

            group.MapDelete("/{categoryId:int}", async (ISender sender, int categoryId, CancellationToken ct) =>
            {
                var command = new DeleteCategoryCommand(categoryId);
                var response = await sender.Send(command, ct);
                return response.ToApiResult();
            })
            .Produces<IResponseWrapper>()
            .WithName("DeleteCategory")
            .RequireAuthorization(AppPermission.NameFor(AppService.Product, AppFeature.Categories, AppAction.Delete));

            return app;
        }
    }
}
'@
    Write-TemplateFile 'UMS.API\Endpoints\RoleEndpoints.cs' @'
using Mediator;
using UMS.API.Extensions;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Roles;
using UMS.Application.Features.Roles.Commands;
using UMS.Application.Features.Roles.Queries;
using UMS.Application.Authorization;

namespace WebApi.Endpoints;

public static class RoleEndpoints
{
    public static IEndpointRouteBuilder MapRoleEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/v{version:apiVersion}/roles")
                       .WithTags("Roles")
                       .RequireAuthorization();

        group.MapPost("/", async (CreateRoleRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new CreateRoleCommand { CreateRole = request }, ct);
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Create))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapGet("all", async (ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetRolesQuery(), ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Read))
          .Produces<IResponseWrapper<List<RoleResponse>>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("/", async (UpdateRoleRequest updateRole, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UpdateRoleCommand { UpdateRole = updateRole }, ct);
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapGet("{roleId:int}", async (int roleId, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetRoleByIdQuery { RoleId = roleId }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Read))
          .Produces<IResponseWrapper<RoleResponse>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapDelete("{roleId:int}", async (int roleId, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new DeleteRoleCommand { RoleId = roleId }, ct);
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Delete))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapGet("permissions/{roleId:int}", async (int roleId, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetPermissionsQuery { RoleId = roleId }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Read))
          .Produces<IResponseWrapper<RoleClaimResponse>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("update-permissions", async (UpdateRoleClaimsRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UpdateRolePermissionsCommand { UpdateRoleClaims = request }, ct);
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Roles, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        return app;
    }
}
'@
    Write-TemplateFile 'UMS.API\Endpoints\UserEndpoints.cs' @'
using Mediator;
using UMS.API.Extensions;
using UMS.Application.Authorization;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Commands.ConfirmTwoFactorAuth;
using UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;
using UMS.Application.Features.Users.Commands.EnableTwoFactorAuth;
using UMS.Application.Features.Users.Commands.SetupTwoFactorAuth;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries;

namespace WebApi.Endpoints;

public static class UserEndpoints
{
    public static IEndpointRouteBuilder MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/v{version:apiVersion}/users")
                       .WithTags("Users")
                       .RequireAuthorization();

        group.MapPost("register", async (UserRegistrationRequest userRegistration, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UserRegistrationCommand { UserRegistration = userRegistration }, ct);
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Create))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapGet("{userId:int}", async (int userId, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetUserByIdQuery { UserId = userId }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<UserResponse>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapGet("paged-list", async ([AsParameters] PagedFilterRequest query, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetUsersPagedQuery { PagedFilterRequest = query }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<PagedResult<UserResponse>>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("update", async (UpdateUserRequest updateUser, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UpdateUserCommand { UpdateUser = updateUser }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("change-password", async (ChangePasswordRequest changePassword, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ChangeUserPasswordCommand { ChangePassword = changePassword }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("change-status", async (ChangeUserStatusRequest changeUserStatus, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new ChangeUserStatusCommand { ChangeUserStatus = changeUserStatus }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPut("user-roles", async (UpdateUserRolesRequest updateUserRoles, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UpdateUserRolesCommand { UpdateUserRoles = updateUserRoles }, ct);
            return response.ToApiResult();
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Update))
          .Produces<IResponseWrapper>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapGet("roles/{userId:int}", async (int userId, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GetUserRolesQuery { UserId = userId }, ct);
            return response.IsSuccessful ? Results.Ok(response) : Results.NotFound(response);
        }).RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Read))
          .Produces<IResponseWrapper<List<UserRoleViewModel>>>(StatusCodes.Status200OK)
          .Produces<IResponseWrapper>(StatusCodes.Status404NotFound);

        group.MapPost("generate-change-email-token", async (GenerateChangeEmailTokenRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GenerateChangeEmailTokenCommand { GenerateChangeEmailToken = request }, ct);
            return response.ToApiResult();
        })
        .RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.ChangeEmail))
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("generate-2fa-recovery-codes", async (ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new GenerateNew2FARecoveryCodesCommand(), ct);
            return response.ToApiResult();
        })
        .RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Manage2FA))
        .Produces<IResponseWrapper<List<string>>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPut("lock-user", async (LockUserRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new LockUserCommand { LockUser = request }, ct);
            return response.ToApiResult();
        })
        .RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Lock))
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPut("unlock-user", async (UnlockUserRequest request, ISender sender, CancellationToken ct) =>
        {
            var response = await sender.Send(new UnlockUserCommand { UnlockUser = request }, ct);
            return response.ToApiResult();
        })
        .RequireAuthorization(AppPermission.NameFor(AppService.Identity, AppFeature.Users, AppAction.Unlock))
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("setup-2fa",
            async (ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(new SetupTwoFactorAuthCommand(), ct);
                return response.ToApiResult();
            })
        .Produces<IResponseWrapper<TwoFactorAuthViewModel>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPost("confirm-2fa",
            async (TwoFactorCodeRequest request, ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(
                    new ConfirmTwoFactorAuthCommand { Request = request }, ct);
                return response.ToApiResult();
            })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPut("enable-2fa",
            async (TwoFactorCodeRequest request, ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(
                    new EnableTwoFactorAuthCommand { Request = request }, ct);
                return response.ToApiResult();
            })
        .Produces<IResponseWrapper<List<string>>>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        group.MapPut("disable-2fa",
            async (DisableTwoFactorAuthRequest request, ISender sender, CancellationToken ct) =>
            {
                var response = await sender.Send(
                    new DisableTwoFactorAuthCommand { Request = request }, ct);
                return response.ToApiResult();
            })
        .Produces<IResponseWrapper>(StatusCodes.Status200OK)
        .Produces<IResponseWrapper>(StatusCodes.Status400BadRequest);

        return app;
    }
}
'@
    Write-TemplateFile 'UMS.API\Extensions\ResponseResultExtensions.cs' @'
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using UMS.Application.Dtos.Wrappers;

namespace UMS.API.Extensions;

public static class ResponseResultExtensions
{
    public static IResult ToApiResult(
     this IResponseWrapper response,
     int? successCode = null,
     int? failureCode = null)
    {
        var statusCode = response.StatusCode;

        if (statusCode <= 0)
        {
            statusCode = response.IsSuccessful
                ? successCode ?? StatusCodes.Status200OK
                : failureCode ?? StatusCodes.Status400BadRequest;
        }

        if (response.IsSuccessful)
        {
            return Results.Ok((object)response);
        }
        else
        {
            return Results.BadRequest((object)response);
        }

        //return Results.Json(
        //    response,
        //   // statusCode: statusCode,
        //    contentType: "application/json"); // Explicit content type
    }
}
'@
    Write-TemplateFile 'UMS.API\Helpers\BearerSchemeTransformer.cs' @'
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace UMS.API.Helpers
{
    public class BearerSchemeTransformer : IOpenApiDocumentTransformer
    {
        public Task TransformAsync(OpenApiDocument document, OpenApiDocumentTransformerContext context, CancellationToken cancellationToken)
        {
            document.Components ??= new OpenApiComponents();
            document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();

            if (!document.Components.SecuritySchemes.ContainsKey("Bearer"))
            {
                document.Components.SecuritySchemes.Add("Bearer", new OpenApiSecurityScheme
                {
                    Type = SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    Description = "Enter JWT Bearer token"
                });
            }

            foreach (var path in document.Paths.Values)
            {
                // Microsoft.OpenApi v2 uses HttpMethod keys directly
                foreach (var operation in path.Operations.Values)
                {
                    operation.Security ??= [];

                    var hasBearerSecurity = operation.Security.Any(req =>
                        req.Any(pair => pair.Key is OpenApiSecuritySchemeReference r &&
                            r.Reference?.Id == "Bearer"));

                    if (!hasBearerSecurity)
                    {
                        var requirement = new OpenApiSecurityRequirement();
                        requirement.Add(new OpenApiSecuritySchemeReference("Bearer"), []);
                        operation.Security.Add(requirement);
                    }
                }
            }

            return Task.CompletedTask;
        }
    }
}
'@
    Write-TemplateFile 'UMS.API\Helpers\SD.cs' @'
namespace UMS.API.Helpers
{
    public static class SD
    {
        public const string ErrorOccurred = "An error occurred. Please try again.";
    }
}
'@
    Write-TemplateFile 'UMS.API\Middlewares\ErrorHandlingMiddleware.cs' @'

using System.Net;
using System.Text.Json;
using UMS.Application.Dtos.Wrappers;

namespace UMS.API
{
    public class ErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandlingMiddleware> _logger;
        private readonly IWebHostEnvironment _env;

        public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger, IWebHostEnvironment env)
        {
            _next = next;
            _logger = logger;
            _env = env;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unhandled exception occurred.");

                if (context.Response.HasStarted)
                {
                    _logger.LogWarning(
                        "The response has already started, the error handling middleware will not modify the response.");
                    return;
                }

                await HandleExceptionAsync(context, ex, _env.IsDevelopment());
            }
        }

        private static async Task HandleExceptionAsync(HttpContext context, Exception ex, bool isDevelopment)
        {
            context.Response.Clear();

            context.Response.StatusCode = ex switch
            {
                UnauthorizedAccessException => (int)HttpStatusCode.Unauthorized,
                KeyNotFoundException => (int)HttpStatusCode.NotFound,
                InvalidOperationException => (int)HttpStatusCode.BadRequest,
                TimeoutException => (int)HttpStatusCode.RequestTimeout,
                ArgumentException => (int)HttpStatusCode.BadRequest,
                _ => (int)HttpStatusCode.InternalServerError
            };

            context.Response.ContentType = "application/json";

            var message = isDevelopment ? ex.Message : "An unexpected error occurred. Please try again later.";
            var responseWrapper = ResponseWrapper.Fail(message, context.Response.StatusCode);
            var result = JsonSerializer.Serialize(responseWrapper);

            await context.Response.WriteAsync(result);
        }
    }
}
'@
    Write-TemplateFile 'UMS.API\Program.cs' @'
using Microsoft.AspNetCore.RateLimiting;
using Scalar.AspNetCore;
using System.Threading.RateLimiting;
using UMS.API;
using UMS.API.Endpoints;
using UMS.API.Helpers;
using UMS.Application;
using UMS.Application.Dtos.TwoFactor;
using UMS.Infrastructure;
using WebApi.Endpoints;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi("v1", options =>
{
    options.AddDocumentTransformer((document, context, ct) =>
        new BearerSchemeTransformer().TransformAsync(document, context, ct)
    );
});

builder.Services.AddCorsConfig(builder.Configuration);
builder.Services.AddHttpContextAccessor();

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddSlidingWindowLimiter("auth", limiter =>
    {
        limiter.PermitLimit = 10;
        limiter.Window = TimeSpan.FromMinutes(1);
        limiter.SegmentsPerWindow = 4;
        limiter.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiter.QueueLimit = 0;
    });
});

builder.Services.AddApiVersioningConfig();
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration, builder.Environment);
builder.Services.Configure<TwoFactorOptions>(builder.Configuration.GetSection("TwoFactor"));


var app = builder.Build();


if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    app.MapScalarApiReference(options =>
    {
        options.AddPreferredSecuritySchemes("Bearer");
    });
        //.RequireAuthorization();
}
else
{
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseMiddleware<ErrorHandlingMiddleware>();

app.UseRouting();
app.UseRateLimiter();

// CORS before authentication
app.UseCors("AllowedOrigins");
await app.UseInfrastructureAsync();
app.MapAccountEndpoints();
app.MapCategoryEndpoints();
app.MapRoleEndpoints();
app.MapUserEndpoints();
app.Run();

'@
    Write-TemplateFile 'UMS.API\Properties\launchSettings.json' @'
{
  "$schema": "https://json.schemastore.org/launchsettings.json",
  "profiles": {
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "launchUrl": "Scalar/v1",
      "applicationUrl": "https://localhost:7122;http://localhost:5055",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "launchUrl": "Scalar/v1",
      "applicationUrl": "http://localhost:5055",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
'@
    Write-TemplateFile 'UMS.API\ServiceCollectionExtensions.cs' @'
using Asp.Versioning;

namespace UMS.API
{
    public static class ServiceCollectionExtensions
    {
        internal static IServiceCollection AddApiVersioningConfig(this IServiceCollection services)
        {
            services
                .AddApiVersioning(options =>
                {
                    options.DefaultApiVersion = new ApiVersion(1, 0);
                    options.AssumeDefaultVersionWhenUnspecified = true;

                    //  This line triggers OnStarting (disable it)
                    options.ReportApiVersions = false;
                })
                .AddApiExplorer(options =>
                {
                    options.GroupNameFormat = "'v'VVV";
                    options.SubstituteApiVersionInUrl = true;
                });

            return services;
        }

        public static IServiceCollection AddCorsConfig(this IServiceCollection services, IConfiguration configuration)
        {
            var allowedOrigins = configuration
                .GetSection("AllowedOrigins")
                .Get<string[]>() ?? [];

            return services.AddCors(options =>
            {
                options.AddPolicy("AllowedOrigins", policy =>
                {
                    if (allowedOrigins.Length > 0)
                    {
                        policy
                            .WithOrigins(allowedOrigins)
                            .AllowAnyMethod()
                            .AllowAnyHeader();
                    }
                    else
                    {
                        // Fallback for local development when no origins are configured
                        policy
                            .WithOrigins("https://localhost:7122", "http://localhost:7122")
                            .AllowAnyMethod()
                            .AllowAnyHeader();
                    }
                });
            });
        }


    }
}
'@
    Write-TemplateFile 'UMS.API\UMS.API.csproj' @'
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <Content Include="Properties\launchSettings.json" />
  </ItemGroup>


	<ItemGroup>
		<PackageReference Include="Asp.Versioning.Mvc.ApiExplorer" Version="8.1.1" />
		<PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="10.0.6" />
		<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="10.0.6" />
		<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="10.0.6">
			<PrivateAssets>all</PrivateAssets>
			<IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
		</PackageReference>
		<PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="10.0.6">
			<PrivateAssets>all</PrivateAssets>
		</PackageReference>
		<PackageReference Include="Scalar.AspNetCore" Version="2.14.1" />
	</ItemGroup>


	<ItemGroup>
	  <ProjectReference Include="..\UMS.Application\UMS.Application.csproj" />
	  <ProjectReference Include="..\UMS.Domain\UMS.Domain.csproj" />
	  <ProjectReference Include="..\UMS.Infrastructure\UMS.Infrastructure.csproj" />
	</ItemGroup>

</Project>
'@
    Write-TemplateFile 'UMS.API\UMS.API.http' @'
@UMS.API_HostAddress = http://localhost:5037

GET {{UMS.API_HostAddress}}/weatherforecast/
Accept: application/json

###
'@
    Write-BinaryFile 'UMS.API\wwwroot\images\banners\1.jpg' @'
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
'@
    Write-TemplateFile 'UMS.Application.Tests\Behaviors\ValidationPipelineBehaviorTests.cs' @'
using FluentValidation;
using Mediator;
using Moq;
using UMS.Application.Behaviors;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Tests.Behaviors;

public class ValidationPipelineBehaviorTests
{
    [Fact]
    public async Task Handle_should_fail_when_any_validator_fails_even_if_another_validator_passes()
    {
        var validators = new IValidator<PipelineTestRequest>[]
        {
            new PassingPipelineTestValidator(),
            new FailingPipelineTestValidator()
        };
        var mockFactory = new Mock<IValidationFailureFactory<IResponseWrapper>>();
        mockFactory.Setup(f => f.CreateFailure(It.IsAny<IReadOnlyList<string>>(), It.IsAny<int>()))
                   .Returns<IReadOnlyList<string>, int>((msgs, code) => ResponseWrapper.Fail(msgs, code));
        var behavior = new ValidationPipelineBehavior<PipelineTestRequest, IResponseWrapper>(validators, mockFactory.Object);
        var handlerWasCalled = false;

        var result = await behavior.Handle(
            new PipelineTestRequest { Name = "invalid" },
            (_, _) =>
            {
                handlerWasCalled = true;
                return new ValueTask<IResponseWrapper>(ResponseWrapper.Success("Handler reached."));
            },
            CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Name must be 'expected'.");
        handlerWasCalled.Should().BeFalse();
    }

    private sealed class PipelineTestRequest : IRequest<IResponseWrapper>, IValidateMe
    {
        public string Name { get; init; } = string.Empty;
    }

    private sealed class PassingPipelineTestValidator : AbstractValidator<PipelineTestRequest>
    {
        public PassingPipelineTestValidator()
        {
            RuleFor(x => x.Name).NotEmpty();
        }
    }

    private sealed class FailingPipelineTestValidator : AbstractValidator<PipelineTestRequest>
    {
        public FailingPipelineTestValidator()
        {
            RuleFor(x => x.Name)
                .Equal("expected")
                .WithMessage("Name must be 'expected'.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Fixtures\TestData.cs' @'
using AutoFixture;
using Bogus;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Features.Roles;
using UMS.Application.Features.Roles.Commands;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Tests.Fixtures;

internal static class TestData
{
    private static readonly Fixture Fixture = new();
    private static readonly Faker Faker = new();

    public static UserRegistrationRequest UserRegistrationRequest() => new()
    {
        FullName = Faker.Name.FullName(),
        Email = Faker.Internet.Email(),
        Password = "Valid@123",
        ConfirmPassword = "Valid@123",
        PhoneNumber = "01012345678",
        AutoConfirmEmail = true,
        ActivateUser = true
    };

    public static TokenRequest TokenRequest() => new()
    {
        Email = Faker.Internet.Email(),
        Password = "Valid@123"
    };

    public static RefreshTokenRequest RefreshTokenRequest() => new()
    {
        Token = Fixture.Create<string>(),
        RefreshToken = Fixture.Create<string>()
    };

    public static ResetPasswordRequest ResetPasswordRequest() => new()
    {
        Email = Faker.Internet.Email(),
        Token = Fixture.Create<string>(),
        Password = "Valid@123",
        ConfirmPassword = "Valid@123"
    };

    public static ChangePasswordRequest ChangePasswordRequest(int? userId = null) => new()
    {
        CurrentPassword = "Current@123",
        NewPassword = "Valid@123",
        ConfirmedNewPassword = "Valid@123"
    };

    public static ChangeUserStatusRequest ChangeUserStatusRequest(int? userId = null) => new()
    {
        UserId = userId ?? Fixture.Create<int>(),
        ActivateOrDeactivate = true
    };

    public static UpdateUserRequest UpdateUserRequest(int? userId = null) => new()
    {
        UserId = userId ?? Fixture.Create<int>(),
        FullName = Faker.Name.FullName(),
        PhoneNumber = "01012345678"
    };

    public static UpdateUserRolesRequest UpdateUserRolesRequest(int? userId = null) => new()
    {
        UserId = userId ?? Fixture.Create<int>(),
        Roles = ["Admin", "Basic"]
    };

    public static PagedFilterRequest PagedFilterRequest() => new()
    {
        PageNumber = 2,
        PageSize = 5,
        SearchTerm = Faker.Lorem.Word(),
        SortBy = "FullName",
        SortDirection = "desc",
        IsActive = true
    };

    public static UserRoleViewModel UserRoleViewModel(string? roleName = null) => new()
    {
        RoleName = roleName ?? "Admin",
        RoleDescription = Faker.Lorem.Sentence()
    };

    public static CreateRoleRequest CreateRoleRequest() => new()
    {
        Name = Faker.Commerce.Department(),
        Description = Faker.Lorem.Sentence()
    };

    public static UpdateRoleRequest UpdateRoleRequest(int? roleId = null) => new()
    {
        RoleId = roleId ?? Fixture.Create<int>(),
        Name = Faker.Commerce.Department(),
        Description = Faker.Lorem.Sentence()
    };

    public static RoleResponse RoleResponse(int? id = null) => new()
    {
        Id = id ?? Fixture.Create<int>(),
        Name = Faker.Commerce.Department(),
        Description = Faker.Lorem.Sentence()
    };

    public static RoleClaimViewModel RoleClaimViewModel(string? claimValue = null) => new()
    {
        ClaimType = "Permission",
        ClaimValue = claimValue ?? Faker.Lorem.Word(),
        Description = Faker.Lorem.Sentence()
    };

    public static RoleClaimResponse RoleClaimResponse(int? roleId = null) => new()
    {
        Role = RoleResponse(roleId),
        RoleClaims =
        [
            RoleClaimViewModel("Permissions.Roles.View"),
            RoleClaimViewModel("Permissions.Roles.Update")
        ]
    };

    public static UpdateRoleClaimsRequest UpdateRoleClaimsRequest(int? roleId = null) => new()
    {
        RoleId = roleId ?? Fixture.Create<int>(),
        RoleClaims =
        [
            RoleClaimViewModel("Permissions.Roles.View"),
            RoleClaimViewModel("Permissions.Roles.Update")
        ]
    };

    public static UserResponse UserResponse(int? id = null) => new()
    {
        Id = id ?? Fixture.Create<int>(),
        FullName = Faker.Name.FullName(),
        Email = Faker.Internet.Email(),
        UserName = Faker.Internet.UserName(),
        IsActive = true,
        PhoneNumber = "01012345678"
    };

    public static ConfirmEmailRequest ConfirmEmailRequest(int? userId = null, string? token = null) => new()
    {
        UserId = userId ?? Fixture.Create<int>(),
        Token  = token  ?? Fixture.Create<string>()
    };

    public static ConfirmEmailChangeRequest ConfirmEmailChangeRequest(int? userId = null) => new()
    {
        UserId   = userId ?? Fixture.Create<int>(),
        NewEmail = Faker.Internet.Email(),
        Token    = Fixture.Create<string>()
    };

    public static ResendConfirmationEmailRequest ResendConfirmationEmailRequest(string? email = null) => new()
    {
        Email = email ?? Faker.Internet.Email()
    };

    public static GenerateChangeEmailTokenRequest GenerateChangeEmailTokenRequest(string? newEmail = null) => new()
    {
        NewEmail = newEmail ?? Faker.Internet.Email()
    };

    public static LockUserRequest LockUserRequest(int? userId = null) => new()
    {
        UserId = userId ?? Fixture.Create<int>()
    };

    public static UnlockUserRequest UnlockUserRequest(int? userId = null) => new()
    {
        UserId = userId ?? Fixture.Create<int>()
    };
}
'@
    Write-TemplateFile 'UMS.Application.Tests\GlobalUsings.cs' @'
global using FluentAssertions;
global using Moq;
global using Xunit;
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Categories\CategoryCommandHandlerTests.cs' @'
using Microsoft.EntityFrameworkCore;
using UMS.Application.Features.Categories;
using UMS.Application.Features.Categories.Commands.Create;
using UMS.Application.Features.Categories.Commands.Delete;
using UMS.Application.Features.Categories.Commands.Update;
using UMS.Application.Features.Categories.Events;
using UMS.Application.Tests.Support.Categories;

namespace UMS.Application.Tests.Handlers.Categories;

public class CreateCategoryCommandHandlerTests
{
    [Fact]
    public async Task Handle_should_create_category_add_outbox_message_and_clear_category_caches()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var handler = new CreateCategoryCommandHandler(scope.DbContext, scope.Cache);
        var command = new CreateCategoryCommand("  New Category  ", "  new-category  ", null, true, 5);

        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        var category = await scope.DbContext.Categories.SingleAsync();
        category.Name.Should().Be("New Category");
        category.Slug.Should().Be("new-category");
        category.RowVersion.Should().Equal([0]);
        scope.Cache.RemovedKeys.Should().BeEquivalentTo(CategoryCacheKeys.All);
        var outbox = await scope.DbContext.OutboxMessages.SingleAsync();
        outbox.Type.Should().Contain(nameof(CategoryCreatedEvent));
        outbox.Payload.Should().Contain($"\"categoryId\":{category.Id}");
    }

    [Fact]
    public async Task Handle_should_fail_when_category_name_already_exists()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        await scope.SeedCategoryAsync("Existing", "existing", 1);
        var handler = new CreateCategoryCommandHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(
            new CreateCategoryCommand(" existing ", "other-slug", null, true, 2),
            CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Category with this name already exists.");
        scope.Cache.RemovedKeys.Should().BeEmpty();
    }
}

public class UpdateCategoryCommandHandlerTests
{
    [Fact]
    public async Task Handle_should_update_category_add_outbox_message_and_clear_category_caches()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var category = await scope.SeedCategoryAsync("Existing", "existing", 1, rowVersion: [3]);
        var parent = await scope.SeedCategoryAsync("Parent", "parent", 2);
        var handler = new UpdateCategoryCommandHandler(scope.DbContext, scope.Cache);
        var command = new UpdateCategoryCommand(category.Id, " Updated ", " updated ", parent.Id, false, 9, [3]);

        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        var updated = await scope.DbContext.Categories.SingleAsync(x => x.Id == category.Id);
        updated.Name.Should().Be("Updated");
        updated.Slug.Should().Be("updated");
        updated.ParentId.Should().Be(parent.Id);
        updated.IsActive.Should().BeFalse();
        updated.SortOrder.Should().Be(9);
        scope.Cache.RemovedKeys.Should().BeEquivalentTo(CategoryCacheKeys.All);
        var outbox = await scope.DbContext.OutboxMessages.SingleAsync();
        outbox.Type.Should().Contain(nameof(CategoryUpdatedEvent));
        outbox.Payload.Should().Contain($"\"categoryId\":{category.Id}");
    }

    [Fact]
    public async Task Handle_should_fail_when_category_does_not_exist()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var handler = new UpdateCategoryCommandHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(
            new UpdateCategoryCommand(404, "Name", "slug", null, true, 1, [1]),
            CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Category not found.");
    }

    [Fact]
    public async Task Handle_should_fail_when_update_hits_concurrency_conflict()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var category = await scope.SeedCategoryAsync("Existing", "existing", 1, rowVersion: [2]);
        scope.DbContext.ThrowConcurrencyOnSave = true;
        var handler = new UpdateCategoryCommandHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(
            new UpdateCategoryCommand(category.Id, "Updated", "updated", null, true, 2, [1]),
            CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.StatusCode.Should().Be(409);
        result.Messages.Should().Contain(message => message.Contains("Concurrency conflict"));
        scope.Cache.RemovedKeys.Should().BeEmpty();
    }
}

public class DeleteCategoryCommandHandlerTests
{
    [Fact]
    public async Task Handle_should_fail_when_category_has_children()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var parent = await scope.SeedCategoryAsync("Parent", "parent", 1);
        await scope.SeedCategoryAsync("Child", "child", 2, parentId: parent.Id);
        var handler = new DeleteCategoryCommandHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(new DeleteCategoryCommand(parent.Id), CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Cannot delete category with children.");
    }

    [Fact]
    public async Task Handle_should_delete_category_add_outbox_message_and_clear_category_caches()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var category = await scope.SeedCategoryAsync("Delete Me", "delete-me", 1);
        var handler = new DeleteCategoryCommandHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(new DeleteCategoryCommand(category.Id), CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        (await scope.DbContext.Categories.CountAsync()).Should().Be(0);
        scope.Cache.RemovedKeys.Should().BeEquivalentTo(CategoryCacheKeys.All);
        var outbox = await scope.DbContext.OutboxMessages.SingleAsync();
        outbox.Type.Should().Contain(nameof(CategoryDeletedEvent));
        outbox.Payload.Should().Contain($"\"categoryId\":{category.Id}");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Categories\CategoryQueryHandlerTests.cs' @'
using Microsoft.EntityFrameworkCore;
using UMS.Application.Features.Categories;
using UMS.Application.Features.Categories.Queries.GetAllCategories;
using UMS.Application.Features.Categories.Queries.GetAllCategoriesForList;
using UMS.Application.Features.Categories.Queries.GetCategoriesAdmin;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;
using UMS.Application.Features.Categories.Queries.GetCategoriesPagedAdmin;
using UMS.Application.Features.Categories.Queries.GetCategoryById;
using UMS.Application.Features.Categories.Queries.GetCategoryByIdAdmin;
using UMS.Application.Tests.Support.Categories;

namespace UMS.Application.Tests.Handlers.Categories;

public class GetAllCategoriesQueryHandlerTests
{
    [Fact]
    public async Task Handle_should_return_cached_categories_when_cache_contains_value()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var cachedCategories = new List<CategoryListDto>
        {
            new(4, "Cached", "cached", null, 7)
        };
        scope.Cache.Set(CategoryCacheKeys.GetAll(true), cachedCategories);
        var handler = new GetAllCategoriesQueryHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(new GetAllCategoriesQuery(true), CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(cachedCategories);
        scope.Cache.SetKeys.Should().ContainSingle();
    }

    [Fact]
    public async Task Handle_should_filter_sort_and_cache_categories_when_cache_misses()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        await scope.SeedCategoryAsync("Gamma", "gamma", 3, isActive: true);
        await scope.SeedCategoryAsync("Alpha", "alpha", 1, isActive: true);
        await scope.SeedCategoryAsync("Beta", "beta", 2, isActive: false);
        await scope.SeedCategoryAsync("Deleted", "deleted", 4, isActive: true, softDeleted: true);
        var handler = new GetAllCategoriesQueryHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(new GetAllCategoriesQuery(true), CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Select(x => x.Name).Should().Equal("Alpha", "Gamma");
        scope.Cache.SetKeys.Should().Contain(CategoryCacheKeys.GetAll(true));
    }
}

public class GetAllCategoriesForListQueryHandlerTests
{
    [Fact]
    public async Task Handle_should_return_cached_lookup_list_when_cache_contains_value()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var cachedCategories = new List<CategoryLookupDto>
        {
            new(4, "Cached")
        };
        scope.Cache.Set(CategoryCacheKeys.GetAllForList, cachedCategories);
        var handler = new GetAllCategoriesForListQueryHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(new GetAllCategoriesForListQuery(), CancellationToken.None);

        result.Data.Should().BeEquivalentTo(cachedCategories);
    }

    [Fact]
    public async Task Handle_should_return_only_active_categories_sorted_for_lookup_when_cache_misses()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        await scope.SeedCategoryAsync("Gamma", "gamma", 2, isActive: true);
        await scope.SeedCategoryAsync("Alpha", "alpha", 1, isActive: true);
        await scope.SeedCategoryAsync("Disabled", "disabled", 0, isActive: false);
        var handler = new GetAllCategoriesForListQueryHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(new GetAllCategoriesForListQuery(), CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Select(x => x.Name).Should().Equal("Alpha", "Gamma");
        scope.Cache.SetKeys.Should().Contain(CategoryCacheKeys.GetAllForList);
    }
}

public class GetCategoryByIdQueryHandlerTests
{
    [Fact]
    public async Task Handle_should_return_category_with_parent_name_when_match_exists()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var parent = await scope.SeedCategoryAsync("Parent", "parent", 1);
        var child = await scope.SeedCategoryAsync("Child", "child", 2, parentId: parent.Id);
        var handler = new GetCategoryByIdQueryHandler(scope.DbContext);

        var result = await handler.Handle(new GetCategoryByIdQuery(child.Id), CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(new CategoryDto(child.Id, "Child", "child", "Parent"));
    }

    [Fact]
    public async Task Handle_should_return_failure_when_category_is_inactive_or_missing()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var inactive = await scope.SeedCategoryAsync("Inactive", "inactive", 1, isActive: false);
        var handler = new GetCategoryByIdQueryHandler(scope.DbContext);

        var result = await handler.Handle(new GetCategoryByIdQuery(inactive.Id), CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Category not found.");
    }
}

public class GetCategoriesPagedQueryHandlerTests
{
    [Fact]
    public async Task Handle_should_filter_sort_and_page_active_categories()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        await scope.SeedCategoryAsync("Alpha", "alpha", 3, isActive: true);
        await scope.SeedCategoryAsync("Beta", "beta", 2, isActive: true);
        await scope.SeedCategoryAsync("Gamma", "gamma", 1, isActive: true);
        await scope.SeedCategoryAsync("Alpha Hidden", "alpha-hidden", 4, isActive: false);
        var handler = new GetCategoriesPagedQueryHandler(scope.DbContext);
        var query = new GetCategoriesPagedQuery
        {
            PagedFilterRequest = new()
            {
                SearchTerm = "a",
                SortBy = "name",
                SortDirection = "desc",
                PageNumber = 1,
                PageSize = 2
            }
        };

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data!.TotalCount.Should().Be(3);
        result.Data.Data.Select(x => x.Name).Should().Equal("Gamma", "Beta");
    }
}

public class GetCategoryByIdAdminQueryHandlerTests
{
    [Fact]
    public async Task Handle_should_return_admin_category_details_when_match_exists()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var parent = await scope.SeedCategoryAsync("Parent", "parent", 1);
        var child = await scope.SeedCategoryAsync("Child", "child", 2, isActive: false, parentId: parent.Id, rowVersion: [4]);
        var handler = new GetCategoryByIdAdminQueryHandler(scope.DbContext);

        var result = await handler.Handle(new GetCategoryByIdAdminQuery(child.Id), CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data!.ParentName.Should().Be("Parent");
        result.Data.IsActive.Should().BeFalse();
        result.Data.RowVersion.Should().Equal([4]);
    }

    [Fact]
    public async Task Handle_should_return_failure_when_category_is_soft_deleted_or_missing()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var deleted = await scope.SeedCategoryAsync("Deleted", "deleted", 1, softDeleted: true);
        var handler = new GetCategoryByIdAdminQueryHandler(scope.DbContext);

        var result = await handler.Handle(new GetCategoryByIdAdminQuery(deleted.Id), CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Category not found or has been deleted.");
    }
}

public class GetAllCategoriesAdminQueryHandlerTests
{
    [Fact]
    public async Task Handle_should_return_cached_admin_categories_when_cache_contains_value()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var cached = new List<CategoryListAdminDto>
        {
            new(1, "Cached", "cached", null, true, 5)
        };
        scope.Cache.Set(CategoryCacheKeys.GetAllAdmin, cached);
        var handler = new GetAllCategoriesAdminQueryHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(new GetAllCategoriesAdminQuery(), CancellationToken.None);

        result.Data.Should().BeEquivalentTo(cached);
    }

    [Fact]
    public async Task Handle_should_return_admin_categories_sorted_and_excluding_soft_deleted_records()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        await scope.SeedCategoryAsync("Gamma", "gamma", 2, isActive: false);
        await scope.SeedCategoryAsync("Alpha", "alpha", 1, isActive: true);
        await scope.SeedCategoryAsync("Deleted", "deleted", 3, isActive: true, softDeleted: true);
        var handler = new GetAllCategoriesAdminQueryHandler(scope.DbContext, scope.Cache);

        var result = await handler.Handle(new GetAllCategoriesAdminQuery(), CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Select(x => x.Name).Should().Equal("Alpha", "Gamma");
        scope.Cache.SetKeys.Should().Contain(CategoryCacheKeys.GetAllAdmin);
    }
}

public class GetCategoriesPagedAdminQueryHandlerTests
{
    [Fact]
    public async Task Handle_should_filter_sort_and_page_admin_categories()
    {
        await using var scope = await CategoryHandlerTestScope.CreateAsync();
        var parent = await scope.SeedCategoryAsync("Parent", "parent", 0);
        await scope.SeedCategoryAsync("Gamma", "gamma", 3, isActive: true, parentId: parent.Id);
        await scope.SeedCategoryAsync("Beta", "beta", 2, isActive: true);
        await scope.SeedCategoryAsync("Alpha", "alpha", 1, isActive: false);
        var handler = new GetCategoriesPagedAdminQueryHandler(scope.DbContext);
        var query = new GetCategoriesPagedAdminQuery
        {
            PagedFilterRequest = new()
            {
                SearchTerm = "a",
                IsActive = true,
                SortBy = "sortorder",
                SortDirection = "desc",
                PageNumber = 1,
                PageSize = 2
            }
        };

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data!.TotalCount.Should().Be(3);
        result.Data.Data.Select(x => x.Name).Should().Equal("Gamma", "Beta");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Roles\RoleHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Roles;
using UMS.Application.Features.Roles.Commands;
using UMS.Application.Features.Roles.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Roles;

public class GetRolesQueryHandlerTests
{
    private readonly Mock<IRoleService> _roleService = new();

    [Fact]
    public async Task Handle_should_return_roles_when_service_finds_matches()
    {
        List<RoleResponse> roles =
        [
            TestData.RoleResponse(1),
            TestData.RoleResponse(2)
        ];
        var expected = ResponseWrapper<List<RoleResponse>>.Success(roles);
        _roleService.Setup(service => service.GetRolesAsync()).ReturnsAsync(expected);
        var handler = new GetRolesQueryHandler(_roleService.Object);

        var result = await handler.Handle(new GetRolesQuery(), CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(roles);
        _roleService.Verify(service => service.GetRolesAsync(), Times.Once);
    }
}

public class GetRoleByIdQueryHandlerTests
{
    private readonly Mock<IRoleService> _roleService = new();

    [Fact]
    public async Task Handle_should_return_role_when_service_finds_match()
    {
        var role = TestData.RoleResponse(15);
        var expected = ResponseWrapper<RoleResponse>.Success(role);
        _roleService.Setup(service => service.GetRoleByIdAsync(role.Id)).ReturnsAsync(expected);
        var handler = new GetRoleByIdQueryHandler(_roleService.Object);

        var result = await handler.Handle(new GetRoleByIdQuery { RoleId = role.Id }, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(role);
        _roleService.Verify(service => service.GetRoleByIdAsync(role.Id), Times.Once);
    }

    [Fact]
    public async Task Handle_should_return_failure_when_service_cannot_find_role()
    {
        const int missingRoleId = 404;
        var expected = ResponseWrapper<RoleResponse>.Fail("Role not found.", 404);
        _roleService.Setup(service => service.GetRoleByIdAsync(missingRoleId)).ReturnsAsync(expected);
        var handler = new GetRoleByIdQueryHandler(_roleService.Object);

        var result = await handler.Handle(new GetRoleByIdQuery { RoleId = missingRoleId }, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Role not found.");
        result.StatusCode.Should().Be(404);
    }
}

public class GetPermissionsQueryHandlerTests
{
    private readonly Mock<IRoleService> _roleService = new();

    [Fact]
    public async Task Handle_should_return_permissions_when_service_finds_match()
    {
        var response = TestData.RoleClaimResponse(7);
        var expected = ResponseWrapper<RoleClaimResponse>.Success(response);
        _roleService.Setup(service => service.GetPermissionsAsync(7)).ReturnsAsync(expected);
        var handler = new GetPermissionsQueryHandler(_roleService.Object);

        var result = await handler.Handle(new GetPermissionsQuery { RoleId = 7 }, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(response);
        _roleService.Verify(service => service.GetPermissionsAsync(7), Times.Once);
    }
}

public class CreateRoleCommandHandlerTests
{
    private readonly Mock<IRoleService> _roleService = new();

    [Fact]
    public async Task Handle_should_delegate_to_role_service_and_return_success_response()
    {
        var request = TestData.CreateRoleRequest();
        var expected = ResponseWrapper.Success("Role created successfully.");
        _roleService.Setup(service => service.CreateRoleAsync(request)).ReturnsAsync(expected);
        var handler = new CreateRoleCommandHandler(_roleService.Object);

        var result = await handler.Handle(new CreateRoleCommand { CreateRole = request }, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _roleService.Verify(service => service.CreateRoleAsync(request), Times.Once);
    }
}

public class UpdateRoleCommandHandlerTests
{
    private readonly Mock<IRoleService> _roleService = new();

    [Fact]
    public async Task Handle_should_delegate_to_role_service_and_return_success_response()
    {
        var request = TestData.UpdateRoleRequest();
        var expected = ResponseWrapper.Success("Role updated successfully.");
        _roleService.Setup(service => service.UpdateRoleAsync(request)).ReturnsAsync(expected);
        var handler = new UpdateRoleCommandHandler(_roleService.Object);

        var result = await handler.Handle(new UpdateRoleCommand { UpdateRole = request }, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _roleService.Verify(service => service.UpdateRoleAsync(request), Times.Once);
    }
}

public class DeleteRoleCommandHandlerTests
{
    private readonly Mock<IRoleService> _roleService = new();

    [Fact]
    public async Task Handle_should_delegate_to_role_service_and_return_success_response()
    {
        const int roleId = 9;
        var expected = ResponseWrapper.Success("Role deleted successfully.");
        _roleService.Setup(service => service.DeleteRoleAsync(roleId)).ReturnsAsync(expected);
        var handler = new DeleteRoleCommandHandler(_roleService.Object);

        var result = await handler.Handle(new DeleteRoleCommand { RoleId = roleId }, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _roleService.Verify(service => service.DeleteRoleAsync(roleId), Times.Once);
    }
}

public class UpdateRolePermissionsCommandHandlerTests
{
    private readonly Mock<IRoleService> _roleService = new();

    [Fact]
    public async Task Handle_should_delegate_to_role_service_and_return_success_response()
    {
        var request = TestData.UpdateRoleClaimsRequest();
        var expected = ResponseWrapper.Success("Role permissions updated successfully.");
        _roleService.Setup(service => service.UpdateRolePermissionsAsync(request)).ReturnsAsync(expected);
        var handler = new UpdateRolePermissionsCommandHandler(_roleService.Object);

        var result = await handler.Handle(
            new UpdateRolePermissionsCommand { UpdateRoleClaims = request },
            CancellationToken.None);

        result.Should().BeSameAs(expected);
        _roleService.Verify(service => service.UpdateRolePermissionsAsync(request), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Token\GetRefreshTokenQueryHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Token;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Token;

public class GetRefreshTokenQueryHandlerTests
{
    private readonly Mock<ITokenService> _tokenService = new();

    [Fact]
    public async Task Handle_should_delegate_to_token_service_and_return_success_response()
    {
        var request = TestData.RefreshTokenRequest();
        var query = new GetRefreshTokenQuery { RefreshTokenRequest = request };
        var expected = ResponseWrapper<TokenResponse>.Success(new TokenResponse());

        _tokenService
            .Setup(service => service.GetRefreshTokenAsync(request))
            .ReturnsAsync(expected);

        var handler = new GetRefreshTokenQueryHandler(_tokenService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _tokenService.Verify(service => service.GetRefreshTokenAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_response_without_wrapping_it()
    {
        var request = TestData.RefreshTokenRequest();
        var query = new GetRefreshTokenQuery { RefreshTokenRequest = request };
        var expected = ResponseWrapper<TokenResponse>.Fail("Invalid refresh token.", 401);

        _tokenService
            .Setup(service => service.GetRefreshTokenAsync(request))
            .ReturnsAsync(expected);

        var handler = new GetRefreshTokenQueryHandler(_tokenService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Invalid refresh token.");
        result.StatusCode.Should().Be(401);
        _tokenService.Verify(service => service.GetRefreshTokenAsync(request), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Token\GetTokenQueryHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Token;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Token;

public class GetTokenQueryHandlerTests
{
    private readonly Mock<ITokenService> _tokenService = new();

    [Fact]
    public async Task Handle_should_delegate_to_token_service_and_return_success_response()
    {
        var request = TestData.TokenRequest();
        var query = new GetTokenQuery { TokenRequest = request };
        var expected = ResponseWrapper<TokenResponse>.Success(new TokenResponse());

        _tokenService
            .Setup(service => service.GetTokenAsync(request))
            .ReturnsAsync(expected);

        var handler = new GetTokenQueryHandler(_tokenService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _tokenService.Verify(service => service.GetTokenAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_response_without_wrapping_it()
    {
        var request = TestData.TokenRequest();
        var query = new GetTokenQuery { TokenRequest = request };
        var expected = ResponseWrapper<TokenResponse>.Fail("Invalid credentials.", 401);

        _tokenService
            .Setup(service => service.GetTokenAsync(request))
            .ReturnsAsync(expected);

        var handler = new GetTokenQueryHandler(_tokenService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Invalid credentials.");
        result.StatusCode.Should().Be(401);
        _tokenService.Verify(service => service.GetTokenAsync(request), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Token\LoginWith2FAQueryHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Token;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Features.Token.Queries.LoginWith2FA;

namespace UMS.Application.Tests.Handlers.Token;

public class LoginWith2FAQueryHandlerTests
{
    private readonly Mock<ITokenService> _tokenService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsTokenServiceLoginWith2FAWithCorrectRequest()
    {
        var request = new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = "challenge-token",
            Code = "123456"
        };
        var query = new LoginWith2FAQuery { Request = request };

        _tokenService
            .Setup(s => s.LoginWith2FAAsync(request))
            .ReturnsAsync(ResponseWrapper<TokenResponse>.Success(new TokenResponse()));

        var handler = new LoginWith2FAQueryHandler(_tokenService.Object);
        await handler.Handle(query, CancellationToken.None);

        _tokenService.Verify(s => s.LoginWith2FAAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughServiceResult()
    {
        var request = new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = "challenge-token",
            Code = "123456"
        };
        var query = new LoginWith2FAQuery { Request = request };
        var expected = ResponseWrapper<TokenResponse>.Success(
            new TokenResponse { Token = "jwt", RefreshToken = "rt" });

        _tokenService
            .Setup(s => s.LoginWith2FAAsync(request))
            .ReturnsAsync(expected);

        var handler = new LoginWith2FAQueryHandler(_tokenService.Object);
        var result = await handler.Handle(query, CancellationToken.None);

        result.Should().BeSameAs(expected);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\ChangeUserPasswordCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Interfaces.Common;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class ChangeUserPasswordCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();
    private readonly Mock<ICurrentUserService> _currentUserService = new();

    public ChangeUserPasswordCommandHandlerTests()
    {
        _currentUserService.Setup(s => s.GetUserId()).Returns(42);
    }

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var request = TestData.ChangePasswordRequest();
        var command = new ChangeUserPasswordCommand { ChangePassword = request };
        var expected = ResponseWrapper.Success("Password changed successfully.");

        _userService
            .Setup(service => service.ChangeUserPasswordAsync(42, request))
            .ReturnsAsync(expected);

        var handler = new ChangeUserPasswordCommandHandler(_userService.Object, _currentUserService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(service => service.ChangeUserPasswordAsync(42, request), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_response_without_wrapping_it()
    {
        var request = TestData.ChangePasswordRequest();
        var command = new ChangeUserPasswordCommand { ChangePassword = request };
        var expected = ResponseWrapper.Fail("Current password is incorrect.", 400);

        _userService
            .Setup(service => service.ChangeUserPasswordAsync(42, request))
            .ReturnsAsync(expected);

        var handler = new ChangeUserPasswordCommandHandler(_userService.Object, _currentUserService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Current password is incorrect.");
        result.StatusCode.Should().Be(400);
        _userService.Verify(service => service.ChangeUserPasswordAsync(42, request), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\ChangeUserStatusCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class ChangeUserStatusCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var request = TestData.ChangeUserStatusRequest();
        var command = new ChangeUserStatusCommand { ChangeUserStatus = request };
        var expected = ResponseWrapper.Success("User status updated successfully.");

        _userService
            .Setup(service => service.ChangeUserStatusAsync(request))
            .ReturnsAsync(expected);

        var handler = new ChangeUserStatusCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(service => service.ChangeUserStatusAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_response_without_wrapping_it()
    {
        var request = TestData.ChangeUserStatusRequest();
        var command = new ChangeUserStatusCommand { ChangeUserStatus = request };
        var expected = ResponseWrapper.Fail("User not found.", 404);

        _userService
            .Setup(service => service.ChangeUserStatusAsync(request))
            .ReturnsAsync(expected);

        var handler = new ChangeUserStatusCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User not found.");
        result.StatusCode.Should().Be(404);
        _userService.Verify(service => service.ChangeUserStatusAsync(request), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\ConfirmEmailChangeCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Handlers.Users;

public class ConfirmEmailChangeCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var req = new ConfirmEmailChangeRequest { UserId = 1, NewEmail = "new@test.com", Token = "tok" };
        var command = new ConfirmEmailChangeCommand { ConfirmEmailChange = req };
        var expected = ResponseWrapper.Success("Email changed successfully.");

        _userService.Setup(s => s.ConfirmEmailChangeAsync(1, "new@test.com", "tok")).ReturnsAsync(expected);

        var handler = new ConfirmEmailChangeCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(s => s.ConfirmEmailChangeAsync(1, "new@test.com", "tok"), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_without_wrapping()
    {
        var req = new ConfirmEmailChangeRequest { UserId = 99, NewEmail = "x@x.com", Token = "bad" };
        var command = new ConfirmEmailChangeCommand { ConfirmEmailChange = req };
        var expected = ResponseWrapper.Fail("User does not exist.");

        _userService.Setup(s => s.ConfirmEmailChangeAsync(99, "x@x.com", "bad")).ReturnsAsync(expected);

        var handler = new ConfirmEmailChangeCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User does not exist.");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\ConfirmEmailCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Handlers.Users;

public class ConfirmEmailCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var command = new ConfirmEmailCommand { ConfirmEmail = new ConfirmEmailRequest { UserId = 1, Token = "tok" } };
        var expected = ResponseWrapper.Success("Email confirmed successfully.");

        _userService.Setup(s => s.ConfirmEmailAsync(1, "tok")).ReturnsAsync(expected);

        var handler = new ConfirmEmailCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(s => s.ConfirmEmailAsync(1, "tok"), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_without_wrapping()
    {
        var command = new ConfirmEmailCommand { ConfirmEmail = new ConfirmEmailRequest { UserId = 99, Token = "bad" } };
        var expected = ResponseWrapper.Fail("User does not exist.");

        _userService.Setup(s => s.ConfirmEmailAsync(99, "bad")).ReturnsAsync(expected);

        var handler = new ConfirmEmailCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User does not exist.");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\ConfirmTwoFactorAuthCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands.ConfirmTwoFactorAuth;
using UMS.Application.Features.Users.Models.Requests;

namespace UMS.Application.Tests.Handlers.Users;

public class ConfirmTwoFactorAuthCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsUserServiceConfirmWithCorrectRequest()
    {
        var request = new TwoFactorCodeRequest { Code = "123456" };
        var command = new ConfirmTwoFactorAuthCommand { Request = request };

        _userService
            .Setup(s => s.ConfirmTwoFactorAuthAsync(request))
            .ReturnsAsync(ResponseWrapper.Success("Verification code is valid."));

        var handler = new ConfirmTwoFactorAuthCommandHandler(_userService.Object);
        await handler.Handle(command, CancellationToken.None);

        _userService.Verify(s => s.ConfirmTwoFactorAuthAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughServiceResult()
    {
        var request = new TwoFactorCodeRequest { Code = "123456" };
        var command = new ConfirmTwoFactorAuthCommand { Request = request };
        var expected = ResponseWrapper.Success("Verification code is valid.");

        _userService
            .Setup(s => s.ConfirmTwoFactorAuthAsync(request))
            .ReturnsAsync(expected);

        var handler = new ConfirmTwoFactorAuthCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\DisableTwoFactorAuthCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;

namespace UMS.Application.Tests.Handlers.Users;

public class DisableTwoFactorAuthCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsUserServiceDisableWithCorrectRequest()
    {
        var request = new DisableTwoFactorAuthRequest { Password = "Pass@123" };
        var command = new DisableTwoFactorAuthCommand { Request = request };

        _userService
            .Setup(s => s.DisableTwoFactorAuthAsync(request))
            .ReturnsAsync(ResponseWrapper.Success("Two-factor authentication disabled."));

        var handler = new DisableTwoFactorAuthCommandHandler(_userService.Object);
        await handler.Handle(command, CancellationToken.None);

        _userService.Verify(s => s.DisableTwoFactorAuthAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughServiceResult()
    {
        var request = new DisableTwoFactorAuthRequest { Password = "Pass@123" };
        var command = new DisableTwoFactorAuthCommand { Request = request };
        var expected = ResponseWrapper.Success("Two-factor authentication disabled.");

        _userService
            .Setup(s => s.DisableTwoFactorAuthAsync(request))
            .ReturnsAsync(expected);

        var handler = new DisableTwoFactorAuthCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\EnableTwoFactorAuthCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands.EnableTwoFactorAuth;
using UMS.Application.Features.Users.Models.Requests;

namespace UMS.Application.Tests.Handlers.Users;

public class EnableTwoFactorAuthCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsUserServiceEnableWithCorrectRequest()
    {
        var request = new TwoFactorCodeRequest { Code = "123456" };
        var command = new EnableTwoFactorAuthCommand { Request = request };

        _userService
            .Setup(s => s.EnableTwoFactorAuthAsync(request))
            .ReturnsAsync(ResponseWrapper<List<string>>.Success(["code1", "code2"], "Enabled."));

        var handler = new EnableTwoFactorAuthCommandHandler(_userService.Object);
        await handler.Handle(command, CancellationToken.None);

        _userService.Verify(s => s.EnableTwoFactorAuthAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughRecoveryCodesList()
    {
        var codes = Enumerable.Range(1, 10).Select(i => $"code-{i}").ToList();
        var request = new TwoFactorCodeRequest { Code = "123456" };
        var command = new EnableTwoFactorAuthCommand { Request = request };
        var expected = ResponseWrapper<List<string>>.Success(codes, "Enabled.");

        _userService
            .Setup(s => s.EnableTwoFactorAuthAsync(request))
            .ReturnsAsync(expected);

        var handler = new EnableTwoFactorAuthCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        result.Data.Should().HaveCount(10);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\ForgotPasswordCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Handlers.Users;

public class ForgotPasswordCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        const string email = "user@example.com";
        var command = new ForgotPasswordCommand { Email = email };
        var expected = ResponseWrapper.Success("Password reset link sent.");

        _userService
            .Setup(service => service.ForgotPasswordAsync(email))
            .ReturnsAsync(expected);

        var handler = new ForgotPasswordCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(service => service.ForgotPasswordAsync(email), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_response_without_wrapping_it()
    {
        const string email = "missing@example.com";
        var command = new ForgotPasswordCommand { Email = email };
        var expected = ResponseWrapper.Fail("User not found.", 404);

        _userService
            .Setup(service => service.ForgotPasswordAsync(email))
            .ReturnsAsync(expected);

        var handler = new ForgotPasswordCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User not found.");
        result.StatusCode.Should().Be(404);
        _userService.Verify(service => service.ForgotPasswordAsync(email), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\GenerateChangeEmailTokenCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Handlers.Users;

public class GenerateChangeEmailTokenCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var command = new GenerateChangeEmailTokenCommand { GenerateChangeEmailToken = new GenerateChangeEmailTokenRequest { NewEmail = "new@test.com" } };
        var expected = ResponseWrapper.Success("Email change confirmation sent. Please check your inbox.");

        _userService.Setup(s => s.GenerateChangeEmailTokenAsync("new@test.com")).ReturnsAsync(expected);

        var handler = new GenerateChangeEmailTokenCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(s => s.GenerateChangeEmailTokenAsync("new@test.com"), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_without_wrapping()
    {
        var command = new GenerateChangeEmailTokenCommand { GenerateChangeEmailToken = new GenerateChangeEmailTokenRequest { NewEmail = "same@test.com" } };
        var expected = ResponseWrapper.Fail("New email must be different from your current email.");

        _userService.Setup(s => s.GenerateChangeEmailTokenAsync("same@test.com")).ReturnsAsync(expected);

        var handler = new GenerateChangeEmailTokenCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("New email must be different from your current email.");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\GenerateNew2FARecoveryCodesCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Handlers.Users;

public class GenerateNew2FARecoveryCodesCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_codes()
    {
        var codes = new List<string> { "code1", "code2" };
        var expected = ResponseWrapper<List<string>>.Success(codes, "New recovery codes generated.");

        _userService.Setup(s => s.GenerateNew2FARecoveryCodesAsync()).ReturnsAsync(expected);

        var handler = new GenerateNew2FARecoveryCodesCommandHandler(_userService.Object);
        var result = await handler.Handle(new GenerateNew2FARecoveryCodesCommand(), CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(s => s.GenerateNew2FARecoveryCodesAsync(), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_without_wrapping()
    {
        var expected = ResponseWrapper<List<string>>.Fail("Two-factor authentication is not enabled.");

        _userService.Setup(s => s.GenerateNew2FARecoveryCodesAsync()).ReturnsAsync(expected);

        var handler = new GenerateNew2FARecoveryCodesCommandHandler(_userService.Object);
        var result = await handler.Handle(new GenerateNew2FARecoveryCodesCommand(), CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Two-factor authentication is not enabled.");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\GetMyProfileQueryHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries.GetMyProfile;

namespace UMS.Application.Tests.Handlers.Users;

public class GetMyProfileQueryHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsUserServiceGetMyProfile()
    {
        _userService
            .Setup(s => s.GetMyProfileAsync())
            .ReturnsAsync(ResponseWrapper<ProfileResponse>.Success(new ProfileResponse()));

        var handler = new GetMyProfileQueryHandler(_userService.Object);
        await handler.Handle(new GetMyProfileQuery(), CancellationToken.None);

        _userService.Verify(s => s.GetMyProfileAsync(), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughProfileResult()
    {
        var profile = new ProfileResponse { Id = 1, Email = "user@test.com" };
        var expected = ResponseWrapper<ProfileResponse>.Success(profile);

        _userService
            .Setup(s => s.GetMyProfileAsync())
            .ReturnsAsync(expected);

        var handler = new GetMyProfileQueryHandler(_userService.Object);
        var result = await handler.Handle(new GetMyProfileQuery(), CancellationToken.None);

        result.Should().BeSameAs(expected);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\GetUserByIdQueryHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class GetUserByIdQueryHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_return_user_when_service_finds_match()
    {
        var user = TestData.UserResponse(15);
        var query = new GetUserByIdQuery { UserId = user.Id };
        var expected = ResponseWrapper<UserResponse>.Success(user);

        _userService
            .Setup(service => service.GetUserByIdAsync(user.Id))
            .ReturnsAsync(expected);

        var handler = new GetUserByIdQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(user);
        _userService.Verify(service => service.GetUserByIdAsync(user.Id), Times.Once);
    }

    [Fact]
    public async Task Handle_should_return_failure_when_service_cannot_find_user()
    {
        const int missingUserId = 404;
        var query = new GetUserByIdQuery { UserId = missingUserId };
        var expected = ResponseWrapper<UserResponse>.Fail("User not found.", 404);

        _userService
            .Setup(service => service.GetUserByIdAsync(missingUserId))
            .ReturnsAsync(expected);

        var handler = new GetUserByIdQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User not found.");
        result.StatusCode.Should().Be(404);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\GetUserRolesQueryHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Features.Users.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class GetUserRolesQueryHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_return_user_roles_when_service_finds_matches()
    {
        const int userId = 15;
        List<UserRoleViewModel> roles =
        [
            TestData.UserRoleViewModel("Admin"),
            TestData.UserRoleViewModel("Basic")
        ];
        var query = new GetUserRolesQuery { UserId = userId };
        var expected = ResponseWrapper<List<UserRoleViewModel>>.Success(roles);

        _userService
            .Setup(service => service.GetUserRolesAsync(userId))
            .ReturnsAsync(expected);

        var handler = new GetUserRolesQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(roles);
        _userService.Verify(service => service.GetUserRolesAsync(userId), Times.Once);
    }

    [Fact]
    public async Task Handle_should_return_failure_when_service_cannot_find_roles()
    {
        const int missingUserId = 404;
        var query = new GetUserRolesQuery { UserId = missingUserId };
        var expected = ResponseWrapper<List<UserRoleViewModel>>.Fail("User not found.", 404);

        _userService
            .Setup(service => service.GetUserRolesAsync(missingUserId))
            .ReturnsAsync(expected);

        var handler = new GetUserRolesQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User not found.");
        result.StatusCode.Should().Be(404);
        _userService.Verify(service => service.GetUserRolesAsync(missingUserId), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\GetUsersPagedQueryHandlerTests.cs' @'
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Features.Users.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class GetUsersPagedQueryHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_return_paged_users_when_service_finds_matches()
    {
        var request = TestData.PagedFilterRequest();
        var pagedUsers = PagedResult<UserResponse>.Create(
            [TestData.UserResponse(1), TestData.UserResponse(2)],
            totalCount: 8,
            pageNumber: request.PageNumber,
            pageSize: request.PageSize);
        var query = new GetUsersPagedQuery { PagedFilterRequest = request };
        var expected = ResponseWrapper<PagedResult<UserResponse>>.Success(pagedUsers);

        _userService
            .Setup(service => service.GetUsersPagedQueryAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var handler = new GetUsersPagedQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().BeEquivalentTo(pagedUsers);
        _userService.Verify(service => service.GetUsersPagedQueryAsync(request, CancellationToken.None), Times.Once);
    }

    [Fact]
    public async Task Handle_should_return_failure_when_service_cannot_load_paged_users()
    {
        var request = TestData.PagedFilterRequest();
        var query = new GetUsersPagedQuery { PagedFilterRequest = request };
        var expected = ResponseWrapper<PagedResult<UserResponse>>.Fail("Users not found.", 404);

        _userService
            .Setup(service => service.GetUsersPagedQueryAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var handler = new GetUsersPagedQueryHandler(_userService.Object);

        var result = await handler.Handle(query, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Users not found.");
        result.StatusCode.Should().Be(404);
        _userService.Verify(service => service.GetUsersPagedQueryAsync(request, CancellationToken.None), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\LockUserCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Handlers.Users;

public class LockUserCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var command = new LockUserCommand { LockUser = new LockUserRequest { UserId = 5 } };
        var expected = ResponseWrapper.Success("User locked successfully.");

        _userService.Setup(s => s.LockUserAsync(5)).ReturnsAsync(expected);

        var handler = new LockUserCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(s => s.LockUserAsync(5), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_without_wrapping()
    {
        var command = new LockUserCommand { LockUser = new LockUserRequest { UserId = 99 } };
        var expected = ResponseWrapper.Fail("User does not exist.");

        _userService.Setup(s => s.LockUserAsync(99)).ReturnsAsync(expected);

        var handler = new LockUserCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User does not exist.");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\LogoutCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands.Logout;

namespace UMS.Application.Tests.Handlers.Users;

public class LogoutCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsUserServiceLogoutWithCorrectRequest()
    {
        var request = new LogoutRequest { RefreshToken = "token-abc" };
        var command = new LogoutCommand { Request = request };

        _userService
            .Setup(s => s.LogoutAsync(request))
            .ReturnsAsync(ResponseWrapper.Success("Logged out successfully."));

        var handler = new LogoutCommandHandler(_userService.Object);
        await handler.Handle(command, CancellationToken.None);

        _userService.Verify(s => s.LogoutAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughServiceResult()
    {
        var request = new LogoutRequest { RefreshToken = "token-abc" };
        var command = new LogoutCommand { Request = request };
        var expected = ResponseWrapper.Success("Logged out successfully.");

        _userService
            .Setup(s => s.LogoutAsync(request))
            .ReturnsAsync(expected);

        var handler = new LogoutCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\ResendConfirmationEmailCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Handlers.Users;

public class ResendConfirmationEmailCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var command = new ResendConfirmationEmailCommand { ResendConfirmation = new ResendConfirmationEmailRequest { Email = "user@test.com" } };
        var expected = ResponseWrapper.Success("Confirmation email sent. Please check your inbox.");

        _userService.Setup(s => s.ResendConfirmationEmailAsync("user@test.com")).ReturnsAsync(expected);

        var handler = new ResendConfirmationEmailCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(s => s.ResendConfirmationEmailAsync("user@test.com"), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_without_wrapping()
    {
        var command = new ResendConfirmationEmailCommand { ResendConfirmation = new ResendConfirmationEmailRequest { Email = "missing@test.com" } };
        var expected = ResponseWrapper.Fail("This email doesn't exist.");

        _userService.Setup(s => s.ResendConfirmationEmailAsync("missing@test.com")).ReturnsAsync(expected);

        var handler = new ResendConfirmationEmailCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("This email doesn't exist.");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\ResetPasswordCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class ResetPasswordCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var request = TestData.ResetPasswordRequest();
        var command = new ResetPasswordCommand { ResetPasswordRequest = request };
        var expected = ResponseWrapper.Success("Password reset successfully.");

        _userService
            .Setup(service => service.ResetPasswordAsync(request))
            .ReturnsAsync(expected);

        var handler = new ResetPasswordCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(service => service.ResetPasswordAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_response_without_wrapping_it()
    {
        var request = TestData.ResetPasswordRequest();
        var command = new ResetPasswordCommand { ResetPasswordRequest = request };
        var expected = ResponseWrapper.Fail("Invalid token.", 400);

        _userService
            .Setup(service => service.ResetPasswordAsync(request))
            .ReturnsAsync(expected);

        var handler = new ResetPasswordCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Invalid token.");
        result.StatusCode.Should().Be(400);
        _userService.Verify(service => service.ResetPasswordAsync(request), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\SetupTwoFactorAuthCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands.SetupTwoFactorAuth;
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Tests.Handlers.Users;

public class SetupTwoFactorAuthCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_WhenCalled_CallsUserServiceSetupTwoFactorAuth()
    {
        _userService
            .Setup(s => s.SetupTwoFactorAuthAsync())
            .ReturnsAsync(ResponseWrapper<TwoFactorAuthViewModel>.Success(new TwoFactorAuthViewModel()));

        var handler = new SetupTwoFactorAuthCommandHandler(_userService.Object);
        await handler.Handle(new SetupTwoFactorAuthCommand(), CancellationToken.None);

        _userService.Verify(s => s.SetupTwoFactorAuthAsync(), Times.Once);
    }

    [Fact]
    public async Task Handle_WhenCalled_PassesThroughViewModelResult()
    {
        var vm = new TwoFactorAuthViewModel { KeySecret = "JBSWY3DPEHPK3PXP", CodeQR = "otpauth://..." };
        var expected = ResponseWrapper<TwoFactorAuthViewModel>.Success(vm);

        _userService
            .Setup(s => s.SetupTwoFactorAuthAsync())
            .ReturnsAsync(expected);

        var handler = new SetupTwoFactorAuthCommandHandler(_userService.Object);
        var result = await handler.Handle(new SetupTwoFactorAuthCommand(), CancellationToken.None);

        result.Should().BeSameAs(expected);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\UnlockUserCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Handlers.Users;

public class UnlockUserCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var command = new UnlockUserCommand { UnlockUser = new UnlockUserRequest { UserId = 5 } };
        var expected = ResponseWrapper.Success("User unlocked successfully.");

        _userService.Setup(s => s.UnlockUserAsync(5)).ReturnsAsync(expected);

        var handler = new UnlockUserCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(s => s.UnlockUserAsync(5), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_without_wrapping()
    {
        var command = new UnlockUserCommand { UnlockUser = new UnlockUserRequest { UserId = 99 } };
        var expected = ResponseWrapper.Fail("User does not exist.");

        _userService.Setup(s => s.UnlockUserAsync(99)).ReturnsAsync(expected);

        var handler = new UnlockUserCommandHandler(_userService.Object);
        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User does not exist.");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\UpdateUserCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class UpdateUserCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var request = TestData.UpdateUserRequest();
        var command = new UpdateUserCommand { UpdateUser = request };
        var expected = ResponseWrapper.Success("User updated successfully.");

        _userService
            .Setup(service => service.UpdateUserAsync(request))
            .ReturnsAsync(expected);

        var handler = new UpdateUserCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(service => service.UpdateUserAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_response_without_wrapping_it()
    {
        var request = TestData.UpdateUserRequest();
        var command = new UpdateUserCommand { UpdateUser = request };
        var expected = ResponseWrapper.Fail("User not found.", 404);

        _userService
            .Setup(service => service.UpdateUserAsync(request))
            .ReturnsAsync(expected);

        var handler = new UpdateUserCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User not found.");
        result.StatusCode.Should().Be(404);
        _userService.Verify(service => service.UpdateUserAsync(request), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\UpdateUserRolesCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class UpdateUserRolesCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var request = TestData.UpdateUserRolesRequest();
        var command = new UpdateUserRolesCommand { UpdateUserRoles = request };
        var expected = ResponseWrapper.Success("User roles updated successfully.");

        _userService
            .Setup(service => service.UpdateUserRolesAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var handler = new UpdateUserRolesCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(service => service.UpdateUserRolesAsync(request, CancellationToken.None), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_response_without_wrapping_it()
    {
        var request = TestData.UpdateUserRolesRequest();
        var command = new UpdateUserRolesCommand { UpdateUserRoles = request };
        var expected = ResponseWrapper.Fail("Role not found.", 404);

        _userService
            .Setup(service => service.UpdateUserRolesAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var handler = new UpdateUserRolesCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Role not found.");
        result.StatusCode.Should().Be(404);
        _userService.Verify(service => service.UpdateUserRolesAsync(request, CancellationToken.None), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Handlers\Users\UserRegistrationCommandHandlerTests.cs' @'
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Handlers.Users;

public class UserRegistrationCommandHandlerTests
{
    private readonly Mock<IUserService> _userService = new();

    [Fact]
    public async Task Handle_should_delegate_to_user_service_and_return_success_response()
    {
        var request = TestData.UserRegistrationRequest();
        var command = new UserRegistrationCommand { UserRegistration = request };
        var expected = ResponseWrapper.Success("User registered successfully.");

        _userService
            .Setup(service => service.RegisterUserAsync(request))
            .ReturnsAsync(expected);

        var handler = new UserRegistrationCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().BeSameAs(expected);
        _userService.Verify(service => service.RegisterUserAsync(request), Times.Once);
    }

    [Fact]
    public async Task Handle_should_propagate_failure_response_without_wrapping_it()
    {
        var request = TestData.UserRegistrationRequest();
        var command = new UserRegistrationCommand { UserRegistration = request };
        var expected = ResponseWrapper.Fail("Email already exists.", 409);

        _userService
            .Setup(service => service.RegisterUserAsync(request))
            .ReturnsAsync(expected);

        var handler = new UserRegistrationCommandHandler(_userService.Object);

        var result = await handler.Handle(command, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("Email already exists.");
        result.StatusCode.Should().Be(409);
        _userService.Verify(service => service.RegisterUserAsync(request), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Support\Categories\CategoryHandlerTestSupport.cs' @'
using System.Text.Json;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using UMS.Application.Interfaces.Common;
using UMS.Domain.Entities;
using UMS.Domain.Interfaces;

namespace UMS.Application.Tests.Support.Categories;

internal sealed class RecordingCacheService : ICacheService
{
    private readonly Dictionary<string, object?> _values = new();

    public List<string> RemovedKeys { get; } = [];
    public List<string> SetKeys { get; } = [];

    public bool TryGet<T>(string cacheKey, out T value)
    {
        if (_values.TryGetValue(cacheKey, out var cached) && cached is T typedValue)
        {
            value = typedValue;
            return true;
        }

        value = default!;
        return false;
    }

    public T Set<T>(string cacheKey, T value)
    {
        _values[cacheKey] = value;
        SetKeys.Add(cacheKey);
        return value;
    }

    public void Remove(string cacheKey)
    {
        _values.Remove(cacheKey);
        RemovedKeys.Add(cacheKey);
    }
}

internal sealed class CategoryHandlerTestDbContext : DbContext, IApplicationDbContext
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

    public CategoryHandlerTestDbContext(DbContextOptions<CategoryHandlerTestDbContext> options)
        : base(options)
    {
    }

    public bool ThrowConcurrencyOnSave { get; set; }

    public DbSet<Category> Categories => Set<Category>();
    public DbSet<AuditTrail> AuditTrails => Set<AuditTrail>();
    public DbSet<LogUserActivity> LogUserActivities => Set<LogUserActivity>();
    public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();

    public Task StartTransaction(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task CommitTransaction(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task RollbackTransaction(CancellationToken cancellationToken = default) => Task.CompletedTask;

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        if (ThrowConcurrencyOnSave)
        {
            ThrowConcurrencyOnSave = false;
            throw new DbUpdateConcurrencyException();
        }

        return base.SaveChangesAsync(cancellationToken);
    }

    public void AddOutboxMessage<TNotification>(TNotification notification) where TNotification : class
    {
        var notificationType = notification.GetType();

        OutboxMessages.Add(new OutboxMessage
        {
            Type = notificationType.AssemblyQualifiedName ?? notificationType.FullName ?? notificationType.Name,
            Payload = JsonSerializer.Serialize(notification, notificationType, SerializerOptions),
            OccurredOnUtc = DateTime.UtcNow
        });
    }

    public void SetOriginalRowVersion<TEntity>(TEntity entity, byte[] rowVersion) where TEntity : class, IDataConcurrency
    {
        Entry(entity).Property(x => x.RowVersion).OriginalValue = rowVersion;
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Category>(builder =>
        {
            builder.ToTable("Categories");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Id).ValueGeneratedOnAdd();
            builder.Property(x => x.Name).IsRequired().HasMaxLength(150);
            builder.Property(x => x.NormalizedName).IsRequired().HasMaxLength(256);
            builder.Property(x => x.Slug).IsRequired().HasMaxLength(250);
            builder.Property(x => x.NormalizedSlug).IsRequired().HasMaxLength(256);
            builder.Property(x => x.RowVersion).IsConcurrencyToken();
            builder.HasIndex(x => x.NormalizedName).IsUnique().HasDatabaseName("UX_Categories_NormalizedName");
            builder.HasIndex(x => x.NormalizedSlug).IsUnique().HasDatabaseName("UX_Categories_NormalizedSlug");
            builder.HasOne(x => x.Parent)
                .WithMany(x => x.Children)
                .HasForeignKey(x => x.ParentId)
                .OnDelete(DeleteBehavior.NoAction);
            builder.HasQueryFilter(x => !x.SoftDeleted);
        });

        modelBuilder.Entity<OutboxMessage>(builder =>
        {
            builder.ToTable("OutboxMessages");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Id).ValueGeneratedOnAdd();
        });
    }
}

internal sealed class CategoryHandlerTestScope : IAsyncDisposable
{
    private readonly SqliteConnection _connection;

    private CategoryHandlerTestScope(SqliteConnection connection, CategoryHandlerTestDbContext dbContext)
    {
        _connection = connection;
        DbContext = dbContext;
        Cache = new RecordingCacheService();
    }

    public CategoryHandlerTestDbContext DbContext { get; }
    public RecordingCacheService Cache { get; }

    public static async Task<CategoryHandlerTestScope> CreateAsync()
    {
        var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync();

        var options = new DbContextOptionsBuilder<CategoryHandlerTestDbContext>()
            .UseSqlite(connection)
            .EnableSensitiveDataLogging()
            .Options;

        var dbContext = new CategoryHandlerTestDbContext(options);
        await dbContext.Database.EnsureCreatedAsync();

        return new CategoryHandlerTestScope(connection, dbContext);
    }

    public async Task<Category> SeedCategoryAsync(
        string name,
        string slug,
        int sortOrder,
        bool isActive = true,
        int? parentId = null,
        bool softDeleted = false,
        byte[]? rowVersion = null)
    {
        var category = new Category
        {
            Name = name,
            Slug = slug,
            NormalizedName = name.Trim().ToUpperInvariant(),
            NormalizedSlug = slug.Trim().ToUpperInvariant(),
            SortOrder = sortOrder,
            IsActive = isActive,
            ParentId = parentId,
            SoftDeleted = softDeleted,
            RowVersion = rowVersion ?? [1]
        };

        DbContext.Categories.Add(category);
        await DbContext.SaveChangesAsync();
        return category;
    }

    public async ValueTask DisposeAsync()
    {
        await DbContext.DisposeAsync();
        await _connection.DisposeAsync();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\UMS.Application.Tests.csproj' @'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="AutoFixture" Version="4.18.1" />
    <PackageReference Include="Bogus" Version="35.6.1" />
    <PackageReference Include="coverlet.collector" Version="6.0.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" Version="8.9.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.6" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="Moq" Version="4.20.72" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <Compile Remove="UnitTest1.cs" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\UMS.Application\UMS.Application.csproj" />
    <ProjectReference Include="..\UMS.Domain\UMS.Domain.csproj" />
  </ItemGroup>

</Project>
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Categories\CreateCategoryCommandValidatorTests.cs' @'
using UMS.Application.Features.Categories.Commands.Create;

namespace UMS.Application.Tests.Validation.Categories;

public class CreateCategoryCommandValidatorTests
{
    private readonly CreateCategoryCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new CreateCategoryCommand("Category", "category", null, true, 1);

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_name_is_missing()
    {
        var command = new CreateCategoryCommand(string.Empty, "category", null, true, 1);

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(CreateCategoryCommand.Name));
    }

    [Fact]
    public void Validate_should_fail_when_parent_id_is_not_positive()
    {
        var command = new CreateCategoryCommand("Category", "category", 0, true, 1);

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(CreateCategoryCommand.ParentId));
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Categories\DeleteCategoryCommandValidatorTests.cs' @'
using UMS.Application.Features.Categories.Commands.Delete;

namespace UMS.Application.Tests.Validation.Categories;

public class DeleteCategoryCommandValidatorTests
{
    private readonly DeleteCategoryCommandValidator _validator = new();

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_should_fail_for_non_positive_category_ids(int categoryId)
    {
        var result = _validator.Validate(new DeleteCategoryCommand(categoryId));

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(DeleteCategoryCommand.Id));
    }

    [Fact]
    public void Validate_should_pass_for_positive_category_id()
    {
        var result = _validator.Validate(new DeleteCategoryCommand(7));

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Categories\GetCategoriesPagedAdminQueryValidatorTests.cs' @'
using UMS.Application.Features.Categories.Queries.GetCategoriesPagedAdmin;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Categories;

public class GetCategoriesPagedAdminQueryValidatorTests
{
    private readonly GetCategoriesPagedAdminQueryValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_supported_sort_field()
    {
        var query = new GetCategoriesPagedAdminQuery
        {
            PagedFilterRequest = TestData.PagedFilterRequest()
        };
        query.PagedFilterRequest.SortBy = "id";

        var result = _validator.Validate(query);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_sort_by_is_not_supported()
    {
        var query = new GetCategoriesPagedAdminQuery
        {
            PagedFilterRequest = TestData.PagedFilterRequest()
        };
        query.PagedFilterRequest.SortBy = "parent";

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "PagedFilterRequest.SortBy");
    }

    [Fact]
    public void Validate_should_fail_when_nested_paged_filter_is_invalid()
    {
        var query = new GetCategoriesPagedAdminQuery
        {
            PagedFilterRequest = TestData.PagedFilterRequest()
        };
        query.PagedFilterRequest.PageNumber = 0;

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "PagedFilterRequest.PageNumber");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Categories\GetCategoriesPagedQueryValidatorTests.cs' @'
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Categories;

public class GetCategoriesPagedQueryValidatorTests
{
    private readonly GetCategoriesPagedQueryValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_supported_sort_field()
    {
        var query = new GetCategoriesPagedQuery
        {
            PagedFilterRequest = TestData.PagedFilterRequest()
        };
        query.PagedFilterRequest.SortBy = "slug";

        var result = _validator.Validate(query);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_sort_by_is_not_supported()
    {
        var query = new GetCategoriesPagedQuery
        {
            PagedFilterRequest = TestData.PagedFilterRequest()
        };
        query.PagedFilterRequest.SortBy = "parent";

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "PagedFilterRequest.SortBy");
    }

    [Fact]
    public void Validate_should_fail_when_nested_paged_filter_is_invalid()
    {
        var query = new GetCategoriesPagedQuery
        {
            PagedFilterRequest = TestData.PagedFilterRequest()
        };
        query.PagedFilterRequest.PageSize = 0;

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "PagedFilterRequest.PageSize");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Categories\GetCategoryByIdAdminQueryValidatorTests.cs' @'
using UMS.Application.Features.Categories.Queries.GetCategoryByIdAdmin;

namespace UMS.Application.Tests.Validation.Categories;

public class GetCategoryByIdAdminQueryValidatorTests
{
    private readonly GetCategoryByIdAdminQueryValidator _validator = new();

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_should_fail_for_non_positive_category_ids(int categoryId)
    {
        var result = _validator.Validate(new GetCategoryByIdAdminQuery(categoryId));

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(GetCategoryByIdAdminQuery.Id));
    }

    [Fact]
    public void Validate_should_pass_for_positive_category_id()
    {
        var result = _validator.Validate(new GetCategoryByIdAdminQuery(7));

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Categories\GetCategoryByIdQueryValidatorTests.cs' @'
using UMS.Application.Features.Categories.Queries.GetCategoryById;

namespace UMS.Application.Tests.Validation.Categories;

public class GetCategoryByIdQueryValidatorTests
{
    private readonly GetCategoryByIdQueryValidator _validator = new();

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_should_fail_for_non_positive_category_ids(int categoryId)
    {
        var result = _validator.Validate(new GetCategoryByIdQuery(categoryId));

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(GetCategoryByIdQuery.Id));
    }

    [Fact]
    public void Validate_should_pass_for_positive_category_id()
    {
        var result = _validator.Validate(new GetCategoryByIdQuery(7));

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Categories\UpdateCategoryCommandValidatorTests.cs' @'
using UMS.Application.Features.Categories.Commands.Update;

namespace UMS.Application.Tests.Validation.Categories;

public class UpdateCategoryCommandValidatorTests
{
    private readonly UpdateCategoryCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new UpdateCategoryCommand(1, "Category", "category", null, true, 1, [1]);

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_category_is_its_own_parent()
    {
        var command = new UpdateCategoryCommand(5, "Category", "category", 5, true, 1, [1]);

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.ErrorMessage == "A category cannot be its own parent.");
    }

    [Fact]
    public void Validate_should_fail_when_row_version_is_missing()
    {
        var command = new UpdateCategoryCommand(1, "Category", "category", null, true, 1, []);

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(UpdateCategoryCommand.RowVersion));
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Roles\CreateRoleCommandValidatorTests.cs' @'
using UMS.Application.Features.Roles.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Roles;

public class CreateRoleCommandValidatorTests
{
    private readonly CreateRoleCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new CreateRoleCommand
        {
            CreateRole = TestData.CreateRoleRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_name_is_missing()
    {
        var request = TestData.CreateRoleRequest();
        request.Name = string.Empty;
        var command = new CreateRoleCommand { CreateRole = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "CreateRole.Name");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Roles\DeleteRoleCommandValidatorTests.cs' @'
using UMS.Application.Features.Roles.Commands;

namespace UMS.Application.Tests.Validation.Roles;

public class DeleteRoleCommandValidatorTests
{
    private readonly DeleteRoleCommandValidator _validator = new();

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_should_fail_for_non_positive_role_ids(int roleId)
    {
        var result = _validator.Validate(new DeleteRoleCommand { RoleId = roleId });

        result.IsValid.Should().BeFalse();
        result.Errors.Select(error => error.ErrorMessage)
            .Should()
            .Contain("Role ID must be greater than 0.");
    }

    [Fact]
    public void Validate_should_pass_for_positive_role_id()
    {
        var result = _validator.Validate(new DeleteRoleCommand { RoleId = 7 });

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Roles\GetPermissionsQueryValidatorTests.cs' @'
using UMS.Application.Features.Roles.Queries;

namespace UMS.Application.Tests.Validation.Roles;

public class GetPermissionsQueryValidatorTests
{
    private readonly GetPermissionsQueryValidator _validator = new();

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_should_fail_for_non_positive_role_ids(int roleId)
    {
        var result = _validator.Validate(new GetPermissionsQuery { RoleId = roleId });

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(GetPermissionsQuery.RoleId));
    }

    [Fact]
    public void Validate_should_pass_for_positive_role_id()
    {
        var result = _validator.Validate(new GetPermissionsQuery { RoleId = 7 });

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Roles\GetRoleByIdQueryValidatorTests.cs' @'
using UMS.Application.Features.Roles.Queries;

namespace UMS.Application.Tests.Validation.Roles;

public class GetRoleByIdQueryValidatorTests
{
    private readonly GetRoleByIdQueryValidator _validator = new();

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_should_fail_for_non_positive_role_ids(int roleId)
    {
        var result = _validator.Validate(new GetRoleByIdQuery { RoleId = roleId });

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(GetRoleByIdQuery.RoleId));
    }

    [Fact]
    public void Validate_should_pass_for_positive_role_id()
    {
        var result = _validator.Validate(new GetRoleByIdQuery { RoleId = 7 });

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Roles\UpdateRoleCommandValidatorTests.cs' @'
using UMS.Application.Features.Roles.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Roles;

public class UpdateRoleCommandValidatorTests
{
    private readonly UpdateRoleCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new UpdateRoleCommand
        {
            UpdateRole = TestData.UpdateRoleRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_role_id_is_missing()
    {
        var request = TestData.UpdateRoleRequest(roleId: 0);
        var command = new UpdateRoleCommand { UpdateRole = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "UpdateRole.RoleId");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Roles\UpdateRolePermissionsCommandValidatorTests.cs' @'
using UMS.Application.Features.Roles.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Roles;

public class UpdateRolePermissionsCommandValidatorTests
{
    private readonly UpdateRolePermissionsCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new UpdateRolePermissionsCommand
        {
            UpdateRoleClaims = TestData.UpdateRoleClaimsRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_role_id_is_not_positive()
    {
        var request = TestData.UpdateRoleClaimsRequest(roleId: 0);
        var command = new UpdateRolePermissionsCommand { UpdateRoleClaims = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "UpdateRoleClaims.RoleId");
    }

    [Fact]
    public void Validate_should_fail_when_role_claim_contains_missing_required_fields()
    {
        var request = TestData.UpdateRoleClaimsRequest();
        request.RoleClaims =
        [
            new() { ClaimType = string.Empty, ClaimValue = string.Empty, Description = string.Empty }
        ];
        var command = new UpdateRolePermissionsCommand { UpdateRoleClaims = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName.StartsWith("UpdateRoleClaims.RoleClaims["));
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Shared\PagedFilterValidatorTests.cs' @'
using UMS.Application.Dtos.Pagination;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Shared;

public class PagedFilterValidatorTests
{
    private readonly PagedFilterValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var request = TestData.PagedFilterRequest();

        var result = _validator.Validate(request);

        result.IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_should_fail_when_page_number_is_not_positive(int pageNumber)
    {
        var request = TestData.PagedFilterRequest();
        request.PageNumber = pageNumber;

        var result = _validator.Validate(request);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(PagedFilterRequest.PageNumber));
    }

    [Theory]
    [InlineData(0)]
    [InlineData(101)]
    public void Validate_should_fail_when_page_size_is_out_of_range(int pageSize)
    {
        var request = TestData.PagedFilterRequest();
        request.PageSize = pageSize;

        var result = _validator.Validate(request);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(PagedFilterRequest.PageSize));
    }

    [Fact]
    public void Validate_should_fail_when_sort_direction_is_invalid()
    {
        var request = TestData.PagedFilterRequest();
        request.SortDirection = "sideways";

        var result = _validator.Validate(request);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(PagedFilterRequest.SortDirection));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData("asc")]
    [InlineData("desc")]
    public void Validate_should_pass_when_sort_direction_is_supported(string? sortDirection)
    {
        var request = TestData.PagedFilterRequest();
        request.SortDirection = sortDirection;

        var result = _validator.Validate(request);

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Token\GetRefreshTokenQueryPipelineTests.cs' @'
using Moq;
using UMS.Application.Behaviors;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Token.Queries;

namespace UMS.Application.Tests.Validation.Token;

public class GetRefreshTokenQueryPipelineTests
{
    [Fact]
    public async Task Handle_should_reject_invalid_refresh_token_query_before_handler_runs()
    {
        var mockFactory = new Mock<IValidationFailureFactory<IResponseWrapper<TokenResponse>>>();
        mockFactory.Setup(f => f.CreateFailure(It.IsAny<IReadOnlyList<string>>(), It.IsAny<int>()))
                   .Returns<IReadOnlyList<string>, int>((msgs, code) => ResponseWrapper<TokenResponse>.Fail(msgs, code));
        var behavior = new ValidationPipelineBehavior<GetRefreshTokenQuery, IResponseWrapper<TokenResponse>>(
            [new GetRefreshTokenQueryValidator()], mockFactory.Object);
        var handlerWasCalled = false;
        var query = new GetRefreshTokenQuery
        {
            RefreshTokenRequest = new RefreshTokenRequest
            {
                Token = string.Empty,
                RefreshToken = string.Empty
            }
        };

        var result = await behavior.Handle(
            query,
            (_, _) =>
            {
                handlerWasCalled = true;
                return new ValueTask<IResponseWrapper<TokenResponse>>(
                    ResponseWrapper<TokenResponse>.Success(new TokenResponse()));
            },
            CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(message => !string.IsNullOrWhiteSpace(message));
        handlerWasCalled.Should().BeFalse();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Token\GetRefreshTokenQueryValidatorTests.cs' @'
using UMS.Application.Features.Token.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Token;

public class GetRefreshTokenQueryValidatorTests
{
    private readonly GetRefreshTokenQueryValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var query = new GetRefreshTokenQuery
        {
            RefreshTokenRequest = TestData.RefreshTokenRequest()
        };

        var result = _validator.Validate(query);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_token_is_missing()
    {
        var request = TestData.RefreshTokenRequest();
        request.Token = string.Empty;
        var query = new GetRefreshTokenQuery { RefreshTokenRequest = request };

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "RefreshTokenRequest.Token");
    }

    [Fact]
    public void Validate_should_fail_when_refresh_token_is_missing()
    {
        var request = TestData.RefreshTokenRequest();
        request.RefreshToken = string.Empty;
        var query = new GetRefreshTokenQuery { RefreshTokenRequest = request };

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "RefreshTokenRequest.RefreshToken");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Token\GetTokenQueryValidatorTests.cs' @'
using UMS.Application.Features.Token.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Token;

public class GetTokenQueryValidatorTests
{
    private readonly GetTokenQueryValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var query = new GetTokenQuery
        {
            TokenRequest = TestData.TokenRequest()
        };

        var result = _validator.Validate(query);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_email_is_invalid()
    {
        var request = TestData.TokenRequest();
        request.Email = "not-an-email";
        var query = new GetTokenQuery { TokenRequest = request };

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "TokenRequest.Email");
    }

    [Fact]
    public void Validate_should_fail_when_password_is_too_short()
    {
        var request = TestData.TokenRequest();
        request.Password = "123";
        var query = new GetTokenQuery { TokenRequest = request };

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "TokenRequest.Password");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Token\LoginWith2FAQueryValidatorTests.cs' @'
using UMS.Application.Features.Token.Queries.LoginWith2FA;

namespace UMS.Application.Tests.Validation.Token;

public class LoginWith2FAQueryValidatorTests
{
    private readonly LoginWith2FAQueryValidator _validator = new();

    [Fact]
    public void Validate_EmptyChallengeToken_ReturnsValidationFailure()
    {
        var command = new LoginWith2FAQuery
        {
            Request = new TwoFactorLoginRequest { TwoFactorChallengeToken = "", Code = "123456" }
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName.Contains("TwoFactorChallengeToken"));
    }

    [Fact]
    public void Validate_EmptyCode_ReturnsValidationFailure()
    {
        var command = new LoginWith2FAQuery
        {
            Request = new TwoFactorLoginRequest { TwoFactorChallengeToken = "challenge-token", Code = "" }
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName.Contains("Code"));
    }

    [Fact]
    public void Validate_BothFieldsPopulated_PassesValidation()
    {
        var command = new LoginWith2FAQuery
        {
            Request = new TwoFactorLoginRequest
            {
                TwoFactorChallengeToken = "valid-challenge-token",
                Code = "123456"
            }
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\ChangeUserPasswordValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class ChangeUserPasswordValidatorTests
{
    private readonly ChangeUserPasswordValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new ChangeUserPasswordCommand
        {
            ChangePassword = TestData.ChangePasswordRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_confirmed_password_does_not_match()
    {
        var request = TestData.ChangePasswordRequest();
        request.ConfirmedNewPassword = "Different@123";
        var command = new ChangeUserPasswordCommand { ChangePassword = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "ChangePassword.ConfirmedNewPassword");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\ChangeUserStatusValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class ChangeUserStatusValidatorTests
{
    private readonly ChangeUserStatusValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new ChangeUserStatusCommand
        {
            ChangeUserStatus = TestData.ChangeUserStatusRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_user_id_is_missing()
    {
        var command = new ChangeUserStatusCommand
        {
            ChangeUserStatus = TestData.ChangeUserStatusRequest(userId: 0)
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "ChangeUserStatus.UserId");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\ConfirmEmailChangeValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class ConfirmEmailChangeValidatorTests
{
    private readonly ConfirmEmailChangeValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new ConfirmEmailChangeCommand
        {
            ConfirmEmailChange = TestData.ConfirmEmailChangeRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_user_id_is_zero()
    {
        var command = new ConfirmEmailChangeCommand
        {
            ConfirmEmailChange = TestData.ConfirmEmailChangeRequest(userId: 0)
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "ConfirmEmailChange.UserId");
    }

    [Fact]
    public void Validate_should_fail_when_new_email_is_empty()
    {
        var request = TestData.ConfirmEmailChangeRequest();
        request.NewEmail = "";
        var command = new ConfirmEmailChangeCommand { ConfirmEmailChange = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "ConfirmEmailChange.NewEmail");
    }

    [Fact]
    public void Validate_should_fail_when_new_email_is_invalid_format()
    {
        var request = TestData.ConfirmEmailChangeRequest();
        request.NewEmail = "not-an-email";
        var command = new ConfirmEmailChangeCommand { ConfirmEmailChange = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "ConfirmEmailChange.NewEmail");
    }

    [Fact]
    public void Validate_should_fail_when_token_is_empty()
    {
        var request = TestData.ConfirmEmailChangeRequest();
        request.Token = "";
        var command = new ConfirmEmailChangeCommand { ConfirmEmailChange = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "ConfirmEmailChange.Token");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\ConfirmEmailValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class ConfirmEmailValidatorTests
{
    private readonly ConfirmEmailValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new ConfirmEmailCommand
        {
            ConfirmEmail = TestData.ConfirmEmailRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_user_id_is_zero()
    {
        var command = new ConfirmEmailCommand
        {
            ConfirmEmail = TestData.ConfirmEmailRequest(userId: 0)
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "ConfirmEmail.UserId");
    }

    [Fact]
    public void Validate_should_fail_when_token_is_empty()
    {
        var command = new ConfirmEmailCommand
        {
            ConfirmEmail = TestData.ConfirmEmailRequest(token: "")
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "ConfirmEmail.Token");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\ConfirmTwoFactorAuthValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands.ConfirmTwoFactorAuth;
using UMS.Application.Features.Users.Models.Requests;

namespace UMS.Application.Tests.Validation.Users;

public class ConfirmTwoFactorAuthValidatorTests
{
    private readonly ConfirmTwoFactorAuthValidator _validator = new();

    [Fact]
    public void Validate_EmptyCode_ReturnsValidationFailure()
    {
        var command = new ConfirmTwoFactorAuthCommand { Request = new TwoFactorCodeRequest { Code = "" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
    }

    [Fact]
    public void Validate_NonNumericCode_ReturnsValidationFailure()
    {
        var command = new ConfirmTwoFactorAuthCommand { Request = new TwoFactorCodeRequest { Code = "abc123" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.ErrorMessage == "Code must be exactly 6 digits.");
    }

    [Fact]
    public void Validate_CodeShorterThanSixDigits_ReturnsValidationFailure()
    {
        var command = new ConfirmTwoFactorAuthCommand { Request = new TwoFactorCodeRequest { Code = "12345" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.ErrorMessage == "Code must be exactly 6 digits.");
    }

    [Fact]
    public void Validate_SixDigitNumericCode_PassesValidation()
    {
        var command = new ConfirmTwoFactorAuthCommand { Request = new TwoFactorCodeRequest { Code = "123456" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\DisableTwoFactorAuthValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;

namespace UMS.Application.Tests.Validation.Users;

public class DisableTwoFactorAuthValidatorTests
{
    private readonly DisableTwoFactorAuthValidator _validator = new();

    [Fact]
    public void Validate_EmptyPassword_ReturnsValidationFailure()
    {
        var command = new DisableTwoFactorAuthCommand
        {
            Request = new DisableTwoFactorAuthRequest { Password = "", Code = null }
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName.Contains("Password"));
    }

    [Fact]
    public void Validate_PasswordPresentAndCodeNull_PassesValidation()
    {
        var command = new DisableTwoFactorAuthCommand
        {
            Request = new DisableTwoFactorAuthRequest { Password = "Pass@123", Code = null }
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_PasswordPresentAndSixDigitCode_PassesValidation()
    {
        var command = new DisableTwoFactorAuthCommand
        {
            Request = new DisableTwoFactorAuthRequest { Password = "Pass@123", Code = "123456" }
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_PasswordPresentAndNonNumericCode_ReturnsValidationFailure()
    {
        var command = new DisableTwoFactorAuthCommand
        {
            Request = new DisableTwoFactorAuthRequest { Password = "Pass@123", Code = "abcdef" }
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.ErrorMessage == "Code must be exactly 6 digits.");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\EnableTwoFactorAuthValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands.EnableTwoFactorAuth;
using UMS.Application.Features.Users.Models.Requests;

namespace UMS.Application.Tests.Validation.Users;

public class EnableTwoFactorAuthValidatorTests
{
    private readonly EnableTwoFactorAuthValidator _validator = new();

    [Fact]
    public void Validate_EmptyCode_ReturnsValidationFailure()
    {
        var command = new EnableTwoFactorAuthCommand { Request = new TwoFactorCodeRequest { Code = "" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
    }

    [Fact]
    public void Validate_NonNumericCode_ReturnsValidationFailure()
    {
        var command = new EnableTwoFactorAuthCommand { Request = new TwoFactorCodeRequest { Code = "abcdef" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.ErrorMessage == "Code must be exactly 6 digits.");
    }

    [Fact]
    public void Validate_CodeShorterThanSixDigits_ReturnsValidationFailure()
    {
        var command = new EnableTwoFactorAuthCommand { Request = new TwoFactorCodeRequest { Code = "12345" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.ErrorMessage == "Code must be exactly 6 digits.");
    }

    [Fact]
    public void Validate_SixDigitNumericCode_PassesValidation()
    {
        var command = new EnableTwoFactorAuthCommand { Request = new TwoFactorCodeRequest { Code = "654321" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\ForgotPasswordCommandValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Validation.Users;

public class ForgotPasswordCommandValidatorTests
{
    private readonly ForgotPasswordCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new ForgotPasswordCommand { Email = "user@example.com" };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_email_is_invalid()
    {
        var command = new ForgotPasswordCommand { Email = "not-an-email" };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(ForgotPasswordCommand.Email));
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\GenerateChangeEmailTokenValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class GenerateChangeEmailTokenValidatorTests
{
    private readonly GenerateChangeEmailTokenValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new GenerateChangeEmailTokenCommand
        {
            GenerateChangeEmailToken = TestData.GenerateChangeEmailTokenRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_new_email_is_empty()
    {
        var command = new GenerateChangeEmailTokenCommand
        {
            GenerateChangeEmailToken = TestData.GenerateChangeEmailTokenRequest(newEmail: "")
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "GenerateChangeEmailToken.NewEmail");
    }

    [Fact]
    public void Validate_should_fail_when_new_email_is_invalid_format()
    {
        var command = new GenerateChangeEmailTokenCommand
        {
            GenerateChangeEmailToken = TestData.GenerateChangeEmailTokenRequest(newEmail: "not-an-email")
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "GenerateChangeEmailToken.NewEmail");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\GetUserByIdQueryValidatorTests.cs' @'
using UMS.Application.Features.Users.Queries;

namespace UMS.Application.Tests.Validation.Users;

public class GetUserByIdQueryValidatorTests
{
    private readonly GetUserByIdQueryValidator _validator = new();

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_should_fail_for_non_positive_ids(int userId)
    {
        var result = _validator.Validate(new GetUserByIdQuery { UserId = userId });

        result.IsValid.Should().BeFalse();
        result.Errors.Select(error => error.ErrorMessage)
            .Should()
            .Contain("UserId must be greater than 0.");
    }

    [Fact]
    public void Validate_should_pass_for_positive_ids()
    {
        var result = _validator.Validate(new GetUserByIdQuery { UserId = 99 });

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\GetUserRolesQueryValidatorTests.cs' @'
using UMS.Application.Features.Users.Queries;

namespace UMS.Application.Tests.Validation.Users;

public class GetUserRolesQueryValidatorTests
{
    private readonly GetUserRolesQueryValidator _validator = new();

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_should_fail_for_non_positive_user_ids(int userId)
    {
        var result = _validator.Validate(new GetUserRolesQuery { UserId = userId });

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == nameof(GetUserRolesQuery.UserId));
    }

    [Fact]
    public void Validate_should_pass_for_positive_user_id()
    {
        var result = _validator.Validate(new GetUserRolesQuery { UserId = 7 });

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\GetUsersPagedQueryValidatorTests.cs' @'
using UMS.Application.Features.Users.Queries;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class GetUsersPagedQueryValidatorTests
{
    private readonly GetUsersPagedQueryValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_supported_sort_field()
    {
        var query = new GetUsersPagedQuery
        {
            PagedFilterRequest = TestData.PagedFilterRequest()
        };
        query.PagedFilterRequest.SortBy = "email";

        var result = _validator.Validate(query);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_sort_field_is_not_supported()
    {
        var query = new GetUsersPagedQuery
        {
            PagedFilterRequest = TestData.PagedFilterRequest()
        };
        query.PagedFilterRequest.SortBy = "phoneNumber";

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "PagedFilterRequest.SortBy");
    }

    [Fact]
    public void Validate_should_fail_when_nested_paged_filter_is_invalid()
    {
        var query = new GetUsersPagedQuery
        {
            PagedFilterRequest = TestData.PagedFilterRequest()
        };
        query.PagedFilterRequest.PageNumber = 0;

        var result = _validator.Validate(query);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "PagedFilterRequest.PageNumber");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\LockUserValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class LockUserValidatorTests
{
    private readonly LockUserValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new LockUserCommand
        {
            LockUser = TestData.LockUserRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_user_id_is_zero()
    {
        var command = new LockUserCommand
        {
            LockUser = TestData.LockUserRequest(userId: 0)
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "LockUser.UserId");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\LogoutCommandValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands.Logout;

namespace UMS.Application.Tests.Validation.Users;

public class LogoutCommandValidatorTests
{
    private readonly LogoutCommandValidator _validator = new();

    [Fact]
    public void Validate_EmptyRefreshToken_ReturnsValidationFailure()
    {
        var command = new LogoutCommand { Request = new LogoutRequest { RefreshToken = "" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName.Contains("RefreshToken"));
    }

    [Fact]
    public void Validate_NonEmptyRefreshToken_PassesValidation()
    {
        var command = new LogoutCommand { Request = new LogoutRequest { RefreshToken = "valid-refresh-token" } };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\ResendConfirmationEmailValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class ResendConfirmationEmailValidatorTests
{
    private readonly ResendConfirmationEmailValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new ResendConfirmationEmailCommand
        {
            ResendConfirmation = TestData.ResendConfirmationEmailRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_email_is_empty()
    {
        var command = new ResendConfirmationEmailCommand
        {
            ResendConfirmation = TestData.ResendConfirmationEmailRequest(email: "")
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "ResendConfirmation.Email");
    }

    [Fact]
    public void Validate_should_fail_when_email_is_invalid_format()
    {
        var command = new ResendConfirmationEmailCommand
        {
            ResendConfirmation = TestData.ResendConfirmationEmailRequest(email: "not-an-email")
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "ResendConfirmation.Email");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\ResetPasswordCommandValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class ResetPasswordCommandValidatorTests
{
    private readonly ResetPasswordCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new ResetPasswordCommand
        {
            ResetPasswordRequest = TestData.ResetPasswordRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_token_is_missing()
    {
        var request = TestData.ResetPasswordRequest();
        request.Token = string.Empty;
        var command = new ResetPasswordCommand { ResetPasswordRequest = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "ResetPasswordRequest.Token");
    }

    [Fact]
    public void Validate_should_fail_when_password_confirmation_does_not_match()
    {
        var request = TestData.ResetPasswordRequest();
        request.ConfirmPassword = "Different@123";
        var command = new ResetPasswordCommand { ResetPasswordRequest = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "ResetPasswordRequest.ConfirmPassword");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\UnlockUserValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class UnlockUserValidatorTests
{
    private readonly UnlockUserValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new UnlockUserCommand
        {
            UnlockUser = TestData.UnlockUserRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_user_id_is_zero()
    {
        var command = new UnlockUserCommand
        {
            UnlockUser = TestData.UnlockUserRequest(userId: 0)
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == "UnlockUser.UserId");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\UpdateUserCommandValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class UpdateUserCommandValidatorTests
{
    private readonly UpdateUserCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new UpdateUserCommand
        {
            UpdateUser = TestData.UpdateUserRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_full_name_is_missing()
    {
        var request = TestData.UpdateUserRequest();
        request.FullName = string.Empty;
        var command = new UpdateUserCommand { UpdateUser = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "UpdateUser.FullName");
    }

    [Fact]
    public void Validate_should_fail_when_phone_number_has_invalid_characters()
    {
        var request = TestData.UpdateUserRequest();
        request.PhoneNumber = "01012ABC678";
        var command = new UpdateUserCommand { UpdateUser = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "UpdateUser.PhoneNumber");
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\UpdateUserRolesCommandPipelineTests.cs' @'
using Moq;
using UMS.Application.Behaviors;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users.Commands;

namespace UMS.Application.Tests.Validation.Users;

public class UpdateUserRolesCommandPipelineTests
{
    [Fact]
    public async Task Handle_should_reject_invalid_update_user_roles_command_before_handler_runs()
    {
        var mockFactory = new Mock<IValidationFailureFactory<IResponseWrapper>>();
        mockFactory.Setup(f => f.CreateFailure(It.IsAny<IReadOnlyList<string>>(), It.IsAny<int>()))
                   .Returns<IReadOnlyList<string>, int>((msgs, code) => ResponseWrapper.Fail(msgs, code));
        var behavior = new ValidationPipelineBehavior<UpdateUserRolesCommand, IResponseWrapper>(
            [new UpdateUserRolesCommandValidator()], mockFactory.Object);
        var handlerWasCalled = false;
        var command = new UpdateUserRolesCommand
        {
            UpdateUserRoles = new UpdateUserRolesRequest
            {
                UserId = 0,
                Roles = []
            }
        };

        var result = await behavior.Handle(
            command,
            (_, _) =>
            {
                handlerWasCalled = true;
                return new ValueTask<IResponseWrapper>(ResponseWrapper.Success("Handler reached."));
            },
            CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain("User ID is required.");
        result.Messages.Should().Contain("At least one role must be assigned.");
        handlerWasCalled.Should().BeFalse();
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\UpdateUserRolesCommandValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class UpdateUserRolesCommandValidatorTests
{
    private readonly UpdateUserRolesCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new UpdateUserRolesCommand
        {
            UpdateUserRoles = TestData.UpdateUserRolesRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_roles_are_empty()
    {
        var request = TestData.UpdateUserRolesRequest();
        request.Roles = [];
        var command = new UpdateUserRolesCommand { UpdateUserRoles = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName == "UpdateUserRoles.Roles");
    }

    [Fact]
    public void Validate_should_fail_when_a_role_name_is_empty()
    {
        var request = TestData.UpdateUserRolesRequest();
        request.Roles = ["Admin", string.Empty];
        var command = new UpdateUserRolesCommand { UpdateUserRoles = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error => error.PropertyName.StartsWith("UpdateUserRoles.Roles["));
    }
}
'@
    Write-TemplateFile 'UMS.Application.Tests\Validation\Users\UserRegistrationCommandValidatorTests.cs' @'
using UMS.Application.Features.Users.Commands;
using UMS.Application.Tests.Fixtures;

namespace UMS.Application.Tests.Validation.Users;

public class UserRegistrationCommandValidatorTests
{
    private readonly UserRegistrationCommandValidator _validator = new();

    [Fact]
    public void Validate_should_pass_for_well_formed_request()
    {
        var command = new UserRegistrationCommand
        {
            UserRegistration = TestData.UserRegistrationRequest()
        };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public void Validate_should_fail_when_password_confirmation_does_not_match()
    {
        var request = TestData.UserRegistrationRequest();
        request.ConfirmPassword = "Different@123";

        var command = new UserRegistrationCommand { UserRegistration = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Select(error => error.ErrorMessage)
            .Should()
            .Contain("Passwords do not match.");
    }

    [Fact]
    public void Validate_should_fail_when_email_is_invalid()
    {
        var request = TestData.UserRegistrationRequest();
        request.Email = "not-an-email";

        var command = new UserRegistrationCommand { UserRegistration = request };

        var result = _validator.Validate(command);

        result.IsValid.Should().BeFalse();
        result.Errors.Select(error => error.ErrorMessage)
            .Should()
            .Contain("Invalid email format.");
    }
}
'@
    Write-TemplateFile 'UMS.Application\Authorization\AppPermissions.cs' @'
using System.Collections.ObjectModel;

namespace UMS.Application.Authorization
{
    public static class AppAction
    {
        public const string Create = nameof(Create);
        public const string Read = nameof(Read);
        public const string Update = nameof(Update);
        public const string Delete = nameof(Delete);
        public const string Lock        = nameof(Lock);
        public const string Unlock      = nameof(Unlock);
        public const string ChangeEmail = nameof(ChangeEmail);
        public const string Manage2FA   = nameof(Manage2FA);
    }

    public static class AppFeature
    {
        public const string Users = nameof(Users);
        public const string Roles = nameof(Roles);
        public const string UserRoles = nameof(UserRoles);
        public const string RoleClaims = nameof(RoleClaims);
        public const string Menus = nameof(Menus);
        public const string Categories = nameof(Categories);
    }

    public static class AppService
    {
        public const string Identity = nameof(Identity);
        public const string Product = nameof(Product);
        public const string Website = nameof(Website);
    }

    public record AppPermission(string Service, string Feature, string Action, string Description, bool IsBasic = false)
    {
        public string Name => NameFor(Service, Feature, Action);

        public static string NameFor(string service, string feature, string action)
        {
            return $"Permission.{service}.{feature}.{action}";
        }
    }

    public static class AppPermissions
    {
        private static readonly AppPermission[] All =
        [
            new(AppService.Identity, AppFeature.Users, AppAction.Create, "Create Users"),
            new(AppService.Identity, AppFeature.Users, AppAction.Read, "Read Users"),
            new(AppService.Identity, AppFeature.Users, AppAction.Update, "Update Users"),
            new(AppService.Identity, AppFeature.Users, AppAction.Delete, "Delete Users"),
            new(AppService.Identity, AppFeature.Roles, AppAction.Create, "Create Roles"),
            new(AppService.Identity, AppFeature.Roles, AppAction.Read, "Read Roles"),
            new(AppService.Identity, AppFeature.Roles, AppAction.Update, "Update Roles"),
            new(AppService.Identity, AppFeature.Roles, AppAction.Delete, "Delete Roles"),
            new(AppService.Identity, AppFeature.UserRoles, AppAction.Read, "Read User Roles"),
            new(AppService.Identity, AppFeature.UserRoles, AppAction.Update, "Update User Roles"),
            new(AppService.Identity, AppFeature.RoleClaims, AppAction.Read, "Read Role Claims/Permissions"),
            new(AppService.Identity, AppFeature.RoleClaims, AppAction.Update, "Update Role Claims/Permissions"),
            new(AppService.Product, AppFeature.Categories, AppAction.Create, "Create Categories"),
            new(AppService.Product, AppFeature.Categories, AppAction.Read, "Read Categories", IsBasic: true),
            new(AppService.Product, AppFeature.Categories, AppAction.Update, "Update Categories"),
            new(AppService.Product, AppFeature.Categories, AppAction.Delete, "Delete Categories"),
            new(AppService.Identity, AppFeature.Users, AppAction.Lock,        "Lock Users"),
            new(AppService.Identity, AppFeature.Users, AppAction.Unlock,      "Unlock Users"),
            new(AppService.Identity, AppFeature.Users, AppAction.ChangeEmail, "Change User Email", IsBasic: true),
            new(AppService.Identity, AppFeature.Users, AppAction.Manage2FA,   "Manage User 2FA",   IsBasic: true),
        ];

        public static IReadOnlyList<AppPermission> AllPermissions { get; } =
            new ReadOnlyCollection<AppPermission>(All);

        public static IReadOnlyList<AppPermission> AdminPermissions { get; } =
            new ReadOnlyCollection<AppPermission>(All.Where(p => !p.IsBasic).ToArray());

        public static IReadOnlyList<AppPermission> BasicPermissions { get; } =
            new ReadOnlyCollection<AppPermission>(All.Where(p => p.IsBasic).ToArray());
    }
}
'@
    Write-TemplateFile 'UMS.Application\Behaviors\IValidationFailureFactory.cs' @'
namespace UMS.Application.Behaviors
{
    public interface IValidationFailureFactory<TResponse>
    {
        TResponse CreateFailure(IReadOnlyList<string> errors, int statusCode);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Behaviors\ValidationFailureFactory.cs' @'
using System.Reflection;
using UMS.Application.Dtos.Wrappers;

namespace UMS.Application.Behaviors
{
    internal sealed class ValidationFailureFactory<TResponse> : IValidationFailureFactory<TResponse>
    {
        // Reflection runs exactly once per TResponse type (at class initialization), not per request.
        private static readonly Func<IReadOnlyList<string>, int, TResponse> _create = BuildFactory();

        public TResponse CreateFailure(IReadOnlyList<string> errors, int statusCode)
            => _create(errors, statusCode);

        private static Func<IReadOnlyList<string>, int, TResponse> BuildFactory()
        {
            if (typeof(TResponse).IsGenericType &&
                typeof(TResponse).GetGenericTypeDefinition() == typeof(IResponseWrapper<>))
            {
                var dataType = typeof(TResponse).GetGenericArguments()[0];
                var wrapperType = typeof(ResponseWrapper<>).MakeGenericType(dataType);
                var failMethod = wrapperType.GetMethod(
                    nameof(ResponseWrapper<object>.Fail),
                    BindingFlags.Public | BindingFlags.Static,
                    [typeof(IReadOnlyList<string>), typeof(int)])!;

                return (errors, statusCode) => (TResponse)failMethod.Invoke(null, [errors, statusCode])!;
            }

            return (errors, statusCode) => (TResponse)ResponseWrapper.Fail(errors, statusCode);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Behaviors\ValidationPipelineBehavior.cs' @'
namespace UMS.Application.Behaviors
{
    internal class ValidationPipelineBehavior<TRequest, TResponse>
        : IPipelineBehavior<TRequest, TResponse>
        where TRequest : IRequest<TResponse>, IValidateMe
    {
        private readonly IEnumerable<IValidator<TRequest>> _validators;
        private readonly IValidationFailureFactory<TResponse> _failureFactory;

        public ValidationPipelineBehavior(
            IEnumerable<IValidator<TRequest>> validators,
            IValidationFailureFactory<TResponse> failureFactory)
        {
            _validators = validators;
            _failureFactory = failureFactory;
        }

        public async ValueTask<TResponse> Handle(
            TRequest request,
            MessageHandlerDelegate<TRequest, TResponse> next,
            CancellationToken cancellationToken)
        {
            if (_validators.Any())
            {
                var context = new ValidationContext<TRequest>(request);
                var validationResults = await Task
                    .WhenAll(_validators.Select(vr => vr.ValidateAsync(context, cancellationToken)));

                var failures = validationResults.SelectMany(vr => vr.Errors)
                    .Where(f => f != null)
                    .ToList();

                if (failures.Count > 0)
                {
                    var errorMessages = failures.Select(f => f.ErrorMessage).ToList();
                    return _failureFactory.CreateFailure(errorMessages, 400);
                }
            }

            return await next(request, cancellationToken);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Cache\CacheConfiguration.cs' @'
namespace UMS.Application.Dtos.Cache
{
    /// <summary>
    /// Configuration options for in-memory caching behavior.
    /// </summary>
    public class CacheConfiguration
    {
        /// <summary>
        /// Absolute expiration time expressed in hours. Cached entries will be
        /// removed after this many hours regardless of access.
        /// </summary>
        public int AbsoluteExpirationInHours { get; set; }

        /// <summary>
        /// Sliding expiration interval expressed in minutes. Each access to a cached
        /// entry will renew its lifetime by this amount.
        /// </summary>
        public int SlidingExpirationInMinutes { get; set; }

    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Common\FileData.cs' @'
namespace UMS.Application.Dtos.Common
{
    public class FileData
    {
        public Stream Content { get; set; } = Stream.Null;
        public string FileName { get; set; } = string.Empty;
        public string ContentType { get; set; } = string.Empty;
        public long Length { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Common\SD.cs' @'
namespace UMS.Application.Dtos.Common
{
    /// <summary>
    /// Static definitions and commonly used constants across the application models.
    /// </summary>
    public class SD
    {

        /// <summary>
        /// Generic error message used when an unexpected error occurs.
        /// </summary>
        public static string ErrorOccured = "An error occured. Please try again later.";
    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Email\EmailConfiguration.cs' @'
namespace UMS.Application.Dtos.Email
{
    /// <summary>
    /// Configuration options for SMTP email sending.
    /// </summary>
    public class EmailConfiguration
    {
        /// <summary>
        /// SMTP port to connect to.
        /// </summary>
        public int Port { get; set; }

        /// <summary>
        /// SMTP host name or IP address.
        /// </summary>
        public string Host { get; set; } = string.Empty;

        /// <summary>
        /// The sender email address used for authentication.
        /// </summary>
        public string Email { get; set; } = string.Empty;

        /// <summary>
        /// Password used to authenticate with the SMTP server.
        /// </summary>
        public string Password { get; set; } = string.Empty;

        /// <summary>
        /// Display name for the sender.
        /// </summary>
        public string DisplayName { get; set; } = string.Empty;

        /// <summary>
        /// Whether to enable SSL/TLS when connecting to SMTP.
        /// </summary>
        public bool EnableSsl { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Email\SendEmailDto.cs' @'
using UMS.Application.Dtos.Common;

namespace UMS.Application.Dtos.Email
{
    public class SendEmailDto
    {
        public string MailTo { get; set; } = string.Empty;

        public string Subject { get; set; } = string.Empty;

        public string MessageBody { get; set; } = string.Empty;

        public IList<FileData> Attachments { get; set; } = new List<FileData>();

        public IEnumerable<string> ToEmails { get; set; } = new List<string>();

        public IEnumerable<string> EmailCC { get; set; } = new List<string>();

        public IEnumerable<string> EmailBCC { get; set; } = new List<string>();

        public string Priority { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\JWT\JwtConfiguration.cs' @'
namespace UMS.Application.Dtos.JWT
{
    /// <summary>
    /// JWT configuration options used to generate and validate tokens.
    /// </summary>
    public class JwtConfiguration
    {
        /// <summary>
        /// Token issuer.
        /// </summary>
        public string Issuer { get; set; } = string.Empty;

        /// <summary>
        /// Token audience.
        /// </summary>
        public string Audience { get; set; } = string.Empty;

        /// <summary>
        /// Secret signing key for tokens.
        /// </summary>
        public string Secret { get; set; } = string.Empty;

        /// <summary>
        /// Token expiry duration in minutes.
        /// </summary>
        public int TokenExpiryInMinutes { get; set; }

        /// <summary>
        /// Refresh token expiry duration in days.
        /// </summary>
        public int RefreshTokenExpiryInDays { get; set; }

        public int TwoFactorChallengeTokenExpiryInMinutes { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Pagination\PagedFilterRequest.cs' @'
namespace UMS.Application.Dtos.Pagination
{
    /// <summary>
    /// Request model for paged queries. Encapsulates paging, filtering and sorting
    /// parameters sent from clients.
    /// </summary>
    public class PagedFilterRequest
    {
        /// <summary>
        /// The requested page number (1-based). Defaults to 1.
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// The number of items per page. Defaults to 10.
        /// </summary>
        public int PageSize { get; set; } = 10;

        /// <summary>
        /// Optional search term used to filter results.
        /// </summary>
        public string? SearchTerm { get; set; }          // optional search filter

        /// <summary>
        /// Optional field name to sort by.
        /// </summary>
        public string? SortBy { get; set; } = ""; // field name

        /// <summary>
        /// Sort direction: "asc" or "desc". Defaults to "asc".
        /// </summary>
        public string? SortDirection { get; set; } = "asc"; // asc or desc

        /// <summary>
        /// Optional filter for active status.
        /// </summary>
        public bool? IsActive { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Pagination\PagedFilterValidator.cs' @'
namespace UMS.Application.Dtos.Pagination
{
    /// <summary>
    /// Validator for <see cref="PagedFilterRequest"/> ensuring paging and sorting
    /// parameters are within acceptable ranges/values.
    /// </summary>
    public class PagedFilterValidator : AbstractValidator<PagedFilterRequest>
    {
        public PagedFilterValidator()
        {
            RuleFor(x => x.PageNumber)
                .GreaterThan(0)
                .WithMessage("PageNumber must be greater than 0");

            RuleFor(x => x.PageSize)
                .GreaterThan(0)
                .WithMessage("PageSize must be greater than 0")
                .LessThanOrEqualTo(100)
                .WithMessage("PageSize cannot exceed 100");

            RuleFor(x => x.SortDirection)
                .Must(x => string.IsNullOrWhiteSpace(x) || x == "asc" || x == "desc")
                .WithMessage("SortDirection must be 'asc' or 'desc'");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Pagination\PagedResult.cs' @'
namespace UMS.Application.Dtos.Pagination
{
    /// <summary>
    /// Represents a single page of results with pagination metadata.
    /// </summary>
    /// <typeparam name="T">Type of items contained in the page.</typeparam>
    public class PagedResult<T>
    {
        /// <summary>
        /// The items contained in the current page.
        /// </summary>
        public List<T> Data { get; set; } = new();

        /// <summary>
        /// Current page number (1-based).
        /// </summary>
        public int CurrentPage { get; set; }

        /// <summary>
        /// Number of items per page.
        /// </summary>
        public int PageSize { get; set; }

        /// <summary>
        /// Total number of items across all pages.
        /// </summary>
        public int TotalCount { get; set; }

        /// <summary>
        /// Total number of pages calculated from <see cref="TotalCount"/> and <see cref="PageSize"/>.
        /// </summary>
        public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);

        /// <summary>
        /// Indicates whether there is a page before the current page.
        /// </summary>
        public bool HasPreviousPage => CurrentPage > 1;

        /// <summary>
        /// Indicates whether there is a page after the current page.
        /// </summary>
        public bool HasNextPage => CurrentPage < TotalPages;

        /// <summary>
        /// Factory method to create a <see cref="PagedResult{T}"/> instance.
        /// </summary>
        /// <param name="data">Items for the current page.</param>
        /// <param name="totalCount">Total number of items available.</param>
        /// <param name="pageNumber">Current page number (1-based).</param>
        /// <param name="pageSize">Number of items per page.</param>
        /// <returns>A populated <see cref="PagedResult{T}"/> instance.</returns>
        public static PagedResult<T> Create(List<T> data, int totalCount, int pageNumber, int pageSize)
        {
            return new PagedResult<T>
            {
                Data = data,
                TotalCount = totalCount,
                CurrentPage = pageNumber,
                PageSize = pageSize
            };
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\TwoFactor\TwoFactorOptions.cs' @'
namespace UMS.Application.Dtos.TwoFactor;

public class TwoFactorOptions
{
    public string Issuer { get; set; } = string.Empty;
}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Wrappers\IResponseWrapper.cs' @'
namespace UMS.Application.Dtos.Wrappers
{
    public interface IResponseWrapper
    {
        IReadOnlyList<string> Messages { get; }
        bool IsSuccessful { get; }
        int StatusCode { get; } // Added
    }


    public interface IResponseWrapper<out T> : IResponseWrapper
    {
        T Data { get; }
    }


}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Wrappers\ResponseWrapper.cs' @'
namespace UMS.Application.Dtos.Wrappers
{
    public class ResponseWrapper : IResponseWrapper
    {
        public IReadOnlyList<string> Messages { get; init; } = [];
        public bool IsSuccessful { get; init; }
        public int StatusCode { get; init; } = 500;

        #region Fail Synchronously
        public static IResponseWrapper Fail(int statusCode = 500)
        {
            return new ResponseWrapper { IsSuccessful = false, StatusCode = statusCode };
        }

        public static IResponseWrapper Fail(string message, int statusCode = 500)
        {
            return new ResponseWrapper { IsSuccessful = false, Messages = [message], StatusCode = statusCode };
        }

        public static IResponseWrapper Fail(IReadOnlyList<string> messages, int statusCode = 500)
        {
            return new ResponseWrapper { IsSuccessful = false, Messages = messages, StatusCode = statusCode };
        }
        #endregion

        #region Fail Asynchronously
        public static Task<IResponseWrapper> FailAsync(int statusCode = 500)
        {
            return Task.FromResult(Fail(statusCode));
        }

        public static Task<IResponseWrapper> FailAsync(string message, int statusCode = 500)
        {
            return Task.FromResult(Fail(message, statusCode));
        }

        public static Task<IResponseWrapper> FailAsync(IReadOnlyList<string> messages, int statusCode = 500)
        {
            return Task.FromResult(Fail(messages, statusCode));
        }
        #endregion

        #region Success Synchronously
        public static IResponseWrapper Success(int statusCode = 200)
        {
            return new ResponseWrapper { IsSuccessful = true, StatusCode = statusCode };
        }

        public static IResponseWrapper Success(string message, int statusCode = 200)
        {
            return new ResponseWrapper { IsSuccessful = true, Messages = [message], StatusCode = statusCode };
        }

        public static IResponseWrapper Success(IReadOnlyList<string> messages, int statusCode = 200)
        {
            return new ResponseWrapper { IsSuccessful = true, Messages = messages, StatusCode = statusCode };
        }
        #endregion

        #region Success Asynchronously
        public static Task<IResponseWrapper> SuccessAsync(int statusCode = 200)
        {
            return Task.FromResult(Success(statusCode));
        }

        public static Task<IResponseWrapper> SuccessAsync(string message, int statusCode = 200)
        {
            return Task.FromResult(Success(message, statusCode));
        }

        public static Task<IResponseWrapper> SuccessAsync(IReadOnlyList<string> messages, int statusCode = 200)
        {
            return Task.FromResult(Success(messages, statusCode));
        }
        #endregion
    }

    public class ResponseWrapper<T> : IResponseWrapper<T>
    {
        public IReadOnlyList<string> Messages { get; init; } = [];
        public bool IsSuccessful { get; init; }
        public int StatusCode { get; init; } = 500;
        public T Data { get; init; } = default!;

        public ResponseWrapper() { }

        #region Fail Synchronously
        public static IResponseWrapper<T> Fail(int statusCode = 500)
        {
            return new ResponseWrapper<T> { IsSuccessful = false, StatusCode = statusCode };
        }

        public static IResponseWrapper<T> Fail(string message, int statusCode = 500)
        {
            return new ResponseWrapper<T> { IsSuccessful = false, Messages = [message], StatusCode = statusCode };
        }

        public static IResponseWrapper<T> Fail(IReadOnlyList<string> messages, int statusCode = 500)
        {
            return new ResponseWrapper<T> { IsSuccessful = false, Messages = messages, StatusCode = statusCode };
        }
        #endregion

        #region Fail Asynchronously
        public static Task<IResponseWrapper<T>> FailAsync(int statusCode = 500)
        {
            return Task.FromResult(Fail(statusCode));
        }

        public static Task<IResponseWrapper<T>> FailAsync(string message, int statusCode = 500)
        {
            return Task.FromResult(Fail(message, statusCode));
        }

        public static Task<IResponseWrapper<T>> FailAsync(IReadOnlyList<string> messages, int statusCode = 500)
        {
            return Task.FromResult(Fail(messages, statusCode));
        }
        #endregion

        #region Success Synchronously
        public static IResponseWrapper<T> Success(int statusCode = 200)
        {
            return new ResponseWrapper<T> { IsSuccessful = true, StatusCode = statusCode };
        }

        public static IResponseWrapper<T> Success(string message, int statusCode = 200)
        {
            return new ResponseWrapper<T> { IsSuccessful = true, Messages = [message], StatusCode = statusCode };
        }

        public static IResponseWrapper<T> Success(IReadOnlyList<string> messages, int statusCode = 200)
        {
            return new ResponseWrapper<T> { IsSuccessful = true, Messages = messages, StatusCode = statusCode };
        }

        public static IResponseWrapper<T> Success(T data, int statusCode = 200)
        {
            return new ResponseWrapper<T> { Data = data, IsSuccessful = true, StatusCode = statusCode };
        }

        public static IResponseWrapper<T> Success(T data, string message, int statusCode = 200)
        {
            return new ResponseWrapper<T> { Data = data, IsSuccessful = true, Messages = [message], StatusCode = statusCode };
        }

        public static IResponseWrapper<T> Success(T data, IReadOnlyList<string> messages, int statusCode = 200)
        {
            return new ResponseWrapper<T> { Data = data, IsSuccessful = true, Messages = messages, StatusCode = statusCode };
        }
        #endregion

        #region Success Asynchronously
        public static Task<IResponseWrapper<T>> SuccessAsync(int statusCode = 200)
        {
            return Task.FromResult(Success(statusCode));
        }

        public static Task<IResponseWrapper<T>> SuccessAsync(string message, int statusCode = 200)
        {
            return Task.FromResult(Success(message, statusCode));
        }

        public static Task<IResponseWrapper<T>> SuccessAsync(IReadOnlyList<string> messages, int statusCode = 200)
        {
            return Task.FromResult(Success(messages, statusCode));
        }

        public static Task<IResponseWrapper<T>> SuccessAsync(T data, int statusCode = 200)
        {
            return Task.FromResult(Success(data, statusCode));
        }

        public static Task<IResponseWrapper<T>> SuccessAsync(T data, string message, int statusCode = 200)
        {
            return Task.FromResult(Success(data, message, statusCode));
        }

        public static Task<IResponseWrapper<T>> SuccessAsync(T data, IReadOnlyList<string> messages, int statusCode = 200)
        {
            return Task.FromResult(Success(data, messages, statusCode));
        }
        #endregion
    }


}
'@
    Write-TemplateFile 'UMS.Application\Dtos\Wrappers\ResponseWrapperExtension.cs' @'
using System.Text.Json;

namespace UMS.Application.Dtos.Wrappers
{
    public static class ResponseWrapperExtension
    {
        public static async Task<IResponseWrapper<T>> ToResponse<T>(this HttpResponseMessage responseMessage)
        {
            if (!responseMessage.IsSuccessStatusCode)
            {
                var errorContent = await responseMessage.Content.ReadAsStringAsync();
                return ResponseWrapper<T>.Fail(
                    $"Request failed with status code {responseMessage.StatusCode}. Details: {errorContent}",
                    (int)responseMessage.StatusCode);
            }

            var responseAsString = await responseMessage.Content.ReadAsStringAsync();

            if (string.IsNullOrWhiteSpace(responseAsString))
            {
                return ResponseWrapper<T>.Fail("Empty response received from the server.", 204);
            }

            var responseObject = JsonSerializer.Deserialize<ResponseWrapper<T>>(responseAsString,
                new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

            return responseObject ?? ResponseWrapper<T>.Fail("Failed to deserialize response.", 500);
        }

        public static async Task<IResponseWrapper> ToResponse(this HttpResponseMessage responseMessage)
        {
            if (!responseMessage.IsSuccessStatusCode)
            {
                var errorContent = await responseMessage.Content.ReadAsStringAsync();
                return ResponseWrapper.Fail(
                    $"Request failed with status code {responseMessage.StatusCode}. Details: {errorContent}",
                    (int)responseMessage.StatusCode);
            }

            var responseAsString = await responseMessage.Content.ReadAsStringAsync();

            if (string.IsNullOrWhiteSpace(responseAsString))
            {
                return ResponseWrapper.Fail("Empty response received from the server.", 204);
            }

            var responseObject = JsonSerializer.Deserialize<ResponseWrapper>(responseAsString,
                new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

            return responseObject ?? ResponseWrapper.Fail("Failed to deserialize response.", 500);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Enums\AppEnums.cs' @'
namespace UMS.Application.Enums
{
    public class AppEnums
    {

        public enum OperationStatus
        {
            Ok = 1,
            Error = 2,
            ValidationError = 3,
        }

        public enum MsgType
        {
            Success = 1,
            Error = 2,
            Warning = 3,
            Info = 4
        }

        public enum DataOrderDirection
        {
            Asc,
            Desc
        }

      


        #region Custom
        #endregion Custom


    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\CategoryCacheKeys.cs' @'
namespace UMS.Application.Features.Categories
{
    public static class CategoryCacheKeys
    {
        public static string GetAll(bool? isActive) => $"categories:all:{isActive?.ToString().ToLowerInvariant() ?? "null"}";
        public static string GetAllAdmin => "categories:allAdmin";
        public static string GetAllForList => "categories:allForList";

        public static IEnumerable<string> All =>
            new[]
            {
                GetAll(null),
                GetAll(true),
                GetAll(false),
                GetAllAdmin,
                GetAllForList,
            };
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Commands\CategoryWriteGuards.cs' @'
namespace UMS.Application.Features.Categories.Commands;

internal static class CategoryWriteGuards
{
    public static string NormalizeKey(string value) => value.Trim().ToUpperInvariant();

    public static async Task<string?> ValidateParentAssignmentAsync(
        IApplicationDbContext dbContext,
        int? categoryId,
        int? parentId,
        CancellationToken ct)
    {
        if (!parentId.HasValue)
        {
            return null;
        }

        if (categoryId.HasValue && categoryId.Value == parentId.Value)
        {
            return "A category cannot be its own parent.";
        }

        var visited = new HashSet<int>();
        var currentParentId = parentId.Value;

        while (true)
        {
            if (!visited.Add(currentParentId))
            {
                return "Category hierarchy contains a cycle. Please select a valid parent category.";
            }

            if (categoryId.HasValue && currentParentId == categoryId.Value)
            {
                return "A category cannot be assigned to one of its descendants.";
            }

            var parentNode = await dbContext.Categories
                .Where(x => x.Id == currentParentId)
                .Select(x => new { x.Id, x.ParentId })
                .FirstOrDefaultAsync(ct);

            if (parentNode is null)
            {
                return "Selected parent category does not exist.";
            }

            if (!parentNode.ParentId.HasValue)
            {
                return null;
            }

            currentParentId = parentNode.ParentId.Value;
        }
    }

    public static bool IsUniqueConstraintViolation(DbUpdateException exception)
    {
        var dbError = exception.InnerException?.Message ?? exception.Message;

        return dbError.Contains("duplicate key", StringComparison.OrdinalIgnoreCase)
            || dbError.Contains("UNIQUE KEY constraint", StringComparison.OrdinalIgnoreCase)
            || dbError.Contains("unique index", StringComparison.OrdinalIgnoreCase);
    }

    public static string GetUniqueConstraintMessage(DbUpdateException exception)
    {
        var dbError = exception.InnerException?.Message ?? string.Empty;

        if (dbError.Contains("UX_Categories_NormalizedName", StringComparison.OrdinalIgnoreCase))
        {
            return "Category with this name already exists.";
        }

        if (dbError.Contains("UX_Categories_NormalizedSlug", StringComparison.OrdinalIgnoreCase))
        {
            return "Category with this slug already exists.";
        }

        return "Category with the same identity data already exists.";
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Commands\Create\CreateCategoryCommand.cs' @'
using UMS.Application.Features.Categories.Commands;
using UMS.Application.Features.Categories.Events;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Commands.Create
{
    public class CreateCategoryRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Slug { get; set; } = string.Empty;
        public int? ParentId { get; set; }
        public bool IsActive { get; set; }
        public int SortOrder { get; set; }
    }

    public record CreateCategoryCommand(
        string Name,
        string Slug,
        int? ParentId,
        bool IsActive,
        int SortOrder
    ) : IRequest<IResponseWrapper<int>>, IValidateMe;

    public class CreateCategoryCommandHandler(
        IApplicationDbContext applicationDbContext,
        ICacheService cacheService)
       : IRequestHandler<CreateCategoryCommand, IResponseWrapper<int>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
        private readonly ICacheService _cacheService = cacheService;

        public async ValueTask<IResponseWrapper<int>> Handle(CreateCategoryCommand request, CancellationToken ct)
        {
            var normalizedName = CategoryWriteGuards.NormalizeKey(request.Name);
            var normalizedSlug = CategoryWriteGuards.NormalizeKey(request.Slug);

            var parentValidationError = await CategoryWriteGuards.ValidateParentAssignmentAsync(
                _applicationDbContext,
                categoryId: null,
                parentId: request.ParentId,
                ct);

            if (!string.IsNullOrWhiteSpace(parentValidationError))
            {
                return ResponseWrapper<int>.Fail(parentValidationError);
            }

            if (await _applicationDbContext.Categories.AnyAsync(
                    o => o.NormalizedName == normalizedName,
                    ct))
            {
                return ResponseWrapper<int>.Fail("Category with this name already exists.");
            }

            if (await _applicationDbContext.Categories.AnyAsync(
                    o => o.NormalizedSlug == normalizedSlug,
                    ct))
            {
                return ResponseWrapper<int>.Fail("Category with this slug already exists.");
            }

            var category = new Category
            {
                Name = request.Name.Trim(),
                NormalizedName = normalizedName,
                Slug = request.Slug.Trim(),
                NormalizedSlug = normalizedSlug,
                ParentId = request.ParentId,
                IsActive = request.IsActive,
                SortOrder = request.SortOrder,
                RowVersion = [0]
            };

            try
            {
                await _applicationDbContext.Categories.AddAsync(category, ct);
                await _applicationDbContext.SaveChangesAsync(ct);

                _applicationDbContext.AddOutboxMessage(new CategoryCreatedEvent(category.Id));
                await _applicationDbContext.SaveChangesAsync(ct);
            }
            catch (DbUpdateException ex) when (CategoryWriteGuards.IsUniqueConstraintViolation(ex))
            {
                return ResponseWrapper<int>.Fail(CategoryWriteGuards.GetUniqueConstraintMessage(ex));
            }

            foreach (var key in CategoryCacheKeys.All)
            {
                _cacheService.Remove(key);
            }

            return ResponseWrapper<int>.Success(category.Id, "Category created successfully.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Commands\Create\CreateCategoryCommandValidator.cs' @'

namespace UMS.Application.Features.Categories.Commands.Create
{
    public class CreateCategoryCommandValidator : AbstractValidator<CreateCategoryCommand>
    {
        public CreateCategoryCommandValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty()
                .WithMessage("Name is required.")
                .MaximumLength(100)
                .WithMessage("Name cannot exceed 100 characters.");

            RuleFor(x => x.Slug)
                .NotEmpty()
                .WithMessage("Slug is required.")
                .MaximumLength(150)
                .WithMessage("Slug cannot exceed 150 characters.");

            RuleFor(x => x.SortOrder)
                .GreaterThanOrEqualTo(0)
                .WithMessage("SortOrder must be greater than or equal to 0.");

            RuleFor(x => x.ParentId)
                .GreaterThan(0)
                .When(x => x.ParentId.HasValue)
                .WithMessage("Parent category id must be greater than 0.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Commands\Delete\DeleteCategoryCommand.cs' @'
using UMS.Application.Features.Categories.Events;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Commands.Delete
{
    public record DeleteCategoryCommand(int Id) : IRequest<IResponseWrapper>, IValidateMe;

    public class DeleteCategoryCommandHandler(
        IApplicationDbContext applicationDbContext,
        ICacheService cacheService)
       : IRequestHandler<DeleteCategoryCommand, IResponseWrapper>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
        private readonly ICacheService _cacheService = cacheService;

        public async ValueTask<IResponseWrapper> Handle(DeleteCategoryCommand request, CancellationToken ct)
        {
            if (request.Id == 0)
            {
                return ResponseWrapper.Fail("Category Id is required.");
            }

            var category = await _applicationDbContext.Categories.FirstOrDefaultAsync(o => o.Id == request.Id, ct);

            if (category == null)
            {
                return ResponseWrapper.Fail("Category not found.");
            }

            if (await _applicationDbContext.Categories.AnyAsync(o => o.ParentId == request.Id, ct))
            {
                return ResponseWrapper.Fail("Cannot delete category with children.");
            }

            _applicationDbContext.Categories.Remove(category);
            _applicationDbContext.AddOutboxMessage(new CategoryDeletedEvent(request.Id));
            await _applicationDbContext.SaveChangesAsync(ct);

            foreach (var key in CategoryCacheKeys.All)
            {
                _cacheService.Remove(key);
            }

            return ResponseWrapper.Success("Category deleted successfully.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Commands\Delete\DeleteCategoryCommandValidator.cs' @'
using FluentValidation;

namespace UMS.Application.Features.Categories.Commands.Delete
{
    public class DeleteCategoryCommandValidator : AbstractValidator<DeleteCategoryCommand>
    {
        public DeleteCategoryCommandValidator()
        {
            RuleFor(x => x.Id)
                .GreaterThan(0)
                .WithMessage("Category Id must be greater than 0.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Commands\Update\UpdateCategoryCommand.cs' @'
using UMS.Application.Features.Categories.Commands;
using UMS.Application.Features.Categories.Events;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Commands.Update
{
    public record UpdateCategoryCommand(
        int Id,
        string Name,
        string Slug,
        int? ParentId,
        bool IsActive,
        int SortOrder,
        byte[] RowVersion
    ) : IRequest<IResponseWrapper>, IValidateMe;

    public class UpdateCategoryCommandHandler(
        IApplicationDbContext applicationDbContext,
        ICacheService cacheService)
       : IRequestHandler<UpdateCategoryCommand, IResponseWrapper>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
        private readonly ICacheService _cacheService = cacheService;

        public async ValueTask<IResponseWrapper> Handle(UpdateCategoryCommand request, CancellationToken ct)
        {
            var normalizedName = CategoryWriteGuards.NormalizeKey(request.Name);
            var normalizedSlug = CategoryWriteGuards.NormalizeKey(request.Slug);

            var category = await _applicationDbContext.Categories.FirstOrDefaultAsync(o => o.Id == request.Id, ct);

            if (category == null)
            {
                return ResponseWrapper.Fail("Category not found.");
            }

            var parentValidationError = await CategoryWriteGuards.ValidateParentAssignmentAsync(
                _applicationDbContext,
                request.Id,
                request.ParentId,
                ct);

            if (!string.IsNullOrWhiteSpace(parentValidationError))
            {
                return ResponseWrapper.Fail(parentValidationError);
            }

            if (await _applicationDbContext.Categories.AnyAsync(
                    o => o.NormalizedName == normalizedName && o.Id != request.Id,
                    ct))
            {
                return ResponseWrapper.Fail("Category with this name already exists.");
            }

            if (await _applicationDbContext.Categories.AnyAsync(
                    o => o.NormalizedSlug == normalizedSlug && o.Id != request.Id,
                    ct))
            {
                return ResponseWrapper.Fail("Category with this slug already exists.");
            }

            _applicationDbContext.SetOriginalRowVersion(category, request.RowVersion);

            category.Name = request.Name.Trim();
            category.NormalizedName = normalizedName;
            category.Slug = request.Slug.Trim();
            category.NormalizedSlug = normalizedSlug;
            category.ParentId = request.ParentId;
            category.IsActive = request.IsActive;
            category.SortOrder = request.SortOrder;

            try
            {
                _applicationDbContext.Categories.Update(category);
                _applicationDbContext.AddOutboxMessage(new CategoryUpdatedEvent(request.Id));
                await _applicationDbContext.SaveChangesAsync(ct);
            }
            catch (DbUpdateConcurrencyException)
            {
                return ResponseWrapper.Fail(
                    "Concurrency conflict: this category was modified by another user. Refresh and try again.",
                    409);
            }
            catch (DbUpdateException ex) when (CategoryWriteGuards.IsUniqueConstraintViolation(ex))
            {
                return ResponseWrapper.Fail(CategoryWriteGuards.GetUniqueConstraintMessage(ex));
            }

            foreach (var key in CategoryCacheKeys.All)
            {
                _cacheService.Remove(key);
            }

            return ResponseWrapper.Success("Category updated successfully.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Commands\Update\UpdateCategoryCommandValidator.cs' @'

namespace UMS.Application.Features.Categories.Commands.Update
{
    public class UpdateCategoryCommandValidator : AbstractValidator<UpdateCategoryCommand>
    {
        public UpdateCategoryCommandValidator()
        {
            RuleFor(x => x.Id)
                .GreaterThan(0)
                .WithMessage("Valid Category Id is required.");

            RuleFor(x => x.Name)
                .NotEmpty()
                .WithMessage("Name is required.")
                .MaximumLength(100)
                .WithMessage("Name cannot exceed 100 characters.");

            RuleFor(x => x.Slug)
                .NotEmpty()
                .WithMessage("Slug is required.")
                .MaximumLength(150)
                .WithMessage("Slug cannot exceed 150 characters.");

            RuleFor(x => x.SortOrder)
                .GreaterThanOrEqualTo(0)
                .WithMessage("SortOrder must be greater than or equal to 0.");

            RuleFor(x => x.ParentId)
                .GreaterThan(0)
                .When(x => x.ParentId.HasValue)
                .WithMessage("Parent category id must be greater than 0.");

            RuleFor(x => x)
                .Must(x => !x.ParentId.HasValue || x.ParentId.Value != x.Id)
                .WithMessage("A category cannot be its own parent.");

            RuleFor(x => x.RowVersion)
                .NotNull()
                .Must(rowVersion => rowVersion is { Length: > 0 })
                .WithMessage("RowVersion is required for concurrency checks.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Events\CategoryCreatedEvent.cs' @'
using Microsoft.Extensions.Logging;

namespace UMS.Application.Features.Categories.Events
{
    public class CategoryCreatedEvent : INotification
    {
        public CategoryCreatedEvent(int id)
        {
            CategoryId = id;
        }

        public int CategoryId { get; }

    }

    public class CategoryCreatedEventHandler(ILogger<CategoryCreatedEventHandler> logger) : INotificationHandler<CategoryCreatedEvent>
    {
        private readonly ILogger<CategoryCreatedEventHandler> _logger = logger;

        public async ValueTask Handle(CategoryCreatedEvent notification, CancellationToken cancellationToken)
        {
            _logger.LogInformation("CategoryCreatedEvent received for CategoryId {CategoryId}", notification.CategoryId);
            await Task.CompletedTask;
        }
    }



}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Events\CategoryDeletedEvent.cs' @'
using Microsoft.Extensions.Logging;

namespace UMS.Application.Features.Categories.Events
{
    public class CategoryDeletedEvent : INotification
    {
        public CategoryDeletedEvent(int id)
        {
            CategoryId = id;
        }
        public int CategoryId { get; }

    }

    public class CategoryDeletedEventHandler(ILogger<CategoryDeletedEventHandler> logger) : INotificationHandler<CategoryDeletedEvent>
    {
        private readonly ILogger<CategoryDeletedEventHandler> _logger = logger;

        public async ValueTask Handle(CategoryDeletedEvent notification, CancellationToken cancellationToken)
        {
            _logger.LogInformation("CategoryDeletedEvent received for CategoryId {CategoryId}", notification.CategoryId);
            await Task.CompletedTask;
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Events\CategoryUpdatedEvent.cs' @'
using Microsoft.Extensions.Logging;

namespace UMS.Application.Features.Categories.Events
{
    public class CategoryUpdatedEvent : INotification
    {
        public CategoryUpdatedEvent(int id)
        {
            CategoryId = id;
        }
        public int CategoryId { get; }
    }
    public class CategoryUpdatedEventHandler(ILogger<CategoryUpdatedEventHandler> logger) : INotificationHandler<CategoryUpdatedEvent>
    {
        private readonly ILogger<CategoryUpdatedEventHandler> _logger = logger;

        public async ValueTask Handle(CategoryUpdatedEvent notification, CancellationToken cancellationToken)
        {
            _logger.LogInformation("CategoryUpdatedEvent received for CategoryId {CategoryId}", notification.CategoryId);
            await Task.CompletedTask;
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetAllCategories\GetAllCategoriesQuery.cs' @'
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Queries.GetAllCategories
{
    public record CategoryListDto(
      int Id,
      string Name,
      string Slug,
      int? ParentId,
      int SortOrder
  );

    public record GetAllCategoriesQuery(bool? isActive) : IRequest<IResponseWrapper<List<CategoryListDto>>>;

    public class GetAllCategoriesQueryHandler(IApplicationDbContext applicationDbContext, ICacheService cacheService)
        : IRequestHandler<GetAllCategoriesQuery, IResponseWrapper<List<CategoryListDto>>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
        private readonly ICacheService _cacheService = cacheService;
        public async ValueTask<IResponseWrapper<List<CategoryListDto>>> Handle(GetAllCategoriesQuery request, CancellationToken ct)
        {
            var cacheKey = CategoryCacheKeys.GetAll(request.isActive);

            if (_cacheService.TryGet<List<CategoryListDto>>(cacheKey, out var cachedCategories))
            {
                return ResponseWrapper<List<CategoryListDto>>.Success(data: cachedCategories);
            }

            var categories = await _applicationDbContext.Categories
                .AsNoTracking()
                .Where(x => request.isActive == null ||  x.IsActive == request.isActive)
                .OrderBy(x => x.SortOrder)
                .Select(x => new CategoryListDto(
                                     x.Id,
                                     x.Name,
                                     x.Slug,
                                     x.ParentId,
                                      x.SortOrder
                                  ))
                .ToListAsync(ct);

            _cacheService.Set<List<CategoryListDto>>(cacheKey, categories);

            return ResponseWrapper<List<CategoryListDto>>.Success(categories);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetAllCategoriesForList\CategoryLookupDto.cs' @'
namespace UMS.Application.Features.Categories.Queries.GetAllCategoriesForList
{
    public record CategoryLookupDto(int Id, string Name);
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetAllCategoriesForList\GetAllCategoriesForListQuery.cs' @'
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Queries.GetAllCategoriesForList
{
    public record GetAllCategoriesForListQuery : IRequest<IResponseWrapper<List<CategoryLookupDto>>>;

    public class GetAllCategoriesForListQueryHandler(IApplicationDbContext applicationDbContext, ICacheService cacheService) : IRequestHandler<GetAllCategoriesForListQuery, IResponseWrapper<List<CategoryLookupDto>>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
        private readonly ICacheService _cacheService = cacheService;
        public async ValueTask<IResponseWrapper<List<CategoryLookupDto>>> Handle(GetAllCategoriesForListQuery request, CancellationToken cancellationToken)
        {

            if (_cacheService.TryGet<List<CategoryLookupDto>>(CategoryCacheKeys.GetAllForList, out var cachedCategories))
            {
                return ResponseWrapper<List<CategoryLookupDto>>.Success(data: cachedCategories);
            }

            var categories = await _applicationDbContext.Categories
                  .AsNoTracking()
                  .Where(c => c.IsActive)
                  .OrderBy(c => c.SortOrder)
                  .ThenBy(c => c.Name)
                  .Select(c => new CategoryLookupDto(
                      c.Id,
                      c.Name
                  ))
                  .ToListAsync(cancellationToken);

            _cacheService.Set<List<CategoryLookupDto>>(CategoryCacheKeys.GetAllForList, categories);

            return ResponseWrapper<List<CategoryLookupDto>>.Success(categories);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetCategoriesAdmin\GetAllCategoriesAdminQuery.cs' @'
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Queries.GetCategoriesAdmin
{
    public record CategoryListAdminDto(
        int Id,
        string Name,
        string Slug,
        int? ParentId,
        // string? ParentName,
        bool IsActive,
        int SortOrder
    );

    public record GetAllCategoriesAdminQuery : IRequest<IResponseWrapper<List<CategoryListAdminDto>>>;

    public class GetAllCategoriesAdminQueryHandler(IApplicationDbContext applicationDbContext, ICacheService cacheService)
        : IRequestHandler<GetAllCategoriesAdminQuery, IResponseWrapper<List<CategoryListAdminDto>>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;
        private readonly ICacheService _cacheService = cacheService;

        public async ValueTask<IResponseWrapper<List<CategoryListAdminDto>>> Handle(GetAllCategoriesAdminQuery request, CancellationToken ct)
        {
            if (_cacheService.TryGet<List<CategoryListAdminDto>>(CategoryCacheKeys.GetAllAdmin, out var cachedCategories))
            {
                return ResponseWrapper<List<CategoryListAdminDto>>.Success(data: cachedCategories);
            }

            // Admin listing intentionally honors global soft-delete filters.
            var categories = await _applicationDbContext.Categories
                .AsNoTracking()
                .OrderBy(c => c.SortOrder)
                .ThenBy(c => c.Name)
                .Select(c => new CategoryListAdminDto(
                    c.Id,
                    c.Name,
                    c.Slug,
                    c.ParentId,
                    c.IsActive,
                    c.SortOrder
                ))
                .ToListAsync(ct);

            _cacheService.Set<List<CategoryListAdminDto>>(CategoryCacheKeys.GetAllAdmin, categories);

            return ResponseWrapper<List<CategoryListAdminDto>>.Success(categories);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetCategoriesPaged\GetCategoriesPagedQuery.cs' @'
using UMS.Application.Dtos.Pagination;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Queries.GetCategoriesPaged
{
    public record CategoryResponse(
        int Id,
        string Name,
        string Slug,
        int? ParentId,
        int SortOrder
    );

    public class GetCategoriesPagedQuery : IRequest<IResponseWrapper<PagedResult<CategoryResponse>>>, IValidateMe
    {
        public PagedFilterRequest PagedFilterRequest { get; set; } = new();
    }

    public class GetCategoriesPagedQueryHandler(IApplicationDbContext applicationDbContext)
        : IRequestHandler<GetCategoriesPagedQuery, IResponseWrapper<PagedResult<CategoryResponse>>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;

        public async ValueTask<IResponseWrapper<PagedResult<CategoryResponse>>> Handle(GetCategoriesPagedQuery request, CancellationToken ct)
        {
            var pagedFilter = request.PagedFilterRequest;
            var categoriesQuery = _applicationDbContext.Categories
                .AsNoTracking()
                .Where(c => c.IsActive); // Default IsActive = true for frontend

            // 1. Filtering
            if (!string.IsNullOrWhiteSpace(pagedFilter.SearchTerm))
            {
                var term = pagedFilter.SearchTerm.Trim();
                var pattern = $"%{term}%";
                categoriesQuery = categoriesQuery.Where(c =>
                    EF.Functions.Like(c.Name, pattern) ||
                    EF.Functions.Like(c.Slug, pattern));
            }

            // 2. Sorting
            categoriesQuery = pagedFilter.SortBy?.ToLower() switch
            {
                "name" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.Name)
                    : categoriesQuery.OrderBy(c => c.Name),
                "slug" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.Slug)
                    : categoriesQuery.OrderBy(c => c.Slug),
                "sortorder" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.SortOrder)
                    : categoriesQuery.OrderBy(c => c.SortOrder),
                "id" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.Id)
                    : categoriesQuery.OrderBy(c => c.Id),
                _ => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.SortOrder).ThenBy(c => c.Name)
                    : categoriesQuery.OrderBy(c => c.SortOrder).ThenBy(c => c.Name)
            };

            // 3. Pagination
            var totalCount = await categoriesQuery.CountAsync(ct);

            var categories = await categoriesQuery
                .Skip((pagedFilter.PageNumber - 1) * pagedFilter.PageSize)
                .Take(pagedFilter.PageSize)
                .Select(c => new CategoryResponse(
                    c.Id,
                    c.Name,
                    c.Slug,
                    c.ParentId,
                    c.SortOrder
                ))
                .ToListAsync(ct);

            var pagedResult = PagedResult<CategoryResponse>.Create(
                categories,
                totalCount,
                pagedFilter.PageNumber,
                pagedFilter.PageSize);

            return ResponseWrapper<PagedResult<CategoryResponse>>.Success(pagedResult);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetCategoriesPaged\GetCategoriesPagedQueryValidator.cs' @'
using UMS.Application.Dtos.Pagination;
using UMS.Application.Features.Categories.Queries.GetCategoriesPaged;

namespace UMS.Application.Features.Categories.Queries.GetCategoriesPaged
{
    public class GetCategoriesPagedQueryValidator : AbstractValidator<GetCategoriesPagedQuery>
    {
        private static readonly string[] AllowedSortFields = ["name", "slug", "sortorder", "id"];

        public GetCategoriesPagedQueryValidator()
        {
            RuleFor(x => x.PagedFilterRequest)
                .SetValidator(new PagedFilterValidator());

            RuleFor(x => x.PagedFilterRequest.SortBy)
                .Must(sortBy => string.IsNullOrWhiteSpace(sortBy) ||
                                AllowedSortFields.Contains(sortBy.Trim(), StringComparer.OrdinalIgnoreCase))
                .WithMessage("SortBy must be one of: name, slug, sortorder, id.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetCategoriesPagedAdmin\GetCategoriesPagedAdminQuery.cs' @'
using UMS.Application.Dtos.Pagination;
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Categories.Queries.GetCategoriesPagedAdmin
{
    public record CategoryAdminResponse(
        int Id,
        string Name,
        string Slug,
        int? ParentId,
        string? ParentName,
        bool IsActive,
        int SortOrder
    );

    public class GetCategoriesPagedAdminQuery : IRequest<IResponseWrapper<PagedResult<CategoryAdminResponse>>>, IValidateMe
    {
        public PagedFilterRequest PagedFilterRequest { get; set; } = new();
    }

    public class GetCategoriesPagedAdminQueryHandler(IApplicationDbContext applicationDbContext)
        : IRequestHandler<GetCategoriesPagedAdminQuery, IResponseWrapper<PagedResult<CategoryAdminResponse>>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;

        public async ValueTask<IResponseWrapper<PagedResult<CategoryAdminResponse>>> Handle(GetCategoriesPagedAdminQuery request, CancellationToken ct)
        {
            var pagedFilter = request.PagedFilterRequest;
            // Admin listing intentionally honors global soft-delete filters.
            var categoriesQuery = _applicationDbContext.Categories.AsNoTracking();

            // 1. Filtering
            if (!string.IsNullOrWhiteSpace(pagedFilter.SearchTerm))
            {
                var term = pagedFilter.SearchTerm.Trim();
                var pattern = $"%{term}%";
                categoriesQuery = categoriesQuery.Where(c =>
                    EF.Functions.Like(c.Name, pattern) ||
                    EF.Functions.Like(c.Slug, pattern));
            }

            if (pagedFilter.IsActive.HasValue)
            {
                categoriesQuery = categoriesQuery.Where(c => c.IsActive == pagedFilter.IsActive.Value);
            }

            // 2. Sorting
            categoriesQuery = pagedFilter.SortBy?.ToLower() switch
            {
                "name" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.Name)
                    : categoriesQuery.OrderBy(c => c.Name),
                "slug" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.Slug)
                    : categoriesQuery.OrderBy(c => c.Slug),
                "sortorder" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.SortOrder)
                    : categoriesQuery.OrderBy(c => c.SortOrder),
                "id" => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.Id)
                    : categoriesQuery.OrderBy(c => c.Id),
                _ => pagedFilter.SortDirection == "desc"
                    ? categoriesQuery.OrderByDescending(c => c.SortOrder).ThenBy(c => c.Name)
                    : categoriesQuery.OrderBy(c => c.SortOrder).ThenBy(c => c.Name)
            };

            // 3. Pagination
            var totalCount = await categoriesQuery.CountAsync(ct);

            var categories = await categoriesQuery
                .Skip((pagedFilter.PageNumber - 1) * pagedFilter.PageSize)
                .Take(pagedFilter.PageSize)
                .Select(c => new CategoryAdminResponse(
                    c.Id,
                    c.Name,
                    c.Slug,
                    c.ParentId,
                    c.Parent != null ? c.Parent.Name : null,
                    c.IsActive,
                    c.SortOrder
                ))
                .ToListAsync(ct);

            var pagedResult = PagedResult<CategoryAdminResponse>.Create(
                categories,
                totalCount,
                pagedFilter.PageNumber,
                pagedFilter.PageSize);

            return ResponseWrapper<PagedResult<CategoryAdminResponse>>.Success(pagedResult);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetCategoriesPagedAdmin\GetCategoriesPagedAdminQueryValidator.cs' @'
using UMS.Application.Dtos.Pagination;

namespace UMS.Application.Features.Categories.Queries.GetCategoriesPagedAdmin
{
    public class GetCategoriesPagedAdminQueryValidator : AbstractValidator<GetCategoriesPagedAdminQuery>
    {
        private static readonly string[] AllowedSortFields = ["name", "slug", "sortorder", "id"];

        public GetCategoriesPagedAdminQueryValidator()
        {
            RuleFor(x => x.PagedFilterRequest)
                .SetValidator(new PagedFilterValidator());

            RuleFor(x => x.PagedFilterRequest.SortBy)
                .Must(sortBy => string.IsNullOrWhiteSpace(sortBy) ||
                                AllowedSortFields.Contains(sortBy.Trim(), StringComparer.OrdinalIgnoreCase))
                .WithMessage("SortBy must be one of: name, slug, sortorder, id.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetCategoryById\GetCategoryByIdQuery.cs' @'
namespace UMS.Application.Features.Categories.Queries.GetCategoryById
{
    public record CategoryDto(
       int Id,
       string Name,
       string Slug,
       string? ParentName
   );

    public record GetCategoryByIdQuery(int Id) : IRequest<IResponseWrapper<CategoryDto>>, IValidateMe;

    public class GetCategoryByIdQueryHandler(IApplicationDbContext applicationDbContext)
        : IRequestHandler<GetCategoryByIdQuery, IResponseWrapper<CategoryDto>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;

        public async ValueTask<IResponseWrapper<CategoryDto>> Handle(GetCategoryByIdQuery request, CancellationToken ct)
        {
            var categoryDto = await _applicationDbContext.Categories
                                 .AsNoTracking()
                                 .Where(x => x.Id == request.Id && x.IsActive)
                                 .Select(x => new CategoryDto(
                                     x.Id,
                                     x.Name,
                                     x.Slug,
                                     x.Parent != null ? x.Parent.Name : null
                                  ))
                                 .FirstOrDefaultAsync(ct);

            if (categoryDto == null)
            {
                return ResponseWrapper<CategoryDto>.Fail("Category not found.");
            }

            return ResponseWrapper<CategoryDto>.Success(categoryDto);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetCategoryById\GetCategoryByIdQueryValidator.cs' @'
namespace UMS.Application.Features.Categories.Queries.GetCategoryById
{
    public class GetCategoryByIdQueryValidator : AbstractValidator<GetCategoryByIdQuery>
    {
        public GetCategoryByIdQueryValidator()
        {
            RuleFor(x => x.Id)
                .GreaterThan(0)
                .WithMessage("Category ID must be greater than 0.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetCategoryByIdAdmin\GetCategoryByIdAdmin.cs' @'
namespace UMS.Application.Features.Categories.Queries.GetCategoryByIdAdmin
{

    public record CategoryAdminDto(
       int Id,
       string Name,
       string Slug,
       int? ParentId,
       string? ParentName,
       bool IsActive,
       byte[] RowVersion,
       int SortOrder
   );


    public record GetCategoryByIdAdminQuery(int Id) : IRequest<IResponseWrapper<CategoryAdminDto>>, IValidateMe;

    public class GetCategoryByIdAdminQueryHandler(IApplicationDbContext applicationDbContext)
        : IRequestHandler<GetCategoryByIdAdminQuery, IResponseWrapper<CategoryAdminDto>>
    {
        private readonly IApplicationDbContext _applicationDbContext = applicationDbContext;

        public async ValueTask<IResponseWrapper<CategoryAdminDto>> Handle(GetCategoryByIdAdminQuery request, CancellationToken ct)
        {
            // Admin details intentionally honor global soft-delete filters.
            var categoryDto = await _applicationDbContext.Categories
                                 .AsNoTracking()
                                 .Where(x => x.Id == request.Id)
                                 .Select(x => new CategoryAdminDto(
                                     x.Id,
                                     x.Name,
                                     x.Slug,
                                     x.ParentId,
                                     x.Parent != null ? x.Parent.Name : null,
                                     x.IsActive,
                                     x.RowVersion,
                                     x.SortOrder
                                 ))
                                 .FirstOrDefaultAsync(ct);

            if (categoryDto == null)
            {
                return ResponseWrapper<CategoryAdminDto>.Fail("Category not found or has been deleted.");
            }

            return ResponseWrapper<CategoryAdminDto>.Success(categoryDto);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Categories\Queries\GetCategoryByIdAdmin\GetCategoryByIdAdminQueryValidator.cs' @'
namespace UMS.Application.Features.Categories.Queries.GetCategoryByIdAdmin
{
    public class GetCategoryByIdAdminQueryValidator : AbstractValidator<GetCategoryByIdAdminQuery>
    {
        public GetCategoryByIdAdminQueryValidator()
        {
            RuleFor(x => x.Id)
                .GreaterThan(0)
                .WithMessage("Category ID must be greater than 0.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Commands\CreateRole\CreateRoleCommand.cs' @'
namespace UMS.Application.Features.Roles.Commands
{
    public class CreateRoleRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
    }

    public class CreateRoleCommand : IRequest<IResponseWrapper>, IValidateMe 
    {
        public required CreateRoleRequest CreateRole { get; set; }
    }

    public class CreateRoleCommandHandler : IRequestHandler<CreateRoleCommand, IResponseWrapper>
    {
        private readonly IRoleService _roleService;

        public CreateRoleCommandHandler(IRoleService roleService)
        {
            _roleService = roleService;
        }

        public async ValueTask<IResponseWrapper> Handle(CreateRoleCommand request, CancellationToken ct)
        {
            return await _roleService.CreateRoleAsync(request.CreateRole);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Commands\CreateRole\CreateRoleCommandValidator.cs' @'
namespace UMS.Application.Features.Roles.Commands
{
    public class CreateRoleCommandValidator : AbstractValidator<CreateRoleCommand>
    {
        public CreateRoleCommandValidator()
        {
            RuleFor(x => x.CreateRole.Name)
                .NotEmpty().WithMessage("Name is required.")
                .MaximumLength(100).WithMessage("Name must not exceed 100 characters.");

            RuleFor(x => x.CreateRole.Description)
                .MaximumLength(256).WithMessage("Description must not exceed 256 characters.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Commands\DeleteRole\DeleteRoleCommand.cs' @'
namespace UMS.Application.Features.Roles.Commands
{
    public class DeleteRoleCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public int RoleId { get; set; }
    }

    public class DeleteRoleCommandHandler : IRequestHandler<DeleteRoleCommand, IResponseWrapper>
    {
        private readonly IRoleService _roleService;

        public DeleteRoleCommandHandler(IRoleService roleService)
        {
            _roleService = roleService;
        }

        public async ValueTask<IResponseWrapper> Handle(DeleteRoleCommand request, CancellationToken ct)
        {
            return await _roleService.DeleteRoleAsync(request.RoleId);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Commands\DeleteRole\DeleteRoleCommandValidator.cs' @'
namespace UMS.Application.Features.Roles.Commands
{
    public class DeleteRoleCommandValidator : AbstractValidator<DeleteRoleCommand>
    {
        public DeleteRoleCommandValidator()
        {
            RuleFor(x => x.RoleId)
                .GreaterThan(0)
                .WithMessage("Role ID must be greater than 0.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Commands\UpdateRole\UpdateRoleCommand.cs' @'
namespace UMS.Application.Features.Roles.Commands
{
    public class UpdateRoleRequest
    {
        public int RoleId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
    }

    public class UpdateRoleCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public UpdateRoleRequest UpdateRole { get; set; }
    }

    public class UpdateRoleCommandHandler : IRequestHandler<UpdateRoleCommand, IResponseWrapper>
    {
        private readonly IRoleService _roleService;

        public UpdateRoleCommandHandler(IRoleService roleService)
        {
            _roleService = roleService;
        }

        public async ValueTask<IResponseWrapper> Handle(UpdateRoleCommand request, CancellationToken ct)
        {
            return await _roleService.UpdateRoleAsync(request.UpdateRole);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Commands\UpdateRole\UpdateRoleCommandValidator.cs' @'
namespace UMS.Application.Features.Roles.Commands
{
    public class UpdateRoleCommandValidator : AbstractValidator<UpdateRoleCommand>
    {
        public UpdateRoleCommandValidator()
        {

            RuleFor(x => x.UpdateRole.RoleId)
                .NotEqual(0).WithMessage("RoleId is required.");

            RuleFor(x => x.UpdateRole.Name)
                .NotEmpty().WithMessage("Name is required.")
                .MaximumLength(100).WithMessage("Name must not exceed 100 characters.");

            RuleFor(x => x.UpdateRole.Description)
                .MaximumLength(256).WithMessage("Description must not exceed 256 characters.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Commands\UpdateRolePermissions\UpdateRolePermissionsCommand.cs' @'
namespace UMS.Application.Features.Roles.Commands
{
    public class UpdateRoleClaimsRequest
    {
        public int RoleId { get; set; }
        public List<RoleClaimViewModel>? RoleClaims { get; set; }
    }

    public class UpdateRolePermissionsCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public required UpdateRoleClaimsRequest UpdateRoleClaims { get; set; }
    }

    public class UpdateRolePermissionsCommandHandler : IRequestHandler<UpdateRolePermissionsCommand, IResponseWrapper>
    {
        private readonly IRoleService _roleService;

        public UpdateRolePermissionsCommandHandler(IRoleService roleService)
        {
            _roleService = roleService;
        }

        public async ValueTask<IResponseWrapper> Handle(UpdateRolePermissionsCommand request, CancellationToken ct)
        {
            return await _roleService.UpdateRolePermissionsAsync(request.UpdateRoleClaims);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Commands\UpdateRolePermissions\UpdateRolePermissionsCommandValidator.cs' @'
namespace UMS.Application.Features.Roles.Commands
{
    public class UpdateRolePermissionsCommandValidator : AbstractValidator<UpdateRolePermissionsCommand>
    {
        public UpdateRolePermissionsCommandValidator()
        {

            RuleFor(x => x.UpdateRoleClaims)
                .NotNull().WithMessage("UpdateRoleClaims is required.");

            RuleFor(x => x.UpdateRoleClaims.RoleId)
                .GreaterThan(0).WithMessage("RoleId must be greater than 0.");

            RuleFor(x => x.UpdateRoleClaims.RoleClaims)
                .NotNull().WithMessage("RoleClaims list is required.")
                .Must(list => list.Any()).WithMessage("At least one RoleClaim must be provided.");

            RuleForEach(x => x.UpdateRoleClaims.RoleClaims).ChildRules(claim =>
            {
                claim.RuleFor(c => c.ClaimType)
                    .NotEmpty().WithMessage("ClaimType is required.");

                claim.RuleFor(c => c.ClaimValue)
                    .NotEmpty().WithMessage("ClaimValue is required.");

                claim.RuleFor(c => c.Description)
                    .NotEmpty().WithMessage("Description is required.");

                // Optional: add validation for IsAssignedToRole if needed
            });
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\IRoleService.cs' @'
using UMS.Application.Features.Roles.Commands;

namespace UMS.Application.Features.Roles
{
    public interface IRoleService
    {
        Task<IResponseWrapper> CreateRoleAsync(CreateRoleRequest createRole);
        Task<IResponseWrapper<List<RoleResponse>>> GetRolesAsync( );
        Task<IResponseWrapper> UpdateRoleAsync(UpdateRoleRequest updateRole);
        Task<IResponseWrapper<RoleResponse>> GetRoleByIdAsync(int roleId);
        Task<IResponseWrapper> DeleteRoleAsync(int roleId);
        Task<IResponseWrapper<RoleClaimResponse>> GetPermissionsAsync(int roleId);
        Task<IResponseWrapper> UpdateRolePermissionsAsync(UpdateRoleClaimsRequest updateRoleClaims);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Queries\GetAll\GetRolesQuery.cs' @'
namespace UMS.Application.Features.Roles.Queries
{
    public class GetRolesQuery : IRequest<IResponseWrapper<List<RoleResponse>>>
    {
    }

    public class GetRolesQueryHandler : IRequestHandler<GetRolesQuery, IResponseWrapper<List<RoleResponse>>>
    {
        private readonly IRoleService _roleService;

        public GetRolesQueryHandler(IRoleService roleService)
        {
            _roleService = roleService;
        }

        public async ValueTask<IResponseWrapper<List<RoleResponse>>> Handle(GetRolesQuery request, CancellationToken ct)
        {
            return await _roleService.GetRolesAsync();
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Queries\GetPermissions\GetPermissionsQuery.cs' @'
namespace UMS.Application.Features.Roles.Queries
{
    public class GetPermissionsQuery : IRequest<IResponseWrapper<RoleClaimResponse>>, IValidateMe
    {
        public int RoleId { get; set; }
    }

    public class GetPermissionsQueryHandler : IRequestHandler<GetPermissionsQuery, IResponseWrapper<RoleClaimResponse>>
    {
        private readonly IRoleService _roleService;

        public GetPermissionsQueryHandler(IRoleService roleService)
        {
            _roleService = roleService;
        }

        public async ValueTask<IResponseWrapper<RoleClaimResponse>> Handle(GetPermissionsQuery request, CancellationToken ct)
        {
            return await _roleService.GetPermissionsAsync(request.RoleId);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Queries\GetPermissions\GetPermissionsQueryValidator.cs' @'
namespace UMS.Application.Features.Roles.Queries
{
    public class GetPermissionsQueryValidator : AbstractValidator<GetPermissionsQuery>
    {
        public GetPermissionsQueryValidator()
        {
            RuleFor(x => x.RoleId)
                .GreaterThan(0)
                .WithMessage("Role ID must be greater than 0.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Queries\GetRoleById\GetRoleByIdQuery.cs' @'
namespace UMS.Application.Features.Roles.Queries
{
    public class GetRoleByIdQuery : IRequest<IResponseWrapper<RoleResponse>>, IValidateMe
    {
        public int RoleId { get; set; }
    }

    public class GetRoleByIdQueryHandler : IRequestHandler<GetRoleByIdQuery, IResponseWrapper<RoleResponse>>
    {
        private readonly IRoleService _roleService;

        public GetRoleByIdQueryHandler(IRoleService roleService)
        {
            _roleService = roleService;
        }

        public async ValueTask<IResponseWrapper<RoleResponse>> Handle(GetRoleByIdQuery request, CancellationToken ct)
        {
            return await _roleService.GetRoleByIdAsync(request.RoleId);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\Queries\GetRoleById\GetRoleByIdQueryValidator.cs' @'
namespace UMS.Application.Features.Roles.Queries
{
    public class GetRoleByIdQueryValidator : AbstractValidator<GetRoleByIdQuery>
    {
        public GetRoleByIdQueryValidator()
        {
            RuleFor(x => x.RoleId)
                .GreaterThan(0)
                .WithMessage("Role ID must be greater than 0.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\RoleClaimResponse.cs' @'

namespace UMS.Application.Features.Roles
{
    public class RoleClaimResponse
    {
        public RoleResponse Role { get; set; }
        public List<RoleClaimViewModel> RoleClaims { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\RoleClaimViewModel.cs' @'
namespace UMS.Application.Features.Roles
{
    public class RoleClaimViewModel
    {
        public string ClaimType { get; set; } = string.Empty;
        public string ClaimValue { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Roles\RoleResponse.cs' @'
namespace UMS.Application.Features.Roles
{
    public class RoleResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\ITokenService.cs' @'
using UMS.Application.Features.Token.Queries;
using UMS.Application.Features.Token.Queries.LoginWith2FA;

namespace UMS.Application.Features.Token
{
    public interface ITokenService
    {
        Task<IResponseWrapper<TokenResponse>> GetTokenAsync(TokenRequest tokenRequest);
        Task<IResponseWrapper<TokenResponse>> GetRefreshTokenAsync(RefreshTokenRequest refreshTokenRequest);
        Task<IResponseWrapper<TokenResponse>> LoginWith2FAAsync(TwoFactorLoginRequest request, CancellationToken ct = default);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\GetRefreshToken\GetRefreshTokenQuery.cs' @'
namespace UMS.Application.Features.Token.Queries
{
    public class GetRefreshTokenQuery : IRequest<IResponseWrapper<TokenResponse>>, IValidateMe
    {
        public RefreshTokenRequest RefreshTokenRequest { get; set; }
    }

    public class GetRefreshTokenQueryHandler : IRequestHandler<GetRefreshTokenQuery, IResponseWrapper<TokenResponse>>
    {
        private readonly ITokenService _tokenService;

        public GetRefreshTokenQueryHandler(ITokenService tokenService)
        {
            _tokenService = tokenService;
        }

        public async ValueTask<IResponseWrapper<TokenResponse>> Handle(GetRefreshTokenQuery request, CancellationToken ct)
        {
            return await _tokenService.GetRefreshTokenAsync(request.RefreshTokenRequest);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\GetRefreshToken\GetRefreshTokenQueryValidator.cs' @'
using UMS.Application.Features.Token.Queries;

namespace UMS.Application.Features.Token.Queries
{
    public class GetRefreshTokenQueryValidator : AbstractValidator<GetRefreshTokenQuery>
    {
        public GetRefreshTokenQueryValidator()
        {
            RuleFor(u => u.RefreshTokenRequest.Token)
                .NotEmpty();

            RuleFor(u => u.RefreshTokenRequest.RefreshToken)
                .NotEmpty();
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\GetRefreshToken\RefreshTokenRequest.cs' @'
namespace UMS.Application.Features.Token.Queries
{
    public class RefreshTokenRequest
    {
        public string Token { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\GetToken\GetTokenQuery.cs' @'
namespace UMS.Application.Features.Token.Queries
{
    public class GetTokenQuery : IRequest<IResponseWrapper<TokenResponse>>, IValidateMe
    {
        public TokenRequest TokenRequest { get; set; }
    }

    public class GetTokenQueryHandler : IRequestHandler<GetTokenQuery, IResponseWrapper<TokenResponse>>
    {
        private readonly ITokenService _tokenService;

        public GetTokenQueryHandler(ITokenService tokenService)
        {
            _tokenService = tokenService;
        }

        public async ValueTask<IResponseWrapper<TokenResponse>> Handle(GetTokenQuery request, CancellationToken ct)
        {
            return await _tokenService.GetTokenAsync(request.TokenRequest);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\GetToken\GetTokenQueryValidator.cs' @'
namespace UMS.Application.Features.Token.Queries
{
    public class GetTokenQueryValidator : AbstractValidator<GetTokenQuery>
    {
        public GetTokenQueryValidator()
        {
            RuleFor(u => u.TokenRequest.Email)
                .NotEmpty()
                .EmailAddress();

            RuleFor(u => u.TokenRequest.Password)
                .NotEmpty()
                .MinimumLength(6);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\GetToken\TokenRequest.cs' @'
namespace UMS.Application.Features.Token.Queries
{
    public class TokenRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\GetToken\TokenResponse.cs' @'
using System.Text.Json.Serialization;

namespace UMS.Application.Features.Token.Queries
{
    public class TokenResponse
    {
        public string? Token { get; set; }
        public string? RefreshToken { get; set; }
        public DateTime? RefreshTokenExpiryTime { get; set; }
        public bool RequiresTwoFactor { get; set; }

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public string? TwoFactorChallengeToken { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\LoginWith2FA\LoginWith2FAQuery.cs' @'
namespace UMS.Application.Features.Token.Queries.LoginWith2FA
{
    public class LoginWith2FAQuery
        : IRequest<IResponseWrapper<TokenResponse>>, IValidateMe
    {
        public TwoFactorLoginRequest Request { get; set; } = null!;
    }

    public class LoginWith2FAQueryHandler
        : IRequestHandler<LoginWith2FAQuery, IResponseWrapper<TokenResponse>>
    {
        private readonly ITokenService _tokenService;

        public LoginWith2FAQueryHandler(ITokenService tokenService)
            => _tokenService = tokenService;

        public async ValueTask<IResponseWrapper<TokenResponse>> Handle(
            LoginWith2FAQuery request, CancellationToken ct)
            => await _tokenService.LoginWith2FAAsync(request.Request, ct);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\LoginWith2FA\LoginWith2FAQueryValidator.cs' @'
namespace UMS.Application.Features.Token.Queries.LoginWith2FA
{
    public class LoginWith2FAQueryValidator : AbstractValidator<LoginWith2FAQuery>
    {
        public LoginWith2FAQueryValidator()
        {
            RuleFor(x => x.Request.TwoFactorChallengeToken).NotEmpty();
            RuleFor(x => x.Request.Code).NotEmpty();
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Token\Queries\LoginWith2FA\TwoFactorLoginRequest.cs' @'
namespace UMS.Application.Features.Token.Queries.LoginWith2FA;

public class TwoFactorLoginRequest
{
    public string TwoFactorChallengeToken { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ChangeUserPassword\ChangePasswordRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ChangePasswordRequest
    {
        public string CurrentPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
        public string ConfirmedNewPassword { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ChangeUserPassword\ChangeUserPasswordCommand.cs' @'
using UMS.Application.Interfaces.Common;

namespace UMS.Application.Features.Users.Commands
{
    public class ChangeUserPasswordCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public ChangePasswordRequest ChangePassword { get; set; }
    }

    public class ChangeUserPasswordCommandHandler : IRequestHandler<ChangeUserPasswordCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;
        private readonly ICurrentUserService _currentUserService;

        public ChangeUserPasswordCommandHandler(IUserService userService, ICurrentUserService currentUserService)
        {
            _userService = userService;
            _currentUserService = currentUserService;
        }

        public async ValueTask<IResponseWrapper> Handle(ChangeUserPasswordCommand request, CancellationToken ct)
        {
            var userId = _currentUserService.GetUserId();
            if (userId is null)
                return ResponseWrapper.Fail("User is not authenticated.");

            return await _userService.ChangeUserPasswordAsync(userId.Value, request.ChangePassword);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ChangeUserPassword\ChangeUserPasswordValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ChangeUserPasswordValidator : AbstractValidator<ChangeUserPasswordCommand>
    {
        public ChangeUserPasswordValidator()
        {
            RuleFor(x => x.ChangePassword.CurrentPassword)
                .NotEmpty().WithMessage("Current password is required.");

            RuleFor(x => x.ChangePassword.NewPassword)
                .NotEmpty().WithMessage("Password is required.")
                .MinimumLength(6).WithMessage("Password must be at least 6 characters long.")
                // Optional stronger rules — uncomment if you want complexity checks:
                .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
                .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter.")
                .Matches("[0-9]").WithMessage("Password must contain at least one number.")
                .Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character.")
                ;

            RuleFor(x => x.ChangePassword.ConfirmedNewPassword)
                .NotEmpty().WithMessage("Confirm password is required.")
                .Equal(x => x.ChangePassword.NewPassword).WithMessage("Passwords do not match.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ChangeUserStatus\ChangeUserStatusCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ChangeUserStatusCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public ChangeUserStatusRequest ChangeUserStatus { get; set; }
    }

    public class ChangeUserStatusCommandHandler : IRequestHandler<ChangeUserStatusCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public ChangeUserStatusCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(ChangeUserStatusCommand request, CancellationToken ct)
        {
            return await _userService.ChangeUserStatusAsync(request.ChangeUserStatus);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ChangeUserStatus\ChangeUserStatusRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ChangeUserStatusRequest
    {
        public int UserId { get; set; }
        public bool ActivateOrDeactivate { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ChangeUserStatus\ChangeUserStatusValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ChangeUserStatusValidator : AbstractValidator<ChangeUserStatusCommand>
    {
        public ChangeUserStatusValidator()
        {

            RuleFor(x => x.ChangeUserStatus.UserId)
                .NotEqual(0).WithMessage("User Id is required.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ConfirmEmail\ConfirmEmailCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ConfirmEmailCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public ConfirmEmailRequest ConfirmEmail { get; set; }
    }

    public class ConfirmEmailCommandHandler : IRequestHandler<ConfirmEmailCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public ConfirmEmailCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(ConfirmEmailCommand request, CancellationToken ct)
        {
            return await _userService.ConfirmEmailAsync(
                request.ConfirmEmail.UserId,
                request.ConfirmEmail.Token);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ConfirmEmail\ConfirmEmailRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ConfirmEmailRequest
    {
        public int    UserId { get; set; }
        public string Token  { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ConfirmEmail\ConfirmEmailValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ConfirmEmailValidator : AbstractValidator<ConfirmEmailCommand>
    {
        public ConfirmEmailValidator()
        {
            RuleFor(x => x.ConfirmEmail.UserId)
                .NotEqual(0).WithMessage("User Id is required.");

            RuleFor(x => x.ConfirmEmail.Token)
                .NotEmpty().WithMessage("Token is required.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ConfirmEmailChange\ConfirmEmailChangeCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ConfirmEmailChangeCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public ConfirmEmailChangeRequest ConfirmEmailChange { get; set; }
    }

    public class ConfirmEmailChangeCommandHandler : IRequestHandler<ConfirmEmailChangeCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public ConfirmEmailChangeCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(ConfirmEmailChangeCommand request, CancellationToken ct)
        {
            return await _userService.ConfirmEmailChangeAsync(
                request.ConfirmEmailChange.UserId,
                request.ConfirmEmailChange.NewEmail,
                request.ConfirmEmailChange.Token);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ConfirmEmailChange\ConfirmEmailChangeRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ConfirmEmailChangeRequest
    {
        public int    UserId   { get; set; }
        public string NewEmail { get; set; } = string.Empty;
        public string Token    { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ConfirmEmailChange\ConfirmEmailChangeValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ConfirmEmailChangeValidator : AbstractValidator<ConfirmEmailChangeCommand>
    {
        public ConfirmEmailChangeValidator()
        {
            RuleFor(x => x.ConfirmEmailChange.UserId)
                .NotEqual(0).WithMessage("User Id is required.");

            RuleFor(x => x.ConfirmEmailChange.NewEmail)
                .NotEmpty().WithMessage("New email is required.")
                .EmailAddress().WithMessage("A valid email address is required.");

            RuleFor(x => x.ConfirmEmailChange.Token)
                .NotEmpty().WithMessage("Token is required.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ConfirmTwoFactorAuth\ConfirmTwoFactorAuthCommand.cs' @'
using UMS.Application.Features.Users.Models.Requests;

namespace UMS.Application.Features.Users.Commands.ConfirmTwoFactorAuth
{
    public class ConfirmTwoFactorAuthCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public TwoFactorCodeRequest Request { get; set; } = null!;
    }

    public class ConfirmTwoFactorAuthCommandHandler
        : IRequestHandler<ConfirmTwoFactorAuthCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public ConfirmTwoFactorAuthCommandHandler(IUserService userService)
            => _userService = userService;

        public async ValueTask<IResponseWrapper> Handle(
            ConfirmTwoFactorAuthCommand request, CancellationToken ct)
            => await _userService.ConfirmTwoFactorAuthAsync(request.Request);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ConfirmTwoFactorAuth\ConfirmTwoFactorAuthValidator.cs' @'
namespace UMS.Application.Features.Users.Commands.ConfirmTwoFactorAuth
{
    public class ConfirmTwoFactorAuthValidator
        : AbstractValidator<ConfirmTwoFactorAuthCommand>
    {
        public ConfirmTwoFactorAuthValidator()
        {
            RuleFor(x => x.Request.Code)
                .NotEmpty()
                .Matches(@"^\d{6}$")
                .WithMessage("Code must be exactly 6 digits.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\DisableTwoFactorAuth\DisableTwoFactorAuthCommand.cs' @'
namespace UMS.Application.Features.Users.Commands.DisableTwoFactorAuth
{
    public class DisableTwoFactorAuthCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public DisableTwoFactorAuthRequest Request { get; set; } = null!;
    }

    public class DisableTwoFactorAuthCommandHandler
        : IRequestHandler<DisableTwoFactorAuthCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public DisableTwoFactorAuthCommandHandler(IUserService userService)
            => _userService = userService;

        public async ValueTask<IResponseWrapper> Handle(
            DisableTwoFactorAuthCommand request, CancellationToken ct)
            => await _userService.DisableTwoFactorAuthAsync(request.Request);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\DisableTwoFactorAuth\DisableTwoFactorAuthRequest.cs' @'
namespace UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;

public class DisableTwoFactorAuthRequest
{
    public string Password { get; set; } = string.Empty;
    public string? Code { get; set; }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\DisableTwoFactorAuth\DisableTwoFactorAuthValidator.cs' @'
namespace UMS.Application.Features.Users.Commands.DisableTwoFactorAuth
{
    public class DisableTwoFactorAuthValidator
        : AbstractValidator<DisableTwoFactorAuthCommand>
    {
        public DisableTwoFactorAuthValidator()
        {
            RuleFor(x => x.Request.Password).NotEmpty();

            When(x => !string.IsNullOrEmpty(x.Request.Code), () =>
            {
                RuleFor(x => x.Request.Code)
                    .Matches(@"^\d{6}$")
                    .WithMessage("Code must be exactly 6 digits.");
            });
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\EnableTwoFactorAuth\EnableTwoFactorAuthCommand.cs' @'
using UMS.Application.Features.Users.Models.Requests;

namespace UMS.Application.Features.Users.Commands.EnableTwoFactorAuth
{
    public class EnableTwoFactorAuthCommand
        : IRequest<IResponseWrapper<List<string>>>, IValidateMe
    {
        public TwoFactorCodeRequest Request { get; set; } = null!;
    }

    public class EnableTwoFactorAuthCommandHandler
        : IRequestHandler<EnableTwoFactorAuthCommand, IResponseWrapper<List<string>>>
    {
        private readonly IUserService _userService;

        public EnableTwoFactorAuthCommandHandler(IUserService userService)
            => _userService = userService;

        public async ValueTask<IResponseWrapper<List<string>>> Handle(
            EnableTwoFactorAuthCommand request, CancellationToken ct)
            => await _userService.EnableTwoFactorAuthAsync(request.Request);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\EnableTwoFactorAuth\EnableTwoFactorAuthValidator.cs' @'
namespace UMS.Application.Features.Users.Commands.EnableTwoFactorAuth
{
    public class EnableTwoFactorAuthValidator
        : AbstractValidator<EnableTwoFactorAuthCommand>
    {
        public EnableTwoFactorAuthValidator()
        {
            RuleFor(x => x.Request.Code)
                .NotEmpty()
                .Matches(@"^\d{6}$")
                .WithMessage("Code must be exactly 6 digits.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ForgotPassword\ForgotPasswordCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ForgotPasswordCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public string Email { get; set; }
    }

    public class ForgotPasswordCommandHandler : IRequestHandler<ForgotPasswordCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public ForgotPasswordCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(ForgotPasswordCommand request, CancellationToken ct)
        {
            return await _userService.ForgotPasswordAsync(request.Email);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ForgotPassword\ForgotPasswordCommandValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ForgotPasswordCommandValidator : AbstractValidator<ForgotPasswordCommand>
    {
        public ForgotPasswordCommandValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required.")
                .EmailAddress().WithMessage("Invalid email format.")
                .MaximumLength(255).WithMessage("Email must not exceed 255 characters.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\GenerateChangeEmailToken\GenerateChangeEmailTokenCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class GenerateChangeEmailTokenCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public GenerateChangeEmailTokenRequest GenerateChangeEmailToken { get; set; }
    }

    public class GenerateChangeEmailTokenCommandHandler : IRequestHandler<GenerateChangeEmailTokenCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public GenerateChangeEmailTokenCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(GenerateChangeEmailTokenCommand request, CancellationToken ct)
        {
            return await _userService.GenerateChangeEmailTokenAsync(
                request.GenerateChangeEmailToken.NewEmail);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\GenerateChangeEmailToken\GenerateChangeEmailTokenRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class GenerateChangeEmailTokenRequest
    {
        public string NewEmail { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\GenerateChangeEmailToken\GenerateChangeEmailTokenValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class GenerateChangeEmailTokenValidator : AbstractValidator<GenerateChangeEmailTokenCommand>
    {
        public GenerateChangeEmailTokenValidator()
        {
            RuleFor(x => x.GenerateChangeEmailToken.NewEmail)
                .NotEmpty().WithMessage("New email address is required.")
                .EmailAddress().WithMessage("A valid email address is required.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\GenerateNew2FARecoveryCodes\GenerateNew2FARecoveryCodesCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class GenerateNew2FARecoveryCodesCommand : IRequest<IResponseWrapper<List<string>>>
    {
    }

    public class GenerateNew2FARecoveryCodesCommandHandler
        : IRequestHandler<GenerateNew2FARecoveryCodesCommand, IResponseWrapper<List<string>>>
    {
        private readonly IUserService _userService;

        public GenerateNew2FARecoveryCodesCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper<List<string>>> Handle(
            GenerateNew2FARecoveryCodesCommand request, CancellationToken ct)
        {
            return await _userService.GenerateNew2FARecoveryCodesAsync();
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\LockUser\LockUserCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class LockUserCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public LockUserRequest LockUser { get; set; }
    }

    public class LockUserCommandHandler : IRequestHandler<LockUserCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public LockUserCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(LockUserCommand request, CancellationToken ct)
        {
            return await _userService.LockUserAsync(request.LockUser.UserId);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\LockUser\LockUserRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class LockUserRequest
    {
        public int UserId { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\LockUser\LockUserValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class LockUserValidator : AbstractValidator<LockUserCommand>
    {
        public LockUserValidator()
        {
            RuleFor(x => x.LockUser.UserId)
                .NotEqual(0).WithMessage("User Id is required.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\Logout\LogoutCommand.cs' @'
namespace UMS.Application.Features.Users.Commands.Logout
{
    public class LogoutCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public LogoutRequest Request { get; set; } = null!;
    }

    public class LogoutCommandHandler : IRequestHandler<LogoutCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public LogoutCommandHandler(IUserService userService)
            => _userService = userService;

        public async ValueTask<IResponseWrapper> Handle(
            LogoutCommand request, CancellationToken ct)
            => await _userService.LogoutAsync(request.Request);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\Logout\LogoutCommandValidator.cs' @'
namespace UMS.Application.Features.Users.Commands.Logout
{
    public class LogoutCommandValidator : AbstractValidator<LogoutCommand>
    {
        public LogoutCommandValidator()
        {
            RuleFor(x => x.Request.RefreshToken).NotEmpty();
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\Logout\LogoutRequest.cs' @'
namespace UMS.Application.Features.Users.Commands.Logout;

public class LogoutRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ResendConfirmationEmail\ResendConfirmationEmailCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ResendConfirmationEmailCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public ResendConfirmationEmailRequest ResendConfirmation { get; set; }
    }

    public class ResendConfirmationEmailCommandHandler : IRequestHandler<ResendConfirmationEmailCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public ResendConfirmationEmailCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(ResendConfirmationEmailCommand request, CancellationToken ct)
        {
            return await _userService.ResendConfirmationEmailAsync(
                request.ResendConfirmation.Email);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ResendConfirmationEmail\ResendConfirmationEmailRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ResendConfirmationEmailRequest
    {
        public string Email { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ResendConfirmationEmail\ResendConfirmationEmailValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ResendConfirmationEmailValidator : AbstractValidator<ResendConfirmationEmailCommand>
    {
        public ResendConfirmationEmailValidator()
        {
            RuleFor(x => x.ResendConfirmation.Email)
                .NotEmpty().WithMessage("Email address is required.")
                .EmailAddress().WithMessage("A valid email address is required.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ResetPassword\ResetPasswordCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ResetPasswordCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public ResetPasswordRequest ResetPasswordRequest { get; set; }
    }

    public class ResetPasswordCommandHandler : IRequestHandler<ResetPasswordCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public ResetPasswordCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(ResetPasswordCommand request, CancellationToken ct)
        {
            return await _userService.ResetPasswordAsync(request.ResetPasswordRequest);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ResetPassword\ResetPasswordCommandValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class ResetPasswordCommandValidator : AbstractValidator<ResetPasswordCommand>
    {
        public ResetPasswordCommandValidator()
        {
            // Rule for Token
            RuleFor(x => x.ResetPasswordRequest.Token)
                .NotEmpty().WithMessage("Token is required.");

            RuleFor(x => x.ResetPasswordRequest.Email)
                .NotEmpty().WithMessage("Email is required.")
                .EmailAddress().WithMessage("Invalid email format.");

            RuleFor(x => x.ResetPasswordRequest.Password)
                .NotEmpty().WithMessage("Password is required.")
                .MinimumLength(6).WithMessage("Password must be at least 6 characters long.")
                // Optional stronger rules — uncomment if you want complexity checks:
                .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
                .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter.")
                .Matches("[0-9]").WithMessage("Password must contain at least one number.")
                .Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character.")
                ;

            RuleFor(x => x.ResetPasswordRequest.ConfirmPassword)
                .NotEmpty().WithMessage("Confirm password is required.")
                .Equal(x => x.ResetPasswordRequest.Password).WithMessage("Passwords do not match.");

        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\ResetPassword\ResetPasswordRequest.cs' @'
using System.ComponentModel.DataAnnotations;

namespace UMS.Application.Features.Users.Commands
{
    public class ResetPasswordRequest
    {
        public string Token { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Password { get; set; } = string.Empty;

        public string ConfirmPassword { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\SetupTwoFactorAuth\SetupTwoFactorAuthCommand.cs' @'
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Features.Users.Commands.SetupTwoFactorAuth
{
    public class SetupTwoFactorAuthCommand
        : IRequest<IResponseWrapper<TwoFactorAuthViewModel>> { }

    public class SetupTwoFactorAuthCommandHandler
        : IRequestHandler<SetupTwoFactorAuthCommand, IResponseWrapper<TwoFactorAuthViewModel>>
    {
        private readonly IUserService _userService;

        public SetupTwoFactorAuthCommandHandler(IUserService userService)
            => _userService = userService;

        public async ValueTask<IResponseWrapper<TwoFactorAuthViewModel>> Handle(
            SetupTwoFactorAuthCommand request, CancellationToken ct)
            => await _userService.SetupTwoFactorAuthAsync();
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UnlockUser\UnlockUserCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class UnlockUserCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public UnlockUserRequest UnlockUser { get; set; }
    }

    public class UnlockUserCommandHandler : IRequestHandler<UnlockUserCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public UnlockUserCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(UnlockUserCommand request, CancellationToken ct)
        {
            return await _userService.UnlockUserAsync(request.UnlockUser.UserId);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UnlockUser\UnlockUserRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class UnlockUserRequest
    {
        public int UserId { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UnlockUser\UnlockUserValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class UnlockUserValidator : AbstractValidator<UnlockUserCommand>
    {
        public UnlockUserValidator()
        {
            RuleFor(x => x.UnlockUser.UserId)
                .NotEqual(0).WithMessage("User Id is required.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UpdateUser\UpdateUserCommand.cs' @'

namespace UMS.Application.Features.Users.Commands
{
    public class UpdateUserCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public UpdateUserRequest UpdateUser { get; set; }
    }

    public class UpdateUserCommandHandler : IRequestHandler<UpdateUserCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public UpdateUserCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(UpdateUserCommand request, CancellationToken ct)
        {
            return await _userService.UpdateUserAsync(request.UpdateUser);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UpdateUser\UpdateUserCommandValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class UpdateUserCommandValidator : AbstractValidator<UpdateUserCommand>
    {
        public UpdateUserCommandValidator()
        {
            RuleFor(x => x.UpdateUser.UserId)
                .NotEmpty().WithMessage("User ID is required.");

            RuleFor(x => x.UpdateUser.FullName)
                .NotEmpty().WithMessage("Full name is required.")
                .MaximumLength(100).WithMessage("Full name must not exceed 100 characters.");

            RuleFor(x => x.UpdateUser.PhoneNumber)
                .NotEmpty().WithMessage("Phone number is required.")
                .Matches(@"^[0-9+\-\s]+$").WithMessage("Phone number contains invalid characters.")
                .MinimumLength(11).WithMessage("Phone number must be at least 11 digits long.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UpdateUser\UpdateUserRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class UpdateUserRequest
    {
        public int UserId { get; set; }
        public string FullName { get; set; }
        public string PhoneNumber { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UpdateUserRoles\UpdateUserRolesCommand.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class UpdateUserRolesCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public UpdateUserRolesRequest UpdateUserRoles { get; set; }
    }

    public class UpdateUserRolesCommandHandler : IRequestHandler<UpdateUserRolesCommand, IResponseWrapper>
    {
        private readonly IUserService _userService;

        public UpdateUserRolesCommandHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper> Handle(UpdateUserRolesCommand request, CancellationToken ct)
        {
            return await _userService.UpdateUserRolesAsync(request.UpdateUserRoles, ct);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UpdateUserRoles\UpdateUserRolesCommandValidator.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class UpdateUserRolesCommandValidator : AbstractValidator<UpdateUserRolesCommand>
    {
        public UpdateUserRolesCommandValidator()
        {
            RuleFor(x => x.UpdateUserRoles.UserId)
                .NotEmpty().WithMessage("User ID is required.");

            RuleFor(x => x.UpdateUserRoles.Roles)
                .NotNull().WithMessage("Roles list cannot be null.")
                .Must(r => r.Count > 0).WithMessage("At least one role must be assigned.");

            RuleForEach(x => x.UpdateUserRoles.Roles).ChildRules(role =>
            {
                role.RuleFor(r => r)
                    .NotEmpty()
                    .WithMessage("RoleName is required.");

                role.RuleFor(r => r)
                    .MaximumLength(256)
                    .WithMessage("RoleName cannot exceed 256 characters.");
            });

        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UpdateUserRoles\UpdateUserRolesRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class UpdateUserRolesRequest
    {
        public int UserId { get; set; }
        public List<string> Roles { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UserRegistration\UserRegistrationCommand.cs' @'

namespace UMS.Application.Features.Users.Commands
{
    public class UserRegistrationCommand : IRequest<IResponseWrapper>, IValidateMe
    {
        public UserRegistrationRequest UserRegistration { get; set; }
    }

    public class UserRegistrationCommandHandler(IUserService userService)
        : IRequestHandler<UserRegistrationCommand, IResponseWrapper>
    {
        private readonly IUserService _userService = userService;

        public async ValueTask<IResponseWrapper> Handle(UserRegistrationCommand request, CancellationToken ct)
        {
            return await _userService.RegisterUserAsync(request.UserRegistration);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UserRegistration\UserRegistrationCommandValidator.cs' @'

namespace UMS.Application.Features.Users.Commands
{
    public class UserRegistrationCommandValidator : AbstractValidator<UserRegistrationCommand>
    {
        public UserRegistrationCommandValidator()
        {
            RuleFor(x => x.UserRegistration.FullName)
                .NotEmpty().WithMessage("Full name is required.")
                .MaximumLength(100).WithMessage("Full name must not exceed 100 characters.");

            RuleFor(x => x.UserRegistration.Email)
                .NotEmpty().WithMessage("Email is required.")
                .EmailAddress().WithMessage("Invalid email format.");

            RuleFor(x => x.UserRegistration.Password)
                .NotEmpty().WithMessage("Password is required.")
                .MinimumLength(6).WithMessage("Password must be at least 6 characters long.")
                // Optional stronger rules — uncomment if you want complexity checks:
                .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
                .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter.")
                .Matches("[0-9]").WithMessage("Password must contain at least one number.")
                .Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character.")
                ;

            RuleFor(x => x.UserRegistration.ConfirmPassword)
                .NotEmpty().WithMessage("Confirm password is required.")
                .Equal(x => x.UserRegistration.Password).WithMessage("Passwords do not match.");

            RuleFor(x => x.UserRegistration.PhoneNumber)
                .NotEmpty().WithMessage("Phone number is required.")
                .Matches(@"^[0-9+\-\s]+$").WithMessage("Phone number contains invalid characters.")
                .MinimumLength(11).WithMessage("Phone number must be at least 11 digits long.");

        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Commands\UserRegistration\UserRegistrationRequest.cs' @'
namespace UMS.Application.Features.Users.Commands
{
    public class UserRegistrationRequest
    {
        public string FullName { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
        public string ConfirmPassword { get; set; }
        public string PhoneNumber { get; set; }
        public bool AutoConfirmEmail { get; set; }
        public bool ActivateUser { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\IUserService.cs' @'
using UMS.Application.Dtos.Pagination;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;
using UMS.Application.Features.Users.Commands.Logout;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Features.Users
{
    public interface IUserService
    {
        Task<IResponseWrapper> RegisterUserAsync(UserRegistrationRequest userRegistration);
        Task<IResponseWrapper> UpdateUserAsync(UpdateUserRequest userUpdate);

        // Start
        Task<IResponseWrapper<UserResponse>> GetUserByIdAsync(int userId);
        Task<IResponseWrapper<PagedResult<UserResponse>>> GetUsersPagedQueryAsync(PagedFilterRequest pagedFilterRequest, CancellationToken ct);
        Task<IResponseWrapper> ChangeUserPasswordAsync(int userId, ChangePasswordRequest changePassword);
        Task<IResponseWrapper> ChangeUserStatusAsync(ChangeUserStatusRequest changeUserStatus);
        Task<IResponseWrapper<List<UserRoleViewModel>>> GetUserRolesAsync(int userId);
        Task<IResponseWrapper> UpdateUserRolesAsync(UpdateUserRolesRequest updateUserRoles,CancellationToken ct);
        Task<IResponseWrapper> ForgotPasswordAsync(string email);
        Task<IResponseWrapper> ResetPasswordAsync(ResetPasswordRequest request);
        Task<IResponseWrapper> ConfirmEmailAsync(int userId, string token);
        Task<IResponseWrapper> ConfirmEmailChangeAsync(int userId, string newEmail, string token);
        Task<IResponseWrapper> ResendConfirmationEmailAsync(string email);
        Task<IResponseWrapper> GenerateChangeEmailTokenAsync(string newEmail);
        Task<IResponseWrapper<List<string>>> GenerateNew2FARecoveryCodesAsync();
        Task<IResponseWrapper> LockUserAsync(int userId);
        Task<IResponseWrapper> UnlockUserAsync(int userId);

        Task<IResponseWrapper<ProfileResponse>> GetMyProfileAsync();
        Task<IResponseWrapper> LogoutAsync(LogoutRequest request);
        Task<IResponseWrapper<TwoFactorAuthViewModel>> SetupTwoFactorAuthAsync();
        Task<IResponseWrapper> ConfirmTwoFactorAuthAsync(TwoFactorCodeRequest request);
        Task<IResponseWrapper<List<string>>> EnableTwoFactorAuthAsync(TwoFactorCodeRequest request);
        Task<IResponseWrapper> DisableTwoFactorAuthAsync(DisableTwoFactorAuthRequest request);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Models\Requests\TwoFactorCodeRequest.cs' @'
namespace UMS.Application.Features.Users.Models.Requests;

public class TwoFactorCodeRequest
{
    public string Code { get; set; } = string.Empty;
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Models\Requests\UserRoleViewModel.cs' @'
namespace UMS.Application.Features.Users.Models.Requests
{
    public class UserRoleViewModel
    {
        public string RoleName { get; set; }
        public string RoleDescription { get; set; }

    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Models\Responses\ProfileResponse.cs' @'
namespace UMS.Application.Features.Users.Models.Responses;

public class ProfileResponse
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public bool EmailConfirmed { get; set; }
    public string? PhoneNumber { get; set; }
    public bool TwoFactorEnabled { get; set; }
    public DateTime CreatedDate { get; set; }
    public List<string> Roles { get; set; } = [];
    public List<string> Permissions { get; set; } = [];
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Models\Responses\TwoFactorAuthViewModel.cs' @'
using System.Text.Json.Serialization;

namespace UMS.Application.Features.Users.Models.Responses;

public class TwoFactorAuthViewModel
{
    public string? KeySecret { get; set; }
    public string? CodeQR { get; set; }

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? VerificationCode { get; set; }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Models\Responses\UserResponse.cs' @'
namespace UMS.Application.Features.Users.Models.Responses
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FullName { get; set; }
        public string Email { get; set; }
        public string UserName { get; set; }
        public bool IsActive { get; set; }
        public bool EmailConfirmed { get; set; }
        public string PhoneNumber { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Queries\GetMyProfile\GetMyProfileQuery.cs' @'
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Features.Users.Queries.GetMyProfile
{
    public class GetMyProfileQuery : IRequest<IResponseWrapper<ProfileResponse>> { }

    public class GetMyProfileQueryHandler
        : IRequestHandler<GetMyProfileQuery, IResponseWrapper<ProfileResponse>>
    {
        private readonly IUserService _userService;

        public GetMyProfileQueryHandler(IUserService userService)
            => _userService = userService;

        public async ValueTask<IResponseWrapper<ProfileResponse>> Handle(
            GetMyProfileQuery request, CancellationToken ct)
            => await _userService.GetMyProfileAsync();
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Queries\GetUserById\GetUserByIdQuery.cs' @'
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Features.Users.Queries
{
    public class GetUserByIdQuery : IRequest<IResponseWrapper<UserResponse>>, IValidateMe
    {
        public int UserId { get; set; }
    }

    public class GetUserByIdQueryHandler : IRequestHandler<GetUserByIdQuery, IResponseWrapper<UserResponse>>
    {
        private readonly IUserService _userService;

        public GetUserByIdQueryHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper<UserResponse>> Handle(GetUserByIdQuery request, CancellationToken ct)
        {
            return await _userService.GetUserByIdAsync(request.UserId);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Queries\GetUserById\GetUserByIdQueryValidator.cs' @'
namespace UMS.Application.Features.Users.Queries
{
    public class GetUserByIdQueryValidator : AbstractValidator<GetUserByIdQuery>
    {
        public GetUserByIdQueryValidator()
        {
            RuleFor(u => u.UserId)
                .GreaterThan(0).WithMessage("UserId must be greater than 0.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Queries\GetUserRolesQuery.cs' @'
using UMS.Application.Features.Users.Models.Requests;

namespace UMS.Application.Features.Users.Queries
{
    public class GetUserRolesQuery : IRequest<IResponseWrapper<List<UserRoleViewModel>>>, IValidateMe
    {
        public int UserId { get; set; }
    }

    public class GetUserRolesQueryHandler : IRequestHandler<GetUserRolesQuery, IResponseWrapper<List<UserRoleViewModel>>>
    {
        private readonly IUserService _userService;

        public GetUserRolesQueryHandler(IUserService userService)
        {
            _userService = userService;
        }

        public async ValueTask<IResponseWrapper<List<UserRoleViewModel>>> Handle(GetUserRolesQuery request, CancellationToken ct)
        {
            return await _userService.GetUserRolesAsync(request.UserId);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Queries\GetUserRolesQueryValidator.cs' @'
namespace UMS.Application.Features.Users.Queries
{
    public class GetUserRolesQueryValidator : AbstractValidator<GetUserRolesQuery>
    {
        public GetUserRolesQueryValidator()
        {
            RuleFor(x => x.UserId)
                .GreaterThan(0)
                .WithMessage("User ID must be greater than 0.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Queries\GetUsersPaged\GetUsersPagedQuery.cs' @'
using UMS.Application.Dtos.Pagination;
using UMS.Application.Features.Users.Models.Responses;

namespace UMS.Application.Features.Users.Queries
{
    public class GetUsersPagedQuery : IRequest<IResponseWrapper<PagedResult<UserResponse>>>, IValidateMe
    {
        public PagedFilterRequest PagedFilterRequest { get; set; }
    }

    public class GetUsersPagedQueryHandler : IRequestHandler<GetUsersPagedQuery, IResponseWrapper<PagedResult<UserResponse>>>
    {
        private readonly IUserService _userService;
        public GetUsersPagedQueryHandler(IUserService userService)
        {
            _userService = userService;
        }
        public async ValueTask<IResponseWrapper<PagedResult<UserResponse>>> Handle(GetUsersPagedQuery request, CancellationToken cancellationToken)
        {
            return await _userService.GetUsersPagedQueryAsync(request.PagedFilterRequest, cancellationToken);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Features\Users\Queries\GetUsersPaged\GetUsersPagedQueryValidator.cs' @'
using UMS.Application.Dtos.Pagination;

namespace UMS.Application.Features.Users.Queries
{
    public class GetUsersPagedQueryValidator : AbstractValidator<GetUsersPagedQuery>
    {
        public GetUsersPagedQueryValidator()
        {
            RuleFor(x => x.PagedFilterRequest)
                .SetValidator(new PagedFilterValidator());

            RuleFor(x => x.PagedFilterRequest.SortBy)
                .Must(field => new[] { "fullname", "email", "id" }.Contains(field))
                .WithMessage("Invalid SortBy value");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\GlobalUsings.cs' @'
global using FluentValidation;
global using Mediator;
global using UMS.Application.Interfaces.Common;
global using System.Security.Claims;
global using UMS.Application.Dtos.Wrappers;
global using UMS.Application.Dtos.Email;
global using UMS.Domain.Entities;
global using Mapster;
global using Microsoft.EntityFrameworkCore;
global using System.Collections.Generic;

[assembly: System.Runtime.CompilerServices.InternalsVisibleTo("UMS.Application.Tests")]
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\IApiRequest.cs' @'
namespace UMS.Application.Interfaces.Common
{
    public interface IApiRequest
    {
        Task<T> GetAsync<T>(string url, object id, string token);
        Task<T> GetAllAsync<T>(string url, string token);
        Task<T> PostAsync<T>(string url, object objToCreate, string token);
        Task<T> UpdateAsync<T>(string url, object objToUpdate, string token);
        Task<T> DeleteAsync<T>(string url, object id, string token);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\IApplicationDbContext.cs' @'
using Microsoft.EntityFrameworkCore;
using UMS.Domain.Entities;
using UMS.Domain.Interfaces;

namespace UMS.Application.Interfaces.Common
{
    public interface IApplicationDbContext
    {
        Task StartTransaction(CancellationToken cancellationToken = default);
        Task CommitTransaction(CancellationToken cancellationToken = default);
        Task RollbackTransaction(CancellationToken cancellationToken = default);

        Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
        DbSet<Category> Categories { get; }
        DbSet<AuditTrail> AuditTrails { get; }
        DbSet<LogUserActivity> LogUserActivities { get; }
        DbSet<OutboxMessage> OutboxMessages { get; }
     

        void AddOutboxMessage<TNotification>(TNotification notification) where TNotification : class;
        void SetOriginalRowVersion<TEntity>(TEntity entity, byte[] rowVersion) where TEntity : class, IDataConcurrency;
    }
}
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\ICacheAbleMediatorQuery.cs' @'

namespace UMS.Application.Interfaces.Common
{
    public interface ICacheAbleMediatorQuery
    {
        bool BypassCache { get; }
        string CacheKey { get; }
        TimeSpan? SlidingExpiration { get; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\ICacheService.cs' @'
namespace UMS.Application.Interfaces.Common
{
    public interface ICacheService
    {
        bool TryGet<T>(string cacheKey, out T value);
        T Set<T>(string cacheKey, T value);
        void Remove(string cacheKey);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\ICurrentUserService.cs' @'
namespace UMS.Application.Interfaces.Common
{
    public interface ICurrentUserService
    {
        ClaimsPrincipal? User { get; }            
        string Name { get; }
        int? GetUserId();
        string GetUserEmail();
        bool IsAuthenticated();
        IList<string> GetRoles();
        IList<Claim> GetClaims();
        bool HasRole(string roleName);
        bool HasClaim(string claimType, string value);
        void SetCurrentUser(ClaimsPrincipal principal);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\IDateTimeService.cs' @'
namespace UMS.Application.Interfaces.Common
{
    public interface IDateTimeService
    {
        DateTime NowUtc { get; }
    }
}
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\IEmailService.cs' @'
namespace UMS.Application.Interfaces.Common
{
    public interface IEmailService
    {
        Task<string> SendAsync(SendEmailDto request, CancellationToken ct = default);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\IFileStorageService.cs' @'
using UMS.Application.Dtos.Common;

namespace UMS.Application.Interfaces.Common
{
    public interface IFileStorageService
    {
        Task<string> SaveFileAsync(FileData file, string folderName, CancellationToken ct = default);

        void DeleteFile(string fileName, string folderName);
    }
}
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\ISessionWrapper.cs' @'
namespace UMS.Application.Interfaces.Common
{
    public interface ISessionWrapper
    {
        public T GetFromSession<T>(string key);
        public void SetInSession<T>(string key, T value);
        public void RemoveFromSession(string key);

    }
}
'@
    Write-TemplateFile 'UMS.Application\Interfaces\Common\IValidateMe.cs' @'
namespace UMS.Application.Interfaces.Common;
public interface IValidateMe
{
}
'@
    Write-TemplateFile 'UMS.Application\ServiceCollectionExtensions.cs' @'

using UMS.Application.Behaviors;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace UMS.Application
{
    /// <summary>
    /// Extension methods for setting up application-specific services in an <see cref="IServiceCollection"/>.
    /// </summary>
    public static class ServiceCollectionExtensions
    {
        /// <summary>
        /// Adds application layer services including validation, Mediator, and Mapster.
        /// </summary>
        /// <param name="services">The service collection to add services to.</param>
        /// <returns>The modified service collection.</returns>
        public static IServiceCollection AddApplicationServices(this IServiceCollection services)
        {
            // Add services for FluentValidation auto-validation
            services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());

            // Fully qualify the method call to resolve ambiguity
            Microsoft.Extensions.DependencyInjection.MediatorDependencyInjectionExtensions.AddMediator(services, options =>
            {
                options.ServiceLifetime = ServiceLifetime.Scoped;
                options.Namespace = "UMS.Application";
            });

            services.AddSingleton(typeof(IValidationFailureFactory<>), typeof(ValidationFailureFactory<>));
            services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationPipelineBehavior<,>));
           // services.AddTransient(typeof(IPipelineBehavior<,>), typeof(AuditBehavior<,>));

            services.AddMapster();

            return services;
        }
    }
}
'@
    Write-TemplateFile 'UMS.Application\UMS.Application.csproj' @'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

	<ItemGroup>
		<PackageReference Include="FluentValidation" Version="12.1.1" />
		<PackageReference Include="FluentValidation.DependencyInjectionExtensions" Version="12.1.1" />
		<PackageReference Include="Mapster" Version="10.0.7" />
		<PackageReference Include="Mapster.DependencyInjection" Version="10.0.7" />
		<PackageReference Include="Mediator.Abstractions" Version="3.0.2" />
		<PackageReference Include="Mediator.SourceGenerator" Version="3.0.2">
			<PrivateAssets>all</PrivateAssets>
			<IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
		</PackageReference>
		<PackageReference Include="Microsoft.EntityFrameworkCore" Version="10.0.6" />
	</ItemGroup>

	<ItemGroup>
	  <ProjectReference Include="..\UMS.Domain\UMS.Domain.csproj" />
	</ItemGroup>
	
</Project>
'@
    Write-TemplateFile 'UMS.Domain.Tests\Builders\CategoryBuilder.cs' @'
using UMS.Domain.Tests.Support;

namespace UMS.Domain.Tests.Builders;

internal sealed class CategoryBuilder
{
    private readonly Category _category = new()
    {
        Name = "Accessories",
        Slug = "accessories",
        IsActive = true,
        SortOrder = 10
    };

    public CategoryBuilder WithId(int id)
    {
        _category.WithId(id);
        return this;
    }

    public CategoryBuilder WithParent(Category parent)
    {
        _category.Parent = parent;
        _category.ParentId = parent.Id;
        return this;
    }

    public CategoryBuilder Deleted()
    {
        _category.SoftDeleted = true;
        _category.DeletedBy = 7;
        _category.DeletedAt = new DateTime(2026, 4, 23, 10, 0, 0, DateTimeKind.Utc);
        return this;
    }

    public CategoryBuilder WithConcurrencyToken(params byte[] rowVersion)
    {
        _category.RowVersion = rowVersion;
        return this;
    }

    public Category Build() => _category;
}
'@
    Write-TemplateFile 'UMS.Domain.Tests\Entities\CategoryTests.cs' @'
using UMS.Domain.Tests.Builders;

namespace UMS.Domain.Tests.Entities;

public class CategoryTests
{
    [Fact]
    public void New_category_should_start_with_expected_defaults()
    {
        var category = new CategoryBuilder().Build();

        category.Name.Should().Be("Accessories");
        category.Slug.Should().Be("accessories");
        category.IsActive.Should().BeTrue();
        category.Children.Should().NotBeNull().And.BeEmpty();
        category.RowVersion.Should().NotBeNull().And.BeEmpty();
        category.SoftDeleted.Should().BeFalse();
    }

    [Fact]
    public void Category_should_support_parent_child_relationships()
    {
        var parent = new CategoryBuilder().WithId(12).Build();
        var child = new CategoryBuilder().WithId(30).WithParent(parent).Build();

        parent.Children.Add(child);

        child.ParentId.Should().Be(12);
        child.Parent.Should().BeSameAs(parent);
        parent.Children.Should().ContainSingle().Which.Should().BeSameAs(child);
    }

    [Fact]
    public void Category_should_preserve_soft_delete_and_concurrency_metadata()
    {
        var category = new CategoryBuilder()
            .Deleted()
            .WithConcurrencyToken(1, 2, 3, 4)
            .Build();

        category.SoftDeleted.Should().BeTrue();
        category.DeletedBy.Should().Be(7);
        category.DeletedAt.Should().HaveValue();
        category.RowVersion.Should().Equal(1, 2, 3, 4);
    }
}
'@
    Write-TemplateFile 'UMS.Domain.Tests\GlobalUsings.cs' @'
global using FluentAssertions;
global using UMS.Domain.Entities;
global using Xunit;
'@
    Write-TemplateFile 'UMS.Domain.Tests\Support\EntityTestExtensions.cs' @'
using System.Reflection;

namespace UMS.Domain.Tests.Support;

internal static class EntityTestExtensions
{
    public static TEntity WithId<TEntity, TId>(this TEntity entity, TId id)
    {
        var type = typeof(TEntity);
        PropertyInfo? propertyInfo = null;

        while (propertyInfo is null && type is not null)
        {
            propertyInfo = type.GetProperty(
                "Id",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            type = type.BaseType;
        }

        propertyInfo.Should().NotBeNull();

        if (propertyInfo!.CanWrite)
        {
            propertyInfo.SetValue(entity, id);
            return entity;
        }

        var backingField = propertyInfo.DeclaringType?.GetField(
            "<Id>k__BackingField",
            BindingFlags.Instance | BindingFlags.NonPublic);

        backingField.Should().NotBeNull();
        backingField!.SetValue(entity, id);
        return entity;
    }
}
'@
    Write-TemplateFile 'UMS.Domain.Tests\UMS.Domain.Tests.csproj' @'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="coverlet.collector" Version="6.0.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" Version="8.9.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <Compile Remove="UnitTest1.cs" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\UMS.Domain\UMS.Domain.csproj" />
  </ItemGroup>

</Project>
'@
    Write-TemplateFile 'UMS.Domain\Common\BaseEntity.cs' @'
namespace UMS.Domain.Common
{
    /// <summary>
    /// Base entity class that provides a generic Id property and domain event handling.
    /// </summary>
    /// <typeparam name="TId">Type of the entity identifier.</typeparam>
    public abstract class BaseEntity<TId> : IEntity<TId> where TId : notnull
    {
        /// <summary>
        /// Primary identifier for the entity.
        /// </summary>
        public TId Id { get; protected set; } = default!;
    }
}
'@
    Write-TemplateFile 'UMS.Domain\Common\DomainEvent.cs' @'
namespace UMS.Domain.Common
{
    /// <summary>
    /// Base class for domain events emitted by entities. Tracks when the event
    /// occurred and whether it has been published by an event dispatcher.
    /// </summary>
    public abstract class DomainEvent : IDomainEvent
    {
        protected DomainEvent()
        {
            DateOccurred = DateTimeOffset.UtcNow;
        }

        /// <summary>
        /// Flag indicating whether the event has been published.
        /// </summary>
        public bool IsPublished { get; set; }

        /// <summary>
        /// Timestamp when the event occurred (UTC).
        /// </summary>
        public DateTimeOffset DateOccurred { get; protected set; }
    }
}
'@
    Write-TemplateFile 'UMS.Domain\Entities\AuditTrail.cs' @'
namespace UMS.Domain.Entities
{
    public class AuditTrail : BaseEntity<int>
    {
        public int? UserId { get; set; }
        public AuditType Type { get; set; }
        public string? TableName { get; set; }
        public DateTime DateTime { get; set; }
        public string? OldValues { get; set; }
        public string? NewValues { get; set; }
        public string? AffectedColumns { get; set; }
        public string? PrimaryKey { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Domain\Entities\Category.cs' @'
namespace UMS.Domain.Entities
{
    public class Category : BaseEntity<int>, IFullEntity, IDataConcurrency
    {
        public string Name { get; set; } = string.Empty;

        public string Slug { get; set; } = string.Empty;

        public string NormalizedName { get; set; } = string.Empty;

        public string NormalizedSlug { get; set; } = string.Empty;

        public int? ParentId { get; set; }

        public virtual Category? Parent { get; set; }

        public virtual ICollection<Category> Children { get; set; } = new HashSet<Category>();

        public bool IsActive { get; set; } = true;

        public int SortOrder { get; set; }

        public bool SoftDeleted { get; set; }
        public int? DeletedBy { get; set; }
        public DateTime? DeletedAt { get; set; }

        public int? CreatedBy { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? LastModifiedBy { get; set; }
        public DateTime? LastModifiedAt { get; set; }

        public byte[] RowVersion { get; set; } = Array.Empty<byte>();
    }
}
'@
    Write-TemplateFile 'UMS.Domain\Entities\LogUserActivity.cs' @'
namespace UMS.Domain.Entities;

/// <summary>
/// Entity for storing user activity logs.
/// </summary>
public class LogUserActivity : BaseEntity<int>
{
    /// <summary>
    /// ID of the user who performed the action.
    /// </summary>
    public int? UserId { get; set; }

    /// <summary>
    /// Date and time when the activity was logged.
    /// </summary>
    public DateTime CreatedDate { get; set; }

    /// <summary>
    /// The URL that was accessed.
    /// </summary>
    public string UrlData { get; set; } = string.Empty;

    /// <summary>
    /// Additional user data (e.g., request body, parameters).
    /// </summary>
    public string UserData { get; set; } = string.Empty;

    /// <summary>
    /// IP address of the client.
    /// </summary>
    public string IPAddress { get; set; } = string.Empty;

    /// <summary>
    /// Browser user agent string.
    /// </summary>
    public string Browser { get; set; } = string.Empty;

    /// <summary>
    /// HTTP method (GET, POST, PUT, DELETE, etc.).
    /// </summary>
    public string HttpMethod { get; set; } = string.Empty;

    /// <summary>
    /// ID of the user who impersonated the acting user (if applicable).
    /// </summary>
    public int? ImpersonatedBy { get; set; }
}
'@
    Write-TemplateFile 'UMS.Domain\Entities\OutboxMessage.cs' @'
namespace UMS.Domain.Entities
{
    /// <summary>
    /// Stores application notifications for asynchronous, reliable dispatch.
    /// </summary>
    public class OutboxMessage : BaseEntity<long>
    {
        public string Type { get; set; } = string.Empty;
        public string Payload { get; set; } = string.Empty;
        public DateTime OccurredOnUtc { get; set; }
        public DateTime? ProcessedOnUtc { get; set; }
        public int RetryCount { get; set; }
        public DateTime? NextRetryOnUtc { get; set; }
        public string? Error { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Domain\Enums\DomainEnums.cs' @'
namespace UMS.Domain.Enums;

/// <summary>
/// Supported Multi-Factor Authentication methods.
/// </summary>
public enum MfaMethod
{
    None = 0,
    Email = 1,
    Totp = 2,
    Sms = 3
}

public enum AuditType
{
    None = 0,
    Create = 1,
    Update = 2,
    Delete = 3
}
'@
    Write-TemplateFile 'UMS.Domain\GlobalUsings.cs' @'
// Global usings for the Domain project
// This file centralizes commonly used namespaces so that individual
// domain files do not need to repeat the same using directives.

global using UMS.Domain.Common;
global using UMS.Domain.Interfaces;
global using UMS.Domain.Enums;
'@
    Write-TemplateFile 'UMS.Domain\Interfaces\IAuditable.cs' @'
namespace UMS.Domain.Interfaces
{
    /// <summary>
    /// Contract for entities that maintain audit information such as who created
    /// or modified the entity and when those actions occurred.
    /// </summary>
    public interface IAuditable
    {
        /// <summary>
        /// Identifier for the user who created the entity, if available.
        /// </summary>
        public int? CreatedBy { get; set; }

        /// <summary>
        /// Creation timestamp for the entity.
        /// </summary>
        DateTime CreatedAt { get; set; }

        /// <summary>
        /// Identifier for the user who last modified the entity, if available.
        /// </summary>
        public int? LastModifiedBy { get; set; }

        /// <summary>
        /// Last modification timestamp for the entity.
        /// </summary>
        DateTime? LastModifiedAt { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Domain\Interfaces\IDataConcurrency.cs' @'
namespace UMS.Domain.Interfaces
{
    /// <summary>
    /// Contract for entities that support optimistic concurrency via a row version.
    /// Implementations should have a timestamp/row-version column in the database
    /// which is used to detect conflicting updates.
    /// Note: The [Timestamp] attribute should be applied in the Infrastructure layer
    /// via IEntityTypeConfiguration, not here in the domain.
    /// </summary>
    public interface IDataConcurrency
    {
        /// <summary>
        /// Row version used for optimistic concurrency control. Typically mapped to a
        /// database timestamp/rowversion column.
        /// </summary>
        byte[] RowVersion { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Domain\Interfaces\IDomainEvent.cs' @'
namespace UMS.Domain.Interfaces
{
    /// <summary>
    /// Marker interface for domain events.
    /// </summary>
    public interface IDomainEvent
    {
    }
}
'@
    Write-TemplateFile 'UMS.Domain\Interfaces\IEntity.cs' @'
namespace UMS.Domain.Interfaces
{
    /// <summary>
    /// Generic entity contract exposing a typed identifier.
    /// </summary>
    /// <typeparam name="TId">Type of the entity identifier.</typeparam>
    public interface IEntity<TId> : IEntity
    {
        TId Id { get; }
    }

    /// <summary>
    /// Marker interface for entities.
    /// </summary>
    public interface IEntity
    {

    }
}
'@
    Write-TemplateFile 'UMS.Domain\Interfaces\IFullEntity.cs' @'
namespace UMS.Domain.Interfaces
{
    /// <summary>
    /// Base contract for entities that are multi-tenant, auditable, 
    /// support soft delete and optimistic concurrency.
    /// </summary>
    public interface IFullEntity : IAuditable, ISoftDelete, IDataConcurrency
    {

    }
}
'@
    Write-TemplateFile 'UMS.Domain\Interfaces\IMustHaveTenant.cs' @'
namespace UMS.Domain.Interfaces
{
    /// <summary>
    /// Contract for entities that belong to a tenant in a multi-tenant application.
    /// </summary>
    public interface IMustHaveTenant
    {
        /// <summary>
        /// Tenant identifier that owns the entity.
        /// </summary>
        public int TenantId { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Domain\Interfaces\ISoftDelete.cs' @'
namespace UMS.Domain.Interfaces
{
    /// <summary>
    /// Contract for entities that support soft deletion.
    /// </summary>
    public interface ISoftDelete
    {
        /// <summary>
        /// Indicates whether the entity has been soft deleted.
        /// </summary>
        public bool SoftDeleted { get; set; }

        /// <summary>
        /// Identifier of the user who performed the delete operation.
        /// </summary>
        public int? DeletedBy { get; set; }

        /// <summary>
        /// Timestamp when the entity was soft deleted.
        /// </summary>
        DateTime? DeletedAt { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Domain\UMS.Domain.csproj' @'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

</Project>
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\appsettings.Testing.json' @'
{
  "ConnectionStrings": {
    "TestConnection": "Server=localhost;Database=UMSDbTest;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;"
  },
  "DbProvider": "SqlServer",
  "EnableAuditLog": false,
  "RunApplicationSeeder": false
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Fixtures\TempDirectoryFixture.cs' @'
namespace UMS.Infrastructure.Tests.Fixtures;

public sealed class TempDirectoryFixture : IDisposable
{
    public TempDirectoryFixture()
    {
        RootPath = Path.Combine(
            Path.GetTempPath(),
            "ums-tests",
            Guid.NewGuid().ToString("N"));

        Directory.CreateDirectory(RootPath);
    }

    public string RootPath { get; }

    public void Dispose()
    {
        if (Directory.Exists(RootPath))
        {
            Directory.Delete(RootPath, recursive: true);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\GlobalUsings.cs' @'
global using FluentAssertions;
global using Moq;
global using Xunit;
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Identity\Services\RoleServiceTests.cs' @'
using Microsoft.AspNetCore.Identity;
using System.Security.Claims;
using UMS.Application.Features.Roles;
using UMS.Application.Features.Roles.Commands;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Identity.Models;
using UMS.Infrastructure.Identity.Services;
using UMS.Infrastructure.Tests.Support;

namespace UMS.Infrastructure.Tests.Identity.Services;

public class RoleServiceTests : IDisposable
{
    private readonly Mock<RoleManager<ApplicationRole>> _roleManager;
    private readonly Mock<UserManager<ApplicationUser>> _userManager;
    private readonly Mock<IApplicationDbContext> _context;
    private readonly RoleService _sut;

    public RoleServiceTests()
    {
        _roleManager = IdentityMockFactory.CreateRoleManager();
        _userManager = IdentityMockFactory.CreateUserManager();
        _context = new Mock<IApplicationDbContext>();
        _sut = new RoleService(_roleManager.Object, _userManager.Object, _context.Object);
    }

    public void Dispose() { }

    private static ApplicationRole MakeRole(int id = 1, string name = "TestRole", string description = "Desc") =>
        new() { Id = id, Name = name, Description = description };

    // â”€â”€ CreateRoleAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task CreateRoleAsync_WhenRoleAlreadyExists_ReturnsFail()
    {
        var existing = MakeRole();
        _roleManager.Setup(m => m.FindByNameAsync(existing.Name!)).ReturnsAsync(existing);

        var result = await _sut.CreateRoleAsync(new CreateRoleRequest { Name = existing.Name!, Description = "x" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role already exists");
    }

    [Fact]
    public async Task CreateRoleAsync_WhenCreateFails_ReturnsFail()
    {
        _roleManager.Setup(m => m.FindByNameAsync("NewRole")).ReturnsAsync((ApplicationRole?)null);
        _roleManager.Setup(m => m.CreateAsync(It.IsAny<ApplicationRole>()))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Store error." }));

        var result = await _sut.CreateRoleAsync(new CreateRoleRequest { Name = "NewRole", Description = "x" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Store error.");
    }

    [Fact]
    public async Task CreateRoleAsync_WhenSuccessful_ReturnsSuccess()
    {
        _roleManager.Setup(m => m.FindByNameAsync("Manager")).ReturnsAsync((ApplicationRole?)null);
        _roleManager.Setup(m => m.CreateAsync(It.Is<ApplicationRole>(r => r.Name == "Manager")))
                    .ReturnsAsync(IdentityResult.Success);

        var result = await _sut.CreateRoleAsync(new CreateRoleRequest { Name = "Manager", Description = "Managers" });

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role created successfully");
    }

    // â”€â”€ DeleteRoleAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task DeleteRoleAsync_WhenRoleIdIsZero_ReturnsFail()
    {
        var result = await _sut.DeleteRoleAsync(0);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role Id is required.");
    }

    [Fact]
    public async Task DeleteRoleAsync_WhenRoleNotFound_ReturnsFail()
    {
        _roleManager.Setup(m => m.FindByIdAsync("99")).ReturnsAsync((ApplicationRole?)null);

        var result = await _sut.DeleteRoleAsync(99);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role does not exist.");
    }

    [Fact]
    public async Task DeleteRoleAsync_WhenAdminRole_ReturnsFail()
    {
        var adminRole = MakeRole(1, "Admin");
        _roleManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(adminRole);

        var result = await _sut.DeleteRoleAsync(1);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Cannot delete Admin role.");
    }

    [Fact]
    public async Task DeleteRoleAsync_WhenUsersAssignedToRole_ReturnsFail()
    {
        var role = MakeRole(2, "Editor");
        _roleManager.Setup(m => m.FindByIdAsync("2")).ReturnsAsync(role);
        _userManager.Setup(m => m.GetUsersInRoleAsync("Editor"))
                    .ReturnsAsync([new ApplicationUser { Id = 1, Email = "u@t.com" }]);

        var result = await _sut.DeleteRoleAsync(2);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Contain("currently assigned");
    }

    [Fact]
    public async Task DeleteRoleAsync_WhenDeleteFails_ReturnsFail()
    {
        var role = MakeRole(3, "Temp");
        _roleManager.Setup(m => m.FindByIdAsync("3")).ReturnsAsync(role);
        _userManager.Setup(m => m.GetUsersInRoleAsync("Temp")).ReturnsAsync([]);
        _roleManager.Setup(m => m.DeleteAsync(role))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Cannot delete." }));

        var result = await _sut.DeleteRoleAsync(3);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Cannot delete.");
    }

    [Fact]
    public async Task DeleteRoleAsync_WhenSuccessful_ReturnsSuccess()
    {
        var role = MakeRole(4, "Temp");
        _roleManager.Setup(m => m.FindByIdAsync("4")).ReturnsAsync(role);
        _userManager.Setup(m => m.GetUsersInRoleAsync("Temp")).ReturnsAsync([]);
        _roleManager.Setup(m => m.DeleteAsync(role)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.DeleteRoleAsync(4);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role successfully deleted.");
    }

    // â”€â”€ GetPermissionsAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetPermissionsAsync_WhenRoleNotFound_ReturnsFail()
    {
        _roleManager.Setup(m => m.FindByIdAsync("77")).ReturnsAsync((ApplicationRole?)null);

        var result = await _sut.GetPermissionsAsync(77);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role does not exist.");
    }

    [Fact]
    public async Task GetPermissionsAsync_WhenRoleFound_ReturnsAllAppPermissionsWithRoleInfo()
    {
        var role = MakeRole(5, "Viewer");
        _roleManager.Setup(m => m.FindByIdAsync("5")).ReturnsAsync(role);
        _roleManager.Setup(m => m.GetClaimsAsync(role)).ReturnsAsync(new List<Claim>());

        var result = await _sut.GetPermissionsAsync(5);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.Role.Id.Should().Be(5);
        result.Data.Role.Name.Should().Be("Viewer");
        result.Data.RoleClaims.Should().NotBeEmpty();
        result.Data.RoleClaims.Should().OnlyContain(rc => rc.ClaimType == "permission");
    }

    // â”€â”€ GetRoleByIdAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetRoleByIdAsync_WhenRoleNotFound_ReturnsFail()
    {
        _roleManager.Setup(m => m.FindByIdAsync("50")).ReturnsAsync((ApplicationRole?)null);

        var result = await _sut.GetRoleByIdAsync(50);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role does not exist.");
    }

    [Fact]
    public async Task GetRoleByIdAsync_WhenRoleFound_ReturnsMappedResponse()
    {
        var role = MakeRole(6, "Editor", "Content editors");
        _roleManager.Setup(m => m.FindByIdAsync("6")).ReturnsAsync(role);

        var result = await _sut.GetRoleByIdAsync(6);

        result.IsSuccessful.Should().BeTrue();
        result.Data!.Id.Should().Be(6);
        result.Data.Name.Should().Be("Editor");
        result.Data.Description.Should().Be("Content editors");
    }

    // â”€â”€ GetRolesAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetRolesAsync_WhenNoRolesExist_ReturnsFail()
    {
        _roleManager.Setup(m => m.Roles)
                    .Returns(new TestAsyncEnumerable<ApplicationRole>([]));

        var result = await _sut.GetRolesAsync();

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("No roles were found.");
    }

    [Fact]
    public async Task GetRolesAsync_WhenRolesExist_ReturnsMappedList()
    {
        var roles = new List<ApplicationRole> { MakeRole(1, "Admin"), MakeRole(2, "Basic") };
        _roleManager.Setup(m => m.Roles).Returns(new TestAsyncEnumerable<ApplicationRole>(roles));

        var result = await _sut.GetRolesAsync();

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().HaveCount(2);
        result.Data!.Select(r => r.Name).Should().BeEquivalentTo("Admin", "Basic");
    }

    // â”€â”€ UpdateRoleAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task UpdateRoleAsync_WhenRoleNotFound_ReturnsFail()
    {
        _roleManager.Setup(m => m.FindByIdAsync("88")).ReturnsAsync((ApplicationRole?)null);

        var result = await _sut.UpdateRoleAsync(new UpdateRoleRequest { RoleId = 88, Name = "X", Description = "Y" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role does not exist.");
    }

    [Fact]
    public async Task UpdateRoleAsync_WhenAdminRole_ReturnsFail()
    {
        var admin = MakeRole(1, "Admin");
        _roleManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(admin);

        var result = await _sut.UpdateRoleAsync(new UpdateRoleRequest { RoleId = 1, Name = "SuperAdmin", Description = "X" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Cannot update Admin role.");
    }

    [Fact]
    public async Task UpdateRoleAsync_WhenUpdateFails_ReturnsFail()
    {
        var role = MakeRole(7, "Editor");
        _roleManager.Setup(m => m.FindByIdAsync("7")).ReturnsAsync(role);
        _roleManager.Setup(m => m.UpdateAsync(role))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Concurrent update." }));

        var result = await _sut.UpdateRoleAsync(new UpdateRoleRequest { RoleId = 7, Name = "NewEditor", Description = "X" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Concurrent update.");
    }

    [Fact]
    public async Task UpdateRoleAsync_WhenSuccessful_ReturnsSuccess()
    {
        var role = MakeRole(8, "OldName");
        _roleManager.Setup(m => m.FindByIdAsync("8")).ReturnsAsync(role);
        _roleManager.Setup(m => m.UpdateAsync(It.Is<ApplicationRole>(r => r.Name == "NewName")))
                    .ReturnsAsync(IdentityResult.Success);

        var result = await _sut.UpdateRoleAsync(new UpdateRoleRequest { RoleId = 8, Name = "NewName", Description = "Updated" });

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role updated successfully");
    }

    // â”€â”€ UpdateRolePermissionsAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task UpdateRolePermissionsAsync_WhenRoleNotFound_ReturnsFail()
    {
        _roleManager.Setup(m => m.FindByIdAsync("99")).ReturnsAsync((ApplicationRole?)null);

        var result = await _sut.UpdateRolePermissionsAsync(new UpdateRoleClaimsRequest { RoleId = 99, RoleClaims = [] });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role does not exist.");
    }

    [Fact]
    public async Task UpdateRolePermissionsAsync_WhenAdminRole_ReturnsFail()
    {
        var admin = MakeRole(1, "Admin");
        _roleManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(admin);

        var result = await _sut.UpdateRolePermissionsAsync(new UpdateRoleClaimsRequest { RoleId = 1, RoleClaims = [] });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Cannot change permissions for this role.");
    }

    [Fact]
    public async Task UpdateRolePermissionsAsync_WhenNoChanges_ReturnsNoChangesMessage()
    {
        var role = MakeRole(9, "Viewer");
        var existingClaims = new List<Claim> { new("permission", "Permission.Identity.Roles.Read") };
        _roleManager.Setup(m => m.FindByIdAsync("9")).ReturnsAsync(role);
        _roleManager.Setup(m => m.GetClaimsAsync(role)).ReturnsAsync(existingClaims);

        var sameClaimsRequest = new UpdateRoleClaimsRequest
        {
            RoleId = 9,
            RoleClaims = [new RoleClaimViewModel { ClaimType = "permission", ClaimValue = "Permission.Identity.Roles.Read" }]
        };

        var result = await _sut.UpdateRolePermissionsAsync(sameClaimsRequest);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("No changes detected.");
    }

    [Fact]
    public async Task UpdateRolePermissionsAsync_WhenClaimsAdded_CallsAddClaimAndReturnsSuccess()
    {
        var role = MakeRole(10, "Viewer");
        _roleManager.Setup(m => m.FindByIdAsync("10")).ReturnsAsync(role);
        _roleManager.Setup(m => m.GetClaimsAsync(role)).ReturnsAsync([]);
        _roleManager.Setup(m => m.AddClaimAsync(role, It.IsAny<Claim>())).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.UpdateRolePermissionsAsync(new UpdateRoleClaimsRequest
        {
            RoleId = 10,
            RoleClaims = [new RoleClaimViewModel { ClaimType = "permission", ClaimValue = "Permission.Identity.Roles.Read" }]
        });

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role permissions updated successfully.");
        _roleManager.Verify(m => m.AddClaimAsync(role, It.Is<Claim>(c => c.Value == "Permission.Identity.Roles.Read")), Times.Once);
    }

    [Fact]
    public async Task UpdateRolePermissionsAsync_WhenClaimsRemoved_CallsRemoveClaimAndReturnsSuccess()
    {
        var role = MakeRole(11, "Viewer");
        var existingClaims = new List<Claim> { new("permission", "Permission.Identity.Roles.Read") };
        _roleManager.Setup(m => m.FindByIdAsync("11")).ReturnsAsync(role);
        _roleManager.Setup(m => m.GetClaimsAsync(role)).ReturnsAsync(existingClaims);
        _roleManager.Setup(m => m.RemoveClaimAsync(role, It.IsAny<Claim>())).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.UpdateRolePermissionsAsync(new UpdateRoleClaimsRequest { RoleId = 11, RoleClaims = [] });

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role permissions updated successfully.");
        _roleManager.Verify(m => m.RemoveClaimAsync(role, It.Is<Claim>(c => c.Value == "Permission.Identity.Roles.Read")), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Identity\Services\TokenService2FATests.cs' @'
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using UMS.Application.Dtos.JWT;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Features.Token.Queries.LoginWith2FA;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Identity.Models;
using UMS.Infrastructure.Identity.Services;
using UMS.Infrastructure.Tests.Support;

namespace UMS.Infrastructure.Tests.Identity.Services;

public class TokenService2FATests
{
    private readonly Mock<UserManager<ApplicationUser>> _userManager;
    private readonly Mock<RoleManager<ApplicationRole>> _roleManager;
    private readonly Mock<IDateTimeService> _dateTimeService = new();
    private readonly Mock<IDistributedCache> _cache = new();
    private readonly JwtConfiguration _jwtConfig;
    private readonly TokenService _sut;

    private static readonly DateTime FixedNow = new(2025, 6, 1, 0, 0, 0, DateTimeKind.Utc);

    private string ChallengeIssuer => $"{_jwtConfig.Issuer}:2fa-challenge";
    private const string ChallengeAudience = "2fa-challenge";
    private const string ChallengeClaim = "2fa_challenge";

    public TokenService2FATests()
    {
        _userManager = IdentityMockFactory.CreateUserManager();
        _roleManager = IdentityMockFactory.CreateRoleManager();
        _dateTimeService.Setup(d => d.NowUtc).Returns(FixedNow);

        _jwtConfig = new JwtConfiguration
        {
            Issuer = "ums-issuer",
            Audience = "ums-audience",
            Secret = "super-secret-key-for-testing-123456",
            TokenExpiryInMinutes = 60,
            RefreshTokenExpiryInDays = 7,
            TwoFactorChallengeTokenExpiryInMinutes = 5
        };

        _sut = new TokenService(
            _userManager.Object,
            _roleManager.Object,
            Options.Create(_jwtConfig),
            _dateTimeService.Object,
            _cache.Object);
    }

    private ApplicationUser MakeUser(bool twoFactorEnabled = false, bool active = true, bool confirmed = true) =>
        new()
        {
            Id = 1,
            Email = "user@test.com",
            UserName = "user@test.com",
            FullName = "Test User",
            PhoneNumber = "01012345678",
            IsActive = active,
            EmailConfirmed = confirmed,
            TwoFactorEnabled = twoFactorEnabled,
            RefreshToken = "existing-refresh",
            RefreshTokenExpiryDate = FixedNow.AddDays(3)
        };

    private string BuildChallengeToken(int userId, string jti, DateTime? expiry = null)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtConfig.Secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ChallengeClaim, "true"),
            new Claim(JwtRegisteredClaimNames.Jti, jti)
        };
        var token = new JwtSecurityToken(
            issuer: ChallengeIssuer,
            audience: ChallengeAudience,
            claims: claims,
            expires: expiry ?? DateTime.UtcNow.AddMinutes(5),
            signingCredentials: credentials);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private void SetupCacheNotFound()
    {
        _cache.Setup(c => c.GetAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
              .ReturnsAsync((byte[]?)null);
    }

    private void SetupCacheFound(string key)
    {
        _cache.Setup(c => c.GetAsync(key, It.IsAny<CancellationToken>()))
              .ReturnsAsync(new byte[] { 1 });
    }

    private void SetupCacheSet()
    {
        _cache.Setup(c => c.SetAsync(
                It.IsAny<string>(),
                It.IsAny<byte[]>(),
                It.IsAny<DistributedCacheEntryOptions>(),
                It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
    }

    // â”€â”€ GetTokenAsync 2FA branch â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetTokenAsync_TwoFactorEnabled_ReturnsRequiresTwoFactorTrue()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Pass@1")).ReturnsAsync(true);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "Pass@1" });

        result.IsSuccessful.Should().BeTrue();
        result.Data!.RequiresTwoFactor.Should().BeTrue();
        result.Data.TwoFactorChallengeToken.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public async Task GetTokenAsync_TwoFactorEnabled_ReturnsChallengeTokenWithCorrectIssuerAndAudience()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Pass@1")).ReturnsAsync(true);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "Pass@1" });

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(result.Data!.TwoFactorChallengeToken);
        jwt.Issuer.Should().Be(ChallengeIssuer);
        jwt.Audiences.Should().Contain(ChallengeAudience);
        jwt.Claims.Should().Contain(c => c.Type == ChallengeClaim && c.Value == "true");
    }

    [Fact]
    public async Task GetTokenAsync_TwoFactorEnabled_ChallengeTokenExpiresAfterConfiguredMinutes()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Pass@1")).ReturnsAsync(true);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "Pass@1" });

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(result.Data!.TwoFactorChallengeToken);
        jwt.ValidTo.Should().BeCloseTo(
            FixedNow.AddMinutes(_jwtConfig.TwoFactorChallengeTokenExpiryInMinutes),
            TimeSpan.FromSeconds(5));
    }

    [Fact]
    public async Task GetTokenAsync_TwoFactorEnabled_DoesNotCallResetAccessFailedCount()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Pass@1")).ReturnsAsync(true);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);

        await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "Pass@1" });

        _userManager.Verify(m => m.ResetAccessFailedCountAsync(It.IsAny<ApplicationUser>()), Times.Never);
    }

    [Fact]
    public async Task GetTokenAsync_TwoFactorDisabled_ReturnsRealTokensWithRequiresTwoFactorFalse()
    {
        var user = MakeUser(twoFactorEnabled: false);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Pass@1")).ReturnsAsync(true);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetClaimsAsync(user)).ReturnsAsync([]);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync([]);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "Pass@1" });

        result.IsSuccessful.Should().BeTrue();
        result.Data!.RequiresTwoFactor.Should().BeFalse();
        result.Data.Token.Should().NotBeNullOrWhiteSpace();
        result.Data.TwoFactorChallengeToken.Should().BeNull();
    }

    // â”€â”€ LoginWith2FAAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task LoginWith2FAAsync_InvalidChallengeTokenSignature_ReturnsFail()
    {
        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = "invalid.token.here",
            Code = "123456"
        });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("Invalid or expired"));
    }

    [Fact]
    public async Task LoginWith2FAAsync_ExpiredChallengeToken_ReturnsFail()
    {
        var expiredToken = BuildChallengeToken(1, Guid.NewGuid().ToString(),
            expiry: DateTime.UtcNow.AddMinutes(-1));

        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = expiredToken,
            Code = "123456"
        });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("Invalid or expired"));
    }

    [Fact]
    public async Task LoginWith2FAAsync_MissingChallengeClaim_ReturnsFail()
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtConfig.Secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: ChallengeIssuer,
            audience: ChallengeAudience,
            claims: [new Claim(ClaimTypes.NameIdentifier, "1")],
            expires: FixedNow.AddMinutes(5),
            signingCredentials: creds);
        var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = tokenString,
            Code = "123456"
        });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("Invalid or expired"));
    }

    [Fact]
    public async Task LoginWith2FAAsync_JtiAlreadyInCache_ReturnsFail()
    {
        var jti = Guid.NewGuid().ToString();
        var token = BuildChallengeToken(1, jti);
        SetupCacheFound($"2fa_jti:{jti}");

        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = token,
            Code = "123456"
        });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("already been used"));
    }

    [Fact]
    public async Task LoginWith2FAAsync_UserLockedOut_ReturnsFail()
    {
        var jti = Guid.NewGuid().ToString();
        var user = MakeUser(twoFactorEnabled: true);
        var token = BuildChallengeToken(user.Id, jti);
        SetupCacheNotFound();
        _userManager.Setup(m => m.FindByIdAsync(user.Id.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(true);

        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = token,
            Code = "123456"
        });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("locked"));
    }

    [Fact]
    public async Task LoginWith2FAAsync_TwoFactorNotEnabledOnAccount_ReturnsFail()
    {
        var jti = Guid.NewGuid().ToString();
        var user = MakeUser(twoFactorEnabled: false);
        var token = BuildChallengeToken(user.Id, jti);
        SetupCacheNotFound();
        _userManager.Setup(m => m.FindByIdAsync(user.Id.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);

        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = token,
            Code = "123456"
        });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("not enabled"));
    }

    [Fact]
    public async Task LoginWith2FAAsync_BothTOTPAndRecoveryCodeFail_ReturnsFailAndCallsAccessFailed()
    {
        var jti = Guid.NewGuid().ToString();
        var user = MakeUser(twoFactorEnabled: true);
        var token = BuildChallengeToken(user.Id, jti);
        SetupCacheNotFound();
        _userManager.Setup(m => m.FindByIdAsync(user.Id.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "bad-code"))
            .ReturnsAsync(false);
        _userManager.Setup(m => m.RedeemTwoFactorRecoveryCodeAsync(user, "bad-code"))
            .ReturnsAsync(IdentityResult.Failed());
        _userManager.Setup(m => m.AccessFailedAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = token,
            Code = "bad-code"
        });

        result.IsSuccessful.Should().BeFalse();
        _userManager.Verify(m => m.AccessFailedAsync(user), Times.Once);
    }

    [Fact]
    public async Task LoginWith2FAAsync_WrongCodeExceedsThreshold_ReturnsLockedOutMessage()
    {
        var jti = Guid.NewGuid().ToString();
        var user = MakeUser(twoFactorEnabled: true);
        var token = BuildChallengeToken(user.Id, jti);
        SetupCacheNotFound();
        _userManager.Setup(m => m.FindByIdAsync(user.Id.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user))
            .ReturnsAsync(false)     // first check (before code verification)
            .Callback(() => _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(true));
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), It.IsAny<string>()))
            .ReturnsAsync(false);
        _userManager.Setup(m => m.RedeemTwoFactorRecoveryCodeAsync(user, It.IsAny<string>()))
            .ReturnsAsync(IdentityResult.Failed());
        _userManager.Setup(m => m.AccessFailedAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = token,
            Code = "bad-code"
        });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("locked"));
    }

    [Fact]
    public async Task LoginWith2FAAsync_ValidTOTPCode_ReturnsRealTokens()
    {
        var jti = Guid.NewGuid().ToString();
        var user = MakeUser(twoFactorEnabled: true);
        var token = BuildChallengeToken(user.Id, jti);
        SetupCacheNotFound();
        SetupCacheSet();
        _userManager.Setup(m => m.FindByIdAsync(user.Id.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "123456"))
            .ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetClaimsAsync(user)).ReturnsAsync([]);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync([]);

        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = token,
            Code = "123456"
        });

        result.IsSuccessful.Should().BeTrue();
        result.Data!.Token.Should().NotBeNullOrWhiteSpace();
        result.Data.RefreshToken.Should().NotBeNullOrWhiteSpace();
        result.Data.RefreshTokenExpiryTime.Should().NotBeNull();
    }

    [Fact]
    public async Task LoginWith2FAAsync_ValidTOTPCode_StoresJtiInCacheWithCorrectTTL()
    {
        var jti = Guid.NewGuid().ToString();
        var user = MakeUser(twoFactorEnabled: true);
        var token = BuildChallengeToken(user.Id, jti);
        SetupCacheNotFound();
        DistributedCacheEntryOptions? capturedOptions = null;
        _cache.Setup(c => c.SetAsync(
                $"2fa_jti:{jti}",
                It.IsAny<byte[]>(),
                It.IsAny<DistributedCacheEntryOptions>(),
                It.IsAny<CancellationToken>()))
            .Callback<string, byte[], DistributedCacheEntryOptions, CancellationToken>(
                (_, _, opts, _) => capturedOptions = opts)
            .Returns(Task.CompletedTask);
        _userManager.Setup(m => m.FindByIdAsync(user.Id.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "123456"))
            .ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetClaimsAsync(user)).ReturnsAsync([]);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync([]);

        await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = token,
            Code = "123456"
        });

        _cache.Verify(c => c.SetAsync(
            $"2fa_jti:{jti}",
            It.IsAny<byte[]>(),
            It.IsAny<DistributedCacheEntryOptions>(),
            It.IsAny<CancellationToken>()), Times.Once);
        capturedOptions!.AbsoluteExpirationRelativeToNow.Should().Be(
            TimeSpan.FromMinutes(_jwtConfig.TwoFactorChallengeTokenExpiryInMinutes));
    }

    [Fact]
    public async Task LoginWith2FAAsync_ValidTOTPCode_CallsResetAccessFailedCount()
    {
        var jti = Guid.NewGuid().ToString();
        var user = MakeUser(twoFactorEnabled: true);
        var token = BuildChallengeToken(user.Id, jti);
        SetupCacheNotFound();
        SetupCacheSet();
        _userManager.Setup(m => m.FindByIdAsync(user.Id.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "123456"))
            .ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetClaimsAsync(user)).ReturnsAsync([]);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync([]);

        await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = token,
            Code = "123456"
        });

        _userManager.Verify(m => m.ResetAccessFailedCountAsync(user), Times.Once);
    }

    [Fact]
    public async Task LoginWith2FAAsync_ValidRecoveryCode_ReturnsRealTokens()
    {
        var jti = Guid.NewGuid().ToString();
        var user = MakeUser(twoFactorEnabled: true);
        var token = BuildChallengeToken(user.Id, jti);
        SetupCacheNotFound();
        SetupCacheSet();
        _userManager.Setup(m => m.FindByIdAsync(user.Id.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "recovery-code-1"))
            .ReturnsAsync(false);
        _userManager.Setup(m => m.RedeemTwoFactorRecoveryCodeAsync(user, "recovery-code-1"))
            .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetClaimsAsync(user)).ReturnsAsync([]);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync([]);

        var result = await _sut.LoginWith2FAAsync(new TwoFactorLoginRequest
        {
            TwoFactorChallengeToken = token,
            Code = "recovery-code-1"
        });

        result.IsSuccessful.Should().BeTrue();
        result.Data!.Token.Should().NotBeNullOrWhiteSpace();
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Identity\Services\TokenServiceTests.cs' @'
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using UMS.Application.Dtos.JWT;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Identity.Models;
using UMS.Infrastructure.Identity.Services;
using UMS.Infrastructure.Tests.Support;

namespace UMS.Infrastructure.Tests.Identity.Services;

public class TokenServiceTests
{
    private readonly Mock<UserManager<ApplicationUser>> _userManager;
    private readonly Mock<RoleManager<ApplicationRole>> _roleManager;
    private readonly Mock<IDateTimeService> _dateTimeService = new();
    private readonly Mock<IDistributedCache> _cache = new();
    private readonly JwtConfiguration _jwtConfig;
    private readonly TokenService _sut;

    private static readonly DateTime FixedNow = new(2025, 6, 1, 0, 0, 0, DateTimeKind.Utc);

    public TokenServiceTests()
    {
        _userManager = IdentityMockFactory.CreateUserManager();
        _roleManager = IdentityMockFactory.CreateRoleManager();
        _dateTimeService.Setup(d => d.NowUtc).Returns(FixedNow);

        _jwtConfig = new JwtConfiguration
        {
            Issuer = "ums-issuer",
            Audience = "ums-audience",
            Secret = "super-secret-key-for-testing-123456",
            TokenExpiryInMinutes = 60,
            RefreshTokenExpiryInDays = 7,
            TwoFactorChallengeTokenExpiryInMinutes = 5
        };

        _sut = new TokenService(
            _userManager.Object,
            _roleManager.Object,
            Options.Create(_jwtConfig),
            _dateTimeService.Object,
            _cache.Object);
    }

    private ApplicationUser MakeUser(string email = "user@test.com", bool active = true, bool confirmed = true, bool lockedOut = false) =>
        new()
        {
            Id = 1,
            Email = email,
            UserName = email,
            FullName = "Test User",
            PhoneNumber = "01012345678",
            IsActive = active,
            EmailConfirmed = confirmed,
            RefreshToken = "existing-refresh",
            RefreshTokenExpiryDate = FixedNow.AddDays(3)
        };

    private string BuildJwt(string email, DateTime? expiry = null)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtConfig.Secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new[] { new Claim(ClaimTypes.Email, email) };
        var token = new JwtSecurityToken(
            issuer: _jwtConfig.Issuer,
            audience: _jwtConfig.Audience,
            claims: claims,
            expires: expiry ?? FixedNow.AddMinutes(60),
            signingCredentials: credentials);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    // â”€â”€ GetTokenAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetTokenAsync_WhenUserNotFound_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByEmailAsync("x@x.com")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = "x@x.com", Password = "p" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Invalid Credentials.");
    }

    [Fact]
    public async Task GetTokenAsync_WhenUserInactive_ReturnsFail()
    {
        var user = MakeUser(active: false);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "p" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Contain("not active");
    }

    [Fact]
    public async Task GetTokenAsync_WhenEmailNotConfirmed_ReturnsFail()
    {
        var user = MakeUser(confirmed: false);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "p" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Email not confirmed.");
    }

    [Fact]
    public async Task GetTokenAsync_WhenPasswordInvalid_ReturnsFail()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "wrong")).ReturnsAsync(false);
        _userManager.Setup(m => m.AccessFailedAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "wrong" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Invalid Credentials.");
    }

    [Fact]
    public async Task GetTokenAsync_WhenLockedOut_ReturnsFail()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "pass")).ReturnsAsync(true);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(true);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "pass" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Contain("locked");
    }

    [Fact]
    public async Task GetTokenAsync_WhenSuccessful_ReturnsTokenResponseWithRequiredClaims()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Valid@1")).ReturnsAsync(true);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetClaimsAsync(user)).ReturnsAsync([]);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync(["Admin"]);
        var adminRole = new ApplicationRole { Id = 1, Name = "Admin" };
        _roleManager.Setup(m => m.FindByNameAsync("Admin")).ReturnsAsync(adminRole);
        _roleManager.Setup(m => m.GetClaimsAsync(adminRole)).ReturnsAsync([new Claim("permission", "Permission.Identity.Users.Read")]);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "Valid@1" });

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.Token.Should().NotBeNullOrEmpty();
        result.Data.RefreshToken.Should().NotBeNullOrEmpty();
        result.Data.RefreshTokenExpiryTime.Should().BeAfter(FixedNow);

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(result.Data.Token);
        jwt.Claims.Should().Contain(c => c.Type == ClaimTypes.NameIdentifier && c.Value == user.Id.ToString());
        jwt.Claims.Should().Contain(c => c.Type == ClaimTypes.Email && c.Value == user.Email);
        jwt.Claims.Should().Contain(c => c.Type == ClaimTypes.Role && c.Value == "Admin");
        jwt.Claims.Should().Contain(c => c.Value == "Permission.Identity.Users.Read");
        jwt.ValidTo.Should().BeCloseTo(FixedNow.AddMinutes(60), TimeSpan.FromSeconds(5));
    }

    [Fact]
    public async Task GetTokenAsync_WhenSuccessful_RotatesRefreshToken()
    {
        var user = MakeUser();
        var originalRefresh = user.RefreshToken;
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Valid@1")).ReturnsAsync(true);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetClaimsAsync(user)).ReturnsAsync([]);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync([]);

        var result = await _sut.GetTokenAsync(new TokenRequest { Email = user.Email!, Password = "Valid@1" });

        result.Data!.RefreshToken.Should().NotBe(originalRefresh);
    }

    // â”€â”€ GetRefreshTokenAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetRefreshTokenAsync_WhenUserNotFound_ReturnsFail()
    {
        var jwt = BuildJwt("ghost@test.com");
        _userManager.Setup(m => m.FindByEmailAsync("ghost@test.com")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.GetRefreshTokenAsync(new RefreshTokenRequest { Token = jwt, RefreshToken = "any" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task GetRefreshTokenAsync_WhenRefreshTokenMismatch_ReturnsFail()
    {
        var user = MakeUser();
        user.RefreshToken = "correct-refresh";
        var jwt = BuildJwt(user.Email!);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);

        var result = await _sut.GetRefreshTokenAsync(new RefreshTokenRequest { Token = jwt, RefreshToken = "wrong-refresh" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Invalid token provided.");
    }

    [Fact]
    public async Task GetRefreshTokenAsync_WhenRefreshTokenExpired_ReturnsFail()
    {
        var user = MakeUser();
        user.RefreshToken = "valid-token";
        user.RefreshTokenExpiryDate = FixedNow.AddDays(-1);
        var jwt = BuildJwt(user.Email!);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);

        var result = await _sut.GetRefreshTokenAsync(new RefreshTokenRequest { Token = jwt, RefreshToken = "valid-token" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Invalid token provided.");
    }

    [Fact]
    public async Task GetRefreshTokenAsync_WhenValid_ReturnsNewTokenAndRotatesRefresh()
    {
        var user = MakeUser();
        user.RefreshToken = "correct-refresh";
        var jwt = BuildJwt(user.Email!);
        _userManager.Setup(m => m.FindByEmailAsync(user.Email!)).ReturnsAsync(user);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GetClaimsAsync(user)).ReturnsAsync([]);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync([]);

        var result = await _sut.GetRefreshTokenAsync(new RefreshTokenRequest { Token = jwt, RefreshToken = "correct-refresh" });

        result.IsSuccessful.Should().BeTrue();
        result.Data!.Token.Should().NotBeNullOrEmpty();
        result.Data.RefreshToken.Should().NotBe("correct-refresh");
        result.Data.RefreshTokenExpiryTime.Should().BeAfter(FixedNow);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Identity\Services\UserServiceAuthTests.cs' @'
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using UMS.Application.Dtos.TwoFactor;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;
using UMS.Application.Features.Users.Commands.Logout;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Identity.Models;
using UMS.Infrastructure.Identity.Services;
using UMS.Infrastructure.Tests.Support;

namespace UMS.Infrastructure.Tests.Identity.Services;

public class UserServiceAuthTests
{
    private readonly Mock<UserManager<ApplicationUser>> _userManager;
    private readonly Mock<RoleManager<ApplicationRole>> _roleManager;
    private readonly Mock<IEmailService> _emailService = new();
    private readonly Mock<IHttpContextAccessor> _httpContextAccessor = new();
    private readonly Mock<IDateTimeService> _dateTimeService = new();
    private readonly Mock<ICurrentUserService> _currentUserService = new();
    private readonly UserService _sut;

    private const int TestUserId = 42;
    private static readonly DateTime FixedNow = new(2025, 1, 15, 12, 0, 0, DateTimeKind.Utc);

    public UserServiceAuthTests()
    {
        _userManager = IdentityMockFactory.CreateUserManager();
        _roleManager = IdentityMockFactory.CreateRoleManager();
        _dateTimeService.Setup(d => d.NowUtc).Returns(FixedNow);
        _currentUserService.Setup(s => s.GetUserId()).Returns(TestUserId);

        var mockRequest = new Mock<HttpRequest>();
        mockRequest.Setup(r => r.Scheme).Returns("https");
        mockRequest.Setup(r => r.Host).Returns(new HostString("example.com"));
        mockRequest.Setup(r => r.PathBase).Returns(new PathString(""));
        var mockHttpContext = new Mock<HttpContext>();
        mockHttpContext.Setup(c => c.Request).Returns(mockRequest.Object);
        _httpContextAccessor.Setup(a => a.HttpContext).Returns(mockHttpContext.Object);

        var twoFactorOptions = Options.Create(new TwoFactorOptions { Issuer = "TestApp" });

        _sut = new UserService(
            _userManager.Object,
            _roleManager.Object,
            _emailService.Object,
            _httpContextAccessor.Object,
            _dateTimeService.Object,
            _currentUserService.Object,
            twoFactorOptions,
            new Mock<ILogger<UserService>>().Object);
    }

    private ApplicationUser MakeUser(bool twoFactorEnabled = false) =>
        new()
        {
            Id = TestUserId,
            Email = "user@test.com",
            UserName = "user@test.com",
            FullName = "Test User",
            IsActive = true,
            EmailConfirmed = true,
            TwoFactorEnabled = twoFactorEnabled,
            PhoneNumber = "01012345678",
            CreatedDate = FixedNow.AddDays(-30),
            RefreshToken = "stored-refresh-token",
            RefreshTokenExpiryDate = FixedNow.AddDays(1)
        };

    // â”€â”€ LogoutAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task LogoutAsync_EmptyRefreshToken_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(MakeUser());

        var result = await _sut.LogoutAsync(new LogoutRequest { RefreshToken = "" });

        result.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task LogoutAsync_RefreshTokenDoesNotMatchStored_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(MakeUser());

        var result = await _sut.LogoutAsync(new LogoutRequest { RefreshToken = "wrong-token" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("Invalid refresh token"));
    }

    [Fact]
    public async Task LogoutAsync_ExpiredButMatchingToken_ClearsTokenAndReturnsSuccess()
    {
        var user = MakeUser();
        user.RefreshTokenExpiryDate = FixedNow.AddDays(-1);
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.LogoutAsync(new LogoutRequest { RefreshToken = "stored-refresh-token" });

        result.IsSuccessful.Should().BeTrue();
        user.RefreshToken.Should().BeEmpty();
    }

    [Fact]
    public async Task LogoutAsync_ValidToken_ClearsRefreshTokenAndSetsExpiryToThePast()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.LogoutAsync(new LogoutRequest { RefreshToken = "stored-refresh-token" });

        result.IsSuccessful.Should().BeTrue();
        user.RefreshToken.Should().BeEmpty();
        user.RefreshTokenExpiryDate.Should().BeBefore(FixedNow);
    }

    // â”€â”€ GetMyProfileAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetMyProfileAsync_ReturnsProfileWithCorrectUserFields()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync(["Basic"]);
        var basicRole = new ApplicationRole { Name = "Basic" };
        _roleManager.Setup(r => r.FindByNameAsync("Basic")).ReturnsAsync(basicRole);
        _roleManager.Setup(r => r.GetClaimsAsync(basicRole)).ReturnsAsync([]);

        var result = await _sut.GetMyProfileAsync();

        result.IsSuccessful.Should().BeTrue();
        result.Data!.Id.Should().Be(user.Id);
        result.Data.Email.Should().Be(user.Email);
        result.Data.FullName.Should().Be(user.FullName);
        result.Data.TwoFactorEnabled.Should().BeFalse();
    }

    [Fact]
    public async Task GetMyProfileAsync_ReturnsDeduplicatedPermissionsFromAllRoles()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync(["Basic", "Admin"]);
        var basicRole = new ApplicationRole { Name = "Basic" };
        var adminRole = new ApplicationRole { Name = "Admin" };
        _roleManager.Setup(r => r.FindByNameAsync("Basic")).ReturnsAsync(basicRole);
        _roleManager.Setup(r => r.FindByNameAsync("Admin")).ReturnsAsync(adminRole);
        _roleManager.Setup(r => r.GetClaimsAsync(basicRole))
            .ReturnsAsync([new System.Security.Claims.Claim("permission", "perm.read")]);
        _roleManager.Setup(r => r.GetClaimsAsync(adminRole))
            .ReturnsAsync([
                new System.Security.Claims.Claim("permission", "perm.read"),
                new System.Security.Claims.Claim("permission", "perm.write")
            ]);

        var result = await _sut.GetMyProfileAsync();

        result.Data!.Permissions.Should().HaveCount(2);
        result.Data.Permissions.Should().Contain("perm.read");
        result.Data.Permissions.Should().Contain("perm.write");
    }

    [Fact]
    public async Task GetMyProfileAsync_ReturnsFlatPermissionClaimValues()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync(["Basic"]);
        var basicRole = new ApplicationRole { Name = "Basic" };
        _roleManager.Setup(r => r.FindByNameAsync("Basic")).ReturnsAsync(basicRole);
        _roleManager.Setup(r => r.GetClaimsAsync(basicRole))
            .ReturnsAsync([new System.Security.Claims.Claim("permission", "Identity.Users.Read")]);

        var result = await _sut.GetMyProfileAsync();

        result.Data!.Permissions.Should().ContainSingle().Which.Should().Be("Identity.Users.Read");
    }

    // â”€â”€ SetupTwoFactorAuthAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task SetupTwoFactorAuthAsync_TwoFactorAlreadyEnabled_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(MakeUser(twoFactorEnabled: true));

        var result = await _sut.SetupTwoFactorAuthAsync();

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("already enabled"));
    }

    [Fact]
    public async Task SetupTwoFactorAuthAsync_ExistingKeyPresent_ReturnsExistingKeyWithoutCallingReset()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("EXISTING-KEY");

        var result = await _sut.SetupTwoFactorAuthAsync();

        result.IsSuccessful.Should().BeTrue();
        result.Data!.KeySecret.Should().Be("EXISTING-KEY");
        _userManager.Verify(m => m.ResetAuthenticatorKeyAsync(It.IsAny<ApplicationUser>()), Times.Never);
    }

    [Fact]
    public async Task SetupTwoFactorAuthAsync_NoKeyPresent_GeneratesAndReturnsNewKey()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.SetupSequence(m => m.GetAuthenticatorKeyAsync(user))
            .ReturnsAsync((string?)null)
            .ReturnsAsync("NEW-GENERATED-KEY");
        _userManager.Setup(m => m.ResetAuthenticatorKeyAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.SetupTwoFactorAuthAsync();

        result.IsSuccessful.Should().BeTrue();
        result.Data!.KeySecret.Should().Be("NEW-GENERATED-KEY");
        _userManager.Verify(m => m.ResetAuthenticatorKeyAsync(user), Times.Once);
    }

    [Fact]
    public async Task SetupTwoFactorAuthAsync_ReturnedCodeQRIsValidOtpauthUri()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("JBSWY3DPEHPK3PXP");

        var result = await _sut.SetupTwoFactorAuthAsync();

        result.Data!.CodeQR.Should().StartWith("otpauth://totp/");
    }

    [Fact]
    public async Task SetupTwoFactorAuthAsync_OtpauthUriContainsEncodedIssuerAndEmail()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("JBSWY3DPEHPK3PXP");

        var result = await _sut.SetupTwoFactorAuthAsync();

        result.Data!.CodeQR.Should().Contain("TestApp");
        result.Data.CodeQR.Should().Contain("user%40test.com");
        result.Data.CodeQR.Should().Contain("JBSWY3DPEHPK3PXP");
    }

    // â”€â”€ ConfirmTwoFactorAuthAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task ConfirmTwoFactorAuthAsync_NoAuthenticatorKeyExists_ReturnsFail()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync((string?)null);

        var result = await _sut.ConfirmTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "123456" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("setup-2fa"));
    }

    [Fact]
    public async Task ConfirmTwoFactorAuthAsync_WrongCode_ReturnsFailAndCallsAccessFailed()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("KEY");
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "000000"))
            .ReturnsAsync(false);
        _userManager.Setup(m => m.AccessFailedAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.ConfirmTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "000000" });

        result.IsSuccessful.Should().BeFalse();
        _userManager.Verify(m => m.AccessFailedAsync(user), Times.Once);
    }

    [Fact]
    public async Task ConfirmTwoFactorAuthAsync_ValidCode_ReturnsSuccessAndCallsResetAccessFailed()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("KEY");
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "123456"))
            .ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.ConfirmTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "123456" });

        result.IsSuccessful.Should().BeTrue();
        _userManager.Verify(m => m.ResetAccessFailedCountAsync(user), Times.Once);
    }

    [Fact]
    public async Task ConfirmTwoFactorAuthAsync_WorksWhenTwoFactorIsAlreadyEnabled()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("KEY");
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "123456"))
            .ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.ConfirmTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "123456" });

        result.IsSuccessful.Should().BeTrue();
    }

    // â”€â”€ EnableTwoFactorAuthAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task EnableTwoFactorAuthAsync_AlreadyEnabled_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(MakeUser(twoFactorEnabled: true));

        var result = await _sut.EnableTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "123456" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("already enabled"));
    }

    [Fact]
    public async Task EnableTwoFactorAuthAsync_NoAuthenticatorKey_ReturnsFail()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync((string?)null);

        var result = await _sut.EnableTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "123456" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("setup-2fa"));
    }

    [Fact]
    public async Task EnableTwoFactorAuthAsync_WrongCode_ReturnsFailAndCallsAccessFailed()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("KEY");
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "000000"))
            .ReturnsAsync(false);
        _userManager.Setup(m => m.AccessFailedAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);

        var result = await _sut.EnableTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "000000" });

        result.IsSuccessful.Should().BeFalse();
        _userManager.Verify(m => m.AccessFailedAsync(user), Times.Once);
    }

    [Fact]
    public async Task EnableTwoFactorAuthAsync_WrongCodeExceedsThreshold_ReturnsLockedOutMessage()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("KEY");
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), It.IsAny<string>()))
            .ReturnsAsync(false);
        _userManager.Setup(m => m.AccessFailedAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(true);

        var result = await _sut.EnableTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "000000" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("locked"));
    }

    [Fact]
    public async Task EnableTwoFactorAuthAsync_ValidCode_SetsTwoFactorEnabledTrue()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("KEY");
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "123456"))
            .ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.SetTwoFactorEnabledAsync(user, true)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GenerateNewTwoFactorRecoveryCodesAsync(user, 10))
            .ReturnsAsync(Enumerable.Range(1, 10).Select(i => $"code-{i}").ToArray());

        await _sut.EnableTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "123456" });

        _userManager.Verify(m => m.SetTwoFactorEnabledAsync(user, true), Times.Once);
    }

    [Fact]
    public async Task EnableTwoFactorAuthAsync_ValidCode_ReturnsTenRecoveryCodes()
    {
        var user = MakeUser();
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.GetAuthenticatorKeyAsync(user)).ReturnsAsync("KEY");
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "123456"))
            .ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.SetTwoFactorEnabledAsync(user, true)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GenerateNewTwoFactorRecoveryCodesAsync(user, 10))
            .ReturnsAsync(Enumerable.Range(1, 10).Select(i => $"code-{i}").ToArray());

        var result = await _sut.EnableTwoFactorAuthAsync(new TwoFactorCodeRequest { Code = "123456" });

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().HaveCount(10);
    }

    // â”€â”€ DisableTwoFactorAuthAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task DisableTwoFactorAuthAsync_TwoFactorNotEnabled_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(MakeUser(twoFactorEnabled: false));

        var result = await _sut.DisableTwoFactorAuthAsync(new DisableTwoFactorAuthRequest { Password = "Pass@123" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("not enabled"));
    }

    [Fact]
    public async Task DisableTwoFactorAuthAsync_WrongPassword_ReturnsFailAndCallsAccessFailed()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "WrongPass")).ReturnsAsync(false);
        _userManager.Setup(m => m.AccessFailedAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(false);

        var result = await _sut.DisableTwoFactorAuthAsync(new DisableTwoFactorAuthRequest { Password = "WrongPass" });

        result.IsSuccessful.Should().BeFalse();
        _userManager.Verify(m => m.AccessFailedAsync(user), Times.Once);
    }

    [Fact]
    public async Task DisableTwoFactorAuthAsync_WrongPasswordExceedsThreshold_ReturnsLockedOutMessage()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "WrongPass")).ReturnsAsync(false);
        _userManager.Setup(m => m.AccessFailedAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.IsLockedOutAsync(user)).ReturnsAsync(true);

        var result = await _sut.DisableTwoFactorAuthAsync(new DisableTwoFactorAuthRequest { Password = "WrongPass" });

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().Contain(m => m.Contains("locked"));
    }

    [Fact]
    public async Task DisableTwoFactorAuthAsync_WrongTOTPCode_ReturnsFailWithoutCallingAccessFailed()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Pass@123")).ReturnsAsync(true);
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "000000"))
            .ReturnsAsync(false);

        var result = await _sut.DisableTwoFactorAuthAsync(new DisableTwoFactorAuthRequest
        {
            Password = "Pass@123",
            Code = "000000"
        });

        result.IsSuccessful.Should().BeFalse();
        _userManager.Verify(m => m.AccessFailedAsync(It.IsAny<ApplicationUser>()), Times.Never);
    }

    [Fact]
    public async Task DisableTwoFactorAuthAsync_ValidPasswordNoCode_SetsTwoFactorEnabledFalse()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Pass@123")).ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.SetTwoFactorEnabledAsync(user, false)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.DisableTwoFactorAuthAsync(new DisableTwoFactorAuthRequest
        {
            Password = "Pass@123",
            Code = null
        });

        result.IsSuccessful.Should().BeTrue();
        _userManager.Verify(m => m.SetTwoFactorEnabledAsync(user, false), Times.Once);
    }

    [Fact]
    public async Task DisableTwoFactorAuthAsync_ValidPasswordValidCode_SetsTwoFactorEnabledFalse()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Pass@123")).ReturnsAsync(true);
        _userManager.Setup(m => m.VerifyTwoFactorTokenAsync(user, It.IsAny<string>(), "123456"))
            .ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.SetTwoFactorEnabledAsync(user, false)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.DisableTwoFactorAuthAsync(new DisableTwoFactorAuthRequest
        {
            Password = "Pass@123",
            Code = "123456"
        });

        result.IsSuccessful.Should().BeTrue();
        _userManager.Verify(m => m.SetTwoFactorEnabledAsync(user, false), Times.Once);
    }

    [Fact]
    public async Task DisableTwoFactorAuthAsync_DoesNotCallResetAuthenticatorKey()
    {
        var user = MakeUser(twoFactorEnabled: true);
        _userManager.Setup(m => m.FindByIdAsync(TestUserId.ToString())).ReturnsAsync(user);
        _userManager.Setup(m => m.CheckPasswordAsync(user, "Pass@123")).ReturnsAsync(true);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.SetTwoFactorEnabledAsync(user, false)).ReturnsAsync(IdentityResult.Success);

        await _sut.DisableTwoFactorAuthAsync(new DisableTwoFactorAuthRequest { Password = "Pass@123" });

        _userManager.Verify(m => m.ResetAuthenticatorKeyAsync(It.IsAny<ApplicationUser>()), Times.Never);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Identity\Services\UserServiceTests.cs' @'
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using UMS.Application.Dtos.TwoFactor;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Identity.Models;
using UMS.Infrastructure.Identity.Services;
using UMS.Infrastructure.Tests.Support;

namespace UMS.Infrastructure.Tests.Identity.Services;

public class UserServiceTests
{
    private readonly Mock<UserManager<ApplicationUser>> _userManager;
    private readonly Mock<RoleManager<ApplicationRole>> _roleManager;
    private readonly Mock<IEmailService> _emailService = new();
    private readonly Mock<IHttpContextAccessor> _httpContextAccessor = new();
    private readonly Mock<IDateTimeService> _dateTimeService = new();
    private readonly Mock<ICurrentUserService> _currentUserService = new();
    private readonly UserService _sut;

    private static readonly DateTime FixedNow = new(2025, 1, 15, 12, 0, 0, DateTimeKind.Utc);

    public UserServiceTests()
    {
        _userManager = IdentityMockFactory.CreateUserManager();
        _roleManager = IdentityMockFactory.CreateRoleManager();

        _dateTimeService.Setup(d => d.NowUtc).Returns(FixedNow);

        var mockRequest = new Mock<HttpRequest>();
        mockRequest.Setup(r => r.Scheme).Returns("https");
        mockRequest.Setup(r => r.Host).Returns(new HostString("example.com"));
        mockRequest.Setup(r => r.PathBase).Returns(new PathString(""));
        var mockHttpContext = new Mock<HttpContext>();
        mockHttpContext.Setup(c => c.Request).Returns(mockRequest.Object);
        _httpContextAccessor.Setup(a => a.HttpContext).Returns(mockHttpContext.Object);

        var twoFactorOptions = Options.Create(new TwoFactorOptions { Issuer = "TestApp" });

        _sut = new UserService(
            _userManager.Object,
            _roleManager.Object,
            _emailService.Object,
            _httpContextAccessor.Object,
            _dateTimeService.Object,
            _currentUserService.Object,
            twoFactorOptions,
            new Mock<ILogger<UserService>>().Object);
    }

    private static ApplicationUser MakeUser(int id = 1, string email = "user@test.com", bool confirmed = true, bool active = true) =>
        new()
        {
            Id = id,
            Email = email,
            UserName = email,
            FullName = "Test User",
            IsActive = active,
            EmailConfirmed = confirmed,
            RefreshToken = "token",
            RefreshTokenExpiryDate = FixedNow.AddDays(1)
        };

    // â”€â”€ RegisterUserAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task RegisterUserAsync_WhenEmailAlreadyTaken_ReturnsFail()
    {
        var req = new UserRegistrationRequest { Email = "taken@test.com", Password = "Pass@1", FullName = "X", AutoConfirmEmail = true, ActivateUser = true };
        _userManager.Setup(m => m.FindByEmailAsync(req.Email)).ReturnsAsync(MakeUser(email: req.Email));

        var result = await _sut.RegisterUserAsync(req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Email address already taken.");
    }

    [Fact]
    public async Task RegisterUserAsync_WhenUserCreationFails_ReturnsFail()
    {
        var req = new UserRegistrationRequest { Email = "new@test.com", Password = "Pass@1", FullName = "X", AutoConfirmEmail = true, ActivateUser = true };
        _userManager.Setup(m => m.FindByEmailAsync(req.Email)).ReturnsAsync((ApplicationUser?)null);
        _userManager.Setup(m => m.CreateAsync(It.IsAny<ApplicationUser>(), req.Password))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Password too weak." }));

        var result = await _sut.RegisterUserAsync(req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Password too weak.");
    }

    [Fact]
    public async Task RegisterUserAsync_WhenRoleAssignmentFails_ReturnsFail()
    {
        var req = new UserRegistrationRequest { Email = "new@test.com", Password = "Pass@1", FullName = "X", AutoConfirmEmail = true, ActivateUser = true };
        _userManager.Setup(m => m.FindByEmailAsync(req.Email)).ReturnsAsync((ApplicationUser?)null);
        _userManager.Setup(m => m.CreateAsync(It.IsAny<ApplicationUser>(), req.Password))
                    .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.AddToRoleAsync(It.IsAny<ApplicationUser>(), "Basic"))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Role not found." }));

        var result = await _sut.RegisterUserAsync(req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role not found.");
    }

    [Fact]
    public async Task RegisterUserAsync_WhenSuccessful_ReturnsSuccess()
    {
        var req = new UserRegistrationRequest { Email = "new@test.com", Password = "Pass@1", FullName = "Alice", AutoConfirmEmail = true, ActivateUser = true };
        _userManager.Setup(m => m.FindByEmailAsync(req.Email)).ReturnsAsync((ApplicationUser?)null);
        _userManager.Setup(m => m.CreateAsync(It.IsAny<ApplicationUser>(), req.Password))
                    .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.AddToRoleAsync(It.IsAny<ApplicationUser>(), "Basic"))
                    .ReturnsAsync(IdentityResult.Success);

        var result = await _sut.RegisterUserAsync(req);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("User registered successfully.");
    }

    // â”€â”€ UpdateUserAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task UpdateUserAsync_WhenUserNotFound_ReturnsFail()
    {
        var req = new UpdateUserRequest { UserId = 99, FullName = "X", PhoneNumber = "000" };
        _userManager.Setup(m => m.FindByIdAsync("99")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.UpdateUserAsync(req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exists.");
    }

    [Fact]
    public async Task UpdateUserAsync_WhenUpdateFails_ReturnsFail()
    {
        var user = MakeUser(5);
        var req = new UpdateUserRequest { UserId = 5, FullName = "New Name", PhoneNumber = "111" };
        _userManager.Setup(m => m.FindByIdAsync("5")).ReturnsAsync(user);
        _userManager.Setup(m => m.UpdateAsync(user))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Concurrency conflict." }));

        var result = await _sut.UpdateUserAsync(req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Concurrency conflict.");
    }

    [Fact]
    public async Task UpdateUserAsync_WhenSuccessful_ReturnsSuccess()
    {
        var user = MakeUser(5);
        var req = new UpdateUserRequest { UserId = 5, FullName = "New Name", PhoneNumber = "111" };
        _userManager.Setup(m => m.FindByIdAsync("5")).ReturnsAsync(user);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.UpdateUserAsync(req);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("User updated successfully.");
    }

    // â”€â”€ GetUserByIdAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetUserByIdAsync_WhenUserNotFound_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync("77")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.GetUserByIdAsync(77);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exists.");
    }

    [Fact]
    public async Task GetUserByIdAsync_WhenUserFound_ReturnsMappedUserResponse()
    {
        var user = MakeUser(3, "bob@test.com");
        _userManager.Setup(m => m.FindByIdAsync("3")).ReturnsAsync(user);

        var result = await _sut.GetUserByIdAsync(3);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().NotBeNull();
        result.Data!.Id.Should().Be(3);
        result.Data.Email.Should().Be("bob@test.com");
    }

    // â”€â”€ GetUsersPagedQueryAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetUsersPagedQueryAsync_ReturnsPaginatedResult()
    {
        var users = Enumerable.Range(1, 10)
            .Select(i => MakeUser(i, $"user{i}@test.com"))
            .ToList();
        _userManager.Setup(m => m.Users).Returns(new TestAsyncEnumerable<ApplicationUser>(users));

        var request = new UMS.Application.Dtos.Pagination.PagedFilterRequest
        {
            PageNumber = 1,
            PageSize = 5,
            SortBy = "email",
            SortDirection = "asc"
        };

        var result = await _sut.GetUsersPagedQueryAsync(request, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data!.TotalCount.Should().Be(10);
        result.Data.Data.Should().HaveCount(5);
        result.Data.CurrentPage.Should().Be(1);
    }

    [Fact]
    public async Task GetUsersPagedQueryAsync_SortByIdDesc_OrdersCorrectly()
    {
        var users = new List<ApplicationUser> { MakeUser(1), MakeUser(3), MakeUser(2) };
        _userManager.Setup(m => m.Users).Returns(new TestAsyncEnumerable<ApplicationUser>(users));

        var request = new UMS.Application.Dtos.Pagination.PagedFilterRequest
        {
            PageNumber = 1,
            PageSize = 10,
            SortBy = "id",
            SortDirection = "desc"
        };

        var result = await _sut.GetUsersPagedQueryAsync(request, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Data!.Data.Select(u => u.Id).Should().BeInDescendingOrder();
    }

    // â”€â”€ ChangeUserPasswordAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task ChangeUserPasswordAsync_WhenUserNotFound_ReturnsFail()
    {
        var req = new ChangePasswordRequest { CurrentPassword = "old", NewPassword = "new" };
        _userManager.Setup(m => m.FindByIdAsync("10")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.ChangeUserPasswordAsync(10, req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task ChangeUserPasswordAsync_WhenPasswordChangeFails_ReturnsFail()
    {
        var user = MakeUser(10);
        var req = new ChangePasswordRequest { CurrentPassword = "old", NewPassword = "new" };
        _userManager.Setup(m => m.FindByIdAsync("10")).ReturnsAsync(user);
        _userManager.Setup(m => m.ChangePasswordAsync(user, "old", "new"))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Incorrect current password." }));

        var result = await _sut.ChangeUserPasswordAsync(10, req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Incorrect current password.");
    }

    [Fact]
    public async Task ChangeUserPasswordAsync_WhenSuccessful_ReturnsSuccess()
    {
        var user = MakeUser(10);
        var req = new ChangePasswordRequest { CurrentPassword = "old", NewPassword = "New@123" };
        _userManager.Setup(m => m.FindByIdAsync("10")).ReturnsAsync(user);
        _userManager.Setup(m => m.ChangePasswordAsync(user, "old", "New@123"))
                    .ReturnsAsync(IdentityResult.Success);

        var result = await _sut.ChangeUserPasswordAsync(10, req);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("User password updated.");
    }

    // â”€â”€ ChangeUserStatusAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task ChangeUserStatusAsync_WhenUserNotFound_ReturnsFail()
    {
        var req = new ChangeUserStatusRequest { UserId = 20, ActivateOrDeactivate = true };
        _userManager.Setup(m => m.FindByIdAsync("20")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.ChangeUserStatusAsync(req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task ChangeUserStatusAsync_WhenUpdateFails_ReturnsFail()
    {
        var user = MakeUser(20);
        var req = new ChangeUserStatusRequest { UserId = 20, ActivateOrDeactivate = true };
        _userManager.Setup(m => m.FindByIdAsync("20")).ReturnsAsync(user);
        _userManager.Setup(m => m.UpdateAsync(user))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Store error." }));

        var result = await _sut.ChangeUserStatusAsync(req);

        result.IsSuccessful.Should().BeFalse();
    }

    [Fact]
    public async Task ChangeUserStatusAsync_WhenActivating_ReturnsActivatedMessage()
    {
        var user = MakeUser(20, active: false);
        var req = new ChangeUserStatusRequest { UserId = 20, ActivateOrDeactivate = true };
        _userManager.Setup(m => m.FindByIdAsync("20")).ReturnsAsync(user);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.ChangeUserStatusAsync(req);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("User activated successfully.");
    }

    [Fact]
    public async Task ChangeUserStatusAsync_WhenDeactivating_ReturnsDeactivatedMessage()
    {
        var user = MakeUser(20);
        var req = new ChangeUserStatusRequest { UserId = 20, ActivateOrDeactivate = false };
        _userManager.Setup(m => m.FindByIdAsync("20")).ReturnsAsync(user);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.ChangeUserStatusAsync(req);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("User de-activated successfully");
    }

    // â”€â”€ GetUserRolesAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GetUserRolesAsync_WhenUserNotFound_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync("5")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.GetUserRolesAsync(5);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task GetUserRolesAsync_WhenUserFound_ReturnsRoleViewModels()
    {
        var user = MakeUser(5);
        var adminRole = new ApplicationRole { Name = "Admin", Description = "Admins" };
        var basicRole = new ApplicationRole { Name = "Basic", Description = "Users" };
        var roles = new List<ApplicationRole> { adminRole, basicRole };

        _userManager.Setup(m => m.FindByIdAsync("5")).ReturnsAsync(user);
        _roleManager.Setup(m => m.Roles)
                    .Returns(new TestAsyncEnumerable<ApplicationRole>(roles));
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync(["Admin"]);

        var result = await _sut.GetUserRolesAsync(5);

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().ContainSingle().Which.RoleName.Should().Be("Admin");
    }

    // â”€â”€ UpdateUserRolesAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task UpdateUserRolesAsync_WhenUserNotFound_ReturnsFail()
    {
        var req = new UpdateUserRolesRequest { UserId = 99, Roles = ["Admin"] };
        var empty = new TestAsyncEnumerable<ApplicationUser>(Enumerable.Empty<ApplicationUser>());
        _userManager.Setup(m => m.Users).Returns(empty);

        var result = await _sut.UpdateUserRolesAsync(req, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task UpdateUserRolesAsync_WhenAdminEmail_ReturnsForbidden()
    {
        var adminUser = MakeUser(1, "admin@seed.com");
        var req = new UpdateUserRolesRequest { UserId = 1, Roles = ["Basic"] };
        _userManager.Setup(m => m.Users)
                    .Returns(new TestAsyncEnumerable<ApplicationUser>([adminUser]));
        _userManager.Setup(m => m.IsInRoleAsync(adminUser, "Admin")).ReturnsAsync(true);

        var result = await _sut.UpdateUserRolesAsync(req, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User roles update not permitted.");
    }

    [Fact]
    public async Task UpdateUserRolesAsync_WhenRoleDoesNotExist_ReturnsFail()
    {
        var user = MakeUser(2, "user@test.com");
        var req = new UpdateUserRolesRequest { UserId = 2, Roles = ["NonExistentRole"] };
        _userManager.Setup(m => m.Users)
                    .Returns(new TestAsyncEnumerable<ApplicationUser>([user]));
        _roleManager.Setup(m => m.RoleExistsAsync("NonExistentRole")).ReturnsAsync(false);

        var result = await _sut.UpdateUserRolesAsync(req, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Role 'NonExistentRole' does not exist.");
    }

    [Fact]
    public async Task UpdateUserRolesAsync_WhenRemoveFails_ReturnsFail()
    {
        var user = MakeUser(2, "user@test.com");
        var req = new UpdateUserRolesRequest { UserId = 2, Roles = ["Admin"] };
        _userManager.Setup(m => m.Users)
                    .Returns(new TestAsyncEnumerable<ApplicationUser>([user]));
        _roleManager.Setup(m => m.RoleExistsAsync("Admin")).ReturnsAsync(true);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync(["Basic"]);
        _userManager.Setup(m => m.RemoveFromRolesAsync(user, It.IsAny<IEnumerable<string>>()))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Remove error." }));

        var result = await _sut.UpdateUserRolesAsync(req, CancellationToken.None);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Remove error.");
    }

    [Fact]
    public async Task UpdateUserRolesAsync_WhenSuccessful_ReturnsSuccess()
    {
        var user = MakeUser(2, "user@test.com");
        var req = new UpdateUserRolesRequest { UserId = 2, Roles = ["Admin"] };
        _userManager.Setup(m => m.Users)
                    .Returns(new TestAsyncEnumerable<ApplicationUser>([user]));
        _roleManager.Setup(m => m.RoleExistsAsync("Admin")).ReturnsAsync(true);
        _userManager.Setup(m => m.GetRolesAsync(user)).ReturnsAsync(["Basic"]);
        _userManager.Setup(m => m.RemoveFromRolesAsync(user, It.IsAny<IEnumerable<string>>()))
                    .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.AddToRolesAsync(user, It.IsAny<IEnumerable<string>>()))
                    .ReturnsAsync(IdentityResult.Success);

        var result = await _sut.UpdateUserRolesAsync(req, CancellationToken.None);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Updated user roles successfully.");
    }

    // â”€â”€ ForgotPasswordAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task ForgotPasswordAsync_WhenUserNotFound_ReturnsSafeSuccessResponse()
    {
        _userManager.Setup(m => m.FindByEmailAsync("ghost@test.com")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.ForgotPasswordAsync("ghost@test.com");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("If the email is registered, you will receive an email shortly.");
    }

    [Fact]
    public async Task ForgotPasswordAsync_WhenEmailNotConfirmed_ReturnsSafeSuccessResponse()
    {
        var user = MakeUser(1, "u@t.com", confirmed: false);
        _userManager.Setup(m => m.FindByEmailAsync("u@t.com")).ReturnsAsync(user);

        var result = await _sut.ForgotPasswordAsync("u@t.com");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("If the email is registered, you will receive an email shortly.");
    }

    [Fact]
    public async Task ForgotPasswordAsync_WhenEmailServiceThrows_StillReturnsSafeSuccessResponse()
    {
        var user = MakeUser(1, "u@t.com");
        _userManager.Setup(m => m.FindByEmailAsync("u@t.com")).ReturnsAsync(user);
        _userManager.Setup(m => m.GeneratePasswordResetTokenAsync(user)).ReturnsAsync("reset-token");
        _emailService.Setup(e => e.SendAsync(It.IsAny<UMS.Application.Dtos.Email.SendEmailDto>(), It.IsAny<CancellationToken>()))
                     .ThrowsAsync(new InvalidOperationException("SMTP error"));

        var result = await _sut.ForgotPasswordAsync("u@t.com");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("If the email is registered, you will receive an email shortly.");
    }

    [Fact]
    public async Task ForgotPasswordAsync_WhenEmailSent_ReturnsSuccess()
    {
        var user = MakeUser(1, "u@t.com");
        _userManager.Setup(m => m.FindByEmailAsync("u@t.com")).ReturnsAsync(user);
        _userManager.Setup(m => m.GeneratePasswordResetTokenAsync(user)).ReturnsAsync("reset-token");
        _emailService.Setup(e => e.SendAsync(It.IsAny<UMS.Application.Dtos.Email.SendEmailDto>(), It.IsAny<CancellationToken>()))
                     .ReturnsAsync(string.Empty);

        var result = await _sut.ForgotPasswordAsync("u@t.com");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("If the email is registered, you will receive an email shortly.");
        _emailService.Verify(e => e.SendAsync(
            It.Is<UMS.Application.Dtos.Email.SendEmailDto>(dto => dto.MailTo == "u@t.com"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    // â”€â”€ ResetPasswordAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task ResetPasswordAsync_WhenUserNotFound_ReturnsFail()
    {
        var req = new ResetPasswordRequest { Email = "ghost@test.com", Token = "tok", Password = "New@1" };
        _userManager.Setup(m => m.FindByEmailAsync("ghost@test.com")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.ResetPasswordAsync(req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("This email doesn't exist.");
    }

    [Fact]
    public async Task ResetPasswordAsync_WhenEmailNotConfirmed_ReturnsFail()
    {
        var user = MakeUser(1, "u@t.com", confirmed: false);
        var req = new ResetPasswordRequest { Email = "u@t.com", Token = "tok", Password = "New@1" };
        _userManager.Setup(m => m.FindByEmailAsync("u@t.com")).ReturnsAsync(user);

        var result = await _sut.ResetPasswordAsync(req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("This email is not confirmed.");
    }

    [Fact]
    public async Task ResetPasswordAsync_WhenResetFails_ReturnsFail()
    {
        var user = MakeUser(1, "u@t.com");
        var req = new ResetPasswordRequest { Email = "u@t.com", Token = "bad-token", Password = "New@1" };
        _userManager.Setup(m => m.FindByEmailAsync("u@t.com")).ReturnsAsync(user);
        _userManager.Setup(m => m.ResetPasswordAsync(user, "bad-token", "New@1"))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Invalid token." }));

        var result = await _sut.ResetPasswordAsync(req);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Invalid token.");
    }

    [Fact]
    public async Task ResetPasswordAsync_WhenSuccessful_ReturnsSuccess()
    {
        var user = MakeUser(1, "u@t.com");
        var req = new ResetPasswordRequest { Email = "u@t.com", Token = "valid-token", Password = "New@123" };
        _userManager.Setup(m => m.FindByEmailAsync("u@t.com")).ReturnsAsync(user);
        _userManager.Setup(m => m.ResetPasswordAsync(user, "valid-token", "New@123"))
                    .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.UpdateSecurityStampAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.ResetPasswordAsync(req);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Your password has changed successfully.");
    }

    // â”€â”€ RegisterUserAsync (email confirmation path) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task RegisterUserAsync_WhenAutoConfirmEmailFalse_SendsConfirmationEmail()
    {
        var req = new UserRegistrationRequest
        {
            Email = "new@test.com", Password = "Pass@1", FullName = "Alice",
            AutoConfirmEmail = false, ActivateUser = true
        };
        _userManager.Setup(m => m.FindByEmailAsync(req.Email)).ReturnsAsync((ApplicationUser?)null);
        _userManager.Setup(m => m.CreateAsync(It.IsAny<ApplicationUser>(), req.Password))
                    .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.AddToRoleAsync(It.IsAny<ApplicationUser>(), "Basic"))
                    .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.GenerateEmailConfirmationTokenAsync(It.IsAny<ApplicationUser>()))
                    .ReturnsAsync("confirm-token");
        _emailService.Setup(e => e.SendAsync(It.IsAny<UMS.Application.Dtos.Email.SendEmailDto>(), It.IsAny<CancellationToken>()))
                     .ReturnsAsync(string.Empty);

        var result = await _sut.RegisterUserAsync(req);

        result.IsSuccessful.Should().BeTrue();
        _emailService.Verify(e => e.SendAsync(
            It.Is<UMS.Application.Dtos.Email.SendEmailDto>(dto =>
                dto.MailTo == req.Email &&
                dto.Subject == "Confirm Your Email"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task RegisterUserAsync_WhenAutoConfirmEmailTrue_DoesNotSendEmail()
    {
        var req = new UserRegistrationRequest
        {
            Email = "new@test.com", Password = "Pass@1", FullName = "Alice",
            AutoConfirmEmail = true, ActivateUser = true
        };
        _userManager.Setup(m => m.FindByEmailAsync(req.Email)).ReturnsAsync((ApplicationUser?)null);
        _userManager.Setup(m => m.CreateAsync(It.IsAny<ApplicationUser>(), req.Password))
                    .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.AddToRoleAsync(It.IsAny<ApplicationUser>(), "Basic"))
                    .ReturnsAsync(IdentityResult.Success);

        var result = await _sut.RegisterUserAsync(req);

        result.IsSuccessful.Should().BeTrue();
        _emailService.Verify(e => e.SendAsync(It.IsAny<UMS.Application.Dtos.Email.SendEmailDto>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    // â”€â”€ ConfirmEmailAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task ConfirmEmailAsync_WhenUserNotFound_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync("99")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.ConfirmEmailAsync(99, "tok");

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task ConfirmEmailAsync_WhenAlreadyConfirmed_ReturnsSuccessSilently()
    {
        var user = MakeUser(1, "u@t.com", confirmed: true);
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(user);

        var result = await _sut.ConfirmEmailAsync(1, "any-token");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Email is already confirmed.");
        _userManager.Verify(m => m.ConfirmEmailAsync(It.IsAny<ApplicationUser>(), It.IsAny<string>()), Times.Never);
    }

    [Fact]
    public async Task ConfirmEmailAsync_WhenTokenInvalid_ReturnsFail()
    {
        var user = MakeUser(1, "u@t.com", confirmed: false);
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(user);
        _userManager.Setup(m => m.ConfirmEmailAsync(user, "bad-token"))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Invalid token." }));

        var result = await _sut.ConfirmEmailAsync(1, "bad-token");

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Invalid token.");
    }

    [Fact]
    public async Task ConfirmEmailAsync_WhenSuccessful_ReturnsSuccess()
    {
        var user = MakeUser(1, "u@t.com", confirmed: false);
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(user);
        _userManager.Setup(m => m.ConfirmEmailAsync(user, "valid-token"))
                    .ReturnsAsync(IdentityResult.Success);

        var result = await _sut.ConfirmEmailAsync(1, "valid-token");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Email confirmed successfully.");
    }

    // â”€â”€ ConfirmEmailChangeAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task ConfirmEmailChangeAsync_WhenUserNotFound_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync("99")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.ConfirmEmailChangeAsync(99, "new@test.com", "tok");

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task ConfirmEmailChangeAsync_WhenTokenInvalid_ReturnsFail()
    {
        var user = MakeUser(1, "old@test.com");
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(user);
        _userManager.Setup(m => m.ChangeEmailAsync(user, "new@test.com", "bad-token"))
                    .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Invalid token." }));

        var result = await _sut.ConfirmEmailChangeAsync(1, "new@test.com", "bad-token");

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Invalid token.");
    }

    [Fact]
    public async Task ConfirmEmailChangeAsync_WhenSuccessful_SyncsUserNameAndReturnsSuccess()
    {
        var user = MakeUser(1, "old@test.com");
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(user);
        _userManager.Setup(m => m.ChangeEmailAsync(user, "new@test.com", "valid-token"))
                    .ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.SetUserNameAsync(user, "new@test.com"))
                    .ReturnsAsync(IdentityResult.Success);

        var result = await _sut.ConfirmEmailChangeAsync(1, "new@test.com", "valid-token");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Email changed successfully.");
        _userManager.Verify(m => m.SetUserNameAsync(user, "new@test.com"), Times.Once);
    }

    // â”€â”€ ResendConfirmationEmailAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task ResendConfirmationEmailAsync_WhenUserNotFound_ReturnsSafeSuccessResponse()
    {
        _userManager.Setup(m => m.FindByEmailAsync("ghost@test.com")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.ResendConfirmationEmailAsync("ghost@test.com");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("If the email is registered, you will receive an email shortly.");
    }

    [Fact]
    public async Task ResendConfirmationEmailAsync_WhenAlreadyConfirmed_ReturnsSafeSuccessResponse()
    {
        var user = MakeUser(1, "u@t.com", confirmed: true);
        _userManager.Setup(m => m.FindByEmailAsync("u@t.com")).ReturnsAsync(user);

        var result = await _sut.ResendConfirmationEmailAsync("u@t.com");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("If the email is registered, you will receive an email shortly.");
    }

    [Fact]
    public async Task ResendConfirmationEmailAsync_WhenUnconfirmed_SendsEmailAndReturnsSuccess()
    {
        var user = MakeUser(1, "u@t.com", confirmed: false);
        _userManager.Setup(m => m.FindByEmailAsync("u@t.com")).ReturnsAsync(user);
        _userManager.Setup(m => m.GenerateEmailConfirmationTokenAsync(user)).ReturnsAsync("confirm-token");
        _emailService.Setup(e => e.SendAsync(It.IsAny<UMS.Application.Dtos.Email.SendEmailDto>(), It.IsAny<CancellationToken>()))
                     .ReturnsAsync(string.Empty);

        var result = await _sut.ResendConfirmationEmailAsync("u@t.com");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("If the email is registered, you will receive an email shortly.");
        _emailService.Verify(e => e.SendAsync(
            It.Is<UMS.Application.Dtos.Email.SendEmailDto>(dto => dto.MailTo == "u@t.com"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    // â”€â”€ GenerateChangeEmailTokenAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GenerateChangeEmailTokenAsync_WhenUserNotFound_ReturnsFail()
    {
        _currentUserService.Setup(s => s.GetUserId()).Returns(5);
        _userManager.Setup(m => m.FindByIdAsync("5")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.GenerateChangeEmailTokenAsync("new@test.com");

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task GenerateChangeEmailTokenAsync_WhenSameEmail_ReturnsFail()
    {
        var user = MakeUser(1, "same@test.com");
        _currentUserService.Setup(s => s.GetUserId()).Returns(1);
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(user);

        var result = await _sut.GenerateChangeEmailTokenAsync("same@test.com");

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("New email must be different from your current email.");
    }

    [Fact]
    public async Task GenerateChangeEmailTokenAsync_WhenSuccessful_SendsEmailAndReturnsSuccess()
    {
        var user = MakeUser(1, "old@test.com");
        _currentUserService.Setup(s => s.GetUserId()).Returns(1);
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(user);
        _userManager.Setup(m => m.GenerateChangeEmailTokenAsync(user, "new@test.com")).ReturnsAsync("change-token");
        _emailService.Setup(e => e.SendAsync(It.IsAny<UMS.Application.Dtos.Email.SendEmailDto>(), It.IsAny<CancellationToken>()))
                     .ReturnsAsync(string.Empty);

        var result = await _sut.GenerateChangeEmailTokenAsync("new@test.com");

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("Email change confirmation sent. Please check your inbox.");
        _emailService.Verify(e => e.SendAsync(
            It.Is<UMS.Application.Dtos.Email.SendEmailDto>(dto =>
                dto.MailTo == "old@test.com" &&
                dto.Subject == "Confirm Your Email Change"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    // â”€â”€ GenerateNew2FARecoveryCodesAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task GenerateNew2FARecoveryCodesAsync_WhenUserNotFound_ReturnsFail()
    {
        _currentUserService.Setup(s => s.GetUserId()).Returns(5);
        _userManager.Setup(m => m.FindByIdAsync("5")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.GenerateNew2FARecoveryCodesAsync();

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task GenerateNew2FARecoveryCodesAsync_WhenTwoFactorNotEnabled_ReturnsFail()
    {
        var user = MakeUser(1);
        user.TwoFactorEnabled = false;
        _currentUserService.Setup(s => s.GetUserId()).Returns(1);
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(user);

        var result = await _sut.GenerateNew2FARecoveryCodesAsync();

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Two-factor authentication is not enabled.");
    }

    [Fact]
    public async Task GenerateNew2FARecoveryCodesAsync_WhenSuccessful_ReturnsTenCodes()
    {
        var user = MakeUser(1);
        user.TwoFactorEnabled = true;
        var codes = Enumerable.Range(1, 10).Select(i => $"code{i}").ToList();
        _currentUserService.Setup(s => s.GetUserId()).Returns(1);
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(user);
        _userManager.Setup(m => m.GenerateNewTwoFactorRecoveryCodesAsync(user, 10))
                    .ReturnsAsync(codes);

        var result = await _sut.GenerateNew2FARecoveryCodesAsync();

        result.IsSuccessful.Should().BeTrue();
        result.Data.Should().HaveCount(10);
        result.Messages.Should().ContainSingle().Which.Should().Be("New recovery codes generated.");
    }

    // â”€â”€ LockUserAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task LockUserAsync_WhenUserNotFound_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync("99")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.LockUserAsync(99);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task LockUserAsync_WhenSeedAdmin_ReturnsFail()
    {
        var admin = MakeUser(1, "admin@seed.com");
        _userManager.Setup(m => m.FindByIdAsync("1")).ReturnsAsync(admin);
        _userManager.Setup(m => m.IsInRoleAsync(admin, "Admin")).ReturnsAsync(true);

        var result = await _sut.LockUserAsync(1);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("Cannot lock the system administrator.");
    }

    [Fact]
    public async Task LockUserAsync_WhenSuccessful_InvalidatesRefreshTokenAndReturnsSuccess()
    {
        var user = MakeUser(2, "user@test.com");
        _userManager.Setup(m => m.FindByIdAsync("2")).ReturnsAsync(user);
        _userManager.Setup(m => m.SetLockoutEnabledAsync(user, true)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue)).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.LockUserAsync(2);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("User locked successfully.");
        user.RefreshTokenExpiryDate.Should().BeBefore(FixedNow);
    }

    // â”€â”€ UnlockUserAsync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    [Fact]
    public async Task UnlockUserAsync_WhenUserNotFound_ReturnsFail()
    {
        _userManager.Setup(m => m.FindByIdAsync("99")).ReturnsAsync((ApplicationUser?)null);

        var result = await _sut.UnlockUserAsync(99);

        result.IsSuccessful.Should().BeFalse();
        result.Messages.Should().ContainSingle().Which.Should().Be("User does not exist.");
    }

    [Fact]
    public async Task UnlockUserAsync_WhenSuccessful_ResetsFailedCountAndReturnsSuccess()
    {
        var user = MakeUser(2, "user@test.com");
        _userManager.Setup(m => m.FindByIdAsync("2")).ReturnsAsync(user);
        _userManager.Setup(m => m.SetLockoutEndDateAsync(user, It.IsAny<DateTimeOffset>())).ReturnsAsync(IdentityResult.Success);
        _userManager.Setup(m => m.ResetAccessFailedCountAsync(user)).ReturnsAsync(IdentityResult.Success);

        var result = await _sut.UnlockUserAsync(2);

        result.IsSuccessful.Should().BeTrue();
        result.Messages.Should().ContainSingle().Which.Should().Be("User unlocked successfully.");
        _userManager.Verify(m => m.ResetAccessFailedCountAsync(user), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Services\Common\CurrentUserServiceTests.cs' @'
using Microsoft.AspNetCore.Http;
using System.Security.Claims;
using UMS.Infrastructure.Services.Common;

namespace UMS.Infrastructure.Tests.Services.Common;

public class CurrentUserServiceTests
{
    private static ClaimsPrincipal AuthenticatedPrincipal(
        int userId = 7,
        string email = "user@test.com",
        string name = "Test User",
        string role = "Admin")
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Email, email),
            new Claim(ClaimTypes.Name, name),
            new Claim(ClaimTypes.Role, role)
        };
        return new ClaimsPrincipal(new ClaimsIdentity(claims, "TestScheme"));
    }

    private static CurrentUserService BuildService(ClaimsPrincipal? principal = null)
    {
        var accessor = new Mock<IHttpContextAccessor>();
        if (principal is not null)
        {
            var ctx = new DefaultHttpContext { User = principal };
            accessor.Setup(a => a.HttpContext).Returns(ctx);
        }
        else
        {
            accessor.Setup(a => a.HttpContext).Returns((HttpContext?)null);
        }

        return new CurrentUserService(accessor.Object);
    }

    [Fact]
    public void User_WhenHttpContextHasUser_ReturnsHttpContextUser()
    {
        var principal = AuthenticatedPrincipal();
        var sut = BuildService(principal);

        sut.User.Should().Be(principal);
    }

    [Fact]
    public void User_WhenExplicitPrincipalIsSet_OverridesHttpContextUser()
    {
        var sut = BuildService(AuthenticatedPrincipal(1, "original@test.com"));
        var overridePrincipal = AuthenticatedPrincipal(99, "override@test.com");

        sut.SetCurrentUser(overridePrincipal);

        sut.User.Should().Be(overridePrincipal);
    }

    [Fact]
    public void GetUserId_WhenNameIdentifierClaimPresent_ReturnsId()
    {
        var sut = BuildService(AuthenticatedPrincipal(42));

        sut.GetUserId().Should().Be(42);
    }

    [Fact]
    public void GetUserId_WhenNoHttpContext_ReturnsNull()
    {
        var sut = BuildService(null);

        sut.GetUserId().Should().BeNull();
    }

    [Fact]
    public void GetUserEmail_WhenAuthenticated_ReturnsEmail()
    {
        var sut = BuildService(AuthenticatedPrincipal(1, "alice@example.com"));

        sut.GetUserEmail().Should().Be("alice@example.com");
    }

    [Fact]
    public void GetUserEmail_WhenNoHttpContext_ReturnsEmptyString()
    {
        var sut = BuildService(null);

        sut.GetUserEmail().Should().BeEmpty();
    }

    [Fact]
    public void IsAuthenticated_WhenContextHasAuthenticatedPrincipal_ReturnsTrue()
    {
        var sut = BuildService(AuthenticatedPrincipal());

        sut.IsAuthenticated().Should().BeTrue();
    }

    [Fact]
    public void IsAuthenticated_WhenNoHttpContext_ReturnsFalse()
    {
        var sut = BuildService(null);

        sut.IsAuthenticated().Should().BeFalse();
    }

    [Fact]
    public void GetRoles_WhenUserHasRoleClaim_ReturnsRoles()
    {
        var sut = BuildService(AuthenticatedPrincipal(1, role: "Editor"));

        sut.GetRoles().Should().ContainSingle().Which.Should().Be("Editor");
    }

    [Fact]
    public void GetClaims_WhenAuthenticated_ReturnsAllClaims()
    {
        var sut = BuildService(AuthenticatedPrincipal());

        sut.GetClaims().Should().NotBeEmpty();
    }

    [Fact]
    public void HasRole_WhenUserIsInRole_ReturnsTrue()
    {
        var sut = BuildService(AuthenticatedPrincipal(1, role: "Admin"));

        sut.HasRole("Admin").Should().BeTrue();
    }

    [Fact]
    public void HasRole_WhenUserIsNotInRole_ReturnsFalse()
    {
        var sut = BuildService(AuthenticatedPrincipal(1, role: "Basic"));

        sut.HasRole("Admin").Should().BeFalse();
    }

    [Fact]
    public void HasClaim_WhenUserHasClaim_ReturnsTrue()
    {
        var sut = BuildService(AuthenticatedPrincipal(1, role: "Admin"));

        sut.HasClaim(ClaimTypes.Role, "Admin").Should().BeTrue();
    }

    [Fact]
    public void HasClaim_WhenUserDoesNotHaveClaim_ReturnsFalse()
    {
        var sut = BuildService(AuthenticatedPrincipal(1, role: "Basic"));

        sut.HasClaim(ClaimTypes.Role, "Admin").Should().BeFalse();
    }

    [Fact]
    public void Name_WhenContextHasNameClaim_ReturnsName()
    {
        var sut = BuildService(AuthenticatedPrincipal(name: "Bob Smith"));

        sut.Name.Should().Be("Bob Smith");
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Services\Common\DateTimeServiceTests.cs' @'
using UMS.Infrastructure.Services.Common;

namespace UMS.Infrastructure.Tests.Services.Common;

public class DateTimeServiceTests
{
    [Fact]
    public void NowUtc_ReturnsValueWithinCurrentSecond()
    {
        var before = DateTime.UtcNow;
        var sut = new DateTimeService();

        var result = sut.NowUtc;

        var after = DateTime.UtcNow;
        result.Should().BeOnOrAfter(before).And.BeOnOrBefore(after);
    }

    [Fact]
    public void NowUtc_KindIsUtc()
    {
        var sut = new DateTimeService();

        sut.NowUtc.Kind.Should().Be(DateTimeKind.Utc);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Services\Common\DistributedCacheServiceTests.cs' @'
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Options;
using System.Text;
using System.Text.Json;
using UMS.Application.Dtos.Cache;
using UMS.Infrastructure.Services.Common;

namespace UMS.Infrastructure.Tests.Services.Common;

public class DistributedCacheServiceTests
{
    private readonly Mock<IDistributedCache> _cache = new();
    private readonly DistributedCacheService _sut;

    public DistributedCacheServiceTests()
    {
        var config = Options.Create(new CacheConfiguration { SlidingExpirationInMinutes = 10 });
        _sut = new DistributedCacheService(_cache.Object, config);
    }

    [Fact]
    public void TryGet_WhenKeyNotFound_ReturnsFalseAndDefaultValue()
    {
        _cache.Setup(c => c.Get("missing")).Returns((byte[]?)null);

        var found = _sut.TryGet<string>("missing", out var value);

        found.Should().BeFalse();
        value.Should().BeNull();
    }

    [Fact]
    public void TryGet_WhenKeyFound_ReturnsTrueAndDeserializedValue()
    {
        var payload = new { name = "Alice", score = 99 };
        var json = JsonSerializer.Serialize(payload, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        _cache.Setup(c => c.Get("hit")).Returns(Encoding.UTF8.GetBytes(json));

        var found = _sut.TryGet<JsonElement>("hit", out var value);

        found.Should().BeTrue();
        value.GetProperty("name").GetString().Should().Be("Alice");
        value.GetProperty("score").GetInt32().Should().Be(99);
    }

    [Fact]
    public void Set_SerializesValueCachesItWithSlidingExpirationAndReturnsValue()
    {
        byte[]? capturedBytes = null;
        DistributedCacheEntryOptions? capturedOptions = null;
        _cache.Setup(c => c.Set(It.IsAny<string>(), It.IsAny<byte[]>(), It.IsAny<DistributedCacheEntryOptions>()))
              .Callback<string, byte[], DistributedCacheEntryOptions>((_, b, o) =>
              {
                  capturedBytes = b;
                  capturedOptions = o;
              });

        var result = _sut.Set("k", "hello-world");

        result.Should().Be("hello-world");
        capturedBytes.Should().NotBeNull();
        Encoding.UTF8.GetString(capturedBytes!).Should().Contain("hello-world");
        capturedOptions!.SlidingExpiration.Should().Be(TimeSpan.FromMinutes(10));
    }

    [Fact]
    public void Remove_DelegatesToUnderlyingCache()
    {
        _sut.Remove("stale-key");

        _cache.Verify(c => c.Remove("stale-key"), Times.Once);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Services\Common\InMemorySessionWrapperTests.cs' @'
#pragma warning disable CS8600 // Moq out-parameter setup triggers nullable false-positives
using Microsoft.AspNetCore.Http;
using System.Text;
using UMS.Infrastructure.Common;

namespace UMS.Infrastructure.Tests.Services.Common;

public class InMemorySessionWrapperTests
{
    private static (InMemorySessionWrapper Sut, Mock<ISession> Session) Build()
    {
        var session = new Mock<ISession>();
        var httpContext = new Mock<HttpContext>();
        httpContext.Setup(c => c.Session).Returns(session.Object);
        var accessor = new Mock<IHttpContextAccessor>();
        accessor.Setup(a => a.HttpContext).Returns(httpContext.Object);
        return (new InMemorySessionWrapper(accessor.Object), session);
    }

    [Fact]
    public void GetFromSession_WhenKeyAbsent_ReturnsDefault()
    {
        var (sut, session) = Build();
        byte[] absent = [];
        session.Setup(s => s.TryGetValue("missing", out absent)).Returns(false);

        var result = sut.GetFromSession<string>("missing");

        result.Should().BeNull();
    }

    [Fact]
    public void GetFromSession_WhenKeyPresent_ReturnsDeserializedValue()
    {
        var (sut, session) = Build();
        var json = "{\"name\":\"alice\",\"score\":42}";
        byte[] stored = Encoding.UTF8.GetBytes(json);
        session.Setup(s => s.TryGetValue("key", out stored)).Returns(true);

        var result = sut.GetFromSession<SessionPayload>("key");

        result.Should().NotBeNull();
        result!.Name.Should().Be("alice");
        result.Score.Should().Be(42);
    }

    [Fact]
    public void SetInSession_WhenValueIsNull_NeverCallsSet()
    {
        var (sut, session) = Build();

        sut.SetInSession<string?>("key", null);

        session.Verify(s => s.Set(It.IsAny<string>(), It.IsAny<byte[]>()), Times.Never);
    }

    [Fact]
    public void SetInSession_WhenValueIsNotNull_StoresSerializedBytes()
    {
        var (sut, session) = Build();
        byte[]? captured = null;
        session.Setup(s => s.Set("key", It.IsAny<byte[]>()))
               .Callback<string, byte[]>((_, b) => captured = b);

        sut.SetInSession("key", new SessionPayload { Name = "bob", Score = 7 });

        session.Verify(s => s.Set("key", It.IsAny<byte[]>()), Times.Once);
        var decoded = Encoding.UTF8.GetString(captured!);
        decoded.Should().Contain("bob");
    }

    [Fact]
    public void RemoveFromSession_DelegatesToSession()
    {
        var (sut, session) = Build();

        sut.RemoveFromSession("old-key");

        session.Verify(s => s.Remove("old-key"), Times.Once);
    }

    private sealed class SessionPayload
    {
        public string Name { get; set; } = string.Empty;
        public int Score { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Services\LocalFileStorageServiceTests.cs' @'
using Microsoft.AspNetCore.Hosting;
using UMS.Application.Dtos.Common;
using UMS.Infrastructure.Services;
using UMS.Infrastructure.Tests.Fixtures;

namespace UMS.Infrastructure.Tests.Services;

public class LocalFileStorageServiceTests : IClassFixture<TempDirectoryFixture>
{
    private readonly TempDirectoryFixture _fixture;

    public LocalFileStorageServiceTests(TempDirectoryFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task SaveFileAsync_should_persist_file_under_web_root_folder()
    {
        var environment = new Mock<IWebHostEnvironment>();
        environment.SetupGet(x => x.WebRootPath).Returns(_fixture.RootPath);

        var service = new LocalFileStorageService(environment.Object);
        await using var stream = new MemoryStream("seed-image"u8.ToArray());
        var file = new FileData
        {
            Content = stream,
            FileName = "banner.png",
            ContentType = "image/png",
            Length = stream.Length
        };

        var savedFileName = await service.SaveFileAsync(file, "images", CancellationToken.None);
        var savedPath = Path.Combine(_fixture.RootPath, "images", savedFileName);

        savedFileName.Should().EndWith(".png");
        File.Exists(savedPath).Should().BeTrue();
        (await File.ReadAllTextAsync(savedPath)).Should().Be("seed-image");
    }

    [Fact]
    public async Task SaveFileAsync_should_fall_back_to_current_directory_when_web_root_is_missing()
    {
        var currentDirectory = Directory.GetCurrentDirectory();
        var fallbackRoot = Path.Combine(currentDirectory, "wwwroot", "avatars");

        try
        {
            var environment = new Mock<IWebHostEnvironment>();
            environment.SetupGet(x => x.WebRootPath).Returns(string.Empty);

            var service = new LocalFileStorageService(environment.Object);
            await using var stream = new MemoryStream("avatar"u8.ToArray());
            var file = new FileData
            {
                Content = stream,
                FileName = "avatar.jpg",
                ContentType = "image/jpeg",
                Length = stream.Length
            };

            var savedFileName = await service.SaveFileAsync(file, "avatars", CancellationToken.None);

            File.Exists(Path.Combine(fallbackRoot, savedFileName)).Should().BeTrue();
        }
        finally
        {
            var wwwrootPath = Path.Combine(currentDirectory, "wwwroot");

            if (Directory.Exists(wwwrootPath))
            {
                Directory.Delete(wwwrootPath, recursive: true);
            }
        }
    }

    [Fact]
    public void DeleteFile_should_remove_existing_file_and_ignore_missing_ones()
    {
        var folder = Path.Combine(_fixture.RootPath, "docs");
        Directory.CreateDirectory(folder);
        var fileName = "sample.txt";
        var fullPath = Path.Combine(folder, fileName);
        File.WriteAllText(fullPath, "content");

        var environment = new Mock<IWebHostEnvironment>();
        environment.SetupGet(x => x.WebRootPath).Returns(_fixture.RootPath);

        var service = new LocalFileStorageService(environment.Object);

        service.DeleteFile(fileName, "docs");
        service.DeleteFile("missing.txt", "docs");

        File.Exists(fullPath).Should().BeFalse();
    }

    [Fact]
    public async Task SaveFileAsync_should_honor_cancellation_token_when_web_root_exists()
    {
        var environment = new Mock<IWebHostEnvironment>();
        environment.SetupGet(x => x.WebRootPath).Returns(_fixture.RootPath);

        var service = new LocalFileStorageService(environment.Object);
        await using var stream = new MemoryStream(new byte[1024]);
        var file = new FileData
        {
            Content = stream,
            FileName = "cancelled.bin",
            ContentType = "application/octet-stream",
            Length = stream.Length
        };
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        var act = () => service.SaveFileAsync(file, "cancel-rooted", cts.Token);

        await act.Should().ThrowAsync<OperationCanceledException>();
    }

    [Fact]
    public async Task SaveFileAsync_should_honor_cancellation_token_when_falling_back_to_current_directory()
    {
        var currentDirectory = Directory.GetCurrentDirectory();
        var wwwrootPath = Path.Combine(currentDirectory, "wwwroot");

        try
        {
            var environment = new Mock<IWebHostEnvironment>();
            environment.SetupGet(x => x.WebRootPath).Returns(string.Empty);

            var service = new LocalFileStorageService(environment.Object);
            await using var stream = new MemoryStream(new byte[1024]);
            var file = new FileData
            {
                Content = stream,
                FileName = "cancelled.bin",
                ContentType = "application/octet-stream",
                Length = stream.Length
            };
            using var cts = new CancellationTokenSource();
            cts.Cancel();

            var act = () => service.SaveFileAsync(file, "cancel-fallback", cts.Token);

            await act.Should().ThrowAsync<OperationCanceledException>();
        }
        finally
        {
            if (Directory.Exists(wwwrootPath))
            {
                Directory.Delete(wwwrootPath, recursive: true);
            }
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Services\MailSenderServiceTests.cs' @'
using FluentEmail.Core;
using Microsoft.Extensions.Options;
using System.Net.Mail;
using System.Reflection;
using UMS.Application.Dtos.Email;
using UMS.Infrastructure.Services.Common;

namespace UMS.Infrastructure.Tests.Services;

public class MailSenderServiceTests
{
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task SendAsync_should_configure_smtp_ssl_from_options(bool enableSsl)
    {
        var options = Options.Create(new EmailConfiguration
        {
            Host = "127.0.0.1",
            Port = 1,
            Email = "sender@example.com",
            Password = "password",
            DisplayName = "Sender",
            EnableSsl = enableSsl
        });
        var service = new MailSenderService(options);

        await service.SendAsync(
            new SendEmailDto
            {
                MailTo = "receiver@example.com",
                Subject = "Test",
                MessageBody = "Body"
            },
            CancellationToken.None);

        var sender = Email.DefaultSender;
        sender.Should().NotBeNull();
        var smtpClientField = sender.GetType()
            .GetField("_smtpClient", BindingFlags.Instance | BindingFlags.NonPublic);
        smtpClientField.Should().NotBeNull();

        var smtpClientValue = smtpClientField!.GetValue(sender);
        smtpClientValue.Should().BeOfType<SmtpClient>();
        var smtpClient = (SmtpClient)smtpClientValue!;

        smtpClient.EnableSsl.Should().Be(enableSsl);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Support\IdentityMockFactory.cs' @'
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using UMS.Infrastructure.Identity.Models;

namespace UMS.Infrastructure.Tests.Support;

internal static class IdentityMockFactory
{
    public static Mock<UserManager<ApplicationUser>> CreateUserManager()
    {
        var store = new Mock<IUserStore<ApplicationUser>>();
        var options = new Mock<IOptions<IdentityOptions>>();
        options.Setup(x => x.Value).Returns(new IdentityOptions());
        var passwordHasher = new Mock<IPasswordHasher<ApplicationUser>>();
        var keyNormalizer = new Mock<ILookupNormalizer>();
        var errors = new IdentityErrorDescriber();
        var logger = new Mock<ILogger<UserManager<ApplicationUser>>>();

        return new Mock<UserManager<ApplicationUser>>(
            store.Object,
            options.Object,
            passwordHasher.Object,
            Array.Empty<IUserValidator<ApplicationUser>>(),
            Array.Empty<IPasswordValidator<ApplicationUser>>(),
            keyNormalizer.Object,
            errors,
            null!,
            logger.Object);
    }

    public static Mock<RoleManager<ApplicationRole>> CreateRoleManager()
    {
        var store = new Mock<IRoleStore<ApplicationRole>>();
        var keyNormalizer = new Mock<ILookupNormalizer>();
        var errors = new IdentityErrorDescriber();
        var logger = new Mock<ILogger<RoleManager<ApplicationRole>>>();

        return new Mock<RoleManager<ApplicationRole>>(
            store.Object,
            Array.Empty<IRoleValidator<ApplicationRole>>(),
            keyNormalizer.Object,
            errors,
            logger.Object);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\Support\TestAsyncQueryProvider.cs' @'
using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore.Query;

namespace UMS.Infrastructure.Tests.Support;

internal class TestAsyncQueryProvider<TEntity> : IAsyncQueryProvider
{
    private readonly IQueryProvider _inner;

    internal TestAsyncQueryProvider(IQueryProvider inner) => _inner = inner;

    public IQueryable CreateQuery(Expression expression) =>
        new TestAsyncEnumerable<TEntity>(expression);

    public IQueryable<TElement> CreateQuery<TElement>(Expression expression) =>
        new TestAsyncEnumerable<TElement>(expression);

    public object? Execute(Expression expression) => _inner.Execute(expression);

    public TResult Execute<TResult>(Expression expression) => _inner.Execute<TResult>(expression);

    public TResult ExecuteAsync<TResult>(Expression expression, CancellationToken cancellationToken)
    {
        var resultType = typeof(TResult).GetGenericArguments()[0];
        var result = typeof(IQueryProvider)
            .GetMethod(nameof(IQueryProvider.Execute), 1, [typeof(Expression)])!
            .MakeGenericMethod(resultType)
            .Invoke(_inner, [expression]);
        return (TResult)typeof(Task)
            .GetMethod(nameof(Task.FromResult))!
            .MakeGenericMethod(resultType)
            .Invoke(null, [result])!;
    }
}

internal class TestAsyncEnumerable<T> : EnumerableQuery<T>, IAsyncEnumerable<T>, IQueryable<T>
{
    public TestAsyncEnumerable(IEnumerable<T> enumerable) : base(enumerable) { }
    public TestAsyncEnumerable(Expression expression) : base(expression) { }

    IQueryProvider IQueryable.Provider => new TestAsyncQueryProvider<T>(this);

    public IAsyncEnumerator<T> GetAsyncEnumerator(CancellationToken cancellationToken = default) =>
        new TestAsyncEnumerator<T>(this.AsEnumerable().GetEnumerator());
}

internal class TestAsyncEnumerator<T> : IAsyncEnumerator<T>
{
    private readonly IEnumerator<T> _inner;

    public TestAsyncEnumerator(IEnumerator<T> inner) => _inner = inner;

    public T Current => _inner.Current;

    public ValueTask DisposeAsync()
    {
        _inner.Dispose();
        return ValueTask.CompletedTask;
    }

    public ValueTask<bool> MoveNextAsync() => ValueTask.FromResult(_inner.MoveNext());
}
'@
    Write-TemplateFile 'UMS.Infrastructure.Tests\UMS.Infrastructure.Tests.csproj' @'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Bogus" Version="35.6.1" />
    <PackageReference Include="coverlet.collector" Version="6.0.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" Version="8.9.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="Moq" Version="4.20.72" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <Compile Remove="UnitTest1.cs" />
  </ItemGroup>

  <ItemGroup>
    <Content Include="appsettings.Testing.json">
      <CopyToOutputDirectory>Always</CopyToOutputDirectory>
    </Content>
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\UMS.Infrastructure\UMS.Infrastructure.csproj" />
    <ProjectReference Include="..\UMS.Application\UMS.Application.csproj" />
  </ItemGroup>

</Project>
'@
    Write-TemplateFile 'UMS.Infrastructure\Extensions\QueryExtensions.cs' @'
using Microsoft.EntityFrameworkCore.Metadata;
using System.Linq.Expressions;

namespace UMS.Infrastructure.Extensions
{
    public static class QueryExtensions
    {
        public static void AddSoftDeleteQueryFilter(this IMutableEntityType entityType)
        {
            // Skip if entity does not implement ISoftDelete
            if (!typeof(ISoftDelete).IsAssignableFrom(entityType.ClrType))
                return;

            var parameter = Expression.Parameter(entityType.ClrType, "e");
            var prop = Expression.Property(parameter, nameof(ISoftDelete.SoftDeleted));
            var filter = Expression.Lambda(Expression.Equal(prop, Expression.Constant(false)), parameter);

            entityType.SetQueryFilter(filter);

            // Add index if not already defined
            var property = entityType.FindProperty(nameof(ISoftDelete.SoftDeleted));
            if (property != null && entityType.GetIndexes().All(i => !i.Properties.Contains(property)))
            {
                entityType.AddIndex(property);
            }
        }

        //public static void AddTenantQueryFilter(this IMutableEntityType entityType, string tenantId)
        //{
        //    // Skip if entity does not implement ITenant
        //    if (!typeof(IMustHaveTenant).IsAssignableFrom(entityType.ClrType))
        //        return;

        //    var parameter = Expression.Parameter(entityType.ClrType, "e");
        //    var prop = Expression.Property(parameter, nameof(IMustHaveTenant.TenantId));
        //    var filter = Expression.Lambda(Expression.Equal(prop, Expression.Constant(tenantId)), parameter);
        //    entityType.SetQueryFilter(filter);

        //    // Add index if not already defined
        //    var property = entityType.FindProperty(nameof(IMustHaveTenant.TenantId));
        //    if (property != null && entityType.GetIndexes().All(i => !i.Properties.Contains(property)))
        //    {
        //        entityType.AddIndex(property);
        //    }
        //}

    }

}
'@
    Write-TemplateFile 'UMS.Infrastructure\GlobalUsings.cs' @'
global using UMS.Domain.Entities;
global using UMS.Domain.Interfaces;
global using Microsoft.EntityFrameworkCore;
global using Microsoft.EntityFrameworkCore.Metadata.Builders;
global using System.ComponentModel.DataAnnotations;
global using Microsoft.AspNetCore.Identity;
global using UMS.Infrastructure.Identity.Constants;
global using Microsoft.AspNetCore.Authorization;
global using Microsoft.Extensions.Configuration;
global using UMS.Infrastructure.Persistence.Contexts;
global using UMS.Infrastructure.Identity.Models;
global using UMS.Application.Interfaces;
global using System.Data;
global using System.Security.Claims;
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Configurations\SeedUsersConfiguration.cs' @'
namespace UMS.Infrastructure.Identity.Configurations
{
    public class SeedUsersConfiguration
    {
        public SeedUserConfiguration Admin { get; set; } = new();
        public SeedUserConfiguration Basic { get; set; } = new();
    }

    public class SeedUserConfiguration
    {
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Constants\AppClaim.cs' @'
namespace UMS.Infrastructure.Identity.Constants
{
    public static class AppClaim
    {
        public const string Permission = "permission";
        public const string Expiration = "exp";
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Constants\AppRoles.cs' @'
using System.Collections.ObjectModel;

namespace UMS.Infrastructure.Identity.Constants
{
    internal class AppRoles
    {
        public const string Basic = nameof(Basic);
        public const string Admin = nameof(Admin);

        public static IReadOnlyList<string> DefaultRoles { get; }
            = new ReadOnlyCollection<string>(
            [
                Basic,
                Admin
            ]);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\CurrentUserMiddleware.cs' @'
using Microsoft.AspNetCore.Http;
using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Identity
{
    public class CurrentUserMiddleware(ICurrentUserService currentUserService) : IMiddleware
    {
        private readonly ICurrentUserService _currentUserService = currentUserService;

        public async Task InvokeAsync(HttpContext context, RequestDelegate next)
        {
            _currentUserService.SetCurrentUser(context.User);
            await next(context);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\IdentityServiceExtensions.cs' @'
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.Net;
using System.Text;
using System.Text.Json;
using UMS.Application.Authorization;
using UMS.Application.Dtos.JWT;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Roles;
using UMS.Application.Features.Token;
using UMS.Application.Features.Users;
using UMS.Infrastructure.Identity.Permissions;
using UMS.Infrastructure.Identity.Services;
using UMS.Infrastructure.Persistence.DbInitializers;

namespace UMS.Infrastructure.Identity
{
    internal static class IdentityServiceExtensions
    {
        internal static IServiceCollection AddIdentityServices(this IServiceCollection services, IConfiguration config)
        {
            return services
                .AddIdentity<ApplicationUser, ApplicationRole>(options =>
                {
                    options.Password.RequiredLength = 8;
                    options.Password.RequireDigit = true;
                    options.Password.RequireLowercase = true;
                    options.Password.RequireUppercase = true;
                    options.Password.RequireNonAlphanumeric = true;
                    options.User.RequireUniqueEmail = true;
                    options.SignIn.RequireConfirmedEmail = true;
                    options.Lockout = new LockoutOptions
                    {
                        DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15),
                        MaxFailedAccessAttempts = 5,
                        AllowedForNewUsers = true
                    };
                })
                .AddEntityFrameworkStores<ApplicationDbContext>()
                .AddDefaultTokenProviders()
                .Services
                .AddScoped<IUserService, UserService>()
                .AddScoped<IRoleService, RoleService>()
                .AddScoped<ITokenService, TokenService>()
                .AddScoped<CurrentUserMiddleware>()
                .AddTransient<IdentityDbSeeder>()
                .Configure<JwtConfiguration>(config.GetSection("JwtConfiguration"));
        }

        internal static IApplicationBuilder UseCurrentUser(this IApplicationBuilder app)
        {
            return app.UseMiddleware<CurrentUserMiddleware>();
        }

        internal static IServiceCollection AddPermissions(this IServiceCollection services)
        {
            services
                .AddSingleton<IAuthorizationPolicyProvider, PermissionPolicyProvider>()
                .AddScoped<IAuthorizationHandler, PermissionAuthorizationHandler>();
            return services;
        }

        internal static JwtConfiguration GetTokenSettings(this IServiceCollection services, IConfiguration config)
        {
            var tokenSettingsConfig = config.GetSection(nameof(JwtConfiguration));
            services.Configure<JwtConfiguration>(tokenSettingsConfig);

            return tokenSettingsConfig.Get<JwtConfiguration>();
        }

        public static IServiceCollection AddJwtAuthentication(this IServiceCollection services, IConfiguration configuration)
        {
            var jwtSettings = configuration
                .GetSection("JwtConfiguration")
                .Get<JwtConfiguration>();

            if (jwtSettings == null)
            {
                throw new InvalidOperationException("JwtConfiguration section is not configured in appsettings.json");
            }

            var key = Encoding.UTF8.GetBytes(jwtSettings.Secret);

            services
              .AddAuthentication(auth =>
              {
                  auth.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                  auth.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
              })
              .AddJwtBearer(bearer =>
              {
                  bearer.RequireHttpsMetadata = true;
                  bearer.SaveToken = true;
                  bearer.TokenValidationParameters = new TokenValidationParameters
                  {
                      ValidateIssuerSigningKey = true,
                      ValidateIssuer = true,
                      ValidateAudience = true,
                      ValidateLifetime = true,
                      ValidIssuer = jwtSettings.Issuer,
                      ValidAudience = jwtSettings.Audience,
                      RoleClaimType = ClaimTypes.Role,
                      ClockSkew = TimeSpan.Zero,
                      IssuerSigningKey = new SymmetricSecurityKey(key)
                  };

                  bearer.Events = new JwtBearerEvents
                  {
                      OnMessageReceived = context =>
                      {
                          var path = context.HttpContext.Request.Path.Value ?? string.Empty;

                          if (path.Contains("refresh-token", StringComparison.OrdinalIgnoreCase))
                          {
                              context.NoResult();
                          }

                          return Task.CompletedTask;
                      },
                      OnAuthenticationFailed = context =>
                      {
                          context.HttpContext.Items["AuthError"] = context.Exception;
                          return Task.CompletedTask;
                      },
                      OnChallenge = context =>
                      {
                          context.HandleResponse();
                          if (!context.Response.HasStarted)
                          {
                              context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                              context.Response.ContentType = "application/json";

                              string errorMessage = "You are not Authorized.";
                              if (context.HttpContext.Items.TryGetValue("AuthError", out var errorObj) && errorObj is Exception ex)
                              {
                                  if (ex is SecurityTokenExpiredException)
                                      errorMessage = "The token has expired. Please log in again.";
                                  else if (ex is ArgumentException && ex.Message.Contains("IDX14100"))
                                      errorMessage = "The provided token format is invalid.";
                                  else if (ex is SecurityTokenInvalidSignatureException)
                                      errorMessage = "The token signature is invalid.";
                                  else
                                      errorMessage = "You are not authorized to access this resource.";
                              }

                              var result = JsonSerializer.Serialize(ResponseWrapper.Fail(errorMessage, (int)HttpStatusCode.Unauthorized));
                              return context.Response.WriteAsync(result);
                          }

                          return Task.CompletedTask;
                      },
                      OnForbidden = context =>
                      {
                          context.Response.StatusCode = (int)HttpStatusCode.Forbidden;
                          context.Response.ContentType = "application/json";
                          var result = JsonSerializer.Serialize(
                              ResponseWrapper.Fail("You are not authorized to access this resource.", (int)HttpStatusCode.Forbidden));
                          return context.Response.WriteAsync(result);
                      }
                  };
              });

            services.AddAuthorization(options =>
            {
                foreach (var permission in AppPermissions.AllPermissions)
                {
                    options.AddPolicy(permission.Name, policy =>
                        policy.RequireClaim(AppClaim.Permission, permission.Name));
                }
            });

            return services;
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Models\ApplicationRole.cs' @'
namespace UMS.Infrastructure.Identity.Models
{
    public class ApplicationRole : IdentityRole<int>
    {
        [MaxLength(256)]
        public string Description { get; set; } = string.Empty;
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Models\ApplicationRoleClaim.cs' @'
namespace UMS.Infrastructure.Identity.Models
{
    public class ApplicationRoleClaim : IdentityRoleClaim<int>
    {
        [MaxLength(256)]
        public string Description { get; set; } = string.Empty;

    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Models\ApplicationUser.cs' @'
namespace UMS.Infrastructure.Identity.Models
{
    public class ApplicationUser : IdentityUser<int>
    {
        [MaxLength(256)]
        public string FullName { get; set; } = string.Empty;
        
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        [MaxLength(256)]
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime RefreshTokenExpiryDate { get; set; }
        public bool IsActive { get; set; }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Models\ApplicationUserClaim.cs' @'
namespace UMS.Infrastructure.Identity.Models
{
    public class ApplicationUserClaim : IdentityUserClaim<int> { }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Models\ApplicationUserLogin.cs' @'
namespace UMS.Infrastructure.Identity.Models
{
    public class ApplicationUserLogin : IdentityUserLogin<int> { }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Models\ApplicationUserRole.cs' @'
namespace UMS.Infrastructure.Identity.Models
{
    public class ApplicationUserRole : IdentityUserRole<int> { }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Models\ApplicationUserToken.cs' @'
namespace UMS.Infrastructure.Identity.Models
{
    public class ApplicationUserToken : IdentityUserToken<int> { }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Permissions\PermissionAuthorizationHandler.cs' @'
using UMS.Application.Dtos.JWT;

namespace UMS.Infrastructure.Identity.Permissions
{
    public class PermissionAuthorizationHandler : AuthorizationHandler<PermissionRequirement>
    {
        private readonly IConfiguration _configuration;

        public PermissionAuthorizationHandler(IConfiguration configuration)
        {
            _configuration = configuration;
        }
        protected override async Task HandleRequirementAsync(AuthorizationHandlerContext context, PermissionRequirement requirement)
        {


            if (context.User != null && context.User.Claims != null && context.User.Claims.Any())
            {
                var jwtSettings = _configuration
                    .GetSection("JwtConfiguration")
                    .Get<JwtConfiguration>();

                var hasPermission = context.User.Claims.Any(c =>
                    c.Type == AppClaim.Permission &&
                    c.Value == requirement.Permission &&
                    c.Issuer == jwtSettings.Issuer);

                if (hasPermission)
                {
                    context.Succeed(requirement);
                }
            }

            // You can optionally leave this or omit it
            await Task.CompletedTask;

            //if (context.User is null)
            //{
            //    await Task.CompletedTask;
            //}

            //if (context.User.Identity.IsAuthenticated == false)
            //{
            //    await Task.CompletedTask;
            //}

            //var jwtSettings = _configuration
            //    .GetSection("JwtConfiguration")
            //    .Get<JwtConfiguration>();

            //var permissions = context.User.Claims
            //    .Where(claim => claim.Type == AppClaim.Permission
            //        && claim.Value == requirement.Permission
            //        && claim.Issuer == jwtSettings.Issuer);
            //if (permissions.Any())
            //{
            //    context.Succeed(requirement);
            //    await Task.CompletedTask;
            //}
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Permissions\PermissionPolicyProvider.cs' @'
using Microsoft.Extensions.Options;

namespace UMS.Infrastructure.Identity.Permissions
{
    public class PermissionPolicyProvider : IAuthorizationPolicyProvider
    {
        public DefaultAuthorizationPolicyProvider FallbackPolicyProvider { get; }

        public PermissionPolicyProvider(IOptions<AuthorizationOptions> options)
        {
            FallbackPolicyProvider = new DefaultAuthorizationPolicyProvider(options);
        }

        public Task<AuthorizationPolicy> GetDefaultPolicyAsync()
        {
            return FallbackPolicyProvider.GetDefaultPolicyAsync();
        }

        public Task<AuthorizationPolicy> GetFallbackPolicyAsync()
        {
            return Task.FromResult<AuthorizationPolicy>(null);
        }

        public Task<AuthorizationPolicy> GetPolicyAsync(string policyName)
        {
            if (policyName.StartsWith(AppClaim.Permission, StringComparison.CurrentCultureIgnoreCase))
            {
                var policy = new AuthorizationPolicyBuilder();
                policy.AddRequirements(new PermissionRequirement(policyName));
                return Task.FromResult(policy.Build());
            }
            return FallbackPolicyProvider.GetPolicyAsync(policyName);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Permissions\PermissionRequirement.cs' @'
namespace UMS.Infrastructure.Identity.Permissions
{
    public class PermissionRequirement : IAuthorizationRequirement
    {
        public string Permission { get; set; }
        public PermissionRequirement(string permission)
        {
            Permission = permission;
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Seeds\FeaturesDbSeeder.cs' @'

namespace UMS.Infrastructure.Persistence.DbInitializers
{
    public class FeaturesDbSeeder
    {
        private readonly ApplicationDbContext _dbContext;

        public FeaturesDbSeeder(ApplicationDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task SeedFeaturesDatabaseAsync()
        {
         //   await SeedMenusAsync();
        }

        //private async Task SeedMenusAsync()
        //{

        //    if (!_dbContext.Menus.Any())
        //    {
        //        var menus = new List<Menu>
        //    {
        //        new Menu { Title = "HOME", Link = "/index", Type = "top", Order = 1 },
        //        new Menu { Title = "SHOP", Link = "/shop", Type = "top", Order = 2 },
        //        new Menu { Title = "PRODUCT", Link = "/product", Type = "top", Order = 3 },
        //        new Menu { Title = "SALE", Link = "/sale", Type = "top", Order = 4 },
        //        new Menu { Title = "PAGES", Link = "/pages", Type = "top", Order = 5 },
        //        new Menu { Title = "BLOG", Link = "/blog", Type = "top", Order = 6 },
        //        new Menu { Title = "BUY", Link = "/buy", Type = "top", Order = 7 }
        //    };

        //        _dbContext.Menus.AddRange(menus);
        //        await _dbContext.SaveChangesAsync();
        //    }
        //}

    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Seeds\IdentityDbSeeder.cs' @'
using Microsoft.Extensions.Options;
using UMS.Application.Authorization;
using UMS.Infrastructure.Identity.Configurations;

namespace UMS.Infrastructure.Persistence.DbInitializers
{
    public class IdentityDbSeeder
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly ApplicationDbContext _context;
        private readonly SeedUsersConfiguration _seedUsersConfiguration;

        public IdentityDbSeeder(
            ApplicationDbContext context,
            RoleManager<ApplicationRole> roleManager,
            UserManager<ApplicationUser> userManager,
            IOptions<SeedUsersConfiguration> seedUsersConfiguration)
        {
            _context = context;
            _roleManager = roleManager;
            _userManager = userManager;
            _seedUsersConfiguration = seedUsersConfiguration.Value;
        }

        public async Task SeedIdentityDatabaseAsync()
        {
            await CheckAndApplyPendingMigrationAsync();
            await SeedRolesAsync();
            await SeedAdminUserAsync();
            await SeedBasicUserAsync();
        }

        private async Task CheckAndApplyPendingMigrationAsync()
        {
            if ((await _context.Database.GetPendingMigrationsAsync()).Any())
            {
                await _context.Database.MigrateAsync();
            }
        }

        private async Task SeedAdminUserAsync()
        {
            var adminConfiguration = _seedUsersConfiguration.Admin;
            var user = new ApplicationUser
            {
                FullName = adminConfiguration.FullName,
                Email = adminConfiguration.Email,
                UserName = adminConfiguration.Email,
                EmailConfirmed = true,
                PhoneNumberConfirmed = true,
                PhoneNumber = adminConfiguration.PhoneNumber,
                NormalizedEmail = adminConfiguration.Email.ToUpperInvariant(),
                NormalizedUserName = adminConfiguration.Email.ToUpperInvariant(),
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                RefreshToken = Guid.NewGuid().ToString("N"),
                RefreshTokenExpiryDate = DateTime.UtcNow.AddDays(1)
            };

            if (!await _userManager.Users.AnyAsync(u => u.Email == adminConfiguration.Email))
            {
                await _userManager.CreateAsync(user, adminConfiguration.Password);
            }

            user = await _userManager.FindByEmailAsync(adminConfiguration.Email);
            if (!await _userManager.IsInRoleAsync(user, AppRoles.Basic)
                && !await _userManager.IsInRoleAsync(user, AppRoles.Admin))
            {
                await _userManager.AddToRolesAsync(user, AppRoles.DefaultRoles);
            }
        }

        private async Task SeedBasicUserAsync()
        {
            var basicConfiguration = _seedUsersConfiguration.Basic;
            var email = basicConfiguration.Email;
            var user = new ApplicationUser
            {
                FullName = basicConfiguration.FullName,
                Email = email,
                UserName = email,
                EmailConfirmed = true,
                PhoneNumberConfirmed = true,
                PhoneNumber = basicConfiguration.PhoneNumber,
                NormalizedEmail = email.ToUpperInvariant(),
                NormalizedUserName = email.ToUpperInvariant(),
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                RefreshToken = Guid.NewGuid().ToString("N"),
                RefreshTokenExpiryDate = DateTime.UtcNow.AddDays(7)
            };

            if (!await _userManager.Users.AnyAsync(u => u.Email == email))
            {
                await _userManager.CreateAsync(user, basicConfiguration.Password);
            }

            user = await _userManager.FindByEmailAsync(email);

            if (!await _userManager.IsInRoleAsync(user, AppRoles.Basic))
            {
                await _userManager.AddToRoleAsync(user, AppRoles.Basic);
            }
        }

        private async Task SeedRolesAsync()
        {
            foreach (var roleName in AppRoles.DefaultRoles)
            {
                if (await _roleManager.Roles.FirstOrDefaultAsync(r => r.Name == roleName) is not ApplicationRole role)
                {
                    role = new ApplicationRole
                    {
                        Name = roleName,
                        Description = $"{roleName} Role.",
                        NormalizedName = roleName.ToUpperInvariant()
                    };

                    await _roleManager.CreateAsync(role);
                }

                if (roleName == AppRoles.Basic)
                {
                    await AssignPermissionsToRoleAsync(role, AppPermissions.BasicPermissions);
                }
                else if (roleName == AppRoles.Admin)
                {
                    await AssignPermissionsToRoleAsync(role, AppPermissions.AdminPermissions);
                }
            }
        }

        private async Task AssignPermissionsToRoleAsync(ApplicationRole role, IReadOnlyList<AppPermission> permmisions)
        {
            var currentlyAssignedClaims = await _roleManager.GetClaimsAsync(role);

            foreach (var permission in permmisions)
            {
                if (!currentlyAssignedClaims.Any(claim => claim.Type == AppClaim.Permission && claim.Value == permission.Name))
                {
                    await _context.RoleClaims.AddAsync(new ApplicationRoleClaim
                    {
                        RoleId = role.Id,
                        ClaimType = AppClaim.Permission,
                        ClaimValue = permission.Name,
                        Description = permission.Description
                    });
                }
            }

            await _context.SaveChangesAsync();
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Services\RoleService.cs' @'
using Mapster;
using UMS.Application.Authorization;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Roles;
using UMS.Application.Features.Roles.Commands;
using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Identity.Services
{
    public class RoleService : IRoleService
    {
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IApplicationDbContext _context;

        public RoleService(RoleManager<ApplicationRole> roleManager, UserManager<ApplicationUser> userManager, IApplicationDbContext context)
        {
            _roleManager = roleManager;
            _userManager = userManager;
            _context = context;
        }

        public async Task<IResponseWrapper> CreateRoleAsync(CreateRoleRequest createRole)
        {
            var roleInDb = await _roleManager.FindByNameAsync(createRole.Name);
            if (roleInDb is not null)
            {
                return ResponseWrapper.Fail("Role already exists");
            }

            var newRole = new ApplicationRole
            {
                Name = createRole.Name,
                Description = createRole.Description
            };

            var identityResult = await _roleManager.CreateAsync(newRole);

            if (identityResult.Succeeded)
            {
                return ResponseWrapper.Success(message: "Role created successfully");
            }

            return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityResult));
        }

        public async Task<IResponseWrapper> DeleteRoleAsync(int roleId)
        {
            if (roleId == 0)
            {
                return ResponseWrapper.Fail("Role Id is required.");
            }

            var roleInDb = await _roleManager.FindByIdAsync(roleId.ToString());

            if (roleInDb is not null)
            {
                if (roleInDb.Name != AppRoles.Admin)
                {
                    var usersInRole = await _userManager.GetUsersInRoleAsync(roleInDb.Name);

                    if (usersInRole.Any())
                    {
                        return ResponseWrapper.Fail($"Role: {roleInDb.Name} is currently assigned to a user.");
                    }

                    var identityResult = await _roleManager.DeleteAsync(roleInDb);

                    if (identityResult.Succeeded)
                    {
                        return ResponseWrapper.Success("Role successfully deleted.");
                    }

                    return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityResult));
                }

                return ResponseWrapper.Fail("Cannot delete Admin role.");
            }

            return ResponseWrapper.Fail("Role does not exist.");
        }

        public async Task<IResponseWrapper<RoleClaimResponse>> GetPermissionsAsync(int roleId)
        {
            var roleInDb = await _roleManager.FindByIdAsync(roleId.ToString());

            if (roleInDb is not null)
            {
                var allPermissions = AppPermissions.AllPermissions;

                var roleClaimResponse = new RoleClaimResponse
                {
                    Role = new RoleResponse
                    {
                        Id = roleId,
                        Name = roleInDb.Name,
                        Description = roleInDb.Description
                    },
                    RoleClaims = new List<RoleClaimViewModel>()
                };

                var currentlyAssignedClaims = await GetAllClaimsForRoleAsync(roleId);

                var allPermissionNames = allPermissions.Select(p => p.Name).ToList();

                var currentlyAssignedClaimsValues = currentlyAssignedClaims
                    .Select(rc => rc.ClaimValue).ToList();

                var currentlyAssignedRoleClaimsNames = allPermissionNames
                    .Intersect(currentlyAssignedClaimsValues)
                    .ToList();

                foreach (var permission in allPermissions)
                {
                    roleClaimResponse.RoleClaims.Add(new RoleClaimViewModel
                    {
                        ClaimType = AppClaim.Permission,
                        ClaimValue = permission.Name,
                        Description = permission.Description,
                    });
                }

                return ResponseWrapper<RoleClaimResponse>.Success(data: roleClaimResponse);
            }

            return ResponseWrapper<RoleClaimResponse>.Fail(message: "Role does not exist.");
        }

        public async Task<IResponseWrapper<RoleResponse>> GetRoleByIdAsync(int roleId)
        {
            var roleInDb = await _roleManager.FindByIdAsync(roleId.ToString());

            if (roleInDb is not null)
            {
                var mappedRole = roleInDb.Adapt<RoleResponse>();

                return ResponseWrapper<RoleResponse>.Success(data: mappedRole);
            }

            return ResponseWrapper<RoleResponse>.Fail("Role does not exist.");
        }

        public async Task<IResponseWrapper<List<RoleResponse>>> GetRolesAsync()
        {
            var allRoles = await _roleManager.Roles.ToListAsync();

            if (allRoles.Count > 0)
            {
                var mappedRoles = allRoles.Adapt<List<RoleResponse>>();

                return ResponseWrapper<List<RoleResponse>>.Success(data: mappedRoles);
            }

            return ResponseWrapper<List<RoleResponse>>.Fail("No roles were found.");
        }

        public async Task<IResponseWrapper> UpdateRoleAsync(UpdateRoleRequest updateRole)
        {
            var roleInDb = await _roleManager.FindByIdAsync(updateRole.RoleId.ToString());

            if (roleInDb is not null)
            {
                if (roleInDb.Name != AppRoles.Admin)
                {
                    roleInDb.Name = updateRole.Name;
                    roleInDb.Description = updateRole.Description;

                    var identityResult = await _roleManager.UpdateAsync(roleInDb);

                    if (identityResult.Succeeded)
                    {
                        return ResponseWrapper.Success("Role updated successfully");
                    }

                    return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityResult));
                }

                return ResponseWrapper.Fail("Cannot update Admin role.");
            }

            return ResponseWrapper.Fail("Role does not exist.");
        }

        public async Task<IResponseWrapper> UpdateRolePermissionsAsync(UpdateRoleClaimsRequest updateRoleClaims)
        {
            var roleInDb = await _roleManager.FindByIdAsync(updateRoleClaims.RoleId.ToString());
            if (roleInDb is null)
                return ResponseWrapper.Fail("Role does not exist.");

            if (roleInDb.Name == AppRoles.Admin)
                return ResponseWrapper.Fail("Cannot change permissions for this role.");

            var allowedValues = AppPermissions.AllPermissions
                .Select(p => p.Name)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);

            var newClaims = updateRoleClaims.RoleClaims
                .Where(rc => rc.ClaimValue != null && allowedValues.Contains(rc.ClaimValue))
                .Select(rc => new Claim(AppClaim.Permission, rc.ClaimValue!))
                .ToList();

            var existingClaims = await _roleManager.GetClaimsAsync(roleInDb);

            var claimsToAdd = newClaims
                .Where(nc => !existingClaims.Any(ec => ec.Type == nc.Type && ec.Value == nc.Value))
                .ToList();

            var claimsToRemove = existingClaims
                .Where(ec => !newClaims.Any(nc => nc.Type == ec.Type && nc.Value == ec.Value))
                .ToList();

            if (!claimsToAdd.Any() && !claimsToRemove.Any())
                return ResponseWrapper.Success("No changes detected.");

            try
            {
                await _context.StartTransaction();

                foreach (var claim in claimsToRemove)
                    await _roleManager.RemoveClaimAsync(roleInDb, claim);

                foreach (var claim in claimsToAdd)
                    await _roleManager.AddClaimAsync(roleInDb, claim);

                await _context.CommitTransaction();
            }
            catch
            {
                await _context.RollbackTransaction();
                throw;
            }

            return ResponseWrapper.Success("Role permissions updated successfully.");
        }

        private List<string> GetIdentityResultErrorDescriptions(IdentityResult identityResult)
        {
            var errorDescriptions = new List<string>();
            foreach (var error in identityResult.Errors)
            {
                errorDescriptions.Add(error.Description);
            }

            return errorDescriptions;
        }

        private async Task<List<RoleClaimViewModel>> GetAllClaimsForRoleAsync(int roleId)
        {
            var role = await _roleManager.FindByIdAsync(roleId.ToString());
            if (role is null) return [];

            var claims = await _roleManager.GetClaimsAsync(role);
            return claims
                .Select(c => new RoleClaimViewModel { ClaimType = c.Type, ClaimValue = c.Value })
                .ToList();
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Services\TokenService.cs' @'
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using System.Text;
using UMS.Application.Dtos.JWT;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Token;
using UMS.Application.Features.Token.Queries;
using UMS.Application.Features.Token.Queries.LoginWith2FA;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Persistence.Contexts;

namespace UMS.Infrastructure.Identity.Services
{
    public class TokenService : ITokenService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly JwtConfiguration _tokenSettings;
        private readonly IDateTimeService _dateTimeService;
        private readonly IDistributedCache _cache;
        private readonly ApplicationDbContext? _dbContext;

        private string ChallengeIssuer => $"{_tokenSettings.Issuer}:2fa-challenge";
        private const string ChallengeAudience = "2fa-challenge";
        private const string ChallengeClaim = "2fa_challenge";

        public TokenService(UserManager<ApplicationUser> userManager,
            RoleManager<ApplicationRole> roleManager,
            IOptions<JwtConfiguration> tokenSettings,
            IDateTimeService dateTimeService,
            IDistributedCache cache,
            ApplicationDbContext? dbContext = null)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _tokenSettings = tokenSettings.Value;
            _dateTimeService = dateTimeService;
            _cache = cache;
            _dbContext = dbContext;
        }

        public async Task<IResponseWrapper<TokenResponse>> GetTokenAsync(TokenRequest tokenRequest)
        {
            #region Validations
            var userInDb = await _userManager.FindByEmailAsync(tokenRequest.Email);

            if (userInDb == null)
            {
                return ResponseWrapper<TokenResponse>.Fail(message: "Invalid Credentials.");
            }
            // Check if Active
            if (!userInDb.IsActive)
            {
                return ResponseWrapper<TokenResponse>.Fail("User not active. Please contact the administrator");
            }
            // Check email if email confirmed
            if (!userInDb.EmailConfirmed)
            {
                return ResponseWrapper<TokenResponse>.Fail("Email not confirmed.");
            }
            // Check if locked out before verifying password so the right message is shown
            if (await _userManager.IsLockedOutAsync(userInDb))
            {
                return ResponseWrapper<TokenResponse>.Fail("Account is locked. Please try again later or contact support.");
            }
            // Check password
            var isPasswordValid = await _userManager.CheckPasswordAsync(userInDb, tokenRequest.Password);

            if (!isPasswordValid)
            {
                await _userManager.AccessFailedAsync(userInDb);
                return ResponseWrapper<TokenResponse>.Fail("Invalid Credentials.");
            }

            #endregion

            // 2FA branch â€” defer ResetAccessFailedCount to Phase 2
            if (userInDb.TwoFactorEnabled)
            {
                var jti = Guid.NewGuid().ToString();
                var challenge = GenerateChallengeToken(userInDb, jti);
                return ResponseWrapper<TokenResponse>.Success(
                    new TokenResponse
                    {
                        RequiresTwoFactor = true,
                        TwoFactorChallengeToken = challenge
                    },
                    "Two-factor authentication required.");
            }

            // Reset failed access count after successful login
            await _userManager.ResetAccessFailedCountAsync(userInDb);

            // Generate token
            userInDb.RefreshToken = GenerateRefreshToken();
            userInDb.RefreshTokenExpiryDate = _dateTimeService.NowUtc.AddDays(_tokenSettings.RefreshTokenExpiryInDays);

            await _userManager.UpdateAsync(userInDb);

            var token = await GenerateJwtAsync(userInDb);

            var tokenResponse = new TokenResponse
            {
                Token = token,
                RefreshToken = userInDb.RefreshToken,
                RefreshTokenExpiryTime = userInDb.RefreshTokenExpiryDate
            };

            return ResponseWrapper<TokenResponse>.Success(data: tokenResponse);
        }

        public async Task<IResponseWrapper<TokenResponse>> LoginWith2FAAsync(TwoFactorLoginRequest request, CancellationToken ct = default)
        {
            // Step A â€” Validate the challenge token
            var validationParams = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidIssuer = ChallengeIssuer,
                ValidAudience = ChallengeAudience,
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(_tokenSettings.Secret)),
                ClockSkew = TimeSpan.Zero
            };

            ClaimsPrincipal principal;
            try
            {
                principal = new JwtSecurityTokenHandler()
                    .ValidateToken(request.TwoFactorChallengeToken, validationParams, out _);
            }
            catch (Exception)
            {
                return ResponseWrapper<TokenResponse>.Fail("Invalid or expired challenge token.");
            }

            // Step B â€” Verify the 2fa_challenge claim is present
            if (principal.FindFirstValue(ChallengeClaim) is null)
                return ResponseWrapper<TokenResponse>.Fail("Invalid or expired challenge token.");

            // Step C â€” Replay check (distributed so it works across multiple instances)
            var jti = principal.FindFirstValue(JwtRegisteredClaimNames.Jti);
            if (await _cache.GetAsync($"2fa_jti:{jti}", ct) is not null)
                return ResponseWrapper<TokenResponse>.Fail("Challenge token has already been used.");

            // Step D â€” Load and validate user
            var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _userManager.FindByIdAsync(userId);

            if (user is null || !user.IsActive)
                return ResponseWrapper<TokenResponse>.Fail("Invalid credentials.");
            if (!user.EmailConfirmed)
                return ResponseWrapper<TokenResponse>.Fail("Email not confirmed.");
            if (await _userManager.IsLockedOutAsync(user))
                return ResponseWrapper<TokenResponse>.Fail("Account is locked. Please try again later.");
            if (!user.TwoFactorEnabled)
                return ResponseWrapper<TokenResponse>.Fail("Two-factor authentication is not enabled.");

            // Step E â€” Verify the code (TOTP first, then recovery code)
            bool success = await _userManager.VerifyTwoFactorTokenAsync(
                user,
                _userManager.Options.Tokens.AuthenticatorTokenProvider,
                request.Code);

            if (!success)
            {
                var recoveryResult = await _userManager.RedeemTwoFactorRecoveryCodeAsync(
                    user, request.Code);
                success = recoveryResult.Succeeded;
            }

            // Step F â€” Handle failure
            if (!success)
            {
                await _userManager.AccessFailedAsync(user);
                if (await _userManager.IsLockedOutAsync(user))
                    return ResponseWrapper<TokenResponse>.Fail(
                        "Account locked due to multiple failed attempts.");
                return ResponseWrapper<TokenResponse>.Fail("Invalid authenticator code.");
            }

            // Step G â€” Handle success (Phase 2 complete)
            await _userManager.ResetAccessFailedCountAsync(user);

            await _cache.SetAsync(
                $"2fa_jti:{jti}",
                [1],
                new DistributedCacheEntryOptions
                {
                    AbsoluteExpirationRelativeToNow =
                        TimeSpan.FromMinutes(_tokenSettings.TwoFactorChallengeTokenExpiryInMinutes)
                },
                ct);

            user.RefreshToken = GenerateRefreshToken();
            user.RefreshTokenExpiryDate = _dateTimeService.NowUtc
                .AddDays(_tokenSettings.RefreshTokenExpiryInDays);
            await _userManager.UpdateAsync(user);

            var token = await GenerateJwtAsync(user);

            return ResponseWrapper<TokenResponse>.Success(new TokenResponse
            {
                Token = token,
                RefreshToken = user.RefreshToken,
                RefreshTokenExpiryTime = user.RefreshTokenExpiryDate
            });
        }

        private string GenerateChallengeToken(ApplicationUser user, string jti)
        {
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ChallengeClaim, "true"),
                new(JwtRegisteredClaimNames.Jti, jti)
            };

            var token = new JwtSecurityToken(
                issuer: ChallengeIssuer,
                audience: ChallengeAudience,
                claims: claims,
                expires: _dateTimeService.NowUtc.AddMinutes(
                    _tokenSettings.TwoFactorChallengeTokenExpiryInMinutes),
                signingCredentials: GetSigningCredentials());

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private string GenerateRefreshToken()
        {
            var randomNumber = new byte[32];
            using var rnd = RandomNumberGenerator.Create();
            rnd.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }

        private async Task<IEnumerable<Claim>> GetClaimsAsync(ApplicationUser user)
        {
            var userClaims = await _userManager.GetClaimsAsync(user);
            var roleNames = await _userManager.GetRolesAsync(user);

            var roleClaims = roleNames.Select(r => new Claim(ClaimTypes.Role, r)).ToList();

            List<Claim> permissionClaims;
            if (_dbContext is not null)
            {
                // Single batch query: join roles â†’ role claims in two round-trips instead of N+1
                var roleIds = await _roleManager.Roles
                    .Where(r => roleNames.Contains(r.Name!))
                    .Select(r => r.Id)
                    .ToListAsync();

                permissionClaims = await _dbContext.RoleClaims
                    .Where(rc => roleIds.Contains(rc.RoleId) && rc.ClaimValue != null)
                    .Select(rc => new Claim(rc.ClaimType!, rc.ClaimValue!))
                    .ToListAsync();
            }
            else
            {
                // Fallback path used in unit tests where DbContext is not injected
                var roleClaimSets = await Task.WhenAll(
                    roleNames.Select(async role =>
                    {
                        var roleEntity = await _roleManager.FindByNameAsync(role);
                        return roleEntity is null
                            ? []
                            : await _roleManager.GetClaimsAsync(roleEntity);
                    }));

                permissionClaims = roleClaimSets
                    .SelectMany(claims => claims.Select(c => new Claim(c.Type, c.Value)))
                    .ToList();
            }

            return new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ClaimTypes.Email, user.Email),
                new(ClaimTypes.Name, user.FullName),
                new(ClaimTypes.MobilePhone, user.PhoneNumber ?? string.Empty),
            }
            .Union(roleClaims)
            .Union(userClaims)
            .Union(permissionClaims);
        }

        private SigningCredentials GetSigningCredentials()
        {
            var secret = Encoding.UTF8.GetBytes(_tokenSettings.Secret);
            return new SigningCredentials(new SymmetricSecurityKey(secret), SecurityAlgorithms.HmacSha256);
        }

        private string GenerateEncryptedToken(SigningCredentials signingCredentials, IEnumerable<Claim> claims)
        {
            var token = new JwtSecurityToken(
                issuer: _tokenSettings.Issuer,
                audience: _tokenSettings.Audience,
                claims: claims,
                expires: _dateTimeService.NowUtc.AddMinutes(_tokenSettings.TokenExpiryInMinutes),
                signingCredentials: signingCredentials);
            var tokenHandler = new JwtSecurityTokenHandler();
            var encryptedToken = tokenHandler.WriteToken(token);
            return encryptedToken;
        }

        private async Task<string> GenerateJwtAsync(ApplicationUser user)
        {
            var token = GenerateEncryptedToken(GetSigningCredentials(), await GetClaimsAsync(user));
            return token;
        }

        public async Task<IResponseWrapper<TokenResponse>> GetRefreshTokenAsync(RefreshTokenRequest refreshTokenRequest)
        {
            var userPrincipal = GetClaimPrincipalFromExpiredToken(refreshTokenRequest.Token);
            var userEmail = userPrincipal.FindFirstValue(ClaimTypes.Email);

            var userInDb = await _userManager.FindByEmailAsync(userEmail);
            if (userInDb is not null)
            {
                if (userInDb.RefreshToken != refreshTokenRequest.RefreshToken
                    || userInDb.RefreshTokenExpiryDate <= _dateTimeService.NowUtc)
                {
                    return ResponseWrapper<TokenResponse>.Fail(message: "Invalid token provided.");
                }

                var token = GenerateEncryptedToken(GetSigningCredentials(), await GetClaimsAsync(userInDb));
                userInDb.RefreshToken = GenerateRefreshToken();
                userInDb.RefreshTokenExpiryDate = _dateTimeService.NowUtc.AddDays(_tokenSettings.RefreshTokenExpiryInDays);

                await _userManager.UpdateAsync(userInDb);

                var tokenResponse = new TokenResponse
                {
                    Token = token,
                    RefreshToken = userInDb.RefreshToken,
                    RefreshTokenExpiryTime = userInDb.RefreshTokenExpiryDate
                };

                return ResponseWrapper<TokenResponse>.Success(tokenResponse);
            }
            return ResponseWrapper<TokenResponse>.Fail(message: "User does not exist.");
        }

        private ClaimsPrincipal GetClaimPrincipalFromExpiredToken(string expiredToken)
        {
            var tokenValidationParms = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = false,
                ValidIssuer = _tokenSettings.Issuer,
                ValidAudience = _tokenSettings.Audience,
                RoleClaimType = ClaimTypes.Role,
                ClockSkew = TimeSpan.Zero,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_tokenSettings.Secret)),
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var principal = tokenHandler.ValidateToken(expiredToken, tokenValidationParms, out var securityToken);
            if (securityToken is not JwtSecurityToken jwtSecurityToken
                || !jwtSecurityToken.Header.Alg
                .Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
            {
                throw new SecurityTokenException("Invalid token");
            }

            return principal;
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Identity\Services\UserService.cs' @'
using Mapster;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Security.Cryptography;
using System.Web;
using UMS.Application.Dtos.Common;
using UMS.Application.Dtos.Email;
using UMS.Application.Dtos.Pagination;
using UMS.Application.Dtos.TwoFactor;
using UMS.Application.Dtos.Wrappers;
using UMS.Application.Features.Users;
using UMS.Application.Features.Users.Commands;
using UMS.Application.Features.Users.Commands.DisableTwoFactorAuth;
using UMS.Application.Features.Users.Commands.Logout;
using UMS.Application.Features.Users.Models.Requests;
using UMS.Application.Features.Users.Models.Responses;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Identity.Configurations;

namespace UMS.Infrastructure.Identity.Services
{
    public class UserService : IUserService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly IEmailService _emailService;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IDateTimeService _dateTimeService;
        private readonly ICurrentUserService _currentUserService;
        private readonly TwoFactorOptions _twoFactorOptions;
        private readonly ILogger<UserService> _logger;

        public UserService(
            UserManager<ApplicationUser> userManager,
            RoleManager<ApplicationRole> roleManager,
            IEmailService emailService,
            IHttpContextAccessor contextAccessor,
            IDateTimeService dateTimeService,
            ICurrentUserService currentUserService,
            IOptions<TwoFactorOptions> twoFactorOptions,
            ILogger<UserService> logger)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _emailService = emailService;
            _httpContextAccessor = contextAccessor;
            _dateTimeService = dateTimeService;
            _currentUserService = currentUserService;
            _twoFactorOptions = twoFactorOptions.Value;
            _logger = logger;
        }

        private static string GenerateSecureToken()
        {
            var bytes = new byte[32];
            RandomNumberGenerator.Fill(bytes);
            return Convert.ToBase64String(bytes);
        }

        public async Task<IResponseWrapper> RegisterUserAsync(UserRegistrationRequest userRegistration)
        {
            var userWithSameEmail = await _userManager.FindByEmailAsync(userRegistration.Email);
            if (userWithSameEmail is not null)
                return ResponseWrapper.Fail("Email address already taken.");

            var newUser = new ApplicationUser
            {
                FullName = userRegistration.FullName,
                Email = userRegistration.Email,
                UserName = userRegistration.Email,
                PhoneNumber = userRegistration.PhoneNumber,
                IsActive = userRegistration.ActivateUser,
                EmailConfirmed = userRegistration.AutoConfirmEmail,
                RefreshToken = GenerateSecureToken(),
                RefreshTokenExpiryDate = _dateTimeService.NowUtc.AddDays(1)
            };

            var identityUserResult = await _userManager.CreateAsync(newUser, userRegistration.Password);

            if (identityUserResult.Succeeded)
            {
                var identityRoleResult = await _userManager.AddToRoleAsync(newUser, AppRoles.Basic);

                if (identityRoleResult.Succeeded)
                {
                    if (!userRegistration.AutoConfirmEmail)
                    {
                        var httpRequest = _httpContextAccessor.HttpContext?.Request;
                        var baseUrl     = $"{httpRequest?.Scheme}://{httpRequest?.Host}{httpRequest?.PathBase}";
                        var emailToken  = await _userManager.GenerateEmailConfirmationTokenAsync(newUser);
                        var callbackUrl = $"{baseUrl}/Account/ConfirmEmail" +
                                          $"?userId={newUser.Id}" +
                                          $"&token={HttpUtility.UrlEncode(emailToken)}";

                        await _emailService.SendAsync(new SendEmailDto
                        {
                            Subject     = "Confirm Your Email",
                            MailTo      = newUser.Email,
                            MessageBody = $"<p>Hello: {newUser.FullName}</p>" +
                                          "<p>Please confirm your email by clicking the link below.</p>" +
                                          $"<p><a href=\"{callbackUrl}\">Confirm Email</a></p>"
                        });
                    }

                    return ResponseWrapper.Success("User registered successfully.");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityRoleResult));
            }

            return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityUserResult));
        }

        public async Task<IResponseWrapper> UpdateUserAsync(UpdateUserRequest userUpdate)
        {
            var userInDb = await _userManager.FindByIdAsync(userUpdate.UserId.ToString());

            if (userInDb is not null)
            {
                userInDb.FullName = userUpdate.FullName;
                userInDb.PhoneNumber = userUpdate.PhoneNumber;

                var identityResult = await _userManager.UpdateAsync(userInDb);

                if (identityResult.Succeeded)
                {
                    return ResponseWrapper.Success("User updated successfully.");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityResult));
            }

            return ResponseWrapper.Fail("User does not exists.");
        }

        #region Private Helpers
        private static List<string> GetIdentityResultErrorDescriptions(IdentityResult identityResult)
        {
            var errorDescriptions = new List<string>();
            foreach (var error in identityResult.Errors)
            {
                errorDescriptions.Add(error.Description);
            }

            return errorDescriptions;
        }
        #endregion

        public async Task<IResponseWrapper<UserResponse>> GetUserByIdAsync(int userId)
        {
            var userInDb = await _userManager.FindByIdAsync(userId.ToString());
            if (userInDb is not null)
            {
                var mappedUser = userInDb.Adapt<UserResponse>();

                return ResponseWrapper<UserResponse>.Success(data: mappedUser);
            }

            return ResponseWrapper<UserResponse>.Fail("User does not exists.");
        }

        public async Task<IResponseWrapper<PagedResult<UserResponse>>> GetUsersPagedQueryAsync(
            PagedFilterRequest pagedFilterRequest,
            CancellationToken ct)
        {
            var usersQuery = _userManager.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(pagedFilterRequest.SearchTerm))
            {
                var term = pagedFilterRequest.SearchTerm.Trim();
                var searchPattern = $"%{term}%";

                usersQuery = usersQuery.Where(u =>
                    EF.Functions.Like(u.FullName, searchPattern) ||
                    EF.Functions.Like(u.Email, searchPattern)
                );
            }

            usersQuery = pagedFilterRequest.SortBy?.ToLower() switch
            {
                "email" => pagedFilterRequest.SortDirection == "desc"
                    ? usersQuery.OrderByDescending(u => u.Email)
                    : usersQuery.OrderBy(u => u.Email),

                "id" => pagedFilterRequest.SortDirection == "desc"
                    ? usersQuery.OrderByDescending(u => u.Id)
                    : usersQuery.OrderBy(u => u.Id),

                "fullname" or _ => pagedFilterRequest.SortDirection == "desc"
                    ? usersQuery.OrderByDescending(u => u.FullName)
                    : usersQuery.OrderBy(u => u.FullName),
            };

            var totalRecords = await usersQuery.CountAsync(ct);

            var users = await usersQuery
                .Skip((pagedFilterRequest.PageNumber - 1) * pagedFilterRequest.PageSize)
                .Take(pagedFilterRequest.PageSize)
                .Select(o => new UserResponse
                {
                    FullName = o.FullName,
                    Email = o.Email,
                    Id = o.Id,
                    IsActive = o.IsActive,
                    PhoneNumber = o.PhoneNumber,
                    UserName = o.UserName,
                    EmailConfirmed = o.EmailConfirmed
                })
                .ToListAsync(ct);

            var data = new PagedResult<UserResponse>
            {
                Data = users,
                TotalCount = totalRecords,
                CurrentPage = pagedFilterRequest.PageNumber,
                PageSize = pagedFilterRequest.PageSize,
            };

            return ResponseWrapper<PagedResult<UserResponse>>.Success(data: data);
        }

        public async Task<IResponseWrapper> ChangeUserPasswordAsync(int userId, ChangePasswordRequest changePassword)
        {
            var userInDb = await _userManager.FindByIdAsync(userId.ToString());
            if (userInDb is not null)
            {
                var identityResult = await _userManager.ChangePasswordAsync(
                    userInDb,
                    changePassword.CurrentPassword,
                    changePassword.NewPassword);

                if (identityResult.Succeeded)
                {
                    return ResponseWrapper.Success(message: "User password updated.");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityResult));
            }

            return ResponseWrapper.Fail("User does not exist.");
        }

        public async Task<IResponseWrapper> ChangeUserStatusAsync(ChangeUserStatusRequest changeUserStatus)
        {
            var userInDb = await _userManager.FindByIdAsync(changeUserStatus.UserId.ToString());
            if (userInDb is not null)
            {
                userInDb.IsActive = changeUserStatus.ActivateOrDeactivate;

                var identityResult = await _userManager.UpdateAsync(userInDb);

                if (identityResult.Succeeded)
                {
                    return ResponseWrapper
                        .Success(changeUserStatus.ActivateOrDeactivate
                            ? "User activated successfully."
                            : "User de-activated successfully");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(identityResult));
            }

            return ResponseWrapper.Fail("User does not exist.");
        }

        public async Task<IResponseWrapper<List<UserRoleViewModel>>> GetUserRolesAsync(int userId)
        {
            var userInDb = await _userManager.FindByIdAsync(userId.ToString());

            if (userInDb is not null)
            {
                var assignedRoleNames = (await _userManager.GetRolesAsync(userInDb)).ToHashSet(StringComparer.OrdinalIgnoreCase);

                var userRolesViewModel = (await _roleManager.Roles.ToListAsync())
                    .Where(r => assignedRoleNames.Contains(r.Name!))
                    .Select(r => new UserRoleViewModel { RoleName = r.Name, RoleDescription = r.Description })
                    .ToList();

                return ResponseWrapper<List<UserRoleViewModel>>.Success(userRolesViewModel);
            }

            return ResponseWrapper<List<UserRoleViewModel>>.Fail("User does not exist.");
        }

        public async Task<IResponseWrapper> UpdateUserRolesAsync(UpdateUserRolesRequest request, CancellationToken ct)
        {
            var user = await _userManager.Users
                .FirstOrDefaultAsync(u => u.Id == request.UserId, ct);

            if (user is null)
                return ResponseWrapper.Fail("User does not exist.");

            if (await _userManager.IsInRoleAsync(user, AppRoles.Admin))
                return ResponseWrapper.Fail("User roles update not permitted.");

            var rolesToAssign = request.Roles.ToList();

            foreach (var roleName in rolesToAssign)
            {
                if (!await _roleManager.RoleExistsAsync(roleName))
                    return ResponseWrapper.Fail($"Role '{roleName}' does not exist.");
            }

            var currentRoles = await _userManager.GetRolesAsync(user);

            var removeResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
            if (!removeResult.Succeeded)
                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(removeResult));

            var addResult = await _userManager.AddToRolesAsync(user, rolesToAssign);
            if (!addResult.Succeeded)
                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(addResult));

            return ResponseWrapper.Success("Updated user roles successfully.");
        }

        public async Task<IResponseWrapper> ForgotPasswordAsync(string email)
        {
            const string safeMessage = "If the email is registered, you will receive an email shortly.";

            var user = await _userManager.FindByEmailAsync(email);
            if (user is null || !user.EmailConfirmed)
                return ResponseWrapper.Success(safeMessage);

            var request = _httpContextAccessor.HttpContext?.Request;
            var baseUrl = $"{request.Scheme}://{request.Host}{request.PathBase}";
            var code = await _userManager.GeneratePasswordResetTokenAsync(user);
            var callbackUrl =
                $"{baseUrl}/Account/ResetPassword?email={HttpUtility.UrlEncode(user.Email)}&code={HttpUtility.UrlEncode(code)}";

            var emailModel = new SendEmailDto
            {
                Subject = "Reset Password",
                MailTo = user.Email,
                MessageBody = $"<p>Hello: {user.FullName}</p>" +
                $"<p>Username: {user.UserName}.</p>" +
                "<p>In order to reset your password, please click on the following link.</p>" +
                $"<p><a href=\"{callbackUrl}\">Click here</a></p>" +
                "<p>Thank you,</p>"
            };

            try
            {
                await _emailService.SendAsync(emailModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send password reset email to {Email}", email);
            }

            return ResponseWrapper.Success(safeMessage);
        }

        public async Task<IResponseWrapper> ResetPasswordAsync(ResetPasswordRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user is null)
                return ResponseWrapper.Fail("This email doesn't exist.");

            if (!user.EmailConfirmed)
                return ResponseWrapper.Fail("This email is not confirmed.");

            try
            {
                var decodedToken = HttpUtility.UrlDecode(request.Token);
                var result = await _userManager.ResetPasswordAsync(user, decodedToken, request.Password);

                if (result.Succeeded)
                {
                    await _userManager.UpdateSecurityStampAsync(user);
                    return ResponseWrapper.Success("Your password has changed successfully.");
                }

                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(result));
            }
            catch (Exception)
            {
                return ResponseWrapper.Fail(SD.ErrorOccured);
            }
        }

        public async Task<IResponseWrapper> ConfirmEmailAsync(int userId, string token)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User does not exist.");

            if (user.EmailConfirmed)
                return ResponseWrapper.Success("Email is already confirmed.");
            
            var decodedToken = HttpUtility.UrlDecode(token);

            var result = await _userManager.ConfirmEmailAsync(user, decodedToken);
            if (!result.Succeeded)
                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(result));

            return ResponseWrapper.Success("Email confirmed successfully.");
        }

        public async Task<IResponseWrapper> ConfirmEmailChangeAsync(int userId, string newEmail, string token)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User does not exist.");

            var result = await _userManager.ChangeEmailAsync(user, newEmail, token);
            if (!result.Succeeded)
                return ResponseWrapper.Fail(GetIdentityResultErrorDescriptions(result));

            await _userManager.SetUserNameAsync(user, newEmail);
            return ResponseWrapper.Success("Email changed successfully.");
        }

        public async Task<IResponseWrapper> ResendConfirmationEmailAsync(string email)
        {
            const string safeMessage = "If the email is registered, you will receive an email shortly.";

            var user = await _userManager.FindByEmailAsync(email);
            if (user is null || user.EmailConfirmed)
                return ResponseWrapper.Success(safeMessage);

            var httpRequest = _httpContextAccessor.HttpContext?.Request;
            var baseUrl     = $"{httpRequest?.Scheme}://{httpRequest?.Host}{httpRequest?.PathBase}";
            var token       = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            var callbackUrl = $"{baseUrl}/Account/ConfirmEmail" +
                              $"?userId={user.Id}" +
                              $"&token={HttpUtility.UrlEncode(token)}";

            await _emailService.SendAsync(new SendEmailDto
            {
                Subject     = "Confirm Your Email",
                MailTo      = user.Email,
                MessageBody = $"<p>Hello: {user.FullName}</p>" +
                              "<p>Please confirm your email by clicking the link below.</p>" +
                              $"<p><a href=\"{callbackUrl}\">Confirm Email</a></p>"
            });

            return ResponseWrapper.Success(safeMessage);
        }

        public async Task<IResponseWrapper> GenerateChangeEmailTokenAsync(string newEmail)
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User does not exist.");

            if (string.Equals(user.Email, newEmail, StringComparison.OrdinalIgnoreCase))
                return ResponseWrapper.Fail("New email must be different from your current email.");

            var httpRequest = _httpContextAccessor.HttpContext?.Request;
            var baseUrl     = $"{httpRequest?.Scheme}://{httpRequest?.Host}{httpRequest?.PathBase}";
            var token       = await _userManager.GenerateChangeEmailTokenAsync(user, newEmail);
            var callbackUrl = $"{baseUrl}/Account/ConfirmEmailChange" +
                              $"?userId={user.Id}" +
                              $"&newEmail={HttpUtility.UrlEncode(newEmail)}" +
                              $"&token={HttpUtility.UrlEncode(token)}";

            await _emailService.SendAsync(new SendEmailDto
            {
                Subject     = "Confirm Your Email Change",
                MailTo      = user.Email,
                MessageBody = $"<p>Hello: {user.FullName}</p>" +
                              "<p>Click the link below to confirm your email change.</p>" +
                              $"<p><a href=\"{callbackUrl}\">Confirm Email Change</a></p>"
            });

            return ResponseWrapper.Success("Email change confirmation sent. Please check your inbox.");
        }

        public async Task<IResponseWrapper<List<string>>> GenerateNew2FARecoveryCodesAsync()
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper<List<string>>.Fail("User does not exist.");

            if (!user.TwoFactorEnabled)
                return ResponseWrapper<List<string>>.Fail("Two-factor authentication is not enabled.");

            var codes = await _userManager.GenerateNewTwoFactorRecoveryCodesAsync(user, 10);
            return ResponseWrapper<List<string>>.Success(codes!.ToList(), "New recovery codes generated.");
        }

        public async Task<IResponseWrapper> LockUserAsync(int userId)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User does not exist.");

            if (await _userManager.IsInRoleAsync(user, AppRoles.Admin))
                return ResponseWrapper.Fail("Cannot lock the system administrator.");

            await _userManager.SetLockoutEnabledAsync(user, true);
            await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue);

            user.RefreshTokenExpiryDate = _dateTimeService.NowUtc.AddDays(-1);
            await _userManager.UpdateAsync(user);

            return ResponseWrapper.Success("User locked successfully.");
        }

        public async Task<IResponseWrapper> UnlockUserAsync(int userId)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User does not exist.");

            await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.UtcNow);
            await _userManager.ResetAccessFailedCountAsync(user);

            return ResponseWrapper.Success("User unlocked successfully.");
        }

        public async Task<IResponseWrapper<ProfileResponse>> GetMyProfileAsync()
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper<ProfileResponse>.Fail("User not found.");

            var roles = (await _userManager.GetRolesAsync(user)).ToList();

            var permissionsSet = new HashSet<string>();
            foreach (var roleName in roles)
            {
                var role   = await _roleManager.FindByNameAsync(roleName);
                var claims = await _roleManager.GetClaimsAsync(role);
                foreach (var claim in claims)
                    permissionsSet.Add(claim.Value);
            }

            return ResponseWrapper<ProfileResponse>.Success(new ProfileResponse
            {
                Id               = user.Id,
                FullName         = user.FullName,
                Email            = user.Email,
                UserName         = user.UserName,
                IsActive         = user.IsActive,
                EmailConfirmed   = user.EmailConfirmed,
                PhoneNumber      = user.PhoneNumber,
                TwoFactorEnabled = user.TwoFactorEnabled,
                CreatedDate      = user.CreatedDate,
                Roles            = roles,
                Permissions      = [.. permissionsSet]
            });
        }

        public async Task<IResponseWrapper> LogoutAsync(LogoutRequest request)
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User not found.");

            if (string.IsNullOrEmpty(request.RefreshToken))
                return ResponseWrapper.Fail("Refresh token is required.");

            if (user.RefreshToken != request.RefreshToken)
                return ResponseWrapper.Fail("Invalid refresh token.");

            user.RefreshToken           = string.Empty;
            user.RefreshTokenExpiryDate = _dateTimeService.NowUtc.AddDays(-1);
            await _userManager.UpdateAsync(user);

            return ResponseWrapper.Success("Logged out successfully.");
        }

        public async Task<IResponseWrapper<TwoFactorAuthViewModel>> SetupTwoFactorAuthAsync()
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper<TwoFactorAuthViewModel>.Fail("User not found.");

            if (user.TwoFactorEnabled)
                return ResponseWrapper<TwoFactorAuthViewModel>.Fail(
                    "Two-factor authentication is already enabled. Disable it first to reconfigure.");

            var key = await _userManager.GetAuthenticatorKeyAsync(user);
            if (string.IsNullOrEmpty(key))
            {
                await _userManager.ResetAuthenticatorKeyAsync(user);
                key = await _userManager.GetAuthenticatorKeyAsync(user);
            }

            var issuer = Uri.EscapeDataString(_twoFactorOptions.Issuer);
            var email  = Uri.EscapeDataString(user.Email);
            var codeQR = $"otpauth://totp/{issuer}:{email}?secret={key}&issuer={issuer}";

            return ResponseWrapper<TwoFactorAuthViewModel>.Success(
                new TwoFactorAuthViewModel { KeySecret = key, CodeQR = codeQR });
        }

        public async Task<IResponseWrapper> ConfirmTwoFactorAuthAsync(TwoFactorCodeRequest request)
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User not found.");

            var key = await _userManager.GetAuthenticatorKeyAsync(user);
            if (string.IsNullOrEmpty(key))
                return ResponseWrapper.Fail(
                    "No authenticator configured. Please call setup-2fa first.");

            var valid = await _userManager.VerifyTwoFactorTokenAsync(
                user,
                _userManager.Options.Tokens.AuthenticatorTokenProvider,
                request.Code);

            if (!valid)
            {
                await _userManager.AccessFailedAsync(user);
                return ResponseWrapper.Fail("Invalid verification code.");
            }

            await _userManager.ResetAccessFailedCountAsync(user);
            return ResponseWrapper.Success("Verification code is valid.");
        }

        public async Task<IResponseWrapper<List<string>>> EnableTwoFactorAuthAsync(
            TwoFactorCodeRequest request)
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper<List<string>>.Fail("User not found.");

            if (user.TwoFactorEnabled)
                return ResponseWrapper<List<string>>.Fail(
                    "Two-factor authentication is already enabled.");

            var key = await _userManager.GetAuthenticatorKeyAsync(user);
            if (string.IsNullOrEmpty(key))
                return ResponseWrapper<List<string>>.Fail(
                    "No authenticator configured. Please call setup-2fa first.");

            var valid = await _userManager.VerifyTwoFactorTokenAsync(
                user,
                _userManager.Options.Tokens.AuthenticatorTokenProvider,
                request.Code);

            if (!valid)
            {
                await _userManager.AccessFailedAsync(user);
                if (await _userManager.IsLockedOutAsync(user))
                    return ResponseWrapper<List<string>>.Fail(
                        "Account locked due to multiple failed attempts.");
                return ResponseWrapper<List<string>>.Fail("Invalid authenticator code.");
            }

            await _userManager.ResetAccessFailedCountAsync(user);
            await _userManager.SetTwoFactorEnabledAsync(user, true);

            var codes = await _userManager.GenerateNewTwoFactorRecoveryCodesAsync(user, 10);

            return ResponseWrapper<List<string>>.Success(
                codes!.ToList(),
                "Two-factor authentication enabled. Store your recovery codes safely.");
        }

        public async Task<IResponseWrapper> DisableTwoFactorAuthAsync(
            DisableTwoFactorAuthRequest request)
        {
            var userId = _currentUserService.GetUserId();
            var user   = await _userManager.FindByIdAsync(userId?.ToString());
            if (user is null)
                return ResponseWrapper.Fail("User not found.");

            if (!user.TwoFactorEnabled)
                return ResponseWrapper.Fail("Two-factor authentication is not enabled.");

            var passwordValid = await _userManager.CheckPasswordAsync(user, request.Password);
            if (!passwordValid)
            {
                await _userManager.AccessFailedAsync(user);
                if (await _userManager.IsLockedOutAsync(user))
                    return ResponseWrapper.Fail("Account locked due to multiple failed attempts.");
                return ResponseWrapper.Fail("Invalid password.");
            }

            if (!string.IsNullOrEmpty(request.Code))
            {
                var codeValid = await _userManager.VerifyTwoFactorTokenAsync(
                    user,
                    _userManager.Options.Tokens.AuthenticatorTokenProvider,
                    request.Code);

                if (!codeValid)
                    return ResponseWrapper.Fail("Invalid authenticator code.");
            }

            await _userManager.ResetAccessFailedCountAsync(user);
            await _userManager.SetTwoFactorEnabledAsync(user, false);

            return ResponseWrapper.Success("Two-factor authentication disabled.");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Migrations\20260418130054_InitiailDb.cs' @'
using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UMS.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitiailDb : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "Identity");

            migrationBuilder.CreateTable(
                name: "AuditTrails",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: true),
                    Type = table.Column<int>(type: "int", nullable: false),
                    TableName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    DateTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    OldValues = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    NewValues = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AffectedColumns = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PrimaryKey = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditTrails", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Categories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Slug = table.Column<string>(type: "nvarchar(250)", maxLength: 150, nullable: false),
                    ParentId = table.Column<int>(type: "int", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    SoftDeleted = table.Column<bool>(type: "bit", nullable: false),
                    DeletedBy = table.Column<int>(type: "int", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedBy = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastModifiedBy = table.Column<int>(type: "int", nullable: true),
                    LastModifiedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RowVersion = table.Column<byte[]>(type: "varbinary(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Categories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Categories_Categories_ParentId",
                        column: x => x.ParentId,
                        principalTable: "Categories",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "LogUserActivities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: true),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UrlData = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    UserData = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IPAddress = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Browser = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    HttpMethod = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ImpersonatedBy = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LogUserActivities", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "OutboxMessages",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Type = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Payload = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    OccurredOnUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ProcessedOnUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RetryCount = table.Column<int>(type: "int", nullable: false),
                    NextRetryOnUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Error = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OutboxMessages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "RefreshTokens",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    Token = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ReplacedByToken = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsRevoked = table.Column<bool>(type: "bit", nullable: false),
                    IpAddress = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    UserAgent = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedBy = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastModifiedBy = table.Column<int>(type: "int", nullable: true),
                    LastModifiedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RefreshTokens", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Roles",
                schema: "Identity",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Description = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    NormalizedName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    ConcurrencyStamp = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Roles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                schema: "Identity",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FullName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    RefreshToken = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    RefreshTokenExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    UserName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    NormalizedUserName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    Email = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    NormalizedEmail = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    EmailConfirmed = table.Column<bool>(type: "bit", nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    SecurityStamp = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ConcurrencyStamp = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PhoneNumberConfirmed = table.Column<bool>(type: "bit", nullable: false),
                    TwoFactorEnabled = table.Column<bool>(type: "bit", nullable: false),
                    LockoutEnd = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    LockoutEnabled = table.Column<bool>(type: "bit", nullable: false),
                    AccessFailedCount = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "RoleClaims",
                schema: "Identity",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Description = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    RoleId = table.Column<int>(type: "int", nullable: false),
                    ClaimType = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ClaimValue = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RoleClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RoleClaims_Roles_RoleId",
                        column: x => x.RoleId,
                        principalSchema: "Identity",
                        principalTable: "Roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserClaims",
                schema: "Identity",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    ClaimType = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ClaimValue = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserClaims_Users_UserId",
                        column: x => x.UserId,
                        principalSchema: "Identity",
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserLogins",
                schema: "Identity",
                columns: table => new
                {
                    LoginProvider = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ProviderKey = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ProviderDisplayName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    UserId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserLogins", x => new { x.LoginProvider, x.ProviderKey });
                    table.ForeignKey(
                        name: "FK_UserLogins_Users_UserId",
                        column: x => x.UserId,
                        principalSchema: "Identity",
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserRoles",
                schema: "Identity",
                columns: table => new
                {
                    UserId = table.Column<int>(type: "int", nullable: false),
                    RoleId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserRoles", x => new { x.UserId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_UserRoles_Roles_RoleId",
                        column: x => x.RoleId,
                        principalSchema: "Identity",
                        principalTable: "Roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserRoles_Users_UserId",
                        column: x => x.UserId,
                        principalSchema: "Identity",
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserTokens",
                schema: "Identity",
                columns: table => new
                {
                    UserId = table.Column<int>(type: "int", nullable: false),
                    LoginProvider = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Value = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserTokens", x => new { x.UserId, x.LoginProvider, x.Name });
                    table.ForeignKey(
                        name: "FK_UserTokens_Users_UserId",
                        column: x => x.UserId,
                        principalSchema: "Identity",
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Categories_ParentId",
                table: "Categories",
                column: "ParentId");

            migrationBuilder.CreateIndex(
                name: "IX_Categories_SoftDeleted",
                table: "Categories",
                column: "SoftDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_RoleClaims_RoleId",
                schema: "Identity",
                table: "RoleClaims",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "RoleNameIndex",
                schema: "Identity",
                table: "Roles",
                column: "NormalizedName",
                unique: true,
                filter: "[NormalizedName] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_UserClaims_UserId",
                schema: "Identity",
                table: "UserClaims",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserLogins_UserId",
                schema: "Identity",
                table: "UserLogins",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserRoles_RoleId",
                schema: "Identity",
                table: "UserRoles",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "EmailIndex",
                schema: "Identity",
                table: "Users",
                column: "NormalizedEmail");

            migrationBuilder.CreateIndex(
                name: "UserNameIndex",
                schema: "Identity",
                table: "Users",
                column: "NormalizedUserName",
                unique: true,
                filter: "[NormalizedUserName] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AuditTrails");

            migrationBuilder.DropTable(
                name: "Categories");

            migrationBuilder.DropTable(
                name: "LogUserActivities");

            migrationBuilder.DropTable(
                name: "OutboxMessages");

            migrationBuilder.DropTable(
                name: "RefreshTokens");

            migrationBuilder.DropTable(
                name: "RoleClaims",
                schema: "Identity");

            migrationBuilder.DropTable(
                name: "UserClaims",
                schema: "Identity");

            migrationBuilder.DropTable(
                name: "UserLogins",
                schema: "Identity");

            migrationBuilder.DropTable(
                name: "UserRoles",
                schema: "Identity");

            migrationBuilder.DropTable(
                name: "UserTokens",
                schema: "Identity");

            migrationBuilder.DropTable(
                name: "Roles",
                schema: "Identity");

            migrationBuilder.DropTable(
                name: "Users",
                schema: "Identity");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Migrations\20260418130054_InitiailDb.Designer.cs' @'
// <auto-generated />
using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using UMS.Infrastructure.Persistence.Contexts;

#nullable disable

namespace UMS.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260418130054_InitiailDb")]
    partial class InitiailDb
    {
        /// <inheritdoc />
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "10.0.6")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("UMS.Domain.Entities.AuditTrail", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("AffectedColumns")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("DateTime")
                        .HasColumnType("datetime2");

                    b.Property<string>("NewValues")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("OldValues")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("PrimaryKey")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("TableName")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("Type")
                        .HasColumnType("int");

                    b.Property<int?>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("AuditTrails");
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("CreatedBy")
                        .HasColumnType("int");

                    b.Property<DateTime?>("DeletedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("DeletedBy")
                        .HasColumnType("int");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<DateTime?>("LastModifiedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("LastModifiedBy")
                        .HasColumnType("int");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("nvarchar(150)");

                    b.Property<int?>("ParentId")
                        .HasColumnType("int");

                    b.Property<byte[]>("RowVersion")
                        .IsRequired()
                        .HasColumnType("varbinary(max)");

                    b.Property<string>("Slug")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("nvarchar(250)");

                    b.Property<bool>("SoftDeleted")
                        .HasColumnType("bit");

                    b.Property<int>("SortOrder")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int")
                        .HasDefaultValue(0);

                    b.HasKey("Id");

                    b.HasIndex("ParentId");

                    b.HasIndex("SoftDeleted");

                    b.ToTable("Categories", (string)null);
                });

            modelBuilder.Entity("UMS.Domain.Entities.LogUserActivity", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("Browser")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("HttpMethod")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("IPAddress")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int?>("ImpersonatedBy")
                        .HasColumnType("int");

                    b.Property<string>("UrlData")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("UserData")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int?>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("LogUserActivities");
                });

            modelBuilder.Entity("UMS.Domain.Entities.OutboxMessage", b =>
                {
                    b.Property<long>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bigint");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<long>("Id"));

                    b.Property<string>("Error")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("NextRetryOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<DateTime>("OccurredOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<string>("Payload")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("ProcessedOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<int>("RetryCount")
                        .HasColumnType("int");

                    b.Property<string>("Type")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("Id");

                    b.ToTable("OutboxMessages");
                });

            modelBuilder.Entity("UMS.Domain.Entities.RefreshToken", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("CreatedBy")
                        .HasColumnType("int");

                    b.Property<DateTime>("ExpiresAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("IpAddress")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("IsRevoked")
                        .HasColumnType("bit");

                    b.Property<DateTime?>("LastModifiedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("LastModifiedBy")
                        .HasColumnType("int");

                    b.Property<string>("ReplacedByToken")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Token")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("UserAgent")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("RefreshTokens");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRole", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("Name")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("NormalizedName")
                        .IsUnique()
                        .HasDatabaseName("RoleNameIndex")
                        .HasFilter("[NormalizedName] IS NOT NULL");

                    b.ToTable("Roles", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRoleClaim", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("RoleId");

                    b.ToTable("RoleClaims", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUser", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("AccessFailedCount")
                        .HasColumnType("int");

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("Email")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<bool>("EmailConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("FullName")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<bool>("IsActive")
                        .HasColumnType("bit");

                    b.Property<bool>("LockoutEnabled")
                        .HasColumnType("bit");

                    b.Property<DateTimeOffset?>("LockoutEnd")
                        .HasColumnType("datetimeoffset");

                    b.Property<string>("NormalizedEmail")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedUserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("PasswordHash")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("PhoneNumber")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("PhoneNumberConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("RefreshToken")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<DateTime>("RefreshTokenExpiryDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("SecurityStamp")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("TwoFactorEnabled")
                        .HasColumnType("bit");

                    b.Property<string>("UserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("NormalizedEmail")
                        .HasDatabaseName("EmailIndex");

                    b.HasIndex("NormalizedUserName")
                        .IsUnique()
                        .HasDatabaseName("UserNameIndex")
                        .HasFilter("[NormalizedUserName] IS NOT NULL");

                    b.ToTable("Users", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserClaim", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("UserId");

                    b.ToTable("UserClaims", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserLogin", b =>
                {
                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderKey")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderDisplayName")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("LoginProvider", "ProviderKey");

                    b.HasIndex("UserId");

                    b.ToTable("UserLogins", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserRole", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("UserId", "RoleId");

                    b.HasIndex("RoleId");

                    b.ToTable("UserRoles", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserToken", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Name")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Value")
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("UserId", "LoginProvider", "Name");

                    b.ToTable("UserTokens", "Identity");
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.HasOne("UMS.Domain.Entities.Category", "Parent")
                        .WithMany("Children")
                        .HasForeignKey("ParentId")
                        .OnDelete(DeleteBehavior.NoAction);

                    b.Navigation("Parent");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRoleClaim", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserClaim", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserLogin", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserRole", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserToken", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.Navigation("Children");
                });
#pragma warning restore 612, 618
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Migrations\20260424070230_AddCategoryNormalizationAndConcurrency.cs' @'
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UMS.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCategoryNormalizationAndConcurrency : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "NormalizedName",
                table: "Categories",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "NormalizedSlug",
                table: "Categories",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.Sql("""
                UPDATE [Categories]
                SET
                    [NormalizedName] = UPPER(LTRIM(RTRIM([Name]))),
                    [NormalizedSlug] = UPPER(LTRIM(RTRIM([Slug])))
                """);

            migrationBuilder.AlterColumn<string>(
                name: "NormalizedName",
                table: "Categories",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(256)",
                oldMaxLength: 256,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "NormalizedSlug",
                table: "Categories",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(256)",
                oldMaxLength: 256,
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "UX_Categories_NormalizedName",
                table: "Categories",
                column: "NormalizedName",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UX_Categories_NormalizedSlug",
                table: "Categories",
                column: "NormalizedSlug",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "UX_Categories_NormalizedName",
                table: "Categories");

            migrationBuilder.DropIndex(
                name: "UX_Categories_NormalizedSlug",
                table: "Categories");

            migrationBuilder.DropColumn(
                name: "NormalizedName",
                table: "Categories");

            migrationBuilder.DropColumn(
                name: "NormalizedSlug",
                table: "Categories");
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Migrations\20260424070230_AddCategoryNormalizationAndConcurrency.Designer.cs' @'
// <auto-generated />
using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using UMS.Infrastructure.Persistence.Contexts;

#nullable disable

namespace UMS.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260424070230_AddCategoryNormalizationAndConcurrency")]
    partial class AddCategoryNormalizationAndConcurrency
    {
        /// <inheritdoc />
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "10.0.6")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("UMS.Domain.Entities.AuditTrail", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("AffectedColumns")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("DateTime")
                        .HasColumnType("datetime2");

                    b.Property<string>("NewValues")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("OldValues")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("PrimaryKey")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("TableName")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("Type")
                        .HasColumnType("int");

                    b.Property<int?>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("AuditTrails");
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("CreatedBy")
                        .HasColumnType("int");

                    b.Property<DateTime?>("DeletedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("DeletedBy")
                        .HasColumnType("int");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<DateTime?>("LastModifiedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("LastModifiedBy")
                        .HasColumnType("int");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("nvarchar(150)");

                    b.Property<string>("NormalizedName")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedSlug")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<int?>("ParentId")
                        .HasColumnType("int");

                    b.Property<byte[]>("RowVersion")
                        .IsConcurrencyToken()
                        .IsRequired()
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("varbinary(max)");

                    b.Property<string>("Slug")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("nvarchar(250)");

                    b.Property<bool>("SoftDeleted")
                        .HasColumnType("bit");

                    b.Property<int>("SortOrder")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int")
                        .HasDefaultValue(0);

                    b.HasKey("Id");

                    b.HasIndex("NormalizedName")
                        .IsUnique()
                        .HasDatabaseName("UX_Categories_NormalizedName");

                    b.HasIndex("NormalizedSlug")
                        .IsUnique()
                        .HasDatabaseName("UX_Categories_NormalizedSlug");

                    b.HasIndex("ParentId");

                    b.HasIndex("SoftDeleted");

                    b.ToTable("Categories", (string)null);
                });

            modelBuilder.Entity("UMS.Domain.Entities.LogUserActivity", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("Browser")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("HttpMethod")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("IPAddress")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int?>("ImpersonatedBy")
                        .HasColumnType("int");

                    b.Property<string>("UrlData")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("UserData")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int?>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("LogUserActivities");
                });

            modelBuilder.Entity("UMS.Domain.Entities.OutboxMessage", b =>
                {
                    b.Property<long>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bigint");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<long>("Id"));

                    b.Property<string>("Error")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("NextRetryOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<DateTime>("OccurredOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<string>("Payload")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("ProcessedOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<int>("RetryCount")
                        .HasColumnType("int");

                    b.Property<string>("Type")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("Id");

                    b.ToTable("OutboxMessages");
                });

            modelBuilder.Entity("UMS.Domain.Entities.RefreshToken", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("CreatedBy")
                        .HasColumnType("int");

                    b.Property<DateTime>("ExpiresAt")
                        .HasColumnType("datetime2");

                    b.Property<string>("IpAddress")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("IsRevoked")
                        .HasColumnType("bit");

                    b.Property<DateTime?>("LastModifiedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("LastModifiedBy")
                        .HasColumnType("int");

                    b.Property<string>("ReplacedByToken")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Token")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("UserAgent")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("RefreshTokens");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRole", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("Name")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("NormalizedName")
                        .IsUnique()
                        .HasDatabaseName("RoleNameIndex")
                        .HasFilter("[NormalizedName] IS NOT NULL");

                    b.ToTable("Roles", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRoleClaim", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("RoleId");

                    b.ToTable("RoleClaims", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUser", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("AccessFailedCount")
                        .HasColumnType("int");

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("Email")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<bool>("EmailConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("FullName")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<bool>("IsActive")
                        .HasColumnType("bit");

                    b.Property<bool>("LockoutEnabled")
                        .HasColumnType("bit");

                    b.Property<DateTimeOffset?>("LockoutEnd")
                        .HasColumnType("datetimeoffset");

                    b.Property<string>("NormalizedEmail")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedUserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("PasswordHash")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("PhoneNumber")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("PhoneNumberConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("RefreshToken")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<DateTime>("RefreshTokenExpiryDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("SecurityStamp")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("TwoFactorEnabled")
                        .HasColumnType("bit");

                    b.Property<string>("UserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("NormalizedEmail")
                        .HasDatabaseName("EmailIndex");

                    b.HasIndex("NormalizedUserName")
                        .IsUnique()
                        .HasDatabaseName("UserNameIndex")
                        .HasFilter("[NormalizedUserName] IS NOT NULL");

                    b.ToTable("Users", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserClaim", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("UserId");

                    b.ToTable("UserClaims", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserLogin", b =>
                {
                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderKey")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderDisplayName")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("LoginProvider", "ProviderKey");

                    b.HasIndex("UserId");

                    b.ToTable("UserLogins", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserRole", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("UserId", "RoleId");

                    b.HasIndex("RoleId");

                    b.ToTable("UserRoles", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserToken", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Name")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Value")
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("UserId", "LoginProvider", "Name");

                    b.ToTable("UserTokens", "Identity");
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.HasOne("UMS.Domain.Entities.Category", "Parent")
                        .WithMany("Children")
                        .HasForeignKey("ParentId")
                        .OnDelete(DeleteBehavior.NoAction);

                    b.Navigation("Parent");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRoleClaim", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserClaim", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserLogin", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserRole", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserToken", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.Navigation("Children");
                });
#pragma warning restore 612, 618
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Migrations\20260425071933_RemoveRefreshTokenTable.cs' @'
using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UMS.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveRefreshTokenTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RefreshTokens");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RefreshTokens",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatedBy = table.Column<int>(type: "int", nullable: true),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IpAddress = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsRevoked = table.Column<bool>(type: "bit", nullable: false),
                    LastModifiedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    LastModifiedBy = table.Column<int>(type: "int", nullable: true),
                    ReplacedByToken = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Token = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    UserAgent = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    UserId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RefreshTokens", x => x.Id);
                });
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Migrations\20260425071933_RemoveRefreshTokenTable.Designer.cs' @'
// <auto-generated />
using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using UMS.Infrastructure.Persistence.Contexts;

#nullable disable

namespace UMS.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260425071933_RemoveRefreshTokenTable")]
    partial class RemoveRefreshTokenTable
    {
        /// <inheritdoc />
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "10.0.6")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("UMS.Domain.Entities.AuditTrail", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("AffectedColumns")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("DateTime")
                        .HasColumnType("datetime2");

                    b.Property<string>("NewValues")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("OldValues")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("PrimaryKey")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("TableName")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("Type")
                        .HasColumnType("int");

                    b.Property<int?>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("AuditTrails");
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("CreatedBy")
                        .HasColumnType("int");

                    b.Property<DateTime?>("DeletedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("DeletedBy")
                        .HasColumnType("int");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<DateTime?>("LastModifiedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("LastModifiedBy")
                        .HasColumnType("int");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("nvarchar(150)");

                    b.Property<string>("NormalizedName")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedSlug")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<int?>("ParentId")
                        .HasColumnType("int");

                    b.Property<byte[]>("RowVersion")
                        .IsConcurrencyToken()
                        .IsRequired()
                        .HasColumnType("varbinary(max)");

                    b.Property<string>("Slug")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("nvarchar(250)");

                    b.Property<bool>("SoftDeleted")
                        .HasColumnType("bit");

                    b.Property<int>("SortOrder")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int")
                        .HasDefaultValue(0);

                    b.HasKey("Id");

                    b.HasIndex("NormalizedName")
                        .IsUnique()
                        .HasDatabaseName("UX_Categories_NormalizedName");

                    b.HasIndex("NormalizedSlug")
                        .IsUnique()
                        .HasDatabaseName("UX_Categories_NormalizedSlug");

                    b.HasIndex("ParentId");

                    b.HasIndex("SoftDeleted");

                    b.ToTable("Categories", (string)null);
                });

            modelBuilder.Entity("UMS.Domain.Entities.LogUserActivity", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("Browser")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("HttpMethod")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("IPAddress")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int?>("ImpersonatedBy")
                        .HasColumnType("int");

                    b.Property<string>("UrlData")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("UserData")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int?>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("LogUserActivities");
                });

            modelBuilder.Entity("UMS.Domain.Entities.OutboxMessage", b =>
                {
                    b.Property<long>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bigint");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<long>("Id"));

                    b.Property<string>("Error")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("NextRetryOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<DateTime>("OccurredOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<string>("Payload")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("ProcessedOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<int>("RetryCount")
                        .HasColumnType("int");

                    b.Property<string>("Type")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("Id");

                    b.ToTable("OutboxMessages");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRole", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("Name")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("NormalizedName")
                        .IsUnique()
                        .HasDatabaseName("RoleNameIndex")
                        .HasFilter("[NormalizedName] IS NOT NULL");

                    b.ToTable("Roles", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRoleClaim", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("RoleId");

                    b.ToTable("RoleClaims", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUser", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("AccessFailedCount")
                        .HasColumnType("int");

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("Email")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<bool>("EmailConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("FullName")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<bool>("IsActive")
                        .HasColumnType("bit");

                    b.Property<bool>("LockoutEnabled")
                        .HasColumnType("bit");

                    b.Property<DateTimeOffset?>("LockoutEnd")
                        .HasColumnType("datetimeoffset");

                    b.Property<string>("NormalizedEmail")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedUserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("PasswordHash")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("PhoneNumber")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("PhoneNumberConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("RefreshToken")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<DateTime>("RefreshTokenExpiryDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("SecurityStamp")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("TwoFactorEnabled")
                        .HasColumnType("bit");

                    b.Property<string>("UserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("NormalizedEmail")
                        .HasDatabaseName("EmailIndex");

                    b.HasIndex("NormalizedUserName")
                        .IsUnique()
                        .HasDatabaseName("UserNameIndex")
                        .HasFilter("[NormalizedUserName] IS NOT NULL");

                    b.ToTable("Users", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserClaim", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("UserId");

                    b.ToTable("UserClaims", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserLogin", b =>
                {
                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderKey")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderDisplayName")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("LoginProvider", "ProviderKey");

                    b.HasIndex("UserId");

                    b.ToTable("UserLogins", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserRole", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("UserId", "RoleId");

                    b.HasIndex("RoleId");

                    b.ToTable("UserRoles", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserToken", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Name")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Value")
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("UserId", "LoginProvider", "Name");

                    b.ToTable("UserTokens", "Identity");
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.HasOne("UMS.Domain.Entities.Category", "Parent")
                        .WithMany("Children")
                        .HasForeignKey("ParentId")
                        .OnDelete(DeleteBehavior.NoAction);

                    b.Navigation("Parent");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRoleClaim", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserClaim", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserLogin", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserRole", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserToken", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.Navigation("Children");
                });
#pragma warning restore 612, 618
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Migrations\ApplicationDbContextModelSnapshot.cs' @'
// <auto-generated />
using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using UMS.Infrastructure.Persistence.Contexts;

#nullable disable

namespace UMS.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    partial class ApplicationDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "10.0.6")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("UMS.Domain.Entities.AuditTrail", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("AffectedColumns")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("DateTime")
                        .HasColumnType("datetime2");

                    b.Property<string>("NewValues")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("OldValues")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("PrimaryKey")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("TableName")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("Type")
                        .HasColumnType("int");

                    b.Property<int?>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("AuditTrails");
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("CreatedBy")
                        .HasColumnType("int");

                    b.Property<DateTime?>("DeletedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("DeletedBy")
                        .HasColumnType("int");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bit")
                        .HasDefaultValue(true);

                    b.Property<DateTime?>("LastModifiedAt")
                        .HasColumnType("datetime2");

                    b.Property<int?>("LastModifiedBy")
                        .HasColumnType("int");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("nvarchar(150)");

                    b.Property<string>("NormalizedName")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedSlug")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<int?>("ParentId")
                        .HasColumnType("int");

                    b.Property<byte[]>("RowVersion")
                        .IsConcurrencyToken()
                        .IsRequired()
                        .HasColumnType("varbinary(max)");

                    b.Property<string>("Slug")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("nvarchar(250)");

                    b.Property<bool>("SoftDeleted")
                        .HasColumnType("bit");

                    b.Property<int>("SortOrder")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int")
                        .HasDefaultValue(0);

                    b.HasKey("Id");

                    b.HasIndex("NormalizedName")
                        .IsUnique()
                        .HasDatabaseName("UX_Categories_NormalizedName");

                    b.HasIndex("NormalizedSlug")
                        .IsUnique()
                        .HasDatabaseName("UX_Categories_NormalizedSlug");

                    b.HasIndex("ParentId");

                    b.HasIndex("SoftDeleted");

                    b.ToTable("Categories", (string)null);
                });

            modelBuilder.Entity("UMS.Domain.Entities.LogUserActivity", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("Browser")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("HttpMethod")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("IPAddress")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int?>("ImpersonatedBy")
                        .HasColumnType("int");

                    b.Property<string>("UrlData")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("UserData")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int?>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.ToTable("LogUserActivities");
                });

            modelBuilder.Entity("UMS.Domain.Entities.OutboxMessage", b =>
                {
                    b.Property<long>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("bigint");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<long>("Id"));

                    b.Property<string>("Error")
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("NextRetryOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<DateTime>("OccurredOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<string>("Payload")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime?>("ProcessedOnUtc")
                        .HasColumnType("datetime2");

                    b.Property<int>("RetryCount")
                        .HasColumnType("int");

                    b.Property<string>("Type")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("Id");

                    b.ToTable("OutboxMessages");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRole", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("Name")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("NormalizedName")
                        .IsUnique()
                        .HasDatabaseName("RoleNameIndex")
                        .HasFilter("[NormalizedName] IS NOT NULL");

                    b.ToTable("Roles", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRoleClaim", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("RoleId");

                    b.ToTable("RoleClaims", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUser", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<int>("AccessFailedCount")
                        .HasColumnType("int");

                    b.Property<string>("ConcurrencyStamp")
                        .IsConcurrencyToken()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("CreatedDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("Email")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<bool>("EmailConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("FullName")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<bool>("IsActive")
                        .HasColumnType("bit");

                    b.Property<bool>("LockoutEnabled")
                        .HasColumnType("bit");

                    b.Property<DateTimeOffset?>("LockoutEnd")
                        .HasColumnType("datetimeoffset");

                    b.Property<string>("NormalizedEmail")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("NormalizedUserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<string>("PasswordHash")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("PhoneNumber")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("PhoneNumberConfirmed")
                        .HasColumnType("bit");

                    b.Property<string>("RefreshToken")
                        .IsRequired()
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.Property<DateTime>("RefreshTokenExpiryDate")
                        .HasColumnType("datetime2");

                    b.Property<string>("SecurityStamp")
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("TwoFactorEnabled")
                        .HasColumnType("bit");

                    b.Property<string>("UserName")
                        .HasMaxLength(256)
                        .HasColumnType("nvarchar(256)");

                    b.HasKey("Id");

                    b.HasIndex("NormalizedEmail")
                        .HasDatabaseName("EmailIndex");

                    b.HasIndex("NormalizedUserName")
                        .IsUnique()
                        .HasDatabaseName("UserNameIndex")
                        .HasFilter("[NormalizedUserName] IS NOT NULL");

                    b.ToTable("Users", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserClaim", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<string>("ClaimType")
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("ClaimValue")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("Id");

                    b.HasIndex("UserId");

                    b.ToTable("UserClaims", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserLogin", b =>
                {
                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderKey")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("ProviderDisplayName")
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.HasKey("LoginProvider", "ProviderKey");

                    b.HasIndex("UserId");

                    b.ToTable("UserLogins", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserRole", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<int>("RoleId")
                        .HasColumnType("int");

                    b.HasKey("UserId", "RoleId");

                    b.HasIndex("RoleId");

                    b.ToTable("UserRoles", "Identity");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserToken", b =>
                {
                    b.Property<int>("UserId")
                        .HasColumnType("int");

                    b.Property<string>("LoginProvider")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Name")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Value")
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("UserId", "LoginProvider", "Name");

                    b.ToTable("UserTokens", "Identity");
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.HasOne("UMS.Domain.Entities.Category", "Parent")
                        .WithMany("Children")
                        .HasForeignKey("ParentId")
                        .OnDelete(DeleteBehavior.NoAction);

                    b.Navigation("Parent");
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationRoleClaim", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserClaim", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserLogin", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserRole", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationRole", null)
                        .WithMany()
                        .HasForeignKey("RoleId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Infrastructure.Identity.Models.ApplicationUserToken", b =>
                {
                    b.HasOne("UMS.Infrastructure.Identity.Models.ApplicationUser", null)
                        .WithMany()
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();
                });

            modelBuilder.Entity("UMS.Domain.Entities.Category", b =>
                {
                    b.Navigation("Children");
                });
#pragma warning restore 612, 618
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Persistence\Audit\AuditEntry.cs' @'
using Microsoft.EntityFrameworkCore.ChangeTracking;
using System.Text.Json;
using UMS.Domain.Enums;
using static UMS.Application.Enums.AppEnums;

namespace UMS.Infrastructure.Persistence.Audit
{
    public class AuditEntry
    {
        public AuditEntry(EntityEntry entry)
        {
            Entry = entry;
        }

        public EntityEntry Entry { get; }
        public int? UserId { get; set; }
        public string? TableName { get; set; }

        // âœ… Changed from string? to AuditType
        public AuditType Type { get; set; }

        public Dictionary<string, object> KeyValues { get; } = new();
        public Dictionary<string, object> OldValues { get; } = new();
        public Dictionary<string, object> NewValues { get; } = new();
        public List<PropertyEntry> TemporaryProperties { get; } = new();

        public bool HasTemporaryProperties => TemporaryProperties.Any();

        public AuditTrail ToAudit()
        {
            var audit = new AuditTrail
            {
                UserId = UserId,
                Type = Type,
                TableName = TableName,
                DateTime = DateTime.UtcNow,
                PrimaryKey = JsonSerializer.Serialize(KeyValues),
                OldValues = OldValues.Count == 0 ? null : JsonSerializer.Serialize(OldValues),
                NewValues = NewValues.Count == 0 ? null : JsonSerializer.Serialize(NewValues),
                AffectedColumns = TemporaryProperties.Count == 0 ? null : JsonSerializer.Serialize(TemporaryProperties.Select(p => p.Metadata.Name).ToList())
            };
            return audit;
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Persistence\Constants\SchemaNames.cs' @'
namespace UMS.Infrastructure.Persistence.Constants
{
    internal static class SchemaNames
    {
        public static string Identity = nameof(Identity);
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Persistence\Contexts\ApplicationDbContext.cs' @'
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using System.Reflection;
using System.Text.Json;
using UMS.Application.Interfaces.Common;
using UMS.Domain.Enums;
using UMS.Domain.Interfaces;
using UMS.Infrastructure.Extensions;
using UMS.Infrastructure.Persistence.Audit;
using static UMS.Application.Enums.AppEnums;

namespace UMS.Infrastructure.Persistence.Contexts
{
    public class ApplicationDbContext : IdentityDbContext<
        ApplicationUser,
        ApplicationRole,
        int,
        ApplicationUserClaim,
        ApplicationUserRole,
        ApplicationUserLogin,
        ApplicationRoleClaim,
        ApplicationUserToken>,
        IApplicationDbContext
    {
        private readonly IConfiguration _configuration;
        private readonly ICurrentUserService _currentUserService;
        private readonly IDateTimeService _dateTimeService;
        private IDbContextTransaction? _dbContextTransaction;

        private static readonly JsonSerializerOptions OutboxSerializerOptions = new(JsonSerializerDefaults.Web);

        public ApplicationDbContext(
            DbContextOptions<ApplicationDbContext> options,
            IConfiguration configuration,
            ICurrentUserService currentUserService,
            IDateTimeService dateTimeService)
            : base(options)
        {
            _configuration = configuration;
            _currentUserService = currentUserService;
            _dateTimeService = dateTimeService;
        }

        public DbSet<Category> Categories => Set<Category>();
        public DbSet<AuditTrail> AuditTrails => Set<AuditTrail>();
        public DbSet<LogUserActivity> LogUserActivities => Set<LogUserActivity>();
        public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
        }

        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            var userId = _currentUserService.GetUserId();
            var dateTime = _dateTimeService.NowUtc;

            foreach (var entry in ChangeTracker.Entries<IAuditable>())
            {
                if (entry.State == EntityState.Added)
                {
                    entry.Entity.CreatedAt = dateTime;
                    entry.Entity.CreatedBy = userId;
                }
                else if (entry.State == EntityState.Modified)
                {
                    entry.Entity.LastModifiedAt = dateTime;
                    entry.Entity.LastModifiedBy = userId;
                }
            }

            foreach (var entry in ChangeTracker.Entries<ISoftDelete>())
            {
                if (entry.State == EntityState.Deleted)
                {
                    entry.State = EntityState.Modified;
                    entry.Entity.SoftDeleted = true;
                    entry.Entity.DeletedAt = dateTime;
                    entry.Entity.DeletedBy = userId;
                }
            }

            var enableAuditLog = _configuration.GetValue<bool>("EnableAuditLog", false);

            if (!enableAuditLog)
            {
                return await base.SaveChangesAsync(cancellationToken);
            }

            var auditEntries = OnBeforeSaveChanges(userId);
            var result = await base.SaveChangesAsync(cancellationToken);
            await OnAfterSaveChanges(auditEntries, cancellationToken);
            return result;
        }

        private List<AuditEntry> OnBeforeSaveChanges(int? userId)
        {
            ChangeTracker.DetectChanges();
            var auditEntries = new List<AuditEntry>();

            foreach (var entry in ChangeTracker.Entries())
            {
                if (entry.Entity is AuditTrail
                    || entry.State is EntityState.Detached or EntityState.Unchanged)
                {
                    continue;
                }

                var auditEntry = new AuditEntry(entry)
                {
                    TableName = entry.Entity.GetType().Name,
                    UserId = userId
                };
                auditEntries.Add(auditEntry);

                foreach (var property in entry.Properties)
                {
                    var propertyName = property.Metadata.Name;

                    if (property.Metadata.IsPrimaryKey())
                    {
                        auditEntry.KeyValues[propertyName] = property.CurrentValue!;
                        continue;
                    }

                    switch (entry.State)
                    {
                        case EntityState.Added:
                            auditEntry.Type = AuditType.Create;
                            auditEntry.NewValues[propertyName] = property.CurrentValue!;
                            break;
                        case EntityState.Deleted:
                            auditEntry.Type = AuditType.Delete;
                            auditEntry.OldValues[propertyName] = property.OriginalValue!;
                            break;
                        case EntityState.Modified when property.IsModified:
                            auditEntry.Type = AuditType.Update;
                            auditEntry.OldValues[propertyName] = property.OriginalValue!;
                            auditEntry.NewValues[propertyName] = property.CurrentValue!;
                            break;
                    }
                }
            }

            foreach (var auditEntry in auditEntries.Where(e => !e.HasTemporaryProperties))
            {
                AuditTrails.Add(auditEntry.ToAudit());
            }

            return auditEntries.Where(e => e.HasTemporaryProperties).ToList();
        }

        private async Task OnAfterSaveChanges(List<AuditEntry> auditEntries, CancellationToken cancellationToken)
        {
            if (auditEntries == null || auditEntries.Count == 0)
            {
                return;
            }

            foreach (var auditEntry in auditEntries)
            {
                foreach (var prop in auditEntry.TemporaryProperties)
                {
                    var name = prop.Metadata.Name;
                    if (prop.Metadata.IsPrimaryKey())
                    {
                        auditEntry.KeyValues[name] = prop.CurrentValue!;
                    }
                    else
                    {
                        auditEntry.NewValues[name] = prop.CurrentValue!;
                    }
                }

                AuditTrails.Add(auditEntry.ToAudit());
            }

            await base.SaveChangesAsync(cancellationToken);
        }

        public void AddOutboxMessage<TNotification>(TNotification notification) where TNotification : class
        {
            if (notification == null)
            {
                throw new ArgumentNullException(nameof(notification));
            }

            var notificationType = notification.GetType();
            var typeName = notificationType.AssemblyQualifiedName
                ?? throw new InvalidOperationException($"Unable to resolve assembly-qualified name for {notificationType.FullName}.");

            OutboxMessages.Add(new OutboxMessage
            {
                Type = typeName,
                Payload = JsonSerializer.Serialize(notification, notificationType, OutboxSerializerOptions),
                OccurredOnUtc = _dateTimeService.NowUtc
            });
        }

        public void SetOriginalRowVersion<TEntity>(TEntity entity, byte[] rowVersion) where TEntity : class, IDataConcurrency
        {
            Entry(entity).Property(e => e.RowVersion).OriginalValue = rowVersion;
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());

            foreach (var entityType in modelBuilder.Model.GetEntityTypes())
            {
                var tableName = entityType.GetTableName();
                if (tableName != null && (tableName.StartsWith("AspNet") || entityType.ClrType.Namespace?.Contains("Identity") == true))
                {
                    if (tableName.StartsWith("AspNet"))
                    {
                        entityType.SetTableName(tableName.Substring(6));
                    }

                    if (Database.IsSqlServer())
                    {
                        entityType.SetSchema("Identity");
                    }
                }

                var decimalProperties = entityType.GetProperties()
                    .Where(p => p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?));

                foreach (var property in decimalProperties)
                {
                    property.SetPrecision(18);
                    property.SetScale(6);
                }

                // Only entities implementing ISoftDelete get the filter.
                // OutboxMessage and AuditTrail inherit BaseEntity<T> without ISoftDelete,
                // so they are intentionally excluded from soft-delete filtering.
                if (typeof(ISoftDelete).IsAssignableFrom(entityType.ClrType))
                {
                    entityType.AddSoftDeleteQueryFilter();
                }
            }
        }

        public async Task StartTransaction(CancellationToken cancellationToken)
        {
            if (_dbContextTransaction != null)
            {
                throw new InvalidOperationException("Transaction already started.");
            }

            _dbContextTransaction = await Database.BeginTransactionAsync(cancellationToken);
        }

        public async Task CommitTransaction(CancellationToken cancellationToken)
        {
            if (_dbContextTransaction == null)
            {
                throw new InvalidOperationException("No transaction to commit.");
            }

            try
            {
                await _dbContextTransaction.CommitAsync(cancellationToken);
            }
            finally
            {
                await _dbContextTransaction.DisposeAsync();
                _dbContextTransaction = null;
            }
        }

        public async Task RollbackTransaction(CancellationToken cancellationToken)
        {
            if (_dbContextTransaction == null)
            {
                throw new InvalidOperationException("No transaction to rollback.");
            }

            try
            {
                await _dbContextTransaction.RollbackAsync(cancellationToken);
            }
            finally
            {
                await _dbContextTransaction.DisposeAsync();
                _dbContextTransaction = null;
            }
        }

        public override void Dispose()
        {
            _dbContextTransaction?.Dispose();
            base.Dispose();
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Persistence\DbConfigurations\CategoryConfiguration.cs' @'
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using UMS.Domain.Entities;

namespace UMS.Infrastructure.Persistence.DbConfigurations
{
    public class CategoryConfiguration : IEntityTypeConfiguration<Category>
    {
        public void Configure(EntityTypeBuilder<Category> builder)
        {
            builder.ToTable("Categories");

            builder.HasKey(c => c.Id);

            builder.Property(c => c.Id)
                .IsRequired()
                .ValueGeneratedOnAdd()
                .HasColumnType("int");

            builder.Property(c => c.Name)
                .IsRequired()
                .HasMaxLength(150)
                .HasColumnType("nvarchar(150)");

            builder.Property(c => c.NormalizedName)
                .IsRequired()
                .HasMaxLength(256)
                .HasColumnType("nvarchar(256)");

            builder.Property(c => c.Slug)
                .IsRequired()
                .HasMaxLength(150)
                .HasColumnType("nvarchar(250)");

            builder.Property(c => c.NormalizedSlug)
                .IsRequired()
                .HasMaxLength(256)
                .HasColumnType("nvarchar(256)");

            builder.Property(c => c.ParentId);

            builder.Property(c => c.IsActive)
                .IsRequired()
                .HasDefaultValue(true);

            builder.Property(c => c.SortOrder)
                .IsRequired()
                .HasDefaultValue(0);

            builder.Property(c => c.RowVersion)
                .IsConcurrencyToken()
                .HasColumnType("varbinary(max)");

            builder.HasIndex(c => c.NormalizedName)
                .IsUnique()
                .HasDatabaseName("UX_Categories_NormalizedName");

            builder.HasIndex(c => c.NormalizedSlug)
                .IsUnique()
                .HasDatabaseName("UX_Categories_NormalizedSlug");

            builder.HasOne(c => c.Parent)
                .WithMany(c => c.Children)
                .HasForeignKey(c => c.ParentId)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Persistence\Interceptors\TrimStringInterceptor.cs' @'
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace UMS.Infrastructure.Persistence.Interceptors
{
    public class TrimStringInterceptor : SaveChangesInterceptor
    {
        public override InterceptionResult<int> SavingChanges(
            DbContextEventData eventData,
            InterceptionResult<int> result)
        {
            TrimStrings(eventData.Context);
            return result;
        }

        public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
            DbContextEventData eventData,
            InterceptionResult<int> result,
            CancellationToken cancellationToken = default)
        {
            TrimStrings(eventData.Context);
            return ValueTask.FromResult(result);
        }

        private void TrimStrings(DbContext? context)
        {
            if (context == null)
                return;

            foreach (var entry in context.ChangeTracker.Entries())
            {
                if (entry.State == EntityState.Added || entry.State == EntityState.Modified)
                {
                    foreach (PropertyEntry prop in entry.Properties)
                    {
                        if (prop.Metadata.ClrType == typeof(string) &&
                            prop.CurrentValue is string value)
                        {
                            var trimmed = value.Trim();

                            if (trimmed != value)
                            {
                                prop.CurrentValue = trimmed;
                            }
                        }
                    }
                }
            }
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Persistence\Seeds\ApplicationDbSeeder.cs' @'
using UMS.Infrastructure.Persistence.Contexts;

namespace UMS.Infrastructure.Persistence.DbInitializers
{
    public class ApplicationDbSeeder
    {
        private readonly ApplicationDbContext _context;
        private readonly IdentityDbSeeder identityDbSeeder;
        private readonly FeaturesDbSeeder featuresDbSeeder;

        public ApplicationDbSeeder(ApplicationDbContext context,  IdentityDbSeeder identityDbSeeder,FeaturesDbSeeder featuresDbSeeder)
        {
            _context = context;
            this.identityDbSeeder = identityDbSeeder;
            this.featuresDbSeeder = featuresDbSeeder;
        }

      

        public async Task SeedApplicationDatabaseAsync()
        {
            await CheckAndApplyPendingMigrationAsync();

            await identityDbSeeder.SeedIdentityDatabaseAsync();
            await featuresDbSeeder.SeedFeaturesDatabaseAsync();
        }

        private async Task CheckAndApplyPendingMigrationAsync()
        {
            if (_context.Database.IsRelational())
            {
                if ((await _context.Database.GetPendingMigrationsAsync()).Any())
                {
                    await _context.Database.MigrateAsync();
                }
            }
        }

    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\ServiceCollectionExtensions.cs' @'
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using UMS.Application.Dtos.Cache;
using UMS.Application.Dtos.Email;
using UMS.Application.Dtos.JWT;
using UMS.Application.Interfaces.Common;
using UMS.Infrastructure.Common;
using UMS.Infrastructure.Identity;
using UMS.Infrastructure.Identity.Configurations;
using UMS.Infrastructure.Persistence.DbInitializers;
using UMS.Infrastructure.Persistence.Interceptors;
using UMS.Infrastructure.Services;
using UMS.Infrastructure.Services.Common;

namespace UMS.Infrastructure
{
    /// <summary>
    /// Extension methods for setting up infrastructure-specific services in an <see cref="IServiceCollection"/>.
    /// </summary>
    public static class ServiceCollectionExtensions
    {
        /// <summary>
        /// Registers all infrastructure services including database, identity, and feature services.
        /// </summary>
        /// <param name="services">The service collection.</param>
        /// <param name="configuration">Application configuration.</param>
        /// <returns>The modified service collection.</returns>
        public static IServiceCollection AddInfrastructureServices(
            this IServiceCollection services,
            IConfiguration configuration,
            IHostEnvironment environment)
        {
            return services
                .AddDatabase(configuration, environment)
                .AddIdentityServices(configuration)
                .AddPermissions()
                .AddJwtAuthentication(configuration)
                .Configure<EmailConfiguration>(configuration.GetSection("EmailConfiguration"))
                .Configure<SeedUsersConfiguration>(configuration.GetSection("SeedUsers"))
                .Configure<CacheConfiguration>(configuration.GetSection("CacheConfiguration"))
                .Configure<JwtConfiguration>(configuration.GetSection("JwtConfiguration"))
                .AddDistributedMemoryCache()
                .AddScoped<ISessionWrapper, InMemorySessionWrapper>()
                .AddScoped<ICacheService, DistributedCacheService>()
                .AddScoped<ICurrentUserService, CurrentUserService>()
                .AddScoped<IEmailService, MailSenderService>()
                .AddScoped<IDateTimeService, DateTimeService>()
                .AddScoped<IFileStorageService, LocalFileStorageService>()
                .AddFeatures();
        }


        internal static IServiceCollection AddFeatures(this IServiceCollection services)
        {
            //services
            //    .AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>))
            //    .AddScoped<IUnitOfWork, UnitOfWork>();
            return services;
        }


        internal static IServiceCollection AddDatabase(
            this IServiceCollection services,
            IConfiguration config,
            IHostEnvironment environment)
        {
            var dbProvider = config.GetValue<string>("DbProvider", "SqlServer");
            var connectionStringName = environment.IsEnvironment("Testing")
                ? "TestConnection"
                : "DefaultConnection";
            var connectionString = config.GetConnectionString(connectionStringName)
                ?? config.GetConnectionString("DefaultConnection");

            services.AddDbContext<ApplicationDbContext>(options =>
            {
                if (dbProvider == "Sqlite")
                {
                    options.UseSqlite(connectionString);
                }
                else if (dbProvider == "InMemory")
                {
                    options.UseInMemoryDatabase("TestingDb");
                }
                else
                {
                    options.UseSqlServer(connectionString, builder =>
                    {
                        builder.MigrationsHistoryTable("Migrations", "EFCore");
                        builder.EnableRetryOnFailure(maxRetryCount: 3, maxRetryDelay: new TimeSpan(0, 0, 0, 100), errorNumbersToAdd: [1]);
                    });
                }

                options.AddInterceptors(new TrimStringInterceptor());
            });

            services.AddScoped<IApplicationDbContext, ApplicationDbContext>()
                    .AddTransient<ApplicationDbSeeder>()
                    .AddTransient<FeaturesDbSeeder>();

            return services;
        }

        public static async Task<IApplicationBuilder> UseInfrastructureAsync(this IApplicationBuilder app)
        {
            var configuration = app.ApplicationServices.GetRequiredService<IConfiguration>();
            var runApplicationSeeder = configuration.GetValue("RunApplicationSeeder", true);

            if (runApplicationSeeder)
            {
                using var scope = app.ApplicationServices.CreateScope();
                var seeder = scope.ServiceProvider.GetRequiredService<ApplicationDbSeeder>();
                await seeder.SeedApplicationDatabaseAsync();
            }

            return app
                .UseAuthentication()
                .UseCurrentUser()
                .UseAuthorization();
        }

    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Services\Common\CurrentUserService.cs' @'
using UMS.Application.Interfaces.Common;
using Microsoft.AspNetCore.Http;
using System.Security.Claims;

namespace UMS.Infrastructure.Services.Common;

public class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private ClaimsPrincipal? _explicitUser;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public ClaimsPrincipal? User => _explicitUser ?? _httpContextAccessor.HttpContext?.User;

    public string Name => User?.Identity?.Name ?? string.Empty;

    public int? GetUserId()
    {
        var id = User?.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.TryParse(id, out var userId) ? userId : null;
    }

    public string GetUserEmail() => User?.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

    public bool IsAuthenticated() => User?.Identity?.IsAuthenticated ?? false;

    public IList<string> GetRoles() => User?.FindAll(ClaimTypes.Role).Select(c => c.Value).ToList() ?? new List<string>();

    public IList<Claim> GetClaims() => User?.Claims.ToList() ?? new List<Claim>();

    public bool HasRole(string roleName) => User?.IsInRole(roleName) ?? false;

    public bool HasClaim(string claimType, string value) => User?.HasClaim(claimType, value) ?? false;

    public void SetCurrentUser(ClaimsPrincipal principal)
    {
        _explicitUser = principal;
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Services\Common\DateTimeService.cs' @'
using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Services.Common
{
    public class DateTimeService : IDateTimeService
    {
        public DateTime NowUtc => DateTime.UtcNow;
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Services\Common\DistributedCacheService.cs' @'
using UMS.Application.Dtos.Cache;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Options;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Services.Common
{
    public class DistributedCacheService : ICacheService
    {
        private readonly IDistributedCache _cache;
        private readonly JsonSerializerOptions _serializerOptions;
        private readonly CacheConfiguration _cacheConfig;

        public DistributedCacheService(
            IDistributedCache cache,
            IOptions<CacheConfiguration> cacheConfig)
        {
            _cache = cache;
            _cacheConfig = cacheConfig.Value;

            _serializerOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
                ReferenceHandler = ReferenceHandler.IgnoreCycles
            };
        }

        public bool TryGet<T>(string cacheKey, out T value)
        {
            var cachedData = _cache.Get(cacheKey);

            if (cachedData is null)
            {
                value = default!;
                return false;
            }

            value = JsonSerializer.Deserialize<T>(
                Encoding.UTF8.GetString(cachedData),
                _serializerOptions)!;

            return true;
        }

        public T Set<T>(string cacheKey, T value)
        {
            var serializedData = JsonSerializer.Serialize(value, _serializerOptions);
            var bytes = Encoding.UTF8.GetBytes(serializedData);

            var options = new DistributedCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromMinutes(
                    _cacheConfig.SlidingExpirationInMinutes)
            };

            _cache.Set(cacheKey, bytes, options);

            return value;
        }

        public void Remove(string cacheKey)
        {
            _cache.Remove(cacheKey);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Services\Common\InMemorySessionWrapper.cs' @'

using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Http;
using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Common
{
    public class InMemorySessionWrapper : ISessionWrapper
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly JsonSerializerOptions _jsonOptions;

        public InMemorySessionWrapper(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;

            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
            };
        }

        public T GetFromSession<T>(string key)
        {
            var value = _httpContextAccessor?.HttpContext?.Session?.GetString(key);

            if (string.IsNullOrWhiteSpace(value))
                return default!;

            return JsonSerializer.Deserialize<T>(value, _jsonOptions)!;
        }

        public void RemoveFromSession(string key)
        {
            _httpContextAccessor?.HttpContext?.Session?.Remove(key);
        }

        public void SetInSession<T>(string key, T value)
        {
            if (value is null)
                return;

            var json = JsonSerializer.Serialize(value, _jsonOptions);
            _httpContextAccessor?.HttpContext?.Session?.SetString(key, json);
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Services\Common\MailSenderService.cs' @'
using FluentEmail.Core;
using FluentEmail.Smtp;
using Microsoft.Extensions.Options;
using System.Net;
using System.Net.Mail;
using UMS.Application.Dtos.Common;
using UMS.Application.Dtos.Email;
using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Services.Common
{
    public class MailSenderService : IEmailService
    {
        private readonly EmailConfiguration _emailSettings;

        public MailSenderService(IOptions<EmailConfiguration> emailConfig)
        {
            _emailSettings = emailConfig.Value;
        }

        public async Task<string> SendAsync(SendEmailDto request, CancellationToken ct)
        {
            var attachmentStreams = new List<MemoryStream>();

            try
            {
                var smtpClient = new SmtpClient(_emailSettings.Host, _emailSettings.Port)
                {
                    Credentials = new NetworkCredential(_emailSettings.Email, _emailSettings.Password),
                    EnableSsl = _emailSettings.EnableSsl
                };
                Email.DefaultSender = new SmtpSender(smtpClient);

                var email = Email
                    .From(_emailSettings.Email, _emailSettings.DisplayName)
                    .Subject(request.Subject)
                    .Body(request.MessageBody, isHtml: true);

                if (request.ToEmails?.Any() == true)
                {
                    foreach (var to in request.ToEmails)
                    {
                        email.To(to);
                    }
                }
                else if (!string.IsNullOrEmpty(request.MailTo))
                {
                    email.To(request.MailTo);
                }

                if (request.EmailCC?.Any() == true)
                {
                    foreach (var cc in request.EmailCC)
                    {
                        email.CC(cc);
                    }
                }

                if (request.EmailBCC?.Any() == true)
                {
                    foreach (var bcc in request.EmailBCC)
                    {
                        email.BCC(bcc);
                    }
                }

                if (request.Attachments?.Any() == true)
                {
                    var attachmentList = new List<FluentEmail.Core.Models.Attachment>();

                    foreach (FileData file in request.Attachments)
                    {
                        if (file.Length <= 0)
                        {
                            continue;
                        }

                        var stream = new MemoryStream();
                        attachmentStreams.Add(stream);

                        if (file.Content.CanSeek)
                        {
                            file.Content.Position = 0;
                        }

                        await file.Content.CopyToAsync(stream, ct);
                        stream.Position = 0;

                        attachmentList.Add(new FluentEmail.Core.Models.Attachment
                        {
                            Data = stream,
                            Filename = file.FileName,
                            ContentType = file.ContentType
                        });
                    }

                    if (attachmentList.Any())
                    {
                        email.Attach(attachmentList);
                    }
                }

                var response = await email.SendAsync(ct);

                return response.Successful
                    ? string.Empty
                    : string.Join("; ", response.ErrorMessages);
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
            finally
            {
                foreach (var stream in attachmentStreams)
                {
                    await stream.DisposeAsync();
                }
            }
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\Services\LocalFileStorageService.cs' @'
using Microsoft.AspNetCore.Hosting;
using UMS.Application.Dtos.Common;
using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Services
{
    public class LocalFileStorageService : IFileStorageService
    {
        private readonly IWebHostEnvironment _webHostEnvironment;

        public LocalFileStorageService(IWebHostEnvironment webHostEnvironment)
        {
            _webHostEnvironment = webHostEnvironment;
        }

        public async Task<string> SaveFileAsync(FileData file, string folderName, CancellationToken ct)
        {
            if (file.Content.CanSeek)
            {
                file.Content.Position = 0;
            }

            if (string.IsNullOrEmpty(_webHostEnvironment.WebRootPath))
            {
                var path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", folderName);
                if (!Directory.Exists(path))
                {
                    Directory.CreateDirectory(path);
                }

                var name = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
                using (var stream = new FileStream(Path.Combine(path, name), FileMode.Create))
                {
                    await file.Content.CopyToAsync(stream, ct);
                }

                return name;
            }

            var uploadPath = Path.Combine(_webHostEnvironment.WebRootPath, folderName);

            if (!Directory.Exists(uploadPath))
            {
                Directory.CreateDirectory(uploadPath);
            }

            var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.Content.CopyToAsync(stream, ct);
            }

            return fileName;
        }

        public void DeleteFile(string fileName, string folderName)
        {
            var webRoot = _webHostEnvironment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var filePath = Path.Combine(webRoot, folderName, fileName);

            if (File.Exists(filePath))
            {
                File.Delete(filePath);
            }
        }
    }
}
'@
    Write-TemplateFile 'UMS.Infrastructure\UMS.Infrastructure.csproj' @'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

	<ItemGroup>
		<PackageReference Include="FluentEmail.Core" Version="3.0.2" />
		<PackageReference Include="FluentEmail.Smtp" Version="3.0.2" />
		<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="10.0.6" />
		<PackageReference Include="Microsoft.AspNetCore.Components.Authorization" Version="10.0.6" />
		<PackageReference Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore" Version="10.0.6" />
		<PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="10.0.6" />
		<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="10.0.6" />
		<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="10.0.6">
			<PrivateAssets>all</PrivateAssets>
			<IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
		</PackageReference>
		<PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="10.0.6" />
	</ItemGroup>
	
  <ItemGroup>
    <ProjectReference Include="..\UMS.Application\UMS.Application.csproj" />
    <ProjectReference Include="..\UMS.Domain\UMS.Domain.csproj" />
  </ItemGroup>

</Project>
'@

    Invoke-Step 'restore' @()
    Write-Host "Scaffold complete: $Root"
}
finally {
    Pop-Location
}
