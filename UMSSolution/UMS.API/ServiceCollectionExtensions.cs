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

        public static IServiceCollection AddCorsAllowAll(this IServiceCollection services)
        {
            // Add CORS policy
            return services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy
                        .AllowAnyOrigin()
                        .AllowAnyMethod()
                        .AllowAnyHeader();
                });
            });
        }

        public static IApplicationBuilder UseCorsAllowAll(this IApplicationBuilder app)
        {
            return app.UseCors("AllowAll");
        }


    }
}
