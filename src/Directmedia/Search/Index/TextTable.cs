using System;
using System.IO;
using System.Linq;
using System.Text;

namespace Directmedia.Search.Index
{
    /// <summary>
    /// Maps the words of a page to the offset of their corresponding hash in the hash table.
    /// </summary>
    public class TextTable : IDisposable
    {
        private const int entrySize = 4;

        private readonly BinaryReader _reader;

        public int NumberOfPages { get; }

        public TextTable(FileInfo ttxFile)
        {
            _reader = new BinaryReader(ttxFile.OpenRead(), Encoding.GetEncoding(1252));
            NumberOfPages = _reader.ReadInt32();
            if (_reader.ReadInt32() == 0) // old format
            {
                NumberOfPages = 105600;
            }
        }

        /// <summary>
        /// Reads the hash table offsets for a given page from the .ttx file.
        /// </summary>
        public int[] ReadHashes(int pagenumber)
        {
            if (pagenumber <= 0 || pagenumber > NumberOfPages)
            {
                throw new ArgumentException();
            }
            if (pagenumber == NumberOfPages)
            {
                // last page: check entries left via (length - position) / 3
            }

            _reader.BaseStream.Seek(pagenumber * entrySize, SeekOrigin.Begin);
            int offsetStart = _reader.ReadInt32();
            int offsetEnd = _reader.ReadInt32();
            int absoluteOffsetStart = (offsetStart - 1) * 3 + (NumberOfPages + 2) * entrySize;
            _reader.BaseStream.Seek(absoluteOffsetStart, SeekOrigin.Begin);
            int hashCount = offsetEnd - offsetStart;
            byte[] hashList = _reader.ReadBytes(hashCount * 3);
            return HashKey3ToHashKey4(hashList, hashCount);
        }

        /// <summary>
        /// Converts an array with 3 byte hashes to an array with 4 byte hashes (as int)
        /// </summary>
        private int[] HashKey3ToHashKey4(byte[] hashList, int hashCount)
        {
            // before: mask = caseSensitive ? 0xffffffff : 0xff7fffff; but no case possible
            int mask = /* TODO caseSensitive ? -1 : */ unchecked((int)0xff7fffff);
            return Enumerable.Range(0, hashCount)
                .Select(i => (((hashList[i * 3] + (hashList[i * 3 + 1] << 8) + (hashList[i * 3 + 2] << 16)) & mask) - 1) & mask)
                .Where(hashKey4 => (hashKey4 & 0x7FFFFF) < 0x7FFFFF - 0x200)
                .ToArray();
        }

        public void Dispose()
        {
            _reader.Dispose();
        }
    }
}