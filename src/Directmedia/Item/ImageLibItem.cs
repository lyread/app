using Book.Item;
using System.IO;
using System.Text;

namespace Directmedia.Item
{
    public class ImageLibItem : IImageItem
    {
        public bool Hidden { get; }
        public LibLocation _title, _description, _thumbnail, _huge;
        private readonly FileInfo _libFile;

        public ImageLibItem(string filename, bool hidden, LibLocation title, LibLocation description, LibLocation thumbnail, LibLocation huge, FileInfo libFile)
        {
            Filename = filename;
            Hidden = hidden;
            _title = title;
            _description = description;
            _thumbnail = thumbnail;
            _huge = huge;
            _libFile = libFile;
        }

        public int Id => Filename.GetHashCode();
        public string Title => LoadString(_title);
        public string Description => LoadString(_description);
        public string Filename { get; }
        public byte[] Thumbnail => LoadBytes(_thumbnail);
        public byte[] Huge => LoadBytes(_huge);

        private string LoadString(LibLocation location)
        {
            if (location == null)
            {
                return null;
            }
            return Encoding.GetEncoding(1252).GetString(LoadBytes(location));
        }

        private byte[] LoadBytes(LibLocation location)
        {
            if (location == null)
            {
                return null;
            }
            using (BinaryReader reader = new BinaryReader(_libFile.OpenRead()))
            {
                reader.BaseStream.Seek(location.Offset, SeekOrigin.Begin);
                return reader.ReadBytes(location.Length);
            }
        }
    }

    public class LibLocation
    {
        public int Offset { get; }
        public int Length { get; }

        public LibLocation(int offset, int length)
        {
            Offset = offset;
            Length = length;
        }
    }
}