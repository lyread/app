using Lyread.UWP;
using System;
using System.IO;
using System.Threading.Tasks;
using Windows.Storage;
using Windows.System;
using Xamarin.Forms;

[assembly: Dependency(typeof(UwpPlatformService))]
namespace Lyread.UWP
{
    public class UwpPlatformService : IPlatformService
    {
        public UwpPlatformService()
        {
        }

        public Uri CacheUri => new Uri("ms-appdata:///localcache/");

        public string ExternalStorageDirectory => ApplicationData.Current.LocalFolder.Path;

        public bool IsLocal(Uri uri)
        {
            return uri.Scheme == "ms-local-stream";
        }

        public async Task LaunchImage(FileInfo file)
        {
            StorageFile storageFile = await StorageFile.GetFileFromPathAsync(file.FullName);
            await Launcher.LaunchFileAsync(storageFile);
        }

        public async Task LaunchPdf(FileInfo file)
        {
            StorageFile storageFile = await StorageFile.GetFileFromPathAsync(file.FullName);
            await Launcher.LaunchFileAsync(storageFile);
        }
    }
}
