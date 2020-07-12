using Book.Item;
using System.Collections.Generic;
using System.IO;

namespace Book.Item
{
    public interface IPublisherItem : IItem
    {
        IEnumerable<IBookItem> QueryBooks(DirectoryInfo folder);
        IEnumerable<IJobItem> QueryJobs(DirectoryInfo folder);
    }
}