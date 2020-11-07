using Book;
using Book.Item;
using Book.Util;
using Duden.Table;
using Lucene.Net.Analysis;
using Lucene.Net.Analysis.CharFilters;
using Lucene.Net.Analysis.Standard;
using Lucene.Net.Analysis.TokenAttributes;
using Lucene.Net.Documents;
using Lucene.Net.Index;
using Lucene.Net.QueryParsers.Classic;
using Lucene.Net.Search.Highlight;
using Lucene.Net.Store;
using Lucene.Net.Util;
using NLog;
using SQLite;
using SQLitePCL;
using SqlKata;
using SqlKata.Compilers;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using static Book.Util.BookConstant;

namespace Duden.Item
{
    public class BookItem : IBookItem
    {
        private static readonly ILogger Log = LogManager.GetCurrentClassLogger();

        private readonly FileInfo _bookFile;

        public BookItem(FileInfo bookFile)
        {
            _bookFile = bookFile;
        }

        public int Id
        {
            get
            {
                Query query = new Query(nameof(TabBookDescription))
                    .SelectRaw("sum(BookId) AS BookId");
                return FindWithQuery<TabBookDescription>(query).BookId;
            }
        }
        public string Title
        {
            get
            {
                Query subquery = new Query(nameof(TabBookDescription))
                    .SelectRaw(string.Format("coalesce(nullif({0},''),{1}) AS Desc", nameof(TabBookDescription.Copyright), nameof(TabBookDescription.Desc)))
                    .OrderBy(nameof(TabBookDescription.BookId))
                    .Distinct();
                Query query = new Query()
                    .SelectRaw(string.Format("group_concat(Desc, '{0}') AS Desc", Environment.NewLine))
                    .From(subquery);
                return FindWithQuery<TabBookDescription>(query)?.Title;
            }
        }
        public byte[] Cover
        {
            get
            {
                Query query = new Query(nameof(TabGUIBitmaps))
                    .SelectRaw("max(Filename) AS Filename, Image")
                    .Where(nameof(TabGUIBitmaps.Filename), nameof(Regexp), "^[0-9]{2}_.*_a.png$");
                return FindWithQuery<TabGUIBitmaps>(query)?.Image;
            }
        }

        public Task<ITocItem> QueryToc(string pattern, IEnumerable<ICategoryItem> categories)
        {
            Query query = new Query(nameof(TabBookDescription))
                .SelectRaw("TabHtmlText.NumId, Desc AS Lemma")
                .Join(nameof(TabMap), j => j.On("TabBookDescription.BookId", "TabMap.BookId").On("TabBookDescription.AdditionsId", "TabMap.Id"))
                .Join(nameof(TabHtmlText), "TabMap.NumId", "TabHtmlText.NumId")
                .OrderBy("TabBookDescription.BookId");
            List<TocItem> items = Query<TocItem>(query);
            TocItem root = items.Count == 1 ? items.First() : new TocItem("Zusätze", items);
            return Task.FromResult<ITocItem>(root);
        }

        public Task<IEnumerable<IIndexItem>> QueryIndex(string pattern, IEnumerable<ICategoryItem> categories, int page)
        {
            Query query = new Query(nameof(TabBookDescription))
                .Select("TabHtmlText.NumId", nameof(TabHtmlText.Lemma))
                .Join(nameof(TabMap), "TabBookDescription.BookId", "TabMap.BookId")
                .Join(nameof(TabHtmlText), "TabMap.NumId", "TabHtmlText.NumId")
                .OrderBy("TabHtmlText.NumId")
                .ForPage(page + 1, PageSize);

            if (categories.Any())
            {
                Query tabFieldValuesQuery = new Query(nameof(TabFieldValues))
                    .Select(nameof(TabFieldValues.BookId))
                    .SelectRaw(nameof(TabFieldValues.Field) + "||" + nameof(TabFieldValues.Val) + " AS " + nameof(TabMetaFachgebiete.FachgebietId))
                    .WhereIn(nameof(CategoryItem.RowId), categories.Select(item => item.Id.ToString()));
                Query tabMetaFachgebieteQuery = new Query(nameof(TabMetaFachgebiete))
                    .Distinct()
                    .Select(nameof(TabFieldValues.BookId), nameof(TabMetaFachgebiete.NumId))
                    .Join(tabFieldValuesQuery.As("TabFieldValues"), j => j.On("TabMetaFachgebiete.FachgebietId", "TabFieldValues.FachgebietId"));
                query.Join(tabMetaFachgebieteQuery.As("TabMetaFachgebiete"), j => j.On("TabBookDescription.BookId", "TabMetaFachgebiete.BookId").On("TabMap.NumId", "TabMetaFachgebiete.NumId"));
            }
            if (!string.IsNullOrWhiteSpace(pattern))
            {
                if (pattern.All(char.IsLetterOrDigit))
                {
                    query.WhereLike(nameof(TabHtmlText.Lemma), string.Format("%{0}%", pattern));
                }
                else
                {
                    query.Where(nameof(TabHtmlText.Lemma), nameof(Regexp), pattern);
                }
            }
            return Task.FromResult(Query<IndexItem>(query).AsEnumerable<IIndexItem>());
        }

