using Book;
using Book.Util;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Windows.Input;
using Xamarin.Forms;

namespace Lyread.ViewModels
{
    public class FolderPickerViewModel : ListViewModel
    {
        public IPublisher Publisher { get; set; }
        public DirectoryInfo Parent { get; private set; } = new DirectoryInfo(DependencyService.Get<IPlatformService>().ExternalStorageDirectory);
        public RangedObservableCollection<FileSystemInfo> FileSystemInfos { get; }

        public ICommand OpenFolderCommand => new Command<FileSystemInfo>(OpenFolder);
        public ICommand RefreshFolderCommand => CreateRefreshCommand(() => OpenFolder(Parent));

        public FolderPickerViewModel()
        {
            FileSystemInfos = new RangedObservableCollection<FileSystemInfo>(ReadFiles());
        }

        private void OpenFolder(FileSystemInfo info)
        {
            if (info.IsDirectory())
            {
                DirectoryInfo folder = (DirectoryInfo)info;
                FileSystemInfos.ReplaceRange(ReadFiles());
                Parent = folder;
                OnPropertyChanged(nameof(Parent));
            }
        }

        private IEnumerable<FileSystemInfo> ReadFiles()
        {
            return Enumerable.Repeat(Parent.Parent ?? Parent, 1).Concat(Parent.EnumerateFileSystemInfos().Where(f => f.IsVisible()));
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
                return ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? info.IsDirectory() ? "@drawable/ic_folder_black_24dp" : "@drawable/ic_insert_drive_file_black_24dp" : info.IsDirectory() ? "Icons/folder.png" : "Icons/file.png");
            }
            return null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
