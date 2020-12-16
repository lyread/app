using Book.Item;

namespace Lyread.ViewModels
{
    public class BookViewModel : ListViewModel
    {
        public IBookItem Book { get; set; }

        public BookViewModel()
        {
            //Title = Book.Title;
        }
    }
}