        public Task<IEnumerable<ICategoryItem>> QueryCategories()
        {
            Query tabFieldValuesQuery = new Query(nameof(TabFieldValues))
                .Select(nameof(CategoryItem.RowId)).Select("*");
            Query query = new Query(nameof(TabFieldsTopLevel))
                .Select(nameof(CategoryItem.RowId)).SelectRaw("TabFieldsTopLevel.Desc || ': ' || TabFieldValues.Desc AS Desc")
                .Join(tabFieldValuesQuery.As(nameof(TabFieldValues)), j => j.On("TabFieldsTopLevel.BookId", "TabFieldValues.BookId").On("TabFieldsTopLevel.Field", "TabFieldValues.Field"));
            return Task.FromResult(Query<CategoryItem>(query).AsEnumerable<ICategoryItem>());
        }

        public Task<IEnumerable<IImageItem>> QueryImages(string pattern, int page)
        {
            Query query = new Query(nameof(TabGUIBitmaps))
                .Select(nameof(ImageItem.Filename), nameof(ImageItem.RowId))
                .WhereNot(nameof(ImageItem.Filename), nameof(Regexp), "^[0-9]{2}_.*_(a|i).png$");
            List<ImageItem> images = Query<ImageItem>(query);
            images.ForEach(item => item.FindImage = FindImage);
            return Task.FromResult(images.AsEnumerable<IImageItem>());
        }

        private byte[] FindImage(int RowId)
        {
            Query query = new Query(nameof(TabGUIBitmaps))
                .Select(nameof(TabGUIBitmaps.Image))
                .Where(nameof(RowId), RowId);
            return FindWithQuery<TabGUIBitmaps>(query)?.Image;
        }

        public Task<IEnumerable<ISearchItem>> Search(string pattern, int page)
        {
            using (Analyzer analyzer = new StandardAnalyzer(LuceneVersion.LUCENE_48))
            using (Lucene.Net.Store.Directory index = new SimpleFSDirectory(Path.ChangeExtension(_bookFile.FullName, Convert.ToInt32(LuceneVersion.LUCENE_48).ToString())))
            using (IndexReader reader = DirectoryReader.Open(index))
            {
                Lucene.Net.Search.Query query = new QueryParser(LuceneVersion.LUCENE_48, nameof(TabHtmlText.Html), analyzer).Parse(pattern);
                Lucene.Net.Search.TopScoreDocCollector collector = Lucene.Net.Search.TopScoreDocCollector.Create(512, true);
                Lucene.Net.Search.IndexSearcher searcher = new Lucene.Net.Search.IndexSearcher(reader);
                searcher.Search(query, collector);
                Lucene.Net.Search.TopDocs docs = collector.GetTopDocs(page * PageSize, PageSize);

                QueryScorer scorer = new QueryScorer(query);
                Highlighter highlighter = new Highlighter(new SimpleHTMLFormatter(), scorer) // SpanGradientFormatter
                {
                    TextFragmenter = new SimpleSpanFragmenter(scorer, 30)
                };

                IEnumerable<ISearchItem> items = docs.ScoreDocs.Select(scoreDoc =>
                {
                    Document doc = searcher.Doc(scoreDoc.Doc);
                    string html = doc.Get(nameof(TabHtmlText.Html));
                    string[] fragments = highlighter.GetBestFragments(new HTMLStripCharAnalyzer(), nameof(TabHtmlText.Html), html, 3);
                    return new SearchItem(int.Parse(doc.Get(nameof(TabHtmlText.NumId))), string.Join("\n", fragments));
                });

                return Task.FromResult(items.ToList().AsEnumerable());
            }
        }

