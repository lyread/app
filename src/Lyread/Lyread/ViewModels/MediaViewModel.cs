using Book.Item;
using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace Lyread.ViewModels
{
    public class MediaViewModel : BookViewModel
    {
        public RangedObservableCollection<IImageItem> MediaItems { get; set; } = new RangedObservableCollection<IImageItem>();

        public ICommand QueryIndexCommand => new Command<string>(async pattern =>
        {
            Pattern = pattern;

        });

        public string Pattern { get; set; }

        public ICommand OpenMediaItemCommand => new Command<IImageItem>(async item =>
        {
            try
            {
                string filename = Path.HasExtension(item.Filename) ? item.Filename : Path.ChangeExtension(item.Filename, ".jpg");
                FileInfo file = new FileInfo(Path.Combine(FileSystem.CacheDirectory, filename));
                File.WriteAllBytes(file.FullName, item.Huge);
                await DependencyService.Get<IPlatformService>().LaunchImage(file);
            }
            catch (Exception e)
            {
                await Application.Current.MainPage.DisplayAlert("Warning", e.Message, "OK");
            }
        });

        public async Task Init()
        {
            MediaItems.ReplaceRange(await Book.QueryImages(null, 0));
        }
    }
}
