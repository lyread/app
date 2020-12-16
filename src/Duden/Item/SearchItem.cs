using Book.Item;

namespace Duden.Item
{
    class SearchItem : ISearchItem
    {
        public int Id { get; }
        public string Title { get; }

        public SearchItem(int NumId, string Lemma)
        {
            Id = NumId;
            Title = Lemma;
        }
    }
}