        private string HtmlToPlain(string html)
        {
            using (TextReader reader = new HTMLStripCharFilter(new StringReader(html)))
            {
                StringBuilder sb = new StringBuilder();
                char[] chars = new char[1024];
                int length;
                while ((length = reader.Read(chars, 0, chars.Length)) > 0)
                {
                    sb.Append(chars, 0, length);
                }
                return sb.ToString();
            }
        }

        public Task<bool> Html(int numId, DirectoryInfo folder, string pattern)
        {
            Query query = new Query(nameof(TabHtmlText))
                .Select(nameof(TabHtmlText.Html))
                .Where(nameof(TabHtmlText.NumId), numId);
            TabHtmlText text = FindWithQuery<TabHtmlText>(query);
            string html = text.UncompressedHtml;
            DumpImages(html, folder);
            using (StreamWriter writer = new StreamWriter(Path.Combine(folder.FullName, Path.ChangeExtension(numId.ToString(), LinkType.html.ToString())), false, Encoding.UTF8))
            {
                writer.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
                writer.Write(ReplaceLinks(Highlight(numId, pattern, html), numId));
            }
            return Task.FromResult(true);
        }

        private string Highlight(int numId, string pattern, string html)
        {
            if (!string.IsNullOrWhiteSpace(pattern))
            {
                using (Analyzer analyzer = new StandardAnalyzer(LuceneVersion.LUCENE_48))
                using (Lucene.Net.Store.Directory index = new SimpleFSDirectory(Path.ChangeExtension(_bookFile.FullName, Convert.ToInt32(LuceneVersion.LUCENE_48).ToString())))
                using (IndexReader reader = DirectoryReader.Open(index))
                {
                    Lucene.Net.Search.IndexSearcher searcher = new Lucene.Net.Search.IndexSearcher(reader);
                    Lucene.Net.Search.TopDocs docs = searcher.Search(Lucene.Net.Search.NumericRangeQuery.NewInt32Range(nameof(TabHtmlText.NumId), numId, numId, true, true), 1);

                    int docId = docs.ScoreDocs.First().Doc;

                    QueryScorer scorer = new QueryScorer(new QueryParser(LuceneVersion.LUCENE_48, nameof(TabHtmlText.Html), analyzer).Parse(pattern));
                    Highlighter highlighter = new Highlighter(new SimpleHTMLFormatter("<span style=\"background-color: yellow\">", "</span>"), scorer)
                    {
                        TextFragmenter = new NullFragmenter()
                    };

                    using (TokenStream stream = TokenSources.GetAnyTokenStream(reader, docId, nameof(TabHtmlText.Html), analyzer))
                    {
                        return highlighter.GetBestFragment(stream, html);
                    }
                }
            }
            return html;
        }

        private string ReplaceLinks(string html, int numId)
        {
            IEnumerable<string> tabMapIds = RegexGroup1(html, "href=\"text:([^\"#]+)(#[^\"]+)?\"");

            Query bookIdQuery = new Query(nameof(TabMap))
                .Select(nameof(TabMap.BookId))
                .Where(nameof(TabMap.NumId), numId);
            Query query = new Query(nameof(TabMap))
                .Select(nameof(TabMap.Id))
                .Select(nameof(TabMap.NumId))
                .Where(nameof(TabMap.BookId), "=", bookIdQuery)
                .WhereIn(nameof(TabMap.Id), tabMapIds);
            IDictionary<string, int> idToNumId = Query<TabMap>(query).ToDictionary(row => row.Id, row => row.NumId);

            return Regex.Replace(html, "href=\"([^:]+):([^\"]+)\"", delegate (Match m)
            {
                StringBuilder builder = new StringBuilder("href=\"");
                if (m.Groups[1].Value == "text")
                {
                    string[] splitId = m.Groups[2].Value.Split(new char[] { '#' });
                    if (idToNumId.TryGetValue(splitId[0], out int mappedNumId))
                    {
                        builder.Append(mappedNumId.ToString());
                        builder.Append('.');
                        builder.Append(LinkType.html.ToString());
                        if (splitId.Length > 1)
                        {
                            builder.Append('#');
                            builder.Append(splitId[1]);
                        }
                    }
                    else
                    {
                        Log.Warn("Could not map id: " + m.Groups[2].Value);
                    }
                }
                else
                {
                    builder.Append(m.Groups[2].Value);
                }
                builder.Append('\"');
                return builder.ToString();
            });
        }

