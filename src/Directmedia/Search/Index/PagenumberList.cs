using Directmedia.Util;
using NLog;
using System;
using System.IO;
using System.Linq;
using System.Text;

namespace Directmedia.Search.Index
{
    /// <summary>
    /// Maps the position of a word in the word list to the pages, that contain that word.
    /// </summary>
    public class PagenumberList : IDisposable
    {
        private readonly ILogger Log = LogManager.GetCurrentClassLogger();

        private readonly BinaryReader _reader;
        private readonly int _entrySize;

        public PagenumberList(FileInfo plxFile)
        {
            _reader = new BinaryReader(plxFile.OpenRead(), Encoding.GetEncoding(1252));
            if (_reader.ReadDkiMagic())
            {
                _reader.BaseStream.Seek(32, SeekOrigin.Begin);
                _entrySize = _reader.ReadByte() + 1;
            }
            else
            {
                _entrySize = 4;
            }
        }

        /// <summary>
        /// Gets the numbers of pages containing a given word.
        /// </summary>
        public int[] ReadPagenumbers(WordListEntry entry)
        {
            _reader.BaseStream.Seek(entry.Position, SeekOrigin.Begin);
            return Enumerable.Range(0, entry.Count).Select(i =>
            {
                byte[] buffer = _reader.ReadBytes(_entrySize);
                return ToPagenumber(buffer);
            }).ToArray();
        }

        private int ToPagenumber(byte[] buffer)
        {
            switch (buffer.Length)
            {
                case 2:
                case 3:
                case 4:
                    Array.Resize(ref buffer, 4);
                    return BitConverter.ToInt32(buffer, 0);
                case 1:
                    Log.Warn("PagelistIndexSize = 1");
                    break;
                default:
                    Log.Warn("PagelistIndexSize > 4");
                    break;
            }

            return 0;
        }

        public void Dispose()
        {
            _reader.Dispose();
        }
    }
}