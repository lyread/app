using Book.Item;
using SQLite;
using System.Net;

namespace Duden.Item
{
    class CategoryItem : ICategoryItem
    {
        public int RowId { get; set; }
        [MaxLength(40)]
        public string Desc { get; set; }

        [Ignore]
        public int Id => RowId;
        [Ignore]
        public string Title => WebUtility.HtmlDecode(Desc).Replace(": single", string.Empty);
        [Ignore]
        public bool Selected { get; set; } = false;
    }
}
