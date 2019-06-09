using Book.Item;
using System.Windows.Input;
using Xamarin.Forms;
using Xamarin.Forms.Extended;
using static Book.Util.BookConstant;

namespace Lyread
{
    public class SearchViewModel : BookViewModel
    {
        public string Pattern { get; set; }

        public InfiniteScrollCollection<ISearchItem> SearchItems { get; set; }

        public ICommand SearchCommand => new Command(async () =>
        {
            if (!QueryBehavior.IsValid(Pattern))
            {
                return;
            }
            SearchItems.Clear();
            await SearchItems.LoadMoreAsync();
        });
        public ICommand OpenDocumentCommand => new Command<ISearchItem>(async item => await Application.Current.MainPage.Navigation.PushAsync(new DocumentPage(Book, item.Id, Pattern)));

        public SearchViewModel()
        {
            SearchItems = new InfiniteScrollCollection<ISearchItem>
            {
                OnLoadMore = async () =>
                {
                    int page = (SearchItems.Count + PageSize - 1) / PageSize;
                    return await Book.Search(Pattern, page);
                }
            };
        }
    }
}
