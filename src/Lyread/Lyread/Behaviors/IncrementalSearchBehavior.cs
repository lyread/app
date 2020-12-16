using System;
using System.Reactive.Linq;
using System.Threading;
using Xamarin.Forms;

namespace Lyread.Behaviors
{
    class IncrementalSearchBehavior : Behavior<SearchBar>
    {
        private IDisposable _subscription;

        protected override void OnAttachedTo(SearchBar searchBar)
        {
            _subscription = Observable.FromEventPattern<TextChangedEventArgs>(
                    handler => searchBar.TextChanged += handler, handler => searchBar.TextChanged -= handler)
                .Select(pattern => pattern.EventArgs.NewTextValue)
                .DistinctUntilChanged()
                .Throttle(TimeSpan.FromMilliseconds(500))
                .ObserveOn(SynchronizationContext.Current)
                .Subscribe(text => Device.BeginInvokeOnMainThread(() => { searchBar.SearchCommand?.Execute(text); }));
        }

        protected override void OnDetachingFrom(SearchBar searchBar)
        {
            _subscription.Dispose();
        }
    }
}