using Book.Item;
using Xamarin.Forms;

namespace Lyread.Views
{
    public partial class TocPage : ContentPage
    {
        public TocPage(IBookItem book)
        {
            InitializeComponent();
            TocViewModel.Book = book;
        }

        protected async override void OnAppearing()
        {
            await TocViewModel.Init();
        }

        protected override bool OnBackButtonPressed()
        {
            return TocViewModel.Back() || base.OnBackButtonPressed();
        }
    }
}
