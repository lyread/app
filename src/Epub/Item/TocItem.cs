using Book.Item;
using System.Collections.Generic;
using System.Linq;

namespace Epub.Item
{
    class TocItem : ITocItem
    {
        public int Id { get; }
        public string Title { get; }
        public ITocItem Parent => ParentConcrete;
        public IEnumerable<ITocItem> Children => ChildrenConcrete;
        public bool HasChildren => ChildrenConcrete.Any();
        public byte Level
        {
            get
            {
                byte level = 0;
                for (ITocItem parent = this; (parent = parent.Parent) != null; level++) ;
                return level;
            }
        }
        public bool Expanded { get; set; }

        public TocItem ParentConcrete { get; set; }
        public List<TocItem> ChildrenConcrete { get; } = new List<TocItem>();

        public TocItem(int id, string title)
        {
            Id = id;
            Title = title;
        }

        public void AddChild(TocItem item)
        {
            item.ParentConcrete = this;
            ChildrenConcrete.Add(item);
        }
    }
}
