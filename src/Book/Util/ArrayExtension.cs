using System;

namespace Book.Util
{
    public static class ArrayExtension
    {
        public static int[] ToInt32Array(this byte[] bytes)
        {
            int[] ints = new int[bytes.Length >> 2];
            Buffer.BlockCopy(bytes, 0, ints, 0, bytes.Length);
            return ints;
        }

        public static byte[] ToByteArray(this int[] ints)
        {
            byte[] bytes = new byte[ints.Length << 2];
            Buffer.BlockCopy(ints, 0, bytes, 0, bytes.Length);
            return bytes;
        }
    }
}