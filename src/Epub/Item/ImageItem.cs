using Book.Item;
using System.IO;

namespace Epub.Item
{
    class ImageItem : IImageItem
    {
        public int Id => Filename.GetHashCode();
        public string Title => Path.GetFileNameWithoutExtension(Filename);
        public string Description => null;
        public string Filename { get; }
        public byte[] Thumbnail => Huge;
        public byte[] Huge { get; }

        public ImageItem(string filename, byte[] file)
        {
            Filename = filename;
            Huge = file;
        }
    }
}
