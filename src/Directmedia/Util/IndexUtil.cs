using Book.Item;
using Book.Util;
using Directmedia.Item;
using IniParser.Model;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using static Book.Util.BookConstant;

namespace Directmedia.Util
{
    /// <summary>
    /// Loads index/categories from lemmata.txt.
    /// </summary>
    public class IndexUtil
    {
        // Lines have the format: [lemma]#[A-Z][page number]
        private static readonly string LineRegex = "^([^#]+)#([A-Z]{1})([0-9]+)$";

        public static IEnumerable<CategoryItem> LoadCategories(FileInfo lemmataFile, IniData ini)
        {
            int categoryCount = LoadLemmata(lemmataFile, null, Enumerable.Empty<ICategoryItem>(), -1)
                .Aggregate(0, (count, item) => Math.Max(count, item.Category + 1));
            return Enumerable.Range(0, categoryCount)
                .Select((category, index) =>
                    new CategoryItem(ini[Constants.Stichwoerter][Constants.Gruppe + (category + 1)],
                        Convert.ToByte(category)));
        }

        public static IEnumerable<IndexItem> LoadLemmata(FileInfo lemmataFile, string pattern,
            IEnumerable<ICategoryItem> categories, int page)
        {
            bool patternIsNullOrWhiteSpace = string.IsNullOrWhiteSpace(pattern);
            int categoryMask = categories.Any()
                ? categories.Aggregate(0, (mask, category) => mask | (1 << category.Id))
                : int.MaxValue;
            return lemmataFile.ReadAllLines(Encoding.GetEncoding(1252))
                .Select(line => Regex.Match(line, LineRegex))
                .Where(match => match.Success)
                .Select(match => new IndexItem(match.Groups[1].Value.Trim(),
                    Convert.ToByte(match.Groups[2].Value.First() - 'A'), Convert.ToInt32(match.Groups[3].Value)))
                .Where(item => patternIsNullOrWhiteSpace || Regex.IsMatch(item.Title, pattern, RegexOptions.IgnoreCase))
                .Where(item => (categoryMask & (1 << item.Category)) > 0)
                .Skip(page < 0 ? 0 : page * PageSize)
                .Take(page < 0 ? int.MaxValue : PageSize);
        }
    }
}