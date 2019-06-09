namespace Book.Item
{
    public interface ICategoryItem : IItem
    {
        bool Selected { get; set; }
    }
}