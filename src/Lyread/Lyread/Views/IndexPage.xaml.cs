﻿using Book.Item;
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
            IndexViewModel.QueryIndexCommand.Execute(null);
        }

        private void ToggleCategoryView(object sender, EventArgs e)
        {
            if (!(CategoryView.IsVisible ^= true))
            {
                //IndexViewModel.OnPropertyChanged(nameof(IndexViewModel.CategoryItems));
                IndexViewModel.QueryIndexCommand.Execute(null);
            }
        }
    }
}