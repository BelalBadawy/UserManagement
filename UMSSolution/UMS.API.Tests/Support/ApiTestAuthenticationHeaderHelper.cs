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

    private static void Clear(HttpClient client)
    {
        client.DefaultRequestHeaders.Authorization = null;
        client.DefaultRequestHeaders.Remove(ApiTestAuthenticationHandler.AuthModeHeaderName);
        client.DefaultRequestHeaders.Remove(ApiTestAuthenticationHandler.RequiredPermissionHeaderName);
    }
}
