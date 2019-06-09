using Android;
using Android.App;
using Android.Content.PM;
using Android.OS;
using Android.Runtime;
using System.Linq;
using Xamarin.Forms.Platform.Android;

namespace Lyread.Droid
{
    [Activity(Theme = "@style/SplashTheme", MainLauncher = true, ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation)]
    public class MainActivity : FormsAppCompatActivity
    {
        protected override void OnCreate(Bundle bundle)
        {
            SetTheme(Resource.Style.MainTheme);
            base.OnCreate(bundle);
            Xamarin.Forms.Forms.Init(this, bundle);
            Xamarin.Essentials.Platform.Init(this, bundle);

            string permission = Manifest.Permission.WriteExternalStorage;
            if ((int)Build.VERSION.SdkInt < 23 || CheckSelfPermission(permission) == Permission.Granted)
            {
                LoadApplication();
            }
            else
            {
                RequestPermissions(new string[] { permission }, 0);
            }
        }

        public override void OnRequestPermissionsResult(int requestCode, string[] permissions, [GeneratedEnum] Permission[] grantResults)
        {
            Xamarin.Essentials.Platform.OnRequestPermissionsResult(requestCode, permissions, grantResults);
            if (grantResults.First() == Permission.Granted)
            {
                LoadApplication();
            }
            else
            {
                Finish();
            }
        }

        private void LoadApplication()
        {
            TabLayoutResource = Resource.Layout.Tabbar;
            ToolbarResource = Resource.Layout.Toolbar;
            LoadApplication(new App());
        }
    }
}

