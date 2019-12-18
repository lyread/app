using Book.Item;
using Xamarin.Forms;
using static Book.ViewType;

namespace Lyread
{
    public partial class BookPage : TabbedPage
    {
        public BookPage(IBookItem book)
        {
            InitializeComponent();
            BookViewModel.Book = book;

            if (book.Has(Toc))
            {
                Children.Add(new TocPage(book));
            }
            if (book.Has(Index))
            {
                Children.Add(new IndexPage(book));
            }
            if (book.Has(Search))
            {
                Children.Add(new SearchPage(book));
            }
            if (book.Has(Images))
            {
                Children.Add(new MediaPage(book));
            }
        }
    }
}
