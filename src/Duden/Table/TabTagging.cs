namespace Duden.Table
{
    class TabTagging
    {
        public int ArtId { get; set; }
        public int BookId { get; set; }
        public string Created { get; set; } // date
        public byte[] Tags { get; set; }
    }
}
