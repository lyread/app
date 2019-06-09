using ICSharpCode.SharpZipLib.Zip;
using System.IO;

namespace Book.Util
{
    public static class ZipInputStreamExtension
    {
        public static void UnpackAll(this ZipInputStream inStream, DirectoryInfo folder)
        {
            ZipEntry entry;
            while ((entry = inStream.GetNextEntry()) != null)
            {
                if (entry.IsDirectory)
                {
                    folder.CreateSubdirectory(entry.Name);
                }
                else if (entry.IsFile)
                {
                    FileInfo file = new FileInfo(Path.Combine(folder.FullName, entry.Name));
                    Directory.CreateDirectory(file.DirectoryName);
                    using (Stream outStream = file.OpenWrite())
                    {
                        inStream.CopyTo(outStream);
                    }
                }
            }
        }
    }
}
