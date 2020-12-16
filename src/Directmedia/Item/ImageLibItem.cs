using Book.Item;
using System.IO;
using System.Text;

namespace Directmedia.Item
{
    public class ImageLibItem : IImageItem
    {
        public bool Hidden { get; }
        public ImageLibOffset _title, _description, _thumbnail, _huge;
        private readonly FileInfo _libFile;

        public ImageLibItem(string filename, bool hidden, ImageLibOffset title, ImageLibOffset description,
            ImageLibOffset thumbnail, ImageLibOffset huge, FileInfo libFile)
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

        private string LoadString(ImageLibOffset location)
        {
            if (location == null)
            {
                return null;
            }

            return Encoding.GetEncoding(1252).GetString(LoadBytes(location));
        }

        private byte[] LoadBytes(ImageLibOffset location)
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

    public class ImageLibOffset
    {
        public int Offset { get; }
        public int Length { get; }

        public ImageLibOffset(int offset, int length)
        {
            Offset = offset;
            Length = length;
        }
    }
}