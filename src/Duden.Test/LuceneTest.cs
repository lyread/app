using Lucene.Net.Analysis.CharFilters;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Xunit;

namespace Duden.Test
{
    public class LuceneTest
    {
        [Fact]
        public void Reader()
        {
            string s = "<html>test1 test2</html>";
            StringReader reader = new StringReader(s);
            HTMLStripCharFilter f = new HTMLStripCharFilter(reader);

            StringBuilder sb = new StringBuilder();
            char[] chars = new char[1024];
            int length;
            while ((length = f.Read(chars, 0, chars.Length)) > 0)
            {
                sb.Append(chars, 0, length);
            }

            Assert.Equal("test", sb.ToString());
        }
    }
}