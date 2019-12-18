using Book;
using System;
using System.Globalization;
using System.Windows.Input;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace Lyread.ViewModels
{
    public class SettingsViewModel : BaseViewModel
    {
        public IPublisher Directmedia => new Directmedia.Directmedia();
        public IPublisher Duden => new Duden.Duden();
        public IPublisher Epub => new Epub.Epub();
        public int CoverSize
        {
            get
            {
                return Preferences.Get(nameof(CoverSize), 3);
            }
            set
            {
                Preferences.Set(nameof(CoverSize), value);
                OnPropertyChanged();
            }
        }

        public ICommand PickFolderCommand => new Command<IPublisher>(async publisher => await Application.Current.MainPage.Navigation.PushAsync(new FolderPickerPage(publisher)));
        public ICommand ResetFolderCommand => new Command<IPublisher>(publisher =>
        {
            string name = publisher.GetType().Name;
            Preferences.Remove(name);
            OnPropertyChanged(name);
        });

        public void Refresh()
        {
            OnPropertyChanged(nameof(Directmedia));
            OnPropertyChanged(nameof(Duden));
            OnPropertyChanged(nameof(Epub));
        }
    }

    class PublisherToNameConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is IPublisher publisher)
            {
                return publisher.GetType().Name;
            }
            return null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class PublisherToPathConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is IPublisher publisher)
            {
                return Preferences.Get(publisher.GetType().Name, null) ?? "Select...";
            }
            return null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
