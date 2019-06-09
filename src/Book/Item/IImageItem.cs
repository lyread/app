namespace Book.Item
{
    public interface IImageItem : IItem
    {
        string Description { get; }
        string Filename { get; }
        byte[] Thumbnail { get; }
        byte[] Huge { get; }
    }
}