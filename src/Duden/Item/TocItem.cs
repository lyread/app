using Book.Item;
using SQLite;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Duden.Item
{
    class TocItem : NavItem, ITocItem
    {
        [Ignore]
        public ITocItem Parent { get; private set; }
        [Ignore]
        public IEnumerable<ITocItem> Children { get; }
        [Ignore]
        public bool HasChildren => Children.Any();
        [Ignore]
        public byte Level => Convert.ToByte(Parent != null);
        [Ignore]
        public bool Expanded { get; set; }

        public TocItem()
        {
            Children = new List<ITocItem>();
        }

        public TocItem(string title, List<TocItem> children)
        {
            Lemma = title;
            Children = children.AsEnumerable<ITocItem>();
            children.ForEach(child => child.Parent = this);
        }
    }
}
