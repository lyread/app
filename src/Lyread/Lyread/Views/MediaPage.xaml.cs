using Book.Item;
using Lyread.ViewModels;
using Xamarin.Forms;

namespace Lyread.Views
{
    public partial class MediaPage : ContentPage
    {
        public MediaPage(IBookItem book)
        {
            InitializeComponent();
            MediaViewModel.Book = book;
        }

        protected async override void OnAppearing()
        {
            await MediaViewModel.Init();
        }
    }
}
