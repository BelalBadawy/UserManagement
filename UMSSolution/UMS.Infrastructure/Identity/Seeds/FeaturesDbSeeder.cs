
namespace UMS.Infrastructure.Persistence.DbInitializers
{
    public class FeaturesDbSeeder
    {
        private readonly ApplicationDbContext _dbContext;

        public FeaturesDbSeeder(ApplicationDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task SeedFeaturesDatabaseAsync()
        {
         //   await SeedMenusAsync();
        }

        //private async Task SeedMenusAsync()
        //{

        //    if (!_dbContext.Menus.Any())
        //    {
        //        var menus = new List<Menu>
        //    {
        //        new Menu { Title = "HOME", Link = "/index", Type = "top", Order = 1 },
        //        new Menu { Title = "SHOP", Link = "/shop", Type = "top", Order = 2 },
        //        new Menu { Title = "PRODUCT", Link = "/product", Type = "top", Order = 3 },
        //        new Menu { Title = "SALE", Link = "/sale", Type = "top", Order = 4 },
        //        new Menu { Title = "PAGES", Link = "/pages", Type = "top", Order = 5 },
        //        new Menu { Title = "BLOG", Link = "/blog", Type = "top", Order = 6 },
        //        new Menu { Title = "BUY", Link = "/buy", Type = "top", Order = 7 }
        //    };

        //        _dbContext.Menus.AddRange(menus);
        //        await _dbContext.SaveChangesAsync();
        //    }
        //}

    }
}
