using Book.Util;
using Directmedia.Decoder;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Directmedia.Util
{
    /// <summary>
    /// Loads tables from .tab files.
    /// </summary>
    public class TableUtil
    {
        public IEnumerable<string> LoadTables(DirectoryInfo dataFolder)
        {
            return dataFolder.EnumerateFiles("tabelle*.tab")
                .Select(file => LoadTable(file));
        }

        private static string LoadTable(FileInfo file)
        {
            return string.Join("\n", file.ReadAllLines(new TableEncoding())
                .Where(line => !string.IsNullOrWhiteSpace(line))
                .Select(line => line.Replace('\t', ';')));
        }
    }
}