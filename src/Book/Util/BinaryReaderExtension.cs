using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Book.Util
{
    public static class BinaryReaderExtension
    {
        public static string ReadNullTerminatedString(this BinaryReader reader, Encoding encoding)
        {
            return encoding.GetString(reader.AsEnumerable().TakeWhile(b => b != 0).ToArray());
        }

        private static IEnumerable<byte> AsEnumerable(this BinaryReader reader)
        {
            while (reader.BaseStream.Position != reader.BaseStream.Length)
            {
                yield return reader.ReadByte();
            }
        }
    }
}
