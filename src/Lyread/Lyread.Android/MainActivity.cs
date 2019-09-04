using Android;
using Android.App;
using Android.Content.PM;
using Android.OS;
using Android.Runtime;
using LabelHtml.Forms.Plugin.Droid;
using System.Linq;

namespace Lyread.Droid
{
    [Activity(Theme = "@style/SplashTheme", MainLauncher = true, ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation)]
    public class MainActivity : global::Xamarin.Forms.Platform.Android.FormsAppCompatActivity
    {
        protected override void OnCreate(Bundle savedInstanceState)
        {
            SetTheme(Resource.Style.MainTheme);
            TabLayoutResource = Resource.Layout.Tabbar;
            ToolbarResource = Resource.Layout.Toolbar;

            base.OnCreate(savedInstanceState);

            HtmlLabelRenderer.Initialize();
            Xamarin.Essentials.Platform.Init(this, savedInstanceState);
            global::Xamarin.Forms.Forms.Init(this, savedInstanceState);

            if ((int)Build.VERSION.SdkInt >= 23 && CheckSelfPermission(Manifest.Permission.WriteExternalStorage) != Permission.Granted)
            {
                RequestPermissions(new[] { Manifest.Permission.WriteExternalStorage }, 0);
                return;
            }
            LoadApplication(new App());
        }
        public override void OnRequestPermissionsResult(int requestCode, string[] permissions, [GeneratedEnum] Android.Content.PM.Permission[] grantResults)
        {
            Xamarin.Essentials.Platform.OnRequestPermissionsResult(requestCode, permissions, grantResults);

            base.OnRequestPermissionsResult(requestCode, permissions, grantResults);

            if (grantResults.First() != Permission.Granted)
            {
                Finish();
            }
            LoadApplication(new App());
        }
    }
}