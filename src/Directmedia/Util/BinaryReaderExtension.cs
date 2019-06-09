using Book.Util;
using System.IO;
using static Directmedia.Util.Constants;

namespace Directmedia.Util
{
    internal static class BinaryReaderExtension
    {
        public static bool ReadDkiMagic(this BinaryReader reader)
        {
            if (reader.ReadUInt32() == Magic)
            {
                reader.ReadInt32(); // version number
                return true;
            }
            else
            {
                reader.BaseStream.Seek(0, SeekOrigin.Begin);
                return false;
            }
        }

        public static int[] ReadDkiBlock(this BinaryReader reader, bool large)
        {
            // two byte length means < 64k, four byte > 64k pages
            int length = (large ? reader.ReadInt32() : reader.ReadUInt16()) + 1;
            return reader.ReadBytes(length << 2).ToInt32Array();
        }
    }
}