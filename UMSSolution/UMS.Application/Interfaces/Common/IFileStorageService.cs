using Microsoft.AspNetCore.Http;

namespace UMS.Application.Interfaces.Common
{
    public interface IFileStorageService
    {
        /// <summary>
        /// Saves a file to the specified folder within the web root.
        /// </summary>
        /// <param name="file">The file to save.</param>
        /// <param name="folderName">The target folder name (e.g., "images/banners").</param>
        /// <param name="ct">Cancellation token.</param>
        /// <returns>The generated filename.</returns>
        Task<string> SaveFileAsync(IFormFile file, string folderName, CancellationToken ct = default);

        /// <summary>
        /// Deletes a file from the specified folder within the web root.
        /// </summary>
        /// <param name="fileName">The filename to delete.</param>
        /// <param name="folderName">The folder name where the file is located.</param>
        void DeleteFile(string fileName, string folderName);
    }
}
