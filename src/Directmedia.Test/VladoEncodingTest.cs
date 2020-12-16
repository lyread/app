using Directmedia.Decoder;
using System.IO;
using System.Linq;
using System.Text;
using Xunit;

namespace Directmedia.Test
{
    public class VladoEncodingTest
    {
        readonly Encoding enc = new VladoEncoding();

        public VladoEncodingTest()
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
        }

        [Fact]
        public void Empty()
        {
            Assert.Equal(string.Empty, enc.GetString(new byte[0]));
        }

        [Fact]
        public void SingleCp1252Char()
        {
            Assert.Equal("ß", enc.GetString(new byte[] {223}));
        }

        [Fact]
        public void SingleUtf16Char()
        {
            Assert.Equal("–", enc.GetString(new byte[] {10, 30}));
        }

        [Fact]
        public void EndWithCp1252Char()
        {
            Assert.Equal("–ß", enc.GetString(new byte[] {10, 30, 223}));
        }

        [Fact]
        public void EndWithUtf16Char()
        {
            Assert.Equal("ß–", enc.GetString(new byte[] {223, 10, 30}));
        }

        [Fact]
        public void EndWithIncompleteUtf16Char()
        {
            Assert.Equal("ß", enc.GetString(new byte[] {223, 10}));
        }

        [Fact]
        public void Blocks()
        {
            byte[] bytes = Enumerable.Repeat((byte) 223, 130).ToArray();
            bytes[126] = bytes[128] = 10;
            bytes[127] = bytes[129] = 30;
            using (StreamReader reader = new StreamReader(new MemoryStream(bytes), enc, false, 128))
            {
                Assert.Equal(new string('ß', 126) + "––", reader.ReadToEnd());
            }
        }

        [Fact]
        public void TrailingByte()
        {
            byte[] bytes = Enumerable.Repeat((byte) 223, 130).ToArray();
            bytes[127] = 10;
            bytes[128] = 30;
            using (StreamReader reader = new StreamReader(new MemoryStream(bytes), enc, false, 128))
            {
                Assert.Equal(new string('ß', 127) + "–ß", reader.ReadToEnd());
            }
        }

        [Fact]
        public void TrailingByteUsedOnlyOnce()
        {
            byte[] bytes = Enumerable.Repeat((byte) 223, 257).ToArray();
            bytes[127] = 10;
            bytes[128] = 30;
            using (StreamReader reader = new StreamReader(new MemoryStream(bytes), enc, false, 128))
            {
                Assert.Equal(new string('ß', 127) + "–" + new string('ß', 128), reader.ReadToEnd());
            }
        }
    }
}