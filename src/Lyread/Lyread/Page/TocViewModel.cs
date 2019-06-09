using Book.Item;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
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
            ITocItem lastItem = TocItems.Last();
            if (TocItems.Any() && lastItem.Level > 1)
            {
                ListChildren(lastItem.Parent.Parent);
                return true;
            }
            return false;
        }

        private void ListChildren(ITocItem item)
        {
            foreach (ITocItem oldItem in TocItems)
            {
                oldItem.Expanded = false;
            }
            List<ITocItem> newItems = new List<ITocItem>();
            for (ITocItem i = item; i != null; i = i.Parent)
            {
                i.Expanded = true;
                newItems.Add(i);
            }
            newItems.Reverse();
            newItems.AddRange(item.Children);
            TocItems.ReplaceRange(newItems);
        }
    }

    class TextConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is ITocItem item)
            {
                return item.HasChildren ? item.Expanded ? "▽" : "▷" : string.Empty;
            }
            return string.Empty;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class WidthConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is byte level)
            {
                return level * 20;
            }
            return 0;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
