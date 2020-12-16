using Book;
using Book.Item;
using Directmedia.Item;
using Duden.Item;
using Epub.Item;
using Lyread.Views;
using System;
using System.Globalization;
using System.Windows.Input;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace Lyread.ViewModels
{
    public class SettingsViewModel : BaseViewModel
    {
        public IPublisherItem Directmedia => new DirectmediaItem();
        public IPublisherItem Duden => new DudenItem();
        public IPublisherItem Epub => new EpubItem();

        public int CoverSize
        {
            get { return Preferences.Get(nameof(CoverSize), 3); }
            set
            {
                Preferences.Set(nameof(CoverSize), value);
                OnPropertyChanged();
            }
        }

        public ICommand PickFolderCommand => new Command<IPublisherItem>(async publisher =>
            await Application.Current.MainPage.Navigation.PushModalAsync(
                new NavigationPage(new FolderPickerPage(publisher))));

        public ICommand ResetFolderCommand => new Command<IPublisherItem>(publisher =>
        {
            string name = publisher.Title;
            Preferences.Remove(name);
            OnPropertyChanged(name);
        });

        public SettingsViewModel()
        {
            Title = "Settings";
        }

        public void Refresh()
        {
            OnPropertyChanged(nameof(Directmedia));
            OnPropertyChanged(nameof(Duden));
            OnPropertyChanged(nameof(Epub));
        }
    }

    class PublisherToPathConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is IPublisherItem publisher)
            {
                return Preferences.Get(publisher.Title, null) ?? "Select...";
            }

            return null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}