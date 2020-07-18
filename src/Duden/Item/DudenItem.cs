using Book;
using Book.Item;
using Duden.Item;
using Lucene.Net.Util;
using System;
using System.Collections.Generic;
using System.Diagnostics;
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
            if (decrypt.Any())
            {
                return decrypt;
            }
            IEnumerable<IJobItem> index = folder.EnumerateFiles("*.sqlite3")
                .Where(file => file.Name != "dbmedia.sqlite3")
                .Where(file => !Directory.Exists(Path.ChangeExtension(file.FullName, Convert.ToInt32(LuceneVersion.LUCENE_CURRENT).ToString())))
                .Select(file => new LuceneItem(file));
            return index;
        }
    }
}
