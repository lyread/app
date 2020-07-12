using Book.Item;
using Lyread.Annotations;
using System;
using System.ComponentModel;
using System.Linq;
using System.Reactive.Linq;
using System.Runtime.CompilerServices;
using Xamarin.Forms;

namespace Lyread.Models
{
    public class ProgressJobItem : IJobItem, INotifyPropertyChanged
    {
        private IJobItem _wrappedJobItem;

        public ProgressJobItem(IJobItem wrappedJobItem)
        {
            _wrappedJobItem = wrappedJobItem;
        }

        public int Id => Title.GetHashCode();
        public string Title => _wrappedJobItem.Title;

        private double _progress;
        public double Progress { get { return _progress; } set { _progress = value; OnPropertyChanged(); } }

        private Color _color = Color.Black;
        public Color Color { get { return _color; } set { _color = value; OnPropertyChanged(); } }

        public bool Run()
        {
            using (Observable.FromEventPattern<ProgressEventArgs>(handler => _wrappedJobItem.ProgressChanged += handler, handler => _wrappedJobItem.ProgressChanged -= handler)
                .Sample(TimeSpan.FromMilliseconds(250))
                .Select(pattern => pattern.EventArgs.Progress)
                .Finally(() => Device.BeginInvokeOnMainThread(() => { Progress = 1; }))
                .Subscribe(progress => Device.BeginInvokeOnMainThread(() => { Progress = progress; })))
            {
                bool success = _wrappedJobItem.Run();
                Device.BeginInvokeOnMainThread(() => { Color = success ? Color.Green : Color.Red; });
                return success;
            }
        }

        public event EventHandler<ProgressEventArgs> ProgressChanged;

        public event PropertyChangedEventHandler PropertyChanged;

        [NotifyPropertyChangedInvocator]
        public virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
