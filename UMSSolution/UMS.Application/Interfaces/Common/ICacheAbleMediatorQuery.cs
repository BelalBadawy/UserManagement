
namespace UMS.Application.Interfaces.Common
{
    public interface ICacheAbleMediatorQuery
    {
        bool BypassCache { get; }
        string CacheKey { get; }
        TimeSpan? SlidingExpiration { get; }
    }
}
