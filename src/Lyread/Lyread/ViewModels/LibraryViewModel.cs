using Book;
using Book.Item;
using Lucene.Net.Util;
using Lyread.Models;
using Lyread.Views;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reactive.Linq;
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
        public RangedObservableCollection<IBookItem> Books { get; } = new RangedObservableCollection<IBookItem>();

        public RangedObservableCollection<IJobItem> Jobs { get; } = new RangedObservableCollection<IJobItem>();

        public string Pattern { get; set; }

        public int CoverWidth => Preferences.Get(nameof(SettingsViewModel.CoverSize), 3) * 24;
        public int CoverHeight => Preferences.Get(nameof(SettingsViewModel.CoverSize), 3) * 31;

        public ICommand LoadBooksCommand => new Command(async () =>
        {
            OnPropertyChanged(nameof(CoverWidth));
            OnPropertyChanged(nameof(CoverHeight));

            IsBusy = true;

            try
            {
                IEnumerable<IJobItem> jobs = await GetJobsAsync();
                if (jobs.Any())
                {
                    Jobs.AddRange(jobs);
                    OnPropertyChanged(nameof(Jobs));

                    //await Task.WhenAll(jobs.Select(job => job.Run()))
                    await Task.Run(() =>
                    {
                        foreach (IJobItem jobItem in Jobs)
                        {
                            jobItem.Run();
                        }
                    }).ContinueWith(task => Device.BeginInvokeOnMainThread(() =>
                    {
                        Jobs.Clear();
                        OnPropertyChanged(nameof(Jobs));
                        LoadBooksCommand.Execute(null);
                    }));
                }
                else
                {
                    Books.Clear();
                    IEnumerable<IBookItem> books = await GetBooksAsync();
                    Books.AddRange(books);
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

        public ICommand LoadMoreBooksCommand => new Command(async () =>
        {
            IsBusy = true;

            try
            {
                IEnumerable<IBookItem> items = await GetBooksAsync();
                Books.AddRange(items);
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

        public ICommand SearchBooksCommand => new Command<string>(pattern =>
        {
            Pattern = pattern;
            LoadBooksCommand.Execute(null);
        });

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

        public LibraryViewModel()
        {
            Title = "Home";
        }

        private async Task<IEnumerable<IBookItem>> GetBooksAsync()
        {
            IEnumerable<IPublisherItem> publishers = await DataStore.GetItemsAsync(true);
            bool patternIsNullOrEmpty = string.IsNullOrEmpty(Pattern);
            int page = (Books.Count + PageSize - 1) / PageSize;

            return publishers
                .SelectMany(publisher => publisher.QueryBooks(new DirectoryInfo(Preferences.Get(publisher.Title, null))))
                .Where(book => patternIsNullOrEmpty || Regex.IsMatch(book.Title, Pattern, RegexOptions.IgnoreCase))
                .Skip(page * PageSize)
                .Take(PageSize);
        }

        private async Task<IEnumerable<IJobItem>> GetJobsAsync()
        {
            IEnumerable<IPublisherItem> publishers = await DataStore.GetItemsAsync(true);
            return publishers
                .SelectMany(publisher => publisher.QueryJobs(new DirectoryInfo(Preferences.Get(publisher.Title, null))))
                .Select(job => new ProgressJobItem(job));
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
