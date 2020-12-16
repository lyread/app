using Book.Item;
using SQLite;

namespace Duden.Item
{
    class IndexItem : NavItem, IIndexItem
    {
        [Ignore] public ICategoryItem Category { get; set; }
    }
}