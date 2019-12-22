using Lyread.Models;
using Lyread.Services;
using System;
using System.Collections.Generic;
using System.Text;
using Xamarin.Forms;
using System.Linq;

namespace Lyread
{
    public class MonkeySearchHandler : SearchHandler
    {
        public IDataStore<Item> DataStore => DependencyService.Get<IDataStore<Item>>();

        protected async override void OnQueryChanged(string oldValue, string newValue)
        {
            base.OnQueryChanged(oldValue, newValue);

            if (string.IsNullOrWhiteSpace(newValue))
            {
                ItemsSource = null;
            }
            else
            {
                ItemsSource = (await DataStore.GetItemsAsync(true))
                    .Where(item => item.Text.ToLower().Contains(newValue.ToLower()))
                    .ToList<Item>();
                //ItemsSource = MonkeyData.Monkeys
                //    .Where(monkey => monkey.Name.ToLower().Contains(newValue.ToLower()))
                //    .ToList<Animal>();
            }
        }

        protected override async void OnItemSelected(object item)
        {
            base.OnItemSelected(item);

            // Note: strings will be URL encoded for navigation (e.g. "Blue Monkey" becomes "Blue%20Monkey"). Therefore, decode at the receiver.
            await (App.Current.MainPage as Xamarin.Forms.Shell).GoToAsync($"monkeydetails?name={((Item)item).Text}");
        }
    }
}
