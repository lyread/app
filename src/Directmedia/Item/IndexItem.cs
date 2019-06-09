using Book.Item;

namespace Directmedia.Item
{
    public class IndexItem : IIndexItem
    {
        public int Id => Pagenumber;
        public string Title { get; }
        public byte Category { get; }
        public int Pagenumber { get; }

        public IndexItem(string title, byte category, int pagenumber)
        {
            Title = title;
            Category = category;
            Pagenumber = pagenumber;
        }
    }
}