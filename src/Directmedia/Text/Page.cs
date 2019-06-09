namespace Directmedia.Text
{
    public class Page
    {
        public int Pagenumber { get; }
        public int AtomCount { get; } // number of tokens
        public int WordCount { get; }
        public byte[] Data { get; }

        public Page(int pagenumber, int atomCount, int wordCount, byte[] data)
        {
            Pagenumber = pagenumber;
            AtomCount = atomCount;
            WordCount = wordCount;
            Data = data;
        }
    }
}