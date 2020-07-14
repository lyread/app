using System.Linq;
using Xamarin.Forms;

namespace Lyread.Views
{
    public partial class LibraryPage : ContentPage
    {
        public LibraryPage()
        {
            InitializeComponent();
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            LibraryViewModel.IsBusy |= LibraryViewModel.Books.Count == 0;
        }
    }
}