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

[assembly: XamlCompilation(XamlCompilationOptions.Compile)]

namespace Lyread
{
    public partial class App : Application
    {
        public App()
        {
            InitializeComponent();

            DependencyService.Register<PublisherDataStore>();
            MainPage = new AppShell();
        }

        protected override void OnStart()
        {
            // Handle when your app starts
            Directory.CreateDirectory(Path.Combine(FileSystem.CacheDirectory, LinkType.html.ToString()));
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