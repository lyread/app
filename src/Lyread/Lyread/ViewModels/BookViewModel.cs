using Book.Item;

namespace Lyread.ViewModels
{
    public class BookViewModel : BaseViewModel
    {
        public IBookItem Book { get; set; }
    }
}
