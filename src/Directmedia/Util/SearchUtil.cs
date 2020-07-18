using Book.Item;
using Directmedia.Item;
using Directmedia.Search;
using Lucene.Net.Analysis;
using Lucene.Net.Analysis.Core;
using Lucene.Net.Index;
using Lucene.Net.QueryParsers.Classic;
using Lucene.Net.Search;
using Lucene.Net.Util;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using static Book.Util.BookConstant;

namespace Directmedia.Util
{
    public class SearchUtil
    {
        private const int NumHits = 1024;

        public static IEnumerable<ISearchItem> Search(string pattern, DirectoryInfo dataFolder, int page)
        {
            using (Analyzer analyzer = new SimpleAnalyzer(LuceneVersion.LUCENE_CURRENT))
            using (IndexReader reader = new PagesReader(dataFolder))
            {
                Query query = new QueryParser(LuceneVersion.LUCENE_CURRENT, string.Empty, analyzer).Parse(pattern);
                IndexSearcher searcher = new IndexSearcher(reader);
                TopFieldCollector collector = TopFieldCollector.Create(Sort.INDEXORDER, NumHits, false, false, false, false);
                searcher.Search(query, collector);

                /*
                IFormatter formatter = new SimpleHTMLFormatter();
                IScorer scorer = new QueryScorer(query);
                Highlighter highlighter = new Highlighter(formatter, scorer)
                {
                    TextFragmenter = new SimpleFragmenter(3)
                };
                */

                ScoreDoc[] docs = collector.GetTopDocs(page * PageSize, PageSize).ScoreDocs;
                return docs.Select(doc => new SearchItem(doc.Doc.ToString(), doc.Doc));

                /*
                Document document = searcher.Doc(doc.Doc);
                string body = document.Get("body");
                TokenStream stream = TokenSources.GetAnyTokenStream(reader, doc.Doc, "body", analyzer);
                //TokenStream stream = analyzer.GetTokenStream("test123", new StringReader("test456"));
                string best = highlighter.GetBestFragments(stream, body, 1, " ");
                */
            }
        }

        public static ISet<int> HighlightedOffsets(int pagenumber, string pattern, DirectoryInfo dataFolder)
        {
            using (Analyzer analyzer = new SimpleAnalyzer(LuceneVersion.LUCENE_CURRENT))
            using (IndexReader reader = new PagesReader(dataFolder))
            {
                Query query = new QueryParser(LuceneVersion.LUCENE_CURRENT, string.Empty, analyzer).Parse(pattern);
                TermsEnum termsEnum = reader.GetTermVector(pagenumber, string.Empty).GetIterator(TermsEnum.EMPTY);
                IEnumerable<int> highlightOffsets = ExtractTerms(query).SelectMany(term =>
                {
                    termsEnum.SeekExact(term.Bytes);
                    DocsAndPositionsEnum docsAndPositionsEnum = termsEnum.DocsAndPositions(null, null, DocsAndPositionsFlags.OFFSETS);
                    docsAndPositionsEnum.Advance(pagenumber);
                    return Enumerable.Range(0, docsAndPositionsEnum.Freq).Select(i =>
                    {
                        docsAndPositionsEnum.NextPosition();
                        return docsAndPositionsEnum.StartOffset;
                    });
                });
                return new HashSet<int>(highlightOffsets);
            }
        }

        private static ISet<Term> ExtractTerms(Query query)
        {
            ISet<Term> terms = new HashSet<Term>();
            try
            {
                query.ExtractTerms(terms); // does not work for all queries
            }
            catch (Exception)
            {
            }
            return terms;
        }
    }
}
