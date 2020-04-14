using Book.Item;
using Book.Util;
using Directmedia.Item;
using NLog;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Directmedia.Util
{
    /// <summary>
    /// Loads images from .lib files or directly.
    /// </summary>
    public class ImageUtil
    {
        private static readonly ILogger Log = LogManager.GetCurrentClassLogger();
        private static readonly int MaxLibFiles = 21;

        public static IEnumerable<IImageItem> LoadImages(DirectoryInfo imagesFolder, bool includeHidden)
        {
            if (imagesFolder.FileExistsIgnoreCase("images.lib"))
            {
                return LoadAllLibs(imagesFolder).Where(i => includeHidden || !i.Hidden);
            }
            else
            {
                return LoadAllFiles(imagesFolder, includeHidden);
            }
        }

        /// <summary>
        /// Loads images from files: IMAGES.LIB, WM01.LIB, ..., WM20.LIB
        /// TODO load 'scribal abbreviations' from sigel.lib
        /// </summary>
        private static IEnumerable<ImageLibItem> LoadAllLibs(DirectoryInfo imagesFolder)
        {
            return Enumerable.Range(0, MaxLibFiles)
                .Select(i => imagesFolder.GetFileIgnoreCase(i == 0 ? "images.lib" : string.Format("wm{0:00}.lib", i)))
                .TakeWhile(file => file.Exists)
                .SelectMany(file => LoadLib(file));
        }

        /// <summary>
        /// Loads a .lib file.
        /// </summary>
        private static IEnumerable<ImageLibItem> LoadLib(FileInfo libFile)
        {
            using (BinaryReader reader = new BinaryReader(libFile.OpenRead()))
            {
                reader.ReadDkiMagic();
                int imageCount = reader.ReadInt32();
                if (imageCount >= 200000)
                {
                    throw new Exception("too many images: " + imageCount);
                }
                int textOffset = reader.ReadInt32(); // beginning of text
                reader.ReadBytes(16);
                for (int i = 0; i < imageCount; i++)
                {
                    yield return CreateLibItem(reader, textOffset, libFile);
                }
            }
        }

        private static ImageLibItem CreateLibItem(BinaryReader reader, int textOffset, FileInfo libFile)
        {
            string filename = ReadLibId(reader);
            bool hidden = reader.ReadByte() != 0;
            int pagenumber = reader.ReadInt32() >> 4; // in text
            ImageLibOffset title = ReadLibLocation(reader, textOffset);
            ImageLibOffset description = ReadLibLocation(reader, textOffset);
            ImageLibOffset thumbnail = null, huge = null;
            for (int i = 0; i < 5; i++)
            {
                int width = reader.ReadUInt16();
                int height = reader.ReadUInt16();
                ImageLibOffset image = ReadLibLocation(reader, 0);
                reader.ReadByte(); // type: jpeg (2), png (3, 10)
                if (width > 0 && height > 0)
                {
                    if (i < 3)
                    {
                        switch (i)
                        {
                            case 0:
                                thumbnail = huge = image;
                                break;
                            case 1:
                                thumbnail = huge = image;
                                break;
                            case 2:
                                huge = image;
                                break;
                        }
                    }
                    else
                    {
                        Log.Warn("More than three pictures.");
                    }
                }
            }
            return new ImageLibItem(filename, hidden, title, description, thumbnail, huge, libFile);
        }

        private static string ReadLibId(BinaryReader reader)
        {
            byte length = reader.ReadByte();
            byte[] name = reader.ReadBytes(8); // always 8 bytes
            return Encoding.GetEncoding(1252).GetString(name, 0, length);
        }

        private static ImageLibOffset ReadLibLocation(BinaryReader reader, int additionalOffset)
        {
            int offset = reader.ReadInt32();
            int length = reader.ReadInt32();
            return length > 0 ? new ImageLibOffset(additionalOffset + offset, length) : null;
        }

        private static IEnumerable<ImageFileItem> LoadAllFiles(DirectoryInfo imagesFolder, bool includeHidden)
        {
            IEnumerable<ImageFileItem> images = Enumerable.Empty<ImageFileItem>();
            DirectoryInfo thumbnailFolder = imagesFolder.GetSubdirectory(NameOf(ImageSize.Small));
            if (thumbnailFolder.Exists)
            {
                images = images.Concat(LoadFiles(thumbnailFolder, false));
            }
            if (includeHidden)
            {
                images = images.Concat(LoadFiles(imagesFolder, true));
            }
            return images;
        }

        private static IEnumerable<ImageFileItem> LoadFiles(DirectoryInfo folder, bool hidden)
        {
            return folder.EnumerateFiles().Select((file, i) => new ImageFileItem(i, hidden, file));
        }

        private static string NameOf(ImageSize imageSize)
        {
            return ((int)imageSize).ToString();
        }
    }
}