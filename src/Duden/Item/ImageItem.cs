using Book.Item;
using SQLite;
using System;
using System.IO;

namespace Duden.Item
{
    class ImageItem : IImageItem
    {
        public string Filename { get; set; }
        public int RowId { get; set; }

        [Ignore] public int Id => RowId;
        [Ignore] public string Title => Path.GetFileNameWithoutExtension(Filename);
        [Ignore] public string Description => null;
        [Ignore] public byte[] Thumbnail => FindImage(RowId);
        [Ignore] public byte[] Huge => FindImage(RowId);
        [Ignore] public Func<int, byte[]> FindImage { get; set; }
    }
}