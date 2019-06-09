using Book.Item;
using System.Collections.Generic;
using System.IO;

namespace Book
{
    public interface IPublisher
    {
        IEnumerable<IBookItem> QueryBooks(DirectoryInfo folder);
        IEnumerable<IJobItem> QueryJobs(DirectoryInfo folder);
    }
}