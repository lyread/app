using System;
using System.IO;
using System.Threading.Tasks;

namespace Lyread
{
    public interface IPlatformService
    {
        Uri CacheUri { get; }

        string ExternalStorageDirectory { get; }

        bool IsLocal(Uri uri);

        Task LaunchImage(FileInfo file);

        Task LaunchPdf(FileInfo file);
    }
}
