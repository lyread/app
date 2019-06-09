using Book.Item;

namespace Directmedia.Item
{
    public class CategoryItem : ICategoryItem
    {
        public int Id => Category;
        public string Title { get; }
        public bool Selected { get; set; }

        private byte Category { get; }

        public CategoryItem(string title, bool selected, byte category)
        {
            Title = title;
            Category = category;
            Selected = selected;
        }
    }
}