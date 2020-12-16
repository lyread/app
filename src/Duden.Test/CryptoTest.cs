using System.IO;
using System.Security.Cryptography;
using Xunit;

namespace Duden.Test
{
    public class CryptoTest
    {
        [Fact]
        public void Encrypt()
        {
            using (CryptoStream inStream = new CryptoStream(new FileInfo("test.sqlite3").OpenRead(),
                new DudenCipher().CreateEncryptor(), CryptoStreamMode.Read))
            using (MemoryStream outStream = new MemoryStream())
            {
                inStream.CopyTo(outStream);
                Assert.Equal(File.ReadAllBytes("test.dbb"), outStream.ToArray());
            }
        }

        [Fact]
        public void Decrypt()
        {
            using (CryptoStream inStream = new CryptoStream(new FileInfo("test.dbb").OpenRead(),
                new DudenCipher().CreateDecryptor(), CryptoStreamMode.Read))
            using (MemoryStream outStream = new MemoryStream())
            {
                inStream.CopyTo(outStream);
                Assert.Equal(File.ReadAllBytes("test.sqlite3"), outStream.ToArray());
            }
        }
    }
}