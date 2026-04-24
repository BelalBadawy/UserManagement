using UMS.Application.Dtos.Common;

namespace UMS.Application.Interfaces.Common
{
    public interface IFileStorageService
    {
        Task<string> SaveFileAsync(FileData file, string folderName, CancellationToken ct = default);

        void DeleteFile(string fileName, string folderName);
    }
}