        /// <summary>
        /// Scans the HTML for images and writes them to the file system.
        /// </summary>
        private void DumpImages(String html, DirectoryInfo htmlFolder)
        {
            IEnumerable<string> filenames = RegexGroup1(html, "src=\"([^\"]+)\"");
            Query query = new Query(nameof(TabGUIBitmaps))
                .WhereIn(nameof(TabGUIBitmaps.Filename), filenames);
            List<TabGUIBitmaps> bitmaps = Query<TabGUIBitmaps>(query);
            foreach (TabGUIBitmaps bitmap in bitmaps)
            {
                File.WriteAllBytes(Path.Combine(htmlFolder.FullName, bitmap.Filename), bitmap.Image);
            }
        }

        public Task<byte[]> ExternalFile(string name)
        {
            switch (Path.GetExtension(name))
            {
                case ".mp3":
                    return Task.FromResult(FindMp3(name.ToLower()));
                case ".pdf":
                    return Task.FromResult(FindPdf(name));
                default:
                    return null;
            }
        }

        private byte[] FindMp3(string filename)
        {
            FileInfo dbmedia = _bookFile.Directory.GetFile("dbmedia.sqlite3");
            if (!dbmedia.Exists)
            {
                return null;
            }
            Query query = new Query(nameof(TabDudenbibMedia))
                .Select(nameof(TabDudenbibMedia.Media))
                .Where(nameof(TabDudenbibMedia.Filename), filename);
            return FindWithQuery<TabDudenbibMedia>(query, dbmedia.FullName)?.Media;
        }

        private byte[] FindPdf(string filename)
        {
            Query query = new Query(nameof(TabExternFiles))
                .Select(nameof(TabExternFiles.Content))
                .Where(nameof(TabExternFiles.Filename), filename);
            return FindWithQuery<TabExternFiles>(query)?.Content;
        }

        public bool Has(ViewType view)
        {
            switch (view)
            {
                case ViewType.Toc:
                    return true;
                case ViewType.Index:
                    return true;
                case ViewType.Search:
                    return true;
                case ViewType.Images:
                    return true;
            }
            return false;
        }

        private IEnumerable<string> RegexGroup1(string input, string pattern)
        {
            return Regex.Matches(input, pattern).Cast<Match>().Select(match => match.Groups[1].Value).Distinct();
        }

        private T FindWithQuery<T>(Query query, string databasePath = null) where T : new()
        {
            using (SQLiteConnection connection = CreateConnection(databasePath))
            {
                SqlResult result = new SqliteCompiler().Compile(query);
                return connection.FindWithQuery<T>(result.Sql, result.Bindings.ToArray());
            }
        }

        private List<T> Query<T>(Query query, string databasePath = null) where T : new()
        {
            using (SQLiteConnection connection = CreateConnection(databasePath))
            {
                SqlResult result = new SqliteCompiler().Compile(query);
                return connection.Query<T>(result.Sql, result.Bindings.ToArray());
            }
        }

        private SQLiteConnection CreateConnection(string databasePath = null)
        {
            SQLiteConnection connection = new SQLiteConnection(databasePath ?? _bookFile.FullName);
            raw.sqlite3_create_function(connection.Handle, nameof(Regexp), 2, null, Regexp);
            return connection;
        }

        private void Regexp(sqlite3_context ctx, object user_data, sqlite3_value[] args)
        {
            bool IsMatch = Regex.IsMatch(raw.sqlite3_value_text(args[1]).utf8_to_string(), raw.sqlite3_value_text(args[0]).utf8_to_string(), RegexOptions.IgnoreCase);
            raw.sqlite3_result_int(ctx, Convert.ToInt32(IsMatch));
        }
    }
}
