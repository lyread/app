using Book;
using Book.Item;
using Lyread.Annotations;
using Lyread.ViewModels;
using Lyread.Views;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reactive.Linq;
using System.Runtime.CompilerServices;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Essentials;
using Xamarin.Forms;
using static Book.Util.BookConstant;

namespace Lyread.ViewModels
{
    public class LibraryViewModel : ListViewModel
    {
        public ObservableCollection<IBookItem> Books { get; }

        public RangedObservableCollection<IJobItem> Jobs { get; } = new RangedObservableCollection<IJobItem>();

        public string Pattern { get; set; }

        public int CoverWidth => Preferences.Get(nameof(SettingsViewModel.CoverSize), 3) * 24;
        public int CoverHeight => Preferences.Get(nameof(SettingsViewModel.CoverSize), 3) * 31;

        public ICommand SearchBooksCommand => new Command<string>(pattern =>
        {
            Pattern = pattern;
            Init();
        });
        public ICommand RefreshBooksCommand { get; set; } // => CreateRefreshCommand(Init);
        public ICommand OpenBookCommand => new Command<IBookItem>(async book =>
        {
            if (book == null)
            {
                return;
            }

            if (Shell.Current.Items.All(item => item.Route != book.Id.ToString()))
            {
                FlyoutItem item = new FlyoutItem()
                {
                    Route = book.Id.ToString(),
                    Title = book.Title,
                    Icon = ImageSource.FromStream(() => new MemoryStream(book.Cover))
                };
                if (book.Has(ViewType.Toc))
                {
                    item.Items.Add(new ShellContent() { Title = "Contents", Icon = ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? "@drawable/ic_toc_black_24dp" : "Icons/toc.png"), Content = new TocPage(book) });
                }
                if (book.Has(ViewType.Index))
                {
                    item.Items.Add(new ShellContent() { Title = "Index", Icon = ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? "@drawable/ic_list_black_24dp" : "Icons/index.png"), Content = new IndexPage(book) });
                }
                if (book.Has(ViewType.Search))
                {
                    item.Items.Add(new ShellContent() { Title = "Search", Icon = ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? "@drawable/ic_search_black_24dp" : "Icons/search.png"), Content = new SearchPage(book) });
                }
                if (book.Has(ViewType.Images))
                {
                    item.Items.Add(new ShellContent() { Title = "Media", Icon = ImageSource.FromFile(Device.RuntimePlatform == Device.Android ? "@drawable/ic_image_black_24dp" : "Icons/media.png"), Content = new MediaPage(book) });
                }
                Shell.Current.Items.Add(item);
            }

            await Shell.Current.GoToAsync("//" + book.Id.ToString());
        });

        public Command LoadItemsCommand { get; set; }
        public ICommand RemainingItemsThresholdReachedCommand => new Command(async () =>
        {
            if (IsBusy)
                return;

            IsBusy = true;

            try
            {
                var items = await LoadBooks();
                foreach (var item in items)
                {
                    Books.Add(item);
                }
                if (items.Count() == 0)
                {
                    return;
                }
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

        public LibraryViewModel()
        {
            Title = "Home";
            Books = new ObservableCollection<IBookItem>();
            LoadItemsCommand = new Command(async () => await ExecuteLoadItemsCommand());
            RefreshBooksCommand = new Command(async () =>
            {
                await ExecuteLoadItemsCommand();
                IsBusy = false;
            });
        }

        private async Task<IEnumerable<IBookItem>> LoadBooks()
        {
            bool patternIsNullOrEmpty = string.IsNullOrEmpty(Pattern);
            int page = (Books.Count + PageSize - 1) / PageSize;
            IEnumerable<IPublisherItem> publishers = await DataStore.GetItemsAsync(true);
            return publishers
                .SelectMany(p => p.QueryBooks(new DirectoryInfo(Preferences.Get(p.GetType().Name, null))))
                .Where(b => patternIsNullOrEmpty || Regex.IsMatch(b.Title, Pattern, RegexOptions.IgnoreCase))
                .Skip(page * PageSize)
                .Take(PageSize);
        }

        public async void Init()
        {
            IEnumerable<IPublisherItem> publishers = await DataStore.GetItemsAsync(true);
            Jobs.ReplaceRange(publishers
                .SelectMany(p => p.QueryJobs(new DirectoryInfo(Preferences.Get(p.GetType().Name, null))))
                .Select(job => new JobItem(job)));
            //OnPropertyChanged(nameof(Jobs));

            Task.Run(() =>
            {
                foreach (IJobItem jobItem in Jobs)
                {
                    jobItem.Run();
                }
                Thread.Sleep(500);
                Device.BeginInvokeOnMainThread(async () =>
                {
                    Jobs.Clear();
                    //OnPropertyChanged(nameof(Jobs));
                    Books.Clear();
                    LoadItemsCommand.Execute(null);
                });
            });

            OnPropertyChanged(nameof(CoverWidth));
            OnPropertyChanged(nameof(CoverHeight));
        }

        public void Clear()
        {
            Books.Clear();
        }

        async Task ExecuteLoadItemsCommand()
        {
            if (IsBusy)
                return;

            IsBusy = true;

            try
            {
                Books.Clear();
                var items = await LoadBooks();
                foreach (var item in items)
                {
                    Books.Add(item);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex);
            }
            finally
            {
                IsBusy = false;
            }
        }
    }

    public class JobItem : IJobItem, INotifyPropertyChanged
    {
        private IJobItem _wrappedJobItem;

        public JobItem(IJobItem wrappedJobItem)
        {
            _wrappedJobItem = wrappedJobItem;
        }

        public int Id => Title.GetHashCode();
        public string Title => _wrappedJobItem.Title;

        private double _progress;
        public double Progress { get { return _progress; } set { _progress = value; OnPropertyChanged(); } }

        private Color _color = Color.Black;
        public Color Color { get { return _color; } set { _color = value; OnPropertyChanged(); } }

        public bool Run()
        {
            using (Observable.FromEventPattern<ProgressEventArgs>(handler => _wrappedJobItem.ProgressChanged += handler, handler => _wrappedJobItem.ProgressChanged -= handler)
                .Sample(TimeSpan.FromMilliseconds(250))
                .Select(pattern => pattern.EventArgs.Progress)
                .Finally(() => Device.BeginInvokeOnMainThread(() => { Progress = 1; }))
                .Subscribe(progress => Device.BeginInvokeOnMainThread(() => { Progress = progress; })))
            {
                bool success = _wrappedJobItem.Run();
                Device.BeginInvokeOnMainThread(() => { Color = success ? Color.Green : Color.Red; });
                return success;
            }
        }

        public event EventHandler<ProgressEventArgs> ProgressChanged;

        public event PropertyChangedEventHandler PropertyChanged;

        [NotifyPropertyChangedInvocator]
        public virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    class JobItemsToBooleanConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is ObservableCollection<IJobItem> items)
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
