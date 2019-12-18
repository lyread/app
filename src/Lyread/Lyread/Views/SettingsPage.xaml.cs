using Xamarin.Forms;

namespace Lyread
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
