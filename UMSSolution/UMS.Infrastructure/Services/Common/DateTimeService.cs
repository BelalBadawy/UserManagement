using UMS.Application.Interfaces.Common;

namespace UMS.Infrastructure.Services.Common
{
    public class DateTimeService : IDateTimeService
    {
        public DateTime NowUtc => DateTime.UtcNow;
    }
}
