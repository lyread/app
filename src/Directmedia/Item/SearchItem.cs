using Book.Item;

namespace Directmedia.Item
{
    class SearchItem : ISearchItem
    {
        public int Id => Pagenumber;
        public string Title { get; }
        public int Pagenumber { get; }

        public SearchItem(string title, int pagenumber)
        {
            Title = title;
            Pagenumber = pagenumber;
        }
    }
}
