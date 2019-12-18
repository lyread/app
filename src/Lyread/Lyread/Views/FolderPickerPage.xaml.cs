using Book;
using Xamarin.Forms;

namespace Lyread
{
    public partial class FolderPickerPage : ContentPage
    {
        public FolderPickerPage(IPublisher publisher)
        {
            InitializeComponent();
            FolderPickerViewModel.Publisher = publisher;
        }
    }
}