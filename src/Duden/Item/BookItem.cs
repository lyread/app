﻿using Book;
using Book.Item;
using Book.Util;
using Duden.Table;
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
                query.WhereIn("TabBookDescription.BookId", categories.Select(item => item.Id.ToString()));
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
            Query query = new Query(nameof(TabBookDescription))
                .Select(nameof(TabBookDescription.BookId), nameof(TabBookDescription.Desc))
                .OrderBy(nameof(TabBookDescription.BookId));
            return Task.FromResult(Query<CategoryItem>(query).AsEnumerable<ICategoryItem>());
        }

        public Task<IEnumerable<IImageItem>> QueryImages()
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

        public Task<IEnumerable<ISearchItem>> Search(string query, int page)
        {
            return Task.FromResult(Enumerable.Empty<ISearchItem>());
        }

        public Task<bool> Html(int numId, DirectoryInfo folder, string highlight)
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
                writer.Write(ReplaceLinks(html, numId));
            }
            return Task.FromResult(true);
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
                    return false;
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
            bool IsMatch = Regex.IsMatch(raw.sqlite3_value_text(args[1]), raw.sqlite3_value_text(args[0]), RegexOptions.IgnoreCase);
            raw.sqlite3_result_int(ctx, Convert.ToInt32(IsMatch));
        }
    }
}