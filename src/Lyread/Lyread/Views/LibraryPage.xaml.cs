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
            LibraryViewModel.Init();
        }

        protected override void OnDisappearing()
        {
            LibraryViewModel.Clear();
        }
    }
}