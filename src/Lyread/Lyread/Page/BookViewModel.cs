using Book.Item;

namespace Lyread
{
    public class BookViewModel : BaseViewModel
    {
        public IBookItem Book { get; set; }
    }
}
