using Lyread.Page;
using NLog;
using NLog.Config;
using NLog.Targets;
using System.IO;
using Xamarin.Essentials;
using Xamarin.Forms;
using static Book.LinkType;

namespace Lyread
{
    public partial class App : Application
    {
        public App()
        {
            InitializeComponent();

            MainPage = new NavigationPage(new MainPage());
        }

        protected override void OnStart()
        {
            // Handle when your app starts
            Directory.CreateDirectory(Path.Combine(FileSystem.CacheDirectory, html.ToString()));

            LogManager.Configuration = new LoggingConfiguration();
            LogManager.Configuration.AddRuleForAllLevels(new OutputDebugStringTarget());
        }

        protected override void OnSleep()
        {
            // Handle when your app sleeps
        }

        protected override void OnResume()
        {
            // Handle when your app resumes
        }
    }
}
