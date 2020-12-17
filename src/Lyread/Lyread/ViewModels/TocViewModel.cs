using System;
using Book.Item;
using Lyread.Views;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.CommunityToolkit.ObjectModel;
using Xamarin.Forms;

namespace Lyread.ViewModels
{
    public class TocViewModel : BookViewModel
    {
        public ObservableRangeCollection<ITocItem> TocItems { get; } = new ObservableRangeCollection<ITocItem>();

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
            OnPropertyChanged(nameof(TocItems));
        }
    }

    class TocItemsToImageConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is ObservableCollection<ITocItem> items && items.Any())
            {
                ITocItem item = items.First();
                if (item.Level == 0)
                {
                    return ImageSource.FromFile(Device.RuntimePlatform == Device.Android
                        ? "@drawable/ic_filter_none_white_24dp"
                        : null);
                }

                if (item.Level > 9)
                {
                    return ImageSource.FromFile(Device.RuntimePlatform == Device.Android
                        ? "@drawable/ic_filter_9_plus_white_24dp.png"
                        : null);
                }

                return ImageSource.FromFile(Device.RuntimePlatform == Device.Android
                    ? $"@drawable/ic_filter_{item.Level}_white_24dp.png"
                    : null);
            }

            return null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}