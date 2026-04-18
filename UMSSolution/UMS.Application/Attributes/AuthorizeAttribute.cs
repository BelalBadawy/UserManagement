
namespace eShop.Application.Attributes
{

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true, Inherited = true)]
    public class AuthorizeAttribute : Attribute
    {
        public AuthorizeAttribute() { }

        public string Roles { get; set; }

        public string Policy { get; set; }

    }
}
