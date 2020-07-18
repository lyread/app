using Lucene.Net.Analysis;
using Lucene.Net.Analysis.Standard;
using Lucene.Net.QueryParsers.Classic;
using Lucene.Net.Util;
using System;
using System.Text.RegularExpressions;

namespace Lyread
{
    class QueryUtil
    {
        public static bool IsValidRegex(string pattern)
        {
            try
            {
                new Regex(pattern);
            }
            catch (ArgumentNullException)
            {
            }
            catch (ArgumentException)
            {
                return false;
            }
            return true;
        }

        public static bool IsValidLucene(string query)
        {
            try
            {
                using (Analyzer analyzer = new StandardAnalyzer(LuceneVersion.LUCENE_CURRENT))
                {
                    new QueryParser(LuceneVersion.LUCENE_CURRENT, string.Empty, analyzer).Parse(query);
                }
            }
            catch (ArgumentNullException)
            {
            }
            catch (ParseException)
            {
                return false;
            }
            return true;
        }
    }
}
