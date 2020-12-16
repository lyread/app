using SQLite;
using System.Net;

namespace Duden.Table
{
    class TabBookDescription
    {
        public int BookId { get; set; }
        public bool Available { get; set; }
        [MaxLength(40)] public string Desc { get; set; }
        public int Version { get; set; }
        [MaxLength(400)] public string Copyright { get; set; }
        [MaxLength(40)] public string BaseImage { get; set; } // 57_BaseImage_a.png in TabGUIBitmaps
        [MaxLength(20)] public string AdditionsId { get; set; } // TabMap.Id
        [MaxLength(200)] public string Homepage { get; set; }
        public bool HasFields { get; set; } // records in TabFieldsTopLevel, TabFieldValues
        public int NumArticles { get; set; }

        [Ignore] public string Title => WebUtility.HtmlDecode(Desc);
    }
}