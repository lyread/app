using Book.Item;
using Book.Util;
using System.IO;

namespace Directmedia.Item
{
    class ImageFileItem : IImageItem
    {
        private readonly bool _hidden;
        private readonly FileInfo _thumbnail;

        public ImageFileItem(int id, bool hidden, FileInfo thumbnail)
        {
            Id = id;
            _hidden = hidden;
            _thumbnail = thumbnail;
        }

        public int Id { get; }
        public string Title => Path.GetFileNameWithoutExtension(_thumbnail.Name);
        public string Description => null;
        public string Filename => _thumbnail.Name;
        public byte[] Thumbnail => File.ReadAllBytes(_thumbnail.FullName);
        public byte[] Huge => File.ReadAllBytes(Path.Combine(_thumbnail.Directory.Parent.GetSubdirectory(((int)ImageSize.Huge).ToString()).FullName, _thumbnail.Name));
    }

    public enum ImageSize
    {
        Thumbnail = 1,
        Small = 2,
        Medium = 3,
        Huge = 4
    }
}
