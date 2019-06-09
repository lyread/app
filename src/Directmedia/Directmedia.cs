using Book;
using Book.Item;
using Book.Util;
using Directmedia.Item;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using static Directmedia.Util.Constants;

namespace Directmedia
{
    public class Directmedia : IPublisher
    {
        public IEnumerable<IBookItem> QueryBooks(DirectoryInfo folder)
        {
            return folder.EnumerateDirectories()
                .Where(f => ContainsBook(f))
                .Select(f => new BookItem(f));
        }

        public IEnumerable<IJobItem> QueryJobs(DirectoryInfo folder)
        {
            return folder.EnumerateFiles("*.dbz")
                .Select(file => new JobItem(file));
        }

        private bool ContainsBook(DirectoryInfo folder)
        {
            try
            {
                return folder.GetSubdirectoryIgnoreCase(DataFolder).FileExistsIgnoreCase(DigibibTxt);
            }
            catch (Exception)
            {
            }
            return false;
        }
    }
}