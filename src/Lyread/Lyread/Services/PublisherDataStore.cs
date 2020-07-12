using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Book;
using Book.Item;
using Directmedia.Item;
using Duden.Item;
using Epub.Item;
using Lyread.Models;
using Xamarin.Essentials;

namespace Lyread.Services
{
    public class PublisherDataStore : IDataStore<IPublisherItem>
    {
        readonly List<IPublisherItem> items;

        public PublisherDataStore()
        {
            items = new List<IPublisherItem>()
            {
                new DirectmediaItem(),
                new DudenItem(),
                new EpubItem()
            };
        }

        public async Task<IPublisherItem> GetItemAsync(int id)
        {
            return await Task.FromResult(items.FirstOrDefault(s => s.Id == id));
        }

        public async Task<IEnumerable<IPublisherItem>> GetItemsAsync(bool forceRefresh = false)
        {
            return items
                .Where(p => Preferences.Get(p.GetType().Name, null) != null)
                .Where(p => new DirectoryInfo(Preferences.Get(p.GetType().Name, null)).Exists);
        }
    }
}