using Xamarin.Forms;

namespace Lyread.Views
{
    public partial class SettingsPage : ContentPage
    {
        public SettingsPage()
        {
            InitializeComponent();
        }

        protected override void OnAppearing()
        {
            SettingsViewModel.Refresh();
        }
    }
}