using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Xml.Linq;
using Book.Util;
using Epub.Extensions;
using Epub.Format;

namespace Epub.Extensions
{
    public static class ZipArchiveExt
    {
        public static void CreateEntry(this ZipArchive archive, string file, string content)
        {
            var data = Constants.DefaultEncoding.GetBytes(content);
            archive.CreateEntry(file, data);
        }

        public static void CreateEntry(this ZipArchive archive, string file, byte[] data)
        {
            var entry = archive.CreateEntry(file);
            using (var stream = entry.Open())
            {
                stream.Write(data, 0, data.Length);
            }
        }

        /// <summary>
        /// ZIP's are slash-side sensitive and ZIP's created on Windows and Linux can contain their own variation.
        /// </summary>
        public static ZipArchiveEntry GetEntryImproved(this ZipArchive archive, string entryName)
        {
            var entry = archive.TryGetEntryImproved(entryName);
            if (entry == null)
            {
                throw new EpubParseException($"{entryName} file not found in archive.");
            }
            return entry;
        }

        public static ZipArchiveEntry TryGetEntryImproved(this ZipArchive archive, string entryName)
        {
            // The zip specs says all file paths in an archive should be relative.
            // That is, they should not include a leading '/' character.
            // Therefore for performance reasons to maximize a match on first attempt
            // exclude it initially and try with a leading slash in the later attempts.
            if (entryName.StartsWith("/") || entryName.StartsWith("\\"))
            {
                entryName = entryName.Substring(1);
            }

            var entry = archive.GetEntry(entryName);

            if (entry == null)
            {
                var namesToTry = new List<string>();

                namesToTry.Add("/" + entryName);
                namesToTry.Add("\\" + entryName);

                // I've seen epubs, where manifest href's are url encoded, but files in archive not.
                namesToTry.Add(Uri.UnescapeDataString(entryName));

                // Such epubs aren't common, but zip archives created on windows uses backslashes.
                // That could happen if an epub is re-archived manually.
                foreach (var newName in new[]
                {
                    entryName.Replace(@"\", "/"),
                    entryName.Replace("/", @"\")
                }.Where(newName => newName != entryName))
                {
                    namesToTry.Add(newName);
                    namesToTry.Add(Uri.UnescapeDataString(newName));
                }

                foreach (var newName in namesToTry)
                {
                    entry = archive.GetEntry(newName);
                    if (entry != null)
                    {
                        break;
                    }
                }
            }

            return entry;
        }

        public static byte[] LoadBytes(this DirectoryInfo folder, string entryName)
        {
            FileInfo file = folder.GetFile(entryName);
            using (var stream = file.OpenRead())
            {
                var data = stream.ReadToEnd();
                return data;
            }
        }

        public static string LoadText(this DirectoryInfo folder, string entryName)
        {
            var data = folder.LoadBytes(entryName).TrimEncodingPreamble();
            var str = Constants.DefaultEncoding.GetString(data, 0, data.Length);
            return str;
        }

        public static XDocument LoadXml(this DirectoryInfo folder, string entryName)
        {
            FileInfo file = folder.GetFile(entryName);
            using (var stream = file.OpenRead())
            {
                var xml = XDocument.Load(stream);
                return xml;
            }
        }

        public static XDocument LoadHtml(this DirectoryInfo folder, string entryName)
        {
            var html = folder.LoadText(entryName);
            return XDocument.Parse(html);
        }
    }
}
