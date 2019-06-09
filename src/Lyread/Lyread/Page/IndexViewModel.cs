using Book.Item;
using System;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Windows.Input;
using Xamarin.Forms;
using Xamarin.Forms.Extended;
using static Book.Util.BookConstant;

namespace Lyread
{
    public class IndexViewModel : BookViewModel
    {
        public RangedObservableCollection<ICategoryItem> CategoryItems { get; set; } = new RangedObservableCollection<ICategoryItem>();
        public InfiniteScrollCollection<IIndexItem> IndexItems { get; }

        public ICommand QueryIndexCommand => new Command(async () =>
        {
            if (!CategoryItems.Any())
            {
                CategoryItems.AddRange(await Book.QueryCategories());
                OnPropertyChanged(nameof(CategoryItems));
            }
            if (!RegexBehavior.IsValid(Pattern))
            {
                return;
            }
            IndexItems.Clear();
            await IndexItems.LoadMoreAsync();
        });
        public ICommand OpenDocumentCommand => new Command<IIndexItem>(async item => await Application.Current.MainPage.Navigation.PushAsync(new DocumentPage(Book, item.Id)));

        public string Pattern { get; set; }

        public IndexViewModel()
        {
            IndexItems = new InfiniteScrollCollection<IIndexItem>
            {
                OnLoadMore = async () =>
                {
                    int page = (IndexItems.Count + PageSize - 1) / PageSize;
                    return await Book.QueryIndex(Pattern, CategoryItems.Where(item => item.Selected), page);
                }
            };
        }
    }

    class CategoryItemsToStringConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is ObservableCollection<ICategoryItem> items)
            {
                if (!items.Any(item => item.Selected))
                {
                    return "None";
                }
                else if (items.All(item => item.Selected))
                {
                    return "All";
                }
                return string.Join(", ", items.Where(item => item.Selected).Select(item => item.Title));
            }
            return string.Empty;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class CategoryItemsToBooleanConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is ObservableCollection<ICategoryItem> items)
            {
                return items.Count > 1;
            }
            return false;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
