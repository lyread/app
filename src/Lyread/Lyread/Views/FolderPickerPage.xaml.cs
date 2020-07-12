using Book;
using System;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace Lyread.Views
{
    public partial class FolderPickerPage : ContentPage
    {
        public FolderPickerPage(IPublisher publisher)
        {
            InitializeComponent();
            FolderPickerViewModel.Publisher = publisher;
        }

        private async void Save_Clicked(object sender, EventArgs e)
        {
            Preferences.Set(FolderPickerViewModel.Publisher.GetType().Name, FolderPickerViewModel.Parent.FullName);
            await Navigation.PopModalAsync();
        }

        private async void Cancel_Clicked(object sender, EventArgs e)
        {
            await Navigation.PopModalAsync();
        }
    }
}