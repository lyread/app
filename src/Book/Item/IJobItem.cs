using System;
using System.Threading.Tasks;

namespace Book.Item
{
    public interface IJobItem : IItem
    {
        event EventHandler<ProgressEventArgs> ProgressChanged;

        Task<bool> Run();
    }

    public class ProgressEventArgs : EventArgs
    {
        public double Progress { get; } // 0-1

        public ProgressEventArgs(double progress)
        {
            Progress = progress;
        }
    }
}
