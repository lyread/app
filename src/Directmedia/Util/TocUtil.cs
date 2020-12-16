using Book.Util;
using Directmedia.Item;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Directmedia.Util
{
    /// <summary>
    /// Loads TOC from tree.dki and tree.dka.
    /// </summary>
    public class TocUtil
    {
        public static TocItem LoadTree(FileInfo treeDki, FileInfo treeDka)
        {
            IEnumerable<string> lines = treeDki.ReadAllLines(Encoding.GetEncoding(1252))
                .Where(line => !string.IsNullOrWhiteSpace(line));
            int[] pagenumbers = LoadPagenumbers(treeDka, lines.Count() > ushort.MaxValue);
            if (lines.Count() != pagenumbers.Length)
            {
                throw new Exception("Different number of entries in tree.dki and tree.dka.");
            }

            return CreateTree(CreateItems(lines, pagenumbers));
        }

        /// <summary>
        /// The tree.dka has four levels.
        /// Each level contains: linenumber -> pagenumber; then #pages + 1; then zeroes.
        /// </summary>
        private static int[] LoadPagenumbers(FileInfo treeDka, bool large)
        {
            using (BinaryReader reader = new BinaryReader(treeDka.OpenRead()))
            {
                reader.ReadDkiBlock(large); // children in first level (direct children of root)
                reader.ReadDkiBlock(large); // children in second level
                reader.ReadDkiBlock(large); // children in third level
                return reader.ReadDkiBlock(large); // all children
            }
        }

        private static IEnumerable<TocItem> CreateItems(IEnumerable<string> lines, int[] pagenumbers)
        {
            return lines.Select((line, i) =>
            {
                byte level = Convert.ToByte(line.TakeWhile(c => c == ' ').Count());
                int pagenumber = i == 0 ? 1 : pagenumbers[i - 1];
                return new TocItem(line.Trim(), level, pagenumber, pagenumbers[i] - pagenumber);
            });
        }

        /// <summary>
        /// The tree.dki encodes the tree using indentation.
        /// </summary>
        private static TocItem CreateTree(IEnumerable<TocItem> items)
        {
            TocItem item = items.Aggregate((parent, next) =>
            {
                while (next.Level <= parent.Level)
                {
                    parent = parent.ParentConcrete;
                }

                parent.AddChild(next);
                return next;
            });
            while (item.ParentConcrete != null)
            {
                item = item.ParentConcrete;
            }

            return item;
        }
    }
}