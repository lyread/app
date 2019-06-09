using Book.Item;
using SQLite;
using System.Net;

namespace Duden.Item
{
    class NavItem : IIndexItem
    {
        [PrimaryKey]
        public int NumId { get; set; } // 12 bits BookId, 20 bits counter
        [MaxLength(40)]
        public string Lemma { get; set; }

        [Ignore]
        public int Id => NumId;
        [Ignore]
        public string Title => WebUtility.HtmlDecode(Lemma);
    }
}
