namespace UMS.Infrastructure.Identity.Attributes
{
    public class MustHavePermissionAttribute : AuthorizeAttribute
    {
        public MustHavePermissionAttribute(string service, string feature, string action)
        {
            Policy = AppPermission.NameFor(service, feature, action);
        }
    }
}
