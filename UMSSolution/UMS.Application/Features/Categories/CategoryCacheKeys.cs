
namespace UMS.Application.Features.Categories
{
    public static class CategoryCacheKeys
    {
        public static string GetAll => "categories:all";
        public static string GetAllAdmin => "categories:allAdmin";
        public static string GetAllForList => "categories:allForList";

        public static IEnumerable<string> All =>
            new[]
            {
                GetAll,
                GetAllAdmin,
                GetAllForList,
            };
    }
}
