using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace Book.Item
{
    public interface IBookItem : IItem
    {
        byte[] Cover { get; }

        Task<ITocItem> QueryToc(string pattern, IEnumerable<ICategoryItem> categories);
        Task<IEnumerable<IIndexItem>> QueryIndex(string pattern, IEnumerable<ICategoryItem> categories, int page);
        Task<IEnumerable<ICategoryItem>> QueryCategories();
        Task<IEnumerable<IImageItem>> QueryImages();
        Task<IEnumerable<ISearchItem>> Search(string pattern, int page);

        Task<bool> Html(int id, DirectoryInfo folder, string highlight = null);
        Task<byte[]> ExternalFile(string name);

        bool Has(ViewType view);
    }
}