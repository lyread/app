using NLog;
using System;
using System.Text;

namespace Directmedia.Decoder
{
    /// <summary>
    /// Decoder for multiple characters in text.dki files.
    /// </summary>
    public class VladoEncoding : Encoding
    {
        public override System.Text.Decoder GetDecoder()
        {
            return new VladoDecoder();
        }

        public override int GetChars(byte[] bytes, int byteIndex, int byteCount, char[] chars, int charIndex)
        {
            return GetDecoder().GetChars(bytes, byteIndex, byteCount, chars, charIndex);
        }

        public override int GetCharCount(byte[] bytes, int index, int count)
        {
            return GetDecoder().GetCharCount(bytes, index, count);
        }

        public override int GetMaxCharCount(int byteCount)
        {
            return byteCount;
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

    public class VladoDecoder : System.Text.Decoder
    {
        private static readonly ILogger Log = LogManager.GetCurrentClassLogger();

        private byte _trailingByte;
        private bool _hasTrailingByte = false;

        public override int GetChars(byte[] bytes, int byteIndex, int byteCount, char[] chars, int charIndex)
        {
            // no unicode
            if (!_hasTrailingByte && GetCharCount(bytes, byteIndex, byteCount) == byteCount)
            {
                return Encoding.GetEncoding(1252).GetChars(bytes, byteIndex, byteCount, chars, charIndex);
            }

            // some unicode
            int charCount = 0;
            for (int i = byteIndex; i < byteIndex + byteCount; i++)
            {
                if (_hasTrailingByte)
                {
                    _hasTrailingByte = false;
                    chars[charIndex + charCount] = Unichar(_trailingByte, bytes[i]);
                    charCount++;
                }
                else if (bytes[i] < 32)
                {
                    if (i == byteIndex + byteCount - 1)
                    {
                        _trailingByte = bytes[i];
                        _hasTrailingByte = true;
                        continue;
                    }

                    chars[charIndex + charCount] = Unichar(bytes[i], bytes[i + 1]);
                    charCount++;
                    i++;
                }
                else
                {
                    charCount += Encoding.GetEncoding(1252).GetChars(bytes, i, 1, chars, charCount);
                }
            }

            return charCount;
        }

        public override int GetCharCount(byte[] bytes, int index, int count)
        {
            int charCount = count;
            for (int i = index; i < index + count; i++)
            {
                if (i == index && _hasTrailingByte)
                {
                    i++;
                    continue;
                }

                if (bytes[i] < 32) // proven to be at least 32
                {
                    charCount--;
                    i++;
                }
            }

            return charCount;
        }

        private char Unichar(byte b0, byte b1)
        {
            char unichar = (char) (b1 - (b0 + 1) + ((b0 - 1) << 8));
            if (unichar >= 0x700 && unichar < 0x1100)
            {
                unichar = (char) (unichar + 0x1700);
            }
            else if (unichar >= 0x1100 && unichar < 0x1200)
            {
                unichar = (char) (unichar + 0xe000 - 0x1100);
            }
            else if (unichar >= 0x1200 && unichar < 0x1e00)
            {
                Log.Warn("Unicode character: " + unichar);
            }

            return unichar;
        }
    }
}