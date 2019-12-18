using Book;
using Book.Util;
using Lyread.ViewModels;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Windows.Input;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace Lyread.ViewModels
{
    public class FolderPickerViewModel : ListViewModel
    {
        public IPublisher Publisher { get; set; }
        public DirectoryInfo Parent { get; set; } = new DirectoryInfo(DependencyService.Get<IPlatformService>().ExternalStorageDirectory);
        public RangedObservableCollection<FileSystemInfo> FileSystemInfos { get; set; } = new RangedObservableCollection<FileSystemInfo>(From(new DirectoryInfo(DependencyService.Get<IPlatformService>().ExternalStorageDirectory)));

        public ICommand OpenFolderCommand => new Command<FileSystemInfo>(OpenFolder);
        public ICommand RefreshFolderCommand => CreateRefreshCommand(() => OpenFolder(Parent));

        private void OpenFolder(FileSystemInfo info)
        {
            if (info.IsDirectory())
            {
                DirectoryInfo folder = (DirectoryInfo)info;
                try
                {
                    FileSystemInfos.ReplaceRange(From(folder));
                }
                catch (Exception)
                {
                    return;
                }
                Preferences.Set(Publisher.GetType().Name, folder.FullName);
                Parent = folder;
                OnPropertyChanged(nameof(Parent));
            }
        }

        private static IEnumerable<FileSystemInfo> From(DirectoryInfo folder)
        {
            List<FileSystemInfo> infos = new List<FileSystemInfo>() { folder.Parent ?? folder };
            infos.AddRange(folder.EnumerateFileSystemInfos().Where(f => f.IsVisible()));
            return infos;
        }
    }

    class FileSystemInfoToNameConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is FileSystemInfo info && parameter is FolderPickerViewModel model)
            {
                return model.FileSystemInfos.Any() && model.FileSystemInfos.First() == info ? "[..]" : info.Name;
            }
            return null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class FileSystemInfoToImageConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is FileSystemInfo info)
            {
                return ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? info.IsDirectory() ? "@drawable/ic_folder_black_24dp" : "@drawable/ic_note_black_24dp" : info.IsDirectory() ? "Icons/folder.png" : "Icons/file.png");
            }
            return null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
