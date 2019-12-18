using Book.Item;
using Xamarin.Forms;

namespace Lyread
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
