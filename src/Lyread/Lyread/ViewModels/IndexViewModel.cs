using Book.Item;
using Lyread.Behaviors;
using Lyread.Models;
using Lyread.Views;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
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
                CategoryItemsChanged();
            }
            if (!QueryUtil.IsValidRegex(Pattern))
            {
                return;
            }
            IndexItems.Clear();
            LoadItemsCommand.Execute(null);
        });
        public ICommand OpenDocumentCommand => new Command<IIndexItem>(async item => await Application.Current.MainPage.Navigation.PushModalAsync(new NavigationPage(new DocumentPage(Book, item.Id))));

        public Command LoadItemsCommand { get; set; }

        public ICommand ItemTresholdReachedCommand => new Command(async () =>
        {
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

        public void CategoryItemsChanged()
        {
            OnPropertyChanged(nameof(CategoryItems));
        }
    }

    class CategoryItemsToImageConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is ObservableCollection<ICategoryItem> items)
            {
                if (items.All(item => !item.Selected) || items.All(item => item.Selected))
                {
                    return ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? "@drawable/ic_filter_none_white_24dp" : "Icons/filter.png");
                }
                else if (items.Count(item => item.Selected) > 9)
                {
                    return ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? "@drawable/ic_filter_9_plus_white_24dp.png" : "Icons/filter.png");
                }
                else
                {
                    return ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? string.Format("@drawable/ic_filter_{0}_white_24dp.png", items.Count(item => item.Selected)) : "Icons/filter.png");
                }
            }
            return null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
