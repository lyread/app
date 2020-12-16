using Book.Item;
using Xamarin.Forms;

namespace Lyread.Views
{
    public partial class SearchPage : ContentPage
    {
        public SearchPage(IBookItem book)
        {
            InitializeComponent();
            SearchViewModel.Book = book;
        }
    }
}