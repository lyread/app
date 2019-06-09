using System;
using System.Text;

namespace Directmedia.Decoder
{
    /// <summary>
    /// Decoder for .tab files.
    /// </summary>
    public class TableEncoding : Encoding
    {
        private byte Map(byte b)
        {
            // if not CR or LF
            if (b == '\r' || b == '\n')
            {
                return b;
            }
            return (byte)(255 - (b - 32));
        }

        public override int GetChars(byte[] bytes, int byteIndex, int byteCount, char[] chars, int charIndex)
        {
            return GetEncoding(1252).GetChars(Array.ConvertAll(bytes, Map), byteIndex, byteCount, chars, charIndex);
        }

        public override int GetCharCount(byte[] bytes, int index, int count)
        {
            return GetEncoding(1252).GetCharCount(bytes, index, count);
        }

        public override int GetMaxCharCount(int byteCount)
        {
            return GetEncoding(1252).GetMaxCharCount(byteCount);
        }

        public override int GetBytes(char[] chars, int charIndex, int charCount, byte[] bytes, int byteIndex)
        {
            throw new NotImplementedException();
        }

        public override int GetByteCount(char[] chars, int index, int count)
        {
            throw new NotImplementedException();
        }

        public override int GetMaxByteCount(int charCount)
        {
            throw new NotImplementedException();
        }
    }
}