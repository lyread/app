using System;
using System.Reactive.Linq;
using System.Threading;
using Xamarin.Forms;

namespace Lyread
{
    public class ReactiveSearchHandler : SearchHandler
    {
        public event EventHandler<TextChangedEventArgs> TextChanged;

        public ReactiveSearchHandler()
        {
            Observable.FromEventPattern<TextChangedEventArgs>(
                    handler => TextChanged += handler, handler => TextChanged -= handler)
                .Select(pattern => pattern.EventArgs.NewTextValue)
                .DistinctUntilChanged()
                .Throttle(TimeSpan.FromMilliseconds(500))
                .ObserveOn(SynchronizationContext.Current)
                .Subscribe(newValue => Device.BeginInvokeOnMainThread(() => { Command?.Execute(newValue); }));
        }

        protected override void OnQueryChanged(string oldValue, string newValue)
        {
            TextChanged?.Invoke(this, new TextChangedEventArgs(oldValue, newValue));
        }
    }
}