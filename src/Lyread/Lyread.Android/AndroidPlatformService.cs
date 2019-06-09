using Android.Content;
using Lyread.Android;
using System;
using System.IO;
using System.Net.Mime;
using System.Threading.Tasks;
using Xamarin.Essentials;
using Xamarin.Forms;

[assembly: Dependency(typeof(AndroidPlatformService))]
namespace Lyread.Android
{
    public class AndroidPlatformService : IPlatformService
    {
        public AndroidPlatformService()
        {
        }

        public Uri CacheUri => new Uri(FileSystem.CacheDirectory + "/");

        public string ExternalStorageDirectory => global::Android.OS.Environment.ExternalStorageDirectory.Path;

        public bool IsLocal(Uri uri)
        {
            return uri.IsFile;
        }

        public Task LaunchImage(FileInfo file)
        {
            return Launch(file, "image/*");
        }

        public Task LaunchPdf(FileInfo file)
        {
            return Launch(file, MediaTypeNames.Application.Pdf);
        }

        private Task Launch(FileInfo file, string type)
        {
            Intent intent = new Intent(Intent.ActionView);
            intent.AddFlags(ActivityFlags.NewTask);
            intent.AddFlags(ActivityFlags.GrantReadUriPermission);
            intent.AddFlags(ActivityFlags.ClearWhenTaskReset);
            intent.SetDataAndType(global::Android.Support.V4.Content.FileProvider.GetUriForFile(global::Android.App.Application.Context, "app.lyread.fileprovider", new Java.IO.File(file.FullName)), type);
            global::Android.App.Application.Context.StartActivity(intent);
            return Task.FromResult<object>(null);
        }

        /*public static Bitmap ToBitmapInverted(byte[] bytes)
        {
            BitmapFactory.Options options = new BitmapFactory.Options { InMutable = true };
            Bitmap bitmap = BitmapFactory.DecodeByteArray(bytes, 0, bytes.Length, options);
            int length = bitmap.Width * bitmap.Height;
            int[] pixels = new int[length];
            bitmap.GetPixels(pixels, 0, bitmap.Width, 0, 0, bitmap.Width, bitmap.Height);
            int[] pixelsInverted = Array.ConvertAll(pixels, color => color ^ 0xffffff);
            bitmap.SetPixels(pixelsInverted, 0, bitmap.Width, 0, 0, bitmap.Width, bitmap.Height);
            return bitmap;
        }*/
    }
}