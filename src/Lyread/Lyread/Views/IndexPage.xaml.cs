using Book.Item;
using System;
using Xamarin.Forms;

namespace Lyread.Views
{
    public partial class IndexPage : ContentPage
    {
        public IndexPage(IBookItem book)
        {
            InitializeComponent();
            IndexViewModel.Book = book;
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            IndexViewModel.IsBusy |= IndexViewModel.IndexItems.Count == 0;
        }

        private void Toggle_Clicked(object sender, EventArgs e)
        {
            IndexViewModel.IsBusy |= CategoryView.IsVisible;
            CategoryView.IsVisible ^= true;
            IndexViewModel.CategoryItemsChanged();
        }
    }
}
