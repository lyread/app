using Book.Item;
using SQLite;
using System.Net;

namespace Duden.Item
{
    class CategoryItem : ICategoryItem
    {
        public int BookId { get; set; }
        [MaxLength(40)]
        public string Desc { get; set; }

        [Ignore]
        public int Id => BookId;
        [Ignore]
        public string Title => WebUtility.HtmlDecode(Desc);
        [Ignore]
        public bool Selected { get; set; } = true;
    }
}
