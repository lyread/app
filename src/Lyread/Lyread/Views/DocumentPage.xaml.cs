using Book.Item;
using System;
using Xamarin.Forms;

namespace Lyread.Views
{
    public partial class DocumentPage : ContentPage
    {
        public DocumentPage(IBookItem book, int id, string pattern = null)
        {
            InitializeComponent();
            DocumentViewModel.Book = book;
            DocumentViewModel.Id = id;
            DocumentViewModel.Pattern = pattern;
        }

        protected override void OnAppearing()
        {
            webView.Source = new UrlWebViewSource { Url = DocumentViewModel.DocumentUri() };
        }

        protected override bool OnBackButtonPressed()
        {
            if (webView.CanGoBack)
            {
                webView.GoBack();
                return true;
            }
            return base.OnBackButtonPressed();
        }

        private async void WebView_Navigating(object sender, WebNavigatingEventArgs e)
        {
            e.Cancel = await DocumentViewModel.CancelNavigation(new Uri(e.Url));
        }
    }
}
