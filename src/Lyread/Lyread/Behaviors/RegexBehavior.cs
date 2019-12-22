using System;
using System.Text.RegularExpressions;
using Xamarin.Forms;

namespace Lyread.Behaviors
{
    class RegexBehavior : Behavior<SearchBar>
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

        public static bool IsValid(string pattern)
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
    }
}
