using System;
using System.IO;
using System.Text;

namespace Directmedia.Search.Index
{
    /// <summary>
    /// Maps hashes of a search word to its offset in the word list.
    /// </summary>
    public class HashTable : IDisposable
    {
        private readonly BinaryReader _reader;
        public int Length => Convert.ToInt32(_reader.BaseStream.Length >> 2);

        public HashTable(FileInfo htxFile)
        {
            _reader = new BinaryReader(htxFile.OpenRead(), Encoding.GetEncoding(1252));
            if (_reader.BaseStream.Length % 4 != 0)
            {
                throw new Exception("Wrong length of Index.htx");
            }
        }

        public int ReadOffset(int hash)
        {
            _reader.BaseStream.Seek(hash << 2, SeekOrigin.Begin);
            return _reader.ReadInt32();
        }

        //public int ReadOffset(string word)
        //{
        //    return ReadOffset(Hash(word));
        //}

        /// <summary>
        /// Result := (((Result*ord(word[i]) mod Offsets)+1)*ord(word[i]) mod Offsets)+1;
        /// </summary>
        public int Hash(string word)
        {
            int result = 1;
            foreach (char ord in word)
            {
                result = (((result * ord % Length) + 1) * ord % Length) + 1;
            }
            return result - 1;
        }

        public void Dispose()
        {
            _reader.Dispose();
        }
    }
}