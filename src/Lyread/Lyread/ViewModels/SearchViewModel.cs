using Book.Item;
using Lyread.Views;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Forms;
using static Book.Util.BookConstant;

namespace Lyread.ViewModels
{
    public class SearchViewModel : BookViewModel
    {
        public RangedObservableCollection<ISearchItem> SearchItems { get; } = new RangedObservableCollection<ISearchItem>();

        public string Pattern { get; set; }

        public ICommand SearchCommand => new Command<string>(async pattern =>
        {
            Pattern = pattern;
            if (!QueryUtil.IsValidLucene(Pattern))
            {
                return;
            }
            SearchItems.Clear();
            IEnumerable<ISearchItem> items = await GetSearchItemsAsync();
            SearchItems.AddRange(items);
        });

        public ICommand LoadMoreItemsCommand => new Command(async () =>
        {
            IsBusy = true;

            try
            {
                IEnumerable<ISearchItem> items = await GetSearchItemsAsync();
                SearchItems.AddRange(items);
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex);
            }
            finally
            {
                IsBusy = false;
            }
        });

        public ICommand OpenDocumentCommand => new Command<ISearchItem>(async item => await Application.Current.MainPage.Navigation.PushModalAsync(new NavigationPage(new DocumentPage(Book, item.Id, Pattern))));

        private async Task<IEnumerable<ISearchItem>> GetSearchItemsAsync()
        {
            int page = (SearchItems.Count + PageSize - 1) / PageSize;
            return await Book.Search(Pattern, page);
        }
    }
}
