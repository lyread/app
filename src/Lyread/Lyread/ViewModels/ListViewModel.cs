using System;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Forms;

namespace Lyread.ViewModels
{
    public class ListViewModel : BaseViewModel
    {
        private bool _isRefreshing;

        public bool IsRefreshing
        {
            get { return _isRefreshing; }
            set { SetProperty(ref _isRefreshing, value); }
        }

        protected ICommand CreateRefreshCommand(Action execute)
        {
            return new Command(async () =>
            {
                IsBusy = true;
                await Task.Run(execute);
                IsBusy = false;
            });
        }
    }
}