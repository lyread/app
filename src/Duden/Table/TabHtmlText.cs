using ICSharpCode.SharpZipLib.Zip.Compression.Streams;
using SQLite;
using System;
using System.IO;
using System.Text;

namespace Duden.Table
{
    class TabHtmlText
    {
        [PrimaryKey]
        public int NumId { get; set; } // 12 bits BookId, 20 bits counter
        [MaxLength(40)]
        public string Lemma { get; set; }
        [MaxLength(100)]
        public string Context { get; set; } // not used
        public int Type { get; set; } // not used
        public byte[] Html { get; set; }

        [Ignore]
        private int CompressedSize => Html.Length - 4;
        [Ignore]
        private int UncompressedSize
        {
            get
            {
                byte[] bytes = new byte[4];
                Array.Copy(Html, bytes, 4);
                Array.Reverse(bytes);
                return BitConverter.ToInt32(bytes, 0);
            }
        }
        [Ignore]
        public string UncompressedHtml
        {
            get
            {
                if (Html == null || Html.Length < 4)
                {
                    return string.Empty;
                }
                using (StreamReader reader = new StreamReader(new InflaterInputStream(new MemoryStream(Html, 4, CompressedSize)), Encoding.UTF8, true, UncompressedSize))
                {
                    return reader.ReadToEnd();
                }
            }
        }
    }
}