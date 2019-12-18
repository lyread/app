using System;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using Lyread.Services;
using Lyread.Views;
using System.IO;
using NLog;
using NLog.Targets;
using Xamarin.Essentials;
using NLog.Config;
using Book;

namespace Lyread
{
    public partial class App : Application
    {

        public App()
        {
            InitializeComponent();

            DependencyService.Register<MockDataStore>();
            MainPage = new AppShell();
        }

        protected override void OnStart()
        {
            Directory.CreateDirectory(Path.Combine(FileSystem.CacheDirectory, LinkType.html.ToString()));
            LogManager.Configuration = new LoggingConfiguration();
            LogManager.Configuration.AddRuleForAllLevels(new OutputDebugStringTarget());
        }

        protected override void OnSleep()
        {
        }

        protected override void OnResume()
        {
        }
    }
}
