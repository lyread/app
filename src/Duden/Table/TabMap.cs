using SQLite;

namespace Duden.Table
{
    class TabMap
    {
        public int BookId { get; set; }
        public string Id { get; set; }
        [PrimaryKey] public int NumId { get; set; }
        public int Type { get; set; }
    }
}