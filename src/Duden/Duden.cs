using Book;
using Book.Item;
using Duden.Item;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Duden
{
    public class Duden : IPublisher
    {
        public IEnumerable<IBookItem> QueryBooks(DirectoryInfo folder)
        {
            return folder.EnumerateFiles("*.sqlite3")
                .Where(file => file.Name != "dbmedia.sqlite3")
                .Select(file => new BookItem(file));
        }

        public IEnumerable<IJobItem> QueryJobs(DirectoryInfo folder)
        {
            return Enumerable.Concat(folder.EnumerateFiles("*.dbb"), folder.EnumerateFiles("*.bdb"))
                .Where(file => !File.Exists(Path.ChangeExtension(file.FullName, "sqlite3")))
                .Select(file => new JobItem(file));
        }
    }
}
