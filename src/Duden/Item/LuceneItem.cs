using Book.Item;
using Duden.Table;
using Lucene.Net.Analysis;
using Lucene.Net.Analysis.Standard;
using Lucene.Net.Documents;
using Lucene.Net.Index;
using Lucene.Net.Store;
using Lucene.Net.Util;
using SQLite;
using SqlKata;
using SqlKata.Compilers;
using System;
using System.IO;

namespace Duden.Item
{
    public class LuceneItem : IJobItem, IProgress<double>
    {
        public int Id => Title.GetHashCode();
        public string Title => _file.Name;

        public event EventHandler<ProgressEventArgs> ProgressChanged;

        private FileInfo _file;

        public LuceneItem(FileInfo file)
        {
            _file = file;
        }

        [Obsolete]
        public bool Run()
        {
            using (Analyzer analyzer = new StandardAnalyzer(LuceneVersion.LUCENE_48))
            using (Lucene.Net.Store.Directory index = new SimpleFSDirectory(Path.ChangeExtension(_file.FullName, string.Empty)))
            using (IndexWriter writer = new IndexWriter(index, new IndexWriterConfig(LuceneVersion.LUCENE_48, analyzer)))
            using (SQLiteConnection connection = new SQLiteConnection(_file.FullName))
            {
                int position = 0, length = connection.FindWithQuery<int>(Compile(new Query(nameof(TabHtmlText)).AsCount()));
                foreach (TabHtmlText row in connection.DeferredQuery<TabHtmlText>(Compile(new Query(nameof(TabHtmlText)))))
                {
                    Document doc = new Document
                    {
                        new Int32Field(nameof(TabHtmlText.NumId), row.NumId, Field.Store.YES),
                        new StringField(nameof(TabHtmlText.Lemma), row.Lemma, Field.Store.YES),
                        new TextField(nameof(TabHtmlText.Html), row.UncompressedHtml, Field.Store.NO)
                    };
                    writer.AddDocument(doc);

                    Report((double)++position / length);
                }
            }
            return true;
        }

        private string Compile(Query query)
        {
            return new SqliteCompiler().Compile(query).Sql;
        }

        public void Report(double progress)
        {
            ProgressChanged.Invoke(this, new ProgressEventArgs(progress));
        }
    }
}
