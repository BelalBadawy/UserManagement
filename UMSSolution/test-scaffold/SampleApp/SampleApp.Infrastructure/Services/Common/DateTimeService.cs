using SampleApp.Application.Interfaces.Common;

namespace SampleApp.Infrastructure.Services.Common
{
    public class DateTimeService : IDateTimeService
    {
        public DateTime NowUtc => DateTime.UtcNow;
    }
}