using Book.Item;
using Lyread.Behaviors;
using Lyread.Views;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Forms;
using static Book.Util.BookConstant;

namespace Lyread.ViewModels
{
    public class IndexViewModel : BookViewModel
    {
        public RangedObservableCollection<ICategoryItem> CategoryItems { get; set; } = new RangedObservableCollection<ICategoryItem>();
        public ObservableCollection<IIndexItem> IndexItems { get; }

        public ICommand QueryIndexCommand => new Command<string>(async pattern =>
        {
            Pattern = pattern;
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
            LoadItemsCommand.Execute(null);
        });
        public ICommand OpenDocumentCommand => new Command<IIndexItem>(async item => await Application.Current.MainPage.Navigation.PushAsync(new DocumentPage(Book, item.Id)));

        public Command LoadItemsCommand { get; set; }

        public ICommand ItemTresholdReachedCommand => new Command(async () => {
            Debug.WriteLine("ItemTresholdReachedCommand");
            try
            {
                var items = await LoadIIndexItems();
                foreach (var item in items)
                {
                    IndexItems.Add(item);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex);
            }
        });

        public string Pattern { get; set; }

        public IndexViewModel()
        {
            Title = "Index";
            IndexItems = new ObservableCollection<IIndexItem>();
            LoadItemsCommand = new Command(async () => await ExecuteLoadItemsCommand());
        }

        private async Task<IEnumerable<IIndexItem>> LoadIIndexItems()
        {
            int page = (IndexItems.Count + PageSize - 1) / PageSize;
            return await Book.QueryIndex(Pattern, CategoryItems.Where(item => item.Selected), page);
        }

        async Task ExecuteLoadItemsCommand()
        {
            try
            {
                IndexItems.Clear();
                var items = await LoadIIndexItems();
                foreach (var item in items)
                {
                    IndexItems.Add(item);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex);
            }
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
                return items.Any();
            }
            return false;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
