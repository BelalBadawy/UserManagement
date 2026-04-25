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
