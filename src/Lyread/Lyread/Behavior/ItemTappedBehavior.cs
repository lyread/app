using System;
using System.Windows.Input;
using Xamarin.Forms;

namespace Lyread
{
    class ItemTappedBehavior : Behavior<ListView>
    {
        public static readonly BindableProperty CommandProperty = BindableProperty.Create(nameof(Command), typeof(ICommand), typeof(ItemTappedBehavior), null);

        public ICommand Command
        {
            get { return (ICommand)GetValue(CommandProperty); }
            set { SetValue(CommandProperty, value); }
        }

        public ListView _listView { get; private set; }

        protected override void OnAttachedTo(ListView listView)
        {
            _listView = listView;
            listView.BindingContextChanged += ListView_BindingContextChanged;
            listView.ItemSelected += ListView_ItemSelected;
        }

        protected override void OnDetachingFrom(ListView listView)
        {
            listView.BindingContextChanged -= ListView_BindingContextChanged;
            listView.ItemSelected -= ListView_ItemSelected;
            _listView = null;
        }

        private void ListView_BindingContextChanged(object sender, EventArgs e)
        {
            OnBindingContextChanged();
        }

        private void ListView_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (Command == null)
            {
                return;
            }
            if (Command.CanExecute(e.SelectedItem))
            {
                Command.Execute(e.SelectedItem);
            }
        }

        protected override void OnBindingContextChanged()
        {
            BindingContext = _listView.BindingContext;
        }
    }
}
