using Book;
using Book.Item;
using Epub.Item;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Book.Util;

namespace Epub.Item
{
    /// <summary>
    /// http://idpf.github.io/epub3-samples/30/samples.html
    /// </summary>
    public class EpubItem : IPublisherItem
    {
        public int Id => Title.GetHashCode();

        public string Title => "Epub";

        public IEnumerable<IBookItem> QueryBooks(DirectoryInfo folder)
        {
            return folder.EnumerateDirectories()
                .Select(f => new BookItem(f));
        }

        public IEnumerable<IJobItem> QueryJobs(DirectoryInfo folder)
        {
            return folder.EnumerateFiles("*.epub")
                .Where(f => !folder.SubdirectoryExists(Path.GetFileNameWithoutExtension(f.Name)))
                .Select(file => new JobItem(file));
        }
    }
}
