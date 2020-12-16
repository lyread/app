using Book.Util;
using System;
using System.Text;

namespace Directmedia.Decoder
{
    public abstract class ByteMappingEncoding : Encoding
    {
        protected abstract int ToUtf32(byte b);

        private byte[] MapAll(byte[] bytes)
        {
            return Array.ConvertAll(bytes, ToUtf32).ToByteArray();
        }

        public override int GetChars(byte[] bytes, int byteIndex, int byteCount, char[] chars, int charIndex)
        {
            return UTF32.GetChars(MapAll(bytes), byteIndex << 2, byteCount << 2, chars, charIndex);
        }

        public override int GetCharCount(byte[] bytes, int index, int count)
        {
            return UTF32.GetCharCount(MapAll(bytes), index << 2, count << 2);
        }

        public override int GetMaxCharCount(int byteCount)
        {
            return UTF32.GetMaxCharCount(byteCount);
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