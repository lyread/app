using System;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Forms;

namespace Lyread.ViewModel
{
    public class ListViewModel : BaseViewModel
    {
        private bool _isRefreshing = false;
        public bool IsRefreshing
        {
            get { return _isRefreshing; }
            set
            {
                _isRefreshing = value;
                OnPropertyChanged();
            }
        }

        protected ICommand CreateRefreshCommand(Action execute)
        {
            return new Command(async () =>
            {
                IsRefreshing = true;
                await Task.Run(execute);
                IsRefreshing = false;
            });
        }
    }
}
