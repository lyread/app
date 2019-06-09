using System;

namespace Directmedia.Text
{
    public interface IMarkupWriter : IDisposable
    {
        int Pagenumber { set; }

        float FontSize { set; }
        bool Bold { set; }
        bool Italic { set; }
        bool Superscript { set; }
        bool Subscript { set; }
        bool Underline { set; }
        bool Strikethrough { set; }
        bool Color { set; }
        bool LetterSpacing { set; }

        bool Centered { set; }
        bool Right { set; }
        bool VerticalLine { set; }

        void BeginPageLink(int pagenumber);
        void BeginImageLink(string name);
        void EndLink();

        void BeginUrl(string url);
        void EndUrl();

        void AddBlockImage(string name);
        void AddInlineImage(string name);
        void AddHalfLineSpace();

        void AddWord(string word, int wordCounter, int delimiterCount);
        void AddBlank();
        void AddLineBreak();
    }
}