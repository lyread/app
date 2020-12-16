using Book.Util;
using System;
using System.IO;
using System.Text;

namespace Directmedia.Search.Index
{
    /// <summary>
    /// Maps every word to each page where it appears.
    /// </summary>
    public class WordList : IDisposable
    {
        private readonly BinaryReader _reader;

        public WordList(FileInfo wlxFile)
        {
            _reader = new BinaryReader(wlxFile.OpenRead(), Encoding.GetEncoding(1252));
        }

        /// <summary>
        /// Reads a word.
        /// </summary>
        public WordListEntry ReadEntry(int offset)
        {
            _reader.BaseStream.Seek(offset, SeekOrigin.Begin);
            if (_reader.BaseStream.Length - _reader.BaseStream.Position >= 12) // entries have a 12 byte header
            {
                int position = _reader.ReadInt32();
                int hash = _reader.ReadInt32() - 1;
                int count = _reader.ReadInt32();
                string word = _reader.ReadNullTerminatedString(Encoding.GetEncoding(1252));
                return new WordListEntry(position, hash, count, word);
            }

            return null;
        }

        public void Dispose()
        {
            _reader.Dispose();
        }
    }

    public class WordListEntry
    {
        public int Position { get; }
        public int Hash { get; }
        public int Count { get; }
        public string Word { get; }

        public WordListEntry(int position, int hash, int count, string word)
        {
            Position = position;
            Hash = hash;
            Count = count;
            Word = word;
        }
    }
}