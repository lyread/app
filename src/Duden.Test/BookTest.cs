using Book.Item;
using Duden.Item;
using System;
using System.IO;
using System.Linq;
using Xunit;

namespace Duden.Test
{
    public class BookTest
    {
        readonly BookItem book = new BookItem(new FileInfo("test.sqlite3"));

        [Fact]
        public void Infos()
        {
            Assert.Equal("Testwörterbuch 1" + Environment.NewLine + "Testwörterbuch 2", book.Title);
            Assert.True(book.Cover.Length > 0);
        }

        [Fact]
        public async void Toc()
        {
            ITocItem item = await book.QueryToc(null, Enumerable.Empty<ICategoryItem>());
            Assert.NotNull(item);
            Assert.Equal(2, item.Children.Count());
        }

        [Fact]
        public async void Index()
        {
            Assert.Equal(2, (await book.QueryIndex(null, Enumerable.Empty<ICategoryItem>(), 0)).Count());
        }

        [Fact]
        public async void Categories()
        {
            Assert.Equal(2, (await book.QueryCategories()).Count());
        }
    }
}