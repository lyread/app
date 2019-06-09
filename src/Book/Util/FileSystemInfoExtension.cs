using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Book.Util
{
    public static class FileSystemInfoExtension
    {
        public static bool SubdirectoryExists(this DirectoryInfo directory, string name)
        {
            return Directory.Exists(Path.Combine(directory.FullName, name));
        }

        public static bool SubdirectoryExistsIgnoreCase(this DirectoryInfo directory, string name)
        {
            return directory.SubdirectoryExists(name) || directory.EnumerateDirectories().Any(EqualsIgnoreCase<DirectoryInfo>(name));
        }

        public static DirectoryInfo GetSubdirectory(this DirectoryInfo directory, string name)
        {
            return new DirectoryInfo(Path.Combine(directory.FullName, name));
        }

        public static DirectoryInfo GetSubdirectoryIgnoreCase(this DirectoryInfo directory, string name)
        {
            DirectoryInfo subdirectory = directory.GetSubdirectory(name);
            return subdirectory.Exists ? subdirectory : directory.EnumerateDirectories().FirstOrDefault(EqualsIgnoreCase<DirectoryInfo>(name)) ?? subdirectory;
        }

        public static bool FileExists(this DirectoryInfo directory, string name)
        {
            return File.Exists(Path.Combine(directory.FullName, name));
        }

        public static bool FileExistsIgnoreCase(this DirectoryInfo directory, string name)
        {
            return directory.FileExists(name) || directory.EnumerateFiles("*" + Path.GetExtension(name)).Any(EqualsIgnoreCase<FileInfo>(name));
        }

        public static FileInfo GetFile(this DirectoryInfo directory, string name)
        {
            return new FileInfo(Path.Combine(directory.FullName, name));
        }

        public static FileInfo GetFileIgnoreCase(this DirectoryInfo directory, string name)
        {
            FileInfo file = directory.GetFile(name);
            return file.Exists ? file : directory.EnumerateFiles("*" + Path.GetExtension(name)).FirstOrDefault(EqualsIgnoreCase<FileInfo>(name)) ?? file;
        }

        private static Func<T, bool> EqualsIgnoreCase<T>(string name) where T : FileSystemInfo
        {
            return info => string.Equals(info.Name, name, StringComparison.InvariantCultureIgnoreCase);
        }

        public static bool IsDirectory(this FileSystemInfo info)
        {
            return info != null && info.Exists && (info.Attributes & FileAttributes.Directory) == FileAttributes.Directory;
        }

        public static bool IsVisible(this FileSystemInfo info)
        {
            return info != null && info.Exists && (info.Attributes & FileAttributes.Hidden) != FileAttributes.Hidden;
        }

        public static IEnumerable<string> ReadAllLines(this FileInfo file, Encoding encoding)
        {
            using (StreamReader reader = new StreamReader(file.OpenRead(), encoding))
            {
                string line;
                while ((line = reader.ReadLine()) != null)
                {
                    yield return line;
                }
            }
        }
    }
}