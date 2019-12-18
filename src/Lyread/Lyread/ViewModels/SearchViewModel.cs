using Book.Item;
using System.Collections.ObjectModel;
using System.Windows.Input;
using Xamarin.Forms;
using static Book.Util.BookConstant;

namespace Lyread.ViewModels
{
    public class SearchViewModel : BookViewModel
    {
        public string Pattern { get; set; }

        public ObservableCollection<ISearchItem> SearchItems { get; set; }

        public ICommand SearchCommand => new Command(async () =>
        {
            if (!QueryBehavior.IsValid(Pattern))
            {
                return;
            }
            SearchItems.Clear();
            //await SearchItems.LoadMoreAsync();
        });
        public ICommand OpenDocumentCommand => new Command<ISearchItem>(async item => await Application.Current.MainPage.Navigation.PushAsync(new DocumentPage(Book, item.Id, Pattern)));

        public SearchViewModel()
        {
            SearchItems = new ObservableCollection<ISearchItem>();
            //{
            //    OnLoadMore = async () =>
            //    {
            //        int page = (SearchItems.Count + PageSize - 1) / PageSize;
            //        return await Book.Search(Pattern, page);
            //    }
            //};
        }
    }
}
