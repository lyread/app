using Book;
using Book.Item;
using Duden.Item;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Duden.Item
{
    public class DudenItem : IPublisherItem
    {
        public int Id => Title.GetHashCode();

        public string Title => "Duden";

        public IEnumerable<IBookItem> QueryBooks(DirectoryInfo folder)
        {
            return folder.EnumerateFiles("*.sqlite3")
                .Where(file => file.Name != "dbmedia.sqlite3")
                .Select(file => new BookItem(file));
        }

        public IEnumerable<IJobItem> QueryJobs(DirectoryInfo folder)
        {
            IEnumerable<IJobItem> decrypt = Enumerable.Concat(folder.EnumerateFiles("*.dbb"), folder.EnumerateFiles("*.bdb"))
               .Where(file => !File.Exists(Path.ChangeExtension(file.FullName, "sqlite3")))
               .Select(file => new JobItem(file));
            IEnumerable<IJobItem> index = folder.EnumerateFiles("*.sqlite3")
                .Where(file => File.Exists(Path.ChangeExtension(file.FullName, "dbb")))
                .Where(file => !Directory.Exists(Path.ChangeExtension(file.FullName, string.Empty)))
                .Select(file => new LuceneItem(file));
            return Enumerable.Concat(decrypt, index);
        }
    }
}
