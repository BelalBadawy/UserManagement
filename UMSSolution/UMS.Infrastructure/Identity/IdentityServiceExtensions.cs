using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Newtonsoft.Json;
using System.Net;
using System.Text;
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
                .AddTransient<IUserService, UserService>()
                .AddTransient<IRoleService, RoleService>()
                .AddTransient<ITokenService, TokenService>()
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
                  bearer.RequireHttpsMetadata = false;
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
                          if (context.Exception is SecurityTokenExpiredException)
                          {
                              context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                              context.Response.ContentType = "application/json";
                              var result = JsonConvert.SerializeObject(
                                  ResponseWrapper.Fail("The token has expired. Please log in again.")
                              );
                              return context.Response.WriteAsync(result);
                          }
                          else if (context.Exception is ArgumentException && context.Exception.Message.Contains("IDX14100"))
                          {
                              context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                              context.Response.ContentType = "application/json";
                              var result = JsonConvert.SerializeObject(
                                  ResponseWrapper.Fail("The provided token format is invalid.")
                              );
                              return context.Response.WriteAsync(result);
                          }
                          else if (context.Exception is SecurityTokenInvalidSignatureException)
                          {
                              context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                              context.Response.ContentType = "application/json";
                              var result = JsonConvert.SerializeObject(
                                  ResponseWrapper.Fail("The token signature is invalid.")
                              );
                              return context.Response.WriteAsync(result);
                          }
                          else
                          {
                              context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                              context.Response.ContentType = "application/json";
                              var result = JsonConvert.SerializeObject(
                                  ResponseWrapper.Fail("You are not authorized to access this resource.")
                              );
                              return context.Response.WriteAsync(result);
                          }
                      },
                      OnChallenge = context =>
                      {
                          context.HandleResponse();
                          if (!context.Response.HasStarted)
                          {
                              context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                              context.Response.ContentType = "application/json";
                              var result = JsonConvert.SerializeObject(ResponseWrapper.Fail("You are not Authorized."));
                              return context.Response.WriteAsync(result);
                          }

                          return Task.CompletedTask;
                      },
                      OnForbidden = context =>
                      {
                          context.Response.StatusCode = (int)HttpStatusCode.Forbidden;
                          context.Response.ContentType = "application/json";
                          var result = JsonConvert.SerializeObject(
                              ResponseWrapper.Fail("You are not authorized to access this resource."));
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
