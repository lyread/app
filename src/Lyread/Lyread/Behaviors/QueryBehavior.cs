using Lucene.Net.Analysis;
using Lucene.Net.Analysis.Standard;
using Lucene.Net.QueryParsers.Classic;
using Lucene.Net.Util;
using Xamarin.Forms;

namespace Lyread.Behaviors
{
    class QueryBehavior : Behavior<SearchBar>
    {
        protected override void OnAttachedTo(SearchBar searchBar)
        {
            searchBar.TextChanged += SearchBar_TextChanged;
        }

        protected override void OnDetachingFrom(SearchBar searchBar)
        {
            searchBar.TextChanged -= SearchBar_TextChanged;
        }

        private void SearchBar_TextChanged(object sender, TextChangedEventArgs e)
        {
            ((SearchBar)sender).TextColor = IsValid(e.NewTextValue) ? Color.Black : Color.Red;
        }

        public static bool IsValid(string query)
        {
            try
            {
                using (Analyzer analyzer = new StandardAnalyzer(LuceneVersion.LUCENE_48))
                {
                    new QueryParser(LuceneVersion.LUCENE_48, string.Empty, analyzer).Parse(query);
                }
            }
            catch (ParseException)
            {
                return false;
            }
            return true;
        }
    }
}
