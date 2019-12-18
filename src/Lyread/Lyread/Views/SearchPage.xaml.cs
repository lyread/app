using Book.Item;
using Xamarin.Forms;

namespace Lyread
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
