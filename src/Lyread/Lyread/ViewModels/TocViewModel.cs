using Book.Item;
using Lyread.Views;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.CommunityToolkit.ObjectModel;
using Xamarin.Forms;

namespace Lyread.ViewModels
{
    public class TocViewModel : BookViewModel
    {
        public ObservableRangeCollection<ITocItem> TocItems { get; set; } = new ObservableRangeCollection<ITocItem>();

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

        public ICommand OpenDocumentCommand => new Command<ITocItem>(async item =>
        {
            if (Book == null || item == null)
            {
                return;
            }

            await Application.Current.MainPage.Navigation.PushModalAsync(
                new NavigationPage(new DocumentPage(Book, item.Id)));
        });

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
            TocItems.ReplaceRange(item.HasChildren ? item.Children : new ITocItem[] {item});
        }
    }
}