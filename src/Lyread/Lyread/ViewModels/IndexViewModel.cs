using Book.Item;
using Lyread.Views;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.CommunityToolkit.ObjectModel;
using Xamarin.Forms;
using static Book.Util.BookConstant;

namespace Lyread.ViewModels
{
    public class IndexViewModel : BookViewModel
    {
        public ObservableRangeCollection<ICategoryItem> CategoryItems { get; } = new ObservableRangeCollection<ICategoryItem>();
        public ObservableRangeCollection<IIndexItem> IndexItems { get; } = new ObservableRangeCollection<IIndexItem>();

        public ICommand LoadIndexItemsCommand => new Command(async () =>
        {
            IsBusy = true;

            try
            {
                if (!CategoryItems.Any())
                {
                    CategoryItems.AddRange(await Book.QueryCategories());
                    CategoryItemsChanged();
                }

                IndexItems.Clear();
                IEnumerable<IIndexItem> items = await GetIndexItemsAsync();
                IndexItems.AddRange(items);
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

        public ICommand LoadMoreIndexItemsCommand => new Command(async () =>
        {
            IsBusy = true;

            try
            {
                IEnumerable<IIndexItem> items = await GetIndexItemsAsync();
                IndexItems.AddRange(items);
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

        public ICommand QueryIndexItemsCommand => new Command<string>(pattern =>
        {
            Pattern = pattern;
            if (QueryUtil.IsValidRegex(Pattern))
            {
                LoadIndexItemsCommand.Execute(null);
            }
        });

        public ICommand OpenDocumentCommand => new Command<IIndexItem>(async item => await Application.Current.MainPage.Navigation.PushModalAsync(new NavigationPage(new DocumentPage(Book, item.Id))));

        public string Pattern { get; set; }

        private async Task<IEnumerable<IIndexItem>> GetIndexItemsAsync()
        {
            int page = (IndexItems.Count + PageSize - 1) / PageSize;
            return await Book.QueryIndex(Pattern, CategoryItems.Where(item => item.Selected), page);
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
                    return ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? "@drawable/ic_filter_none_white_24dp" : null);
                }
                else if (items.Count(item => item.Selected) > 9)
                {
                    return ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? "@drawable/ic_filter_9_plus_white_24dp.png" : null);
                }
                else
                {
                    return ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? $"@drawable/ic_filter_{items.Count(item => item.Selected)}_white_24dp.png" : null);
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
