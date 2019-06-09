using System.Collections.Generic;

namespace Book.Item
{
    public interface ITocItem : IItem
    {
        ITocItem Parent { get; }
        IEnumerable<ITocItem> Children { get; }
        bool HasChildren { get; }
        byte Level { get; }
        bool Expanded { get; set; }
    }
}