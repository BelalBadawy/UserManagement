
using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Identity.Services
{
    public class CurrentUserService : ICurrentUserService
    {
        private ClaimsPrincipal _principal;

        public string Name => _principal.Identity.Name;

        public ClaimsPrincipal? User => _principal;

        public int? UserId => int.TryParse(_principal?.FindFirstValue(ClaimTypes.NameIdentifier), out int userId) ? userId : null;


        public IEnumerable<Claim> GetUserClaims()
        {
            return _principal.Claims;
        }

        public string GetUserEmail()
        {
            if (IsAuthenticated())
            {
                return _principal.FindFirstValue(ClaimTypes.Email);
            }
            return string.Empty;
        }

        public int? GetUserId()
        {
            if (IsAuthenticated())
            {
                return int.TryParse(_principal?.FindFirstValue(ClaimTypes.NameIdentifier), out int userId) ? userId : null;
            }
            return null;
        }

        public bool IsAuthenticated()
            => _principal.Identity.IsAuthenticated;

        public bool IsInRole(string roleName)
        {
            return _principal.IsInRole(roleName);
        }

        public void SetCurrentUser(ClaimsPrincipal principal)
        {
            //if (_principal is null)
            //{
            //    // throw new ConflictException("Invalid operation on claim.");
            //}

            if (_principal != null)
            {
                _principal = principal;
            }
        }

        public IList<Claim> GetClaims()
        {
            return User?.Claims.ToList();
        }

        public IList<string> GetRoles()
        {
            // 1. Ensure the principal is available and the user is authenticated.
            if (_principal?.Identity?.IsAuthenticated != true)
            {
                return new List<string>();
            }

            // 2. Extract all role claims from the principal and return their values.
            return _principal.Claims
                .Where(c => c.Type == ClaimTypes.Role || c.Type == "role") // Be flexible with claim type
                .Select(c => c.Value)
                .ToList();
        }

        public bool HasClaim(string claimType, string value)
        {
            return User?.HasClaim(claimType, value) ?? false;
        }

        public bool HasRole(string roleName)
        {
            return User?.IsInRole(roleName) ?? false;
        }
    }
}
