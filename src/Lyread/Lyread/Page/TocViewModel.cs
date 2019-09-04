using Book.Item;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Forms;

namespace Lyread
{
    public class TocViewModel : BookViewModel
    {
        public RangedObservableCollection<ITocItem> TocItems { get; set; } = new RangedObservableCollection<ITocItem>();

        public ICommand OpenTocItemCommand => new Command<ITocItem>(item =>
        {
            if (item.HasChildren)
            {
                ListChildren(item);
            }
            else
            {
                OpenDocumentCommand.Execute(item);
            }
        });
        public ICommand OpenDocumentCommand => new Command<ITocItem>(async item => await Application.Current.MainPage.Navigation.PushAsync(new DocumentPage(Book, item.Id)));

        public async Task Init()
        {
            if (!TocItems.Any())
            {
                ITocItem root = await Book.QueryToc(null, null);
                ListChildren(root);
            }
        }

        public bool Back()
        {
            if (TocItems.Any() && TocItems.First().Level > 1)
            {
                ListChildren(TocItems.First().Parent.Parent);
                return true;
            }
            return false;
        }

        private void ListChildren(ITocItem item)
        {
            TocItems.ReplaceRange(item.HasChildren ? item.Children : new ITocItem[] { item });
        }
    }
}
