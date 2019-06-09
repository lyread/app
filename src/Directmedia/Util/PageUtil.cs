using Book.Util;
using Directmedia.Decoder;
using Directmedia.Text;
using NLog;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Directmedia.Util
{
    /// <summary>
    /// Loads text pages from text.dki.
    /// </summary>
    public class PageUtil
    {
        private static readonly ILogger Log = LogManager.GetCurrentClassLogger();

        public static IEnumerable<Page> LoadPages(FileInfo textDki, int pagenumber, int pagecount)
        {
            using (BinaryReader reader = new BinaryReader(textDki.OpenRead()))
            {
                bool magic = reader.ReadDkiMagic();
                int[] pagetable = reader.ReadDkiBlock(true); // FIXME read partially
                foreach (int i in Enumerable.Range(pagenumber, pagecount))
                {
                    yield return LoadPage(reader, pagetable, i, magic);
                }
            }
        }

        private static Page LoadPage(BinaryReader reader, int[] pagetable, int pagenumber, bool magic)
        {
            int address = pagetable[pagenumber - 1];
            reader.BaseStream.Seek(address, SeekOrigin.Begin);
            int pagesize = reader.ReadUInt16() & ushort.MaxValue;
            int atomCount = 0, wordCount = 0;
            if (magic)
            {
                atomCount = reader.ReadUInt16() & ushort.MaxValue;
                wordCount = reader.ReadUInt16() & ushort.MaxValue;
            }
            else
            {
                pagesize -= 2;
            }
            byte[] data = reader.ReadBytes(pagesize);
            return new Page(pagenumber, atomCount, wordCount, data);
        }

        public static void Parse(Page page, IMarkupWriter markup)
        {
            markup.Pagenumber = page.Pagenumber;

            using (BinaryReader reader = new BinaryReader(new MemoryStream(page.Data)))
            {
                bool hardCarriageReturn = false;

                bool hyphenAtEol = false;
                bool hyphenAtEolSeparatingCK = false; // ck -> k-k
                bool hyphenInvisible = false;

                bool hyphen() => hyphenAtEol || hyphenAtEolSeparatingCK || hyphenInvisible;

                bool incompleteWord = false;

                byte font = 0;

                int atomCounter;
                int wordCounter;
                bool endOfPage = false;
                for (atomCounter = 0, wordCounter = 0; atomCounter < 20000 && !endOfPage; atomCounter++)
                {
                    byte token = reader.ReadByte();
                    switch (token)
                    {
                        case 0: // Blanks
                            {
                                reader.ReadByte(); // number of blanks
                                if (!hardCarriageReturn) // no blank after line break
                                {
                                    markup.AddBlank();
                                }
                                hardCarriageReturn = false;
                                break;
                            }
                        case 1: // Word
                            {
                                int length = reader.ReadByte();
                                string word = ReadWord(reader, length, GetEncoding(length, font));
                                if (incompleteWord) // at beginning of page
                                {
                                    incompleteWord = false;
                                }
                                else
                                {
                                    int delimiterCount = DelimiterCount(word, hyphen());
                                    if (word.Length > 0)
                                    {
                                        markup.AddWord(word, wordCounter, delimiterCount);
                                    }
                                    wordCounter += delimiterCount;
                                }
                                hyphenAtEol = hyphenAtEolSeparatingCK = hyphenInvisible = false;
                                if (length > sbyte.MaxValue) // blank at the end
                                {
                                    markup.AddBlank();
                                    atomCounter++;
                                }
                                break;
                            }
                        case 2: // Hard carriage return
                            {
                                hardCarriageReturn = true;
                                markup.AddLineBreak();
                                break;
                            }
                        case 3: // End of page
                            {
                                endOfPage = true;
                                break;
                            }
                        case 4: // Italic on
                            {
                                markup.Italic = true;
                                break;
                            }
                        case 5: // Italic off
                            {
                                markup.Italic = false;
                                break;
                            }
                        case 6: // Bold on
                            {
                                markup.Bold = true;
                                break;
                            }
                        case 7: // Bold off
                            {
                                markup.Bold = false;
                                break;
                            }
                        case 8: // Font preset (size and style)
                            {
                                byte preset = reader.ReadByte();
                                switch (preset)
                                {
                                    case 0:
                                        markup.FontSize = 1.0f;
                                        markup.Bold = false;
                                        markup.Italic = false;
                                        break;
                                    case 1:
                                        markup.FontSize = 1.34f;
                                        break;
                                    case 2:
                                        markup.FontSize = 1.22f;
                                        break;
                                    case 3:
                                        markup.FontSize = 1.1f;
                                        break;
                                    case 4:
                                        markup.FontSize = 1.0f;
                                        markup.Bold = true;
                                        break;
                                    case 5:
                                        markup.FontSize = 1.0f;
                                        break;
                                    case 6:
                                        markup.FontSize = 1.0f;
                                        markup.Italic = true;
                                        break;
                                    default:
                                        Log.Warn(string.Format("Font preset {0:D} is unknown.", preset));
                                        break;
                                }
                                break;
                            }
                        case 9: // Ly
                            {
                                break;
                            }
                        case 10: // Image
                            {
                                int width = reader.ReadInt32();
                                string name = ReadName(reader);
                                markup.AddBlockImage(name.Replace("#", ""));
                                break;
                            }
                        case 11: // Image link
                            {
                                string name = ReadName(reader);
                                markup.BeginImageLink(name);
                                break;
                            }
                        case 12: // End link
                            {
                                markup.EndLink();
                                break;
                            }
                        case 13: // Font
                            {
                                font = reader.ReadByte();
                                break;
                            }
                        case 14: // Filename
                            {
                                string filename = ReadName(reader);
                                break;
                            }
                        case 15: // Concordance
                            {
                                int concordance = reader.ReadUInt16();
                                break;
                            }
                        case 16: // Node number
                            {
                                int nodenumber = reader.ReadUInt16();
                                break;
                            }
                        case 17: // Superscript on
                            {
                                markup.Superscript = true;
                                break;
                            }
                        case 18: // Superscript off
                            {
                                markup.Superscript = false;
                                break;
                            }
                        case 19: // Sigil
                            {
                                string sigil = ReadName(reader);
                                break;
                            }
                        case 20: // Header (not generated anymore)
                            {
                                break;
                            }
                        case 21: // Hyphen at end of line
                            {
                                hyphenAtEol = true;
                                break;
                            }
                        case 22: // Underlined on
                            {
                                markup.Underline = true;
                                break;
                            }
                        case 23: // Underlined off
                            {
                                markup.Underline = false;
                                break;
                            }
                        case 24: // Greek on
                            {
                                break;
                            }
                        case 25: // Greek off
                            {
                                break;
                            }
                        case 27: // One blank
                            {
                                markup.AddBlank();
                                break;
                            }
                        case 28: // Vertical line on
                            {
                                markup.VerticalLine = true;
                                break;
                            }
                        case 29: // Vertical line off
                            {
                                markup.VerticalLine = false;
                                break;
                            }
                        case 30: // TD
                            {
                                break;
                            }
                        case 31: // Null
                            {
                                break;
                            }
                        case 128: // Page link (replaces image link)
                            {
                                int pagenumber = reader.ReadInt32();
                                string imageName = ReadName(reader);
                                if (pagenumber != 0)
                                {
                                    markup.BeginPageLink(pagenumber);
                                }
                                else
                                {
                                    markup.BeginImageLink(imageName);
                                }
                                break;
                            }
                        case 129: // ID
                            {
                                reader.ReadByte();
                                break;
                            }
                        case 130: // End ID
                            {
                                reader.ReadByte();
                                break;
                            }
                        case 131: // Subscript on
                            {
                                markup.Subscript = true;
                                break;
                            }
                        case 132: // Subscript off
                            {
                                markup.Subscript = false;
                                break;
                            }
                        case 133: // Color
                            {
                                markup.Color = reader.ReadBoolean();
                                break;
                            }
                        case 134: // Image inline
                            {
                                int width = reader.ReadUInt16();
                                int height = reader.ReadUInt16();
                                string name = ReadName(reader);
                                markup.AddInlineImage(name);
                                break;
                            }
                        case 135: // Searchword
                            {
                                string searchword = ReadName(reader);
                                break;
                            }
                        case 136: // Font size
                            {
                                byte fontSize = reader.ReadByte();
                                markup.FontSize = fontSize / 100.0f;
                                break;
                            }
                        case 137: // Copyright
                            {
                                reader.ReadByte();
                                break;
                            }
                        case 138: // Auto link
                            {
                                int autoLink = reader.ReadInt32();
                                markup.BeginPageLink(autoLink);
                                break;
                            }
                        case 139: // Soft carriage return
                            {
                                if (!hyphen())
                                {
                                    markup.AddBlank();
                                }
                                break;
                            }
                        case 140: // Hyphen invisible (e.g. in 1984 between 19 and 84)
                            {
                                hyphenInvisible = true;
                                break;
                            }
                        case 141: // Letter spacing on
                            {
                                markup.LetterSpacing = true;
                                break;
                            }
                        case 142: // Letter spacing off
                            {
                                markup.LetterSpacing = false;
                                break;
                            }
                        case 143: // Half line spacing
                            {
                                markup.AddHalfLineSpace();
                                break;
                            }
                        case 144: // List item
                            {
                                break;
                            }
                        case 145: // End list item
                            {
                                break;
                            }
                        case 146: // Unordered list
                            {
                                break;
                            }
                        case 147: // End unordered list
                            {
                                break;
                            }
                        case 148: // Set X (offset left border pixel, is reset after SoftCarriageReturn)
                            {
                                int xValue = reader.ReadUInt16();
                                break;
                            }
                        case 149: // SV (some sort of link)
                            {
                                reader.ReadInt64(); // jump 8 bytes
                                break;
                            }
                        case 150: // SV lemma
                            {
                                string lemma = ReadName(reader);
                                break;
                            }
                        case 151: // No SVFF (stops SV lemma)
                            {
                                break;
                            }
                        case 152: // Centered on (alignment)
                            {
                                markup.Centered = true;
                                break;
                            }
                        case 153: // Centered off
                            {
                                markup.Centered = false;
                                break;
                            }
                        case 154: // Align right on (precedes centered)
                            {
                                markup.Right = true;
                                break;
                            }
                        case 155: // Align right off
                            {
                                markup.Right = false;
                                break;
                            }
                        case 156: // E (not used anymore)
                            {
                                reader.ReadUInt16();
                                break;
                            }
                        case 157: // End E
                            {
                                break;
                            }
                        case 158: // Biblio page number
                            {
                                reader.ReadInt32();
                                break;
                            }
                        case 159: // Not first line
                            {
                                break;
                            }
                        case 160: // Thumb
                            {
                                break;
                            }
                        case 161: // End new
                            {
                                reader.ReadBytes(3);
                                break;
                            }
                        case 162: // URL
                            {
                                string url = ReadName(reader);
                                if (url.Length > 0)
                                {
                                    markup.BeginUrl(url);
                                }
                                break;
                            }
                        case 163: // End URL
                            {
                                markup.EndUrl();
                                break;
                            }
                        case 164: // Word anchor
                            {
                                break;
                            }
                        case 165: // Thumb www
                            {
                                break;
                            }
                        case 166: // S
                            {
                                break;
                            }
                        case 167: // No justification on (alignment)
                            {
                                break;
                            }
                        case 168: // No justification off
                            {
                                break;
                            }
                        case 169: // Next blank is fixed
                            {
                                break;
                            }
                        case 170: // Word rest (which appears on next page)
                            {
                                int length = reader.ReadByte();
                                string word = ReadWord(reader, length, Encoding.GetEncoding(1252));
                                int delimiterCount = DelimiterCount(word, false);
                                markup.AddWord(word, wordCounter, delimiterCount);
                                wordCounter += delimiterCount;
                                if (length > sbyte.MaxValue) // blank at the end
                                {
                                    markup.AddBlank();
                                    atomCounter++;
                                }
                                break;
                            }
                        case 171: // Incomplete word (at beginning of page)
                            {
                                ReadName(reader);
                                incompleteWord = true;
                                break;
                            }
                        case 172: // Hyphen CK (e.g. "entwickelte" is separated as "entwik-kelte")
                            {
                                hyphenAtEolSeparatingCK = true;
                                break;
                            }
                        case 173: // Hebrew on
                            {
                                break;
                            }
                        case 174: // Hebrew off
                            {
                                break;
                            }
                        case 175: // NodeNumber2
                            {
                                int nodenumber = reader.ReadInt32();
                                break;
                            }
                        case 176: // Strikethrough on
                            {
                                markup.Strikethrough = true;
                                break;
                            }
                        case 177: // Strikethrough off
                            {
                                markup.Strikethrough = false;
                                break;
                            }
                        case 178: // Set Y
                            {
                                reader.ReadUInt16(); // jump 2
                                break;
                            }
                        case 179: // Cor (swallows next element)
                            {
                                reader.ReadUInt32();
                                break;
                            }
                        case 180: // End cor
                            {
                                break;
                            }
                        case 236: // Thin dashed line (distance 28)
                            {
                                break;
                            }
                        default:
                            {
                                Log.Warn("No matching tag found for token {0} on page {1}.", token, page);
                                endOfPage = true;
                                break;
                            }
                    }

                    endOfPage |= reader.BaseStream.Position == reader.BaseStream.Length;
                }

                if (page.AtomCount != 0 && atomCounter != page.AtomCount)
                {
                    Log.Warn("Number of atoms was {0} but should be {1}.", atomCounter, page.AtomCount);
                }
            }
        }

        private static string ReadName(BinaryReader reader)
        {
            byte length = reader.ReadByte();
            return Encoding.GetEncoding(1252).GetString(reader.ReadBytes(length));
        }

        private static string ReadWord(BinaryReader reader, int length, Encoding encoding)
        {
            return encoding.GetString(reader.ReadBytes(length & sbyte.MaxValue)); // zero out 8th bit, max length is 127
        }

        private static Encoding GetEncoding(int length, byte font)
        {
            if ((length & sbyte.MaxValue) == 1 && font != 0) // special character
            {
                switch (font)
                {
                    case 1:
                        return new WingdingsEncoding();
                    case 2:
                        return new SymbolEncoding();
                    default:
                        return new IdentityEncoding();
                }
            }
            return new VladoEncoding(); // no trailing byte between words
        }

        private static int DelimiterCount(string word, bool hyphen)
        {
            int[] ints = Encoding.UTF32.GetBytes(word).ToInt32Array();
            bool IsDelimiter(int i) => i > char.MaxValue || !char.IsLetterOrDigit(Convert.ToChar(i));
            return Convert.ToInt32(!hyphen && !ints.All(IsDelimiter)) + ints
                .SkipWhile(IsDelimiter) // trim start
                .Reverse()
                .SkipWhile(IsDelimiter) // trim end
                .Count(IsDelimiter);
        }
    }
}