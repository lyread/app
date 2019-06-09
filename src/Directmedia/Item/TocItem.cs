using Book.Item;
using System.Collections.Generic;
using System.Linq;

namespace Directmedia.Item
{
    public class TocItem : ITocItem
    {
        public int Id => Pagenumber;
        public string Title { get; }
        public ITocItem Parent => ParentConcrete;
        public IEnumerable<ITocItem> Children => ChildrenConcrete;
        public bool HasChildren => ChildrenConcrete.Any();
        public byte Level { get; }
        public bool Expanded { get; set; }

        public TocItem ParentConcrete { get; set; }
        public List<TocItem> ChildrenConcrete { get; } = new List<TocItem>();
        public int Pagenumber { get; }
        public int Pagecount { get; }

        public TocItem(string title, byte level, int pagenumber, int pagecount)
        {
            Title = title;
            Level = level;
            Pagenumber = pagenumber;
            Pagecount = pagecount;
        }

        public void AddChild(TocItem item)
        {
            item.ParentConcrete = this;
            ChildrenConcrete.Add(item);
        }
    }
}