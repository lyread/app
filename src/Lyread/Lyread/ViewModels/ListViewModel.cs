using System;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Forms;

namespace Lyread.ViewModels
{
    public class ListViewModel : BaseViewModel
    {
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
