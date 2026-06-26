using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using SampleApp.Application.Dtos.Cache;
using SampleApp.Application.Dtos.Email;
using SampleApp.Application.Dtos.JWT;
using SampleApp.Application.Interfaces.Common;
using SampleApp.Infrastructure.Common;
using SampleApp.Infrastructure.Identity;
using SampleApp.Infrastructure.Identity.Configurations;
using SampleApp.Infrastructure.Persistence.DbInitializers;
using SampleApp.Infrastructure.Persistence.Interceptors;
using SampleApp.Infrastructure.Services;
using SampleApp.Infrastructure.Services.Common;
using QuestPDF.Infrastructure;

namespace SampleApp.Infrastructure
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
            // Register QuestPDF Community License
            QuestPDF.Settings.License = LicenseType.Community;

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
                .AddScoped<IAuditTrailExportService, AuditTrailExportService>()
                .AddScoped<ICategoryExportService, CategoryExportService>()
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