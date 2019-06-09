using Directmedia.Text;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;

namespace Lyread.Text
{
    public class HtmlWriter : IMarkupWriter
    {
        public Dictionary<int, string> ImageIdsToExtensions { get; } = new Dictionary<int, string>();

        private readonly int _highlightedPagenumber;
        private readonly ISet<int> _highlightedOffsets;

        private int _pagenumber;

        private StreamWriter writer;

        public HtmlWriter(Stream stream, int highlightedPagenumber, ISet<int> highlightedOffsets)
        {
            _highlightedPagenumber = highlightedPagenumber;
            _highlightedOffsets = highlightedOffsets;

            writer = new StreamWriter(stream, Encoding.UTF8);
            writer.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
            writer.WriteLine("<html>");
            writer.WriteLine("<body>");
            writer.WriteLine("<p style=\"font-size: 100%\">");
        }

        public void Dispose()
        {
            writer.WriteLine("</p>");
            writer.WriteLine("</body>");
            writer.WriteLine("</html>");
            writer.Dispose();
        }

        public int Pagenumber { set { _pagenumber = value; writer.Write("<span id=\"" + value + "\"/>"); } }

        public float FontSize { set { writer.WriteLine("</p>"); writer.Write("<p style=\"font-size:" + (value * 100) + "%\">"); } }
        public bool Bold { set { writer.Write(value ? "<b>" : "</b>"); } }
        public bool Italic { set { writer.Write(value ? "<i>" : "</i>"); } }
        public bool Superscript { set { writer.Write(value ? "<sup>" : "</sup>"); } }
        public bool Subscript { set { writer.Write(value ? "<sub>" : "</sub>"); } }
        public bool Underline { set { writer.Write(value ? "<u>" : "</u>"); } }
        public bool Strikethrough { set { writer.Write(value ? "<strike>" : "</strike>"); } }
        public bool Color { set { writer.Write(value ? "<font color=\"gray\">" : "</font>"); } }
        public bool LetterSpacing { set { writer.Write(value ? "<span style=\"letter-spacing:2px;\"> " : "</span>"); } }

        public bool Centered { set { writer.Write(value ? "<div align=\"center\">" : "</div>"); } }
        public bool Right { set { writer.Write(value ? "<div align=\"right\">" : "</div>"); } }
        public bool VerticalLine { set { writer.Write(value ? "<div style=\"border-left: thick solid red;\">" : "</div>"); } }

        public void BeginPageLink(int pagenumber) { writer.Write("<a href=\"" + pagenumber + ".html#" + pagenumber + "\">"); }
        public void BeginImageLink(string name) { writer.Write("<a href=\"" + name + "\">"); }
        public void EndLink() { writer.Write("</a>"); }

        public void BeginUrl(string url) { writer.Write("<a href=\"" + url + "\">"); }
        public void EndUrl() { writer.Write("</a>"); }

        public void AddBlockImage(string name) { writer.Write("<div align=\"center\"><img src=\"" + name + "\" style=\"display:inline;height:auto;max-width:100%;\"></div>"); ImageIdsToExtensions[Path.GetFileNameWithoutExtension(name).GetHashCode()] = Path.GetExtension(name); }
        public void AddInlineImage(string name) { writer.Write("<img src=\"" + name + "\" style=\"height:1em;vertical-align:middle;\">"); ImageIdsToExtensions[Path.GetFileNameWithoutExtension(name).GetHashCode()] = Path.GetExtension(name); }
        public void AddHalfLineSpace() { writer.Write("<br style=\"line-height: .5em;\"/>"); }

        public void AddWord(string word, int wordCounter, int delimiterCount)
        {
            if (_pagenumber == _highlightedPagenumber && Enumerable.Range(wordCounter, delimiterCount).Any(i => _highlightedOffsets.Contains(i)))
            {
                writer.Write("<span style=\"background-color: yellow\">");
                writer.Write(WebUtility.HtmlEncode(word));
                writer.Write("</span>");
            }
            else
            {
                writer.Write(WebUtility.HtmlEncode(word));
            }
        }
        public void AddBlank() { writer.Write(' '); }
        public void AddLineBreak() { writer.Write("<br/>"); }
    }
}