using Book;
using Book.Item;
using NLog;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using Epub;
using Epub.Extensions;
using Epub.Format;
using Epub.Format.Readers;
using Epub.Misc;
using Book.Util;

namespace Epub.Item
{
    class BookItem : IBookItem
    {
        /// <summary>
        /// Read-only raw epub format structures.
        /// </summary>
        //public EpubFormat Format { get; internal set; }

        /// <summary>
        /// All files within the EPUB.
        /// </summary>
        //public EpubResources Resources { get; internal set; }

        /// <summary>
        /// EPUB format specific resources.
        /// </summary>
        //public EpubSpecialResources SpecialResources { get; internal set; }

        public byte[] CoverImage { get; internal set; }

        //public IList<EpubChapter> TableOfContents { get; internal set; }


        /// ////////////////////////////////////////////////////
        private static readonly ILogger Log = LogManager.GetCurrentClassLogger();

        private readonly DirectoryInfo _bookFolder;

        public BookItem(DirectoryInfo bookFolder)
        {
            _bookFolder = bookFolder;
        }

        public int Id => _bookFolder.Name.GetHashCode();

        public string Title
        {
            get
            {
                try
                {
                    EpubFormat format = ReadFormat();
                    return format.Opf.Metadata.Titles.FirstOrDefault() + Environment.NewLine + string.Join(", ",
                        format.Opf.Metadata.Creators.Select(creator => creator.Text));
                }
                catch (Exception)
                {
                    return null;
                }
            }
        }

        public byte[] Cover
        {
            get
            {
                try
                {
                    EpubFormat format = ReadFormat();
                    if (format == null)
                    {
                        return DefaultCover;
                    }

                    var coverPath = format.Opf.FindCoverPath();
                    if (coverPath == null)
                    {
                        return DefaultCover;
                    }

                    EpubResources resources = LoadResources(format);
                    //var coverImageFile = resources.Images.SingleOrDefault(e => e.Href == coverPath);
                    //return coverImageFile?.Content ?? DefaultCover;

                    //var path = item.Href.ToAbsolutePath(format.Paths.OpfAbsolutePath);

                    return File.ReadAllBytes(Path.Combine(_bookFolder.FullName, coverPath));
                }
                catch (Exception)
                {
                    return DefaultCover;
                }
            }
        }

        private byte[] DefaultCover
        {
            get
            {
                using (Stream inStream = GetType().Assembly.GetManifestResourceStream("Epub.cover.png"))
                using (MemoryStream outStream = new MemoryStream())
                {
                    inStream.CopyTo(outStream);
                    return outStream.ToArray();
                }
            }
        }

        public Task<ITocItem> QueryToc(string pattern, IEnumerable<ICategoryItem> categories)
        {
            //Read(_bookFile.FullName);
            //TocItem root = new TocItem(0, epub.Title);
            //AddChapters(root, epub.TableOfContents);
            //return Task.FromResult<ITocItem>(root);
            return null;
        }

        private void AddChapters(TocItem parent, IList<EpubChapter> chapters)
        {
            foreach (EpubChapter chapter in chapters)
            {
                TocItem child = new TocItem(chapter.AbsolutePath.GetHashCode(), chapter.Title);
                parent.AddChild(child);
                AddChapters(child, chapter.SubChapters);
            }
        }

        public Task<IEnumerable<IIndexItem>> QueryIndex(string pattern, IEnumerable<ICategoryItem> categories, int page)
        {
            return Task.FromResult(Enumerable.Empty<IIndexItem>());
        }

        public Task<IEnumerable<ICategoryItem>> QueryCategories()
        {
            return Task.FromResult(Enumerable.Empty<ICategoryItem>());
        }

        public Task<IEnumerable<IImageItem>> QueryImages(string pattern, int page)
        {
            //Read(_bookFile.FullName);
            //return Task.FromResult(epub.Resources.Images.Select(file => new ImageItem(Path.GetFileName(file.AbsolutePath), file.Content)).AsEnumerable<IImageItem>());
            return null;
        }

        public Task<IEnumerable<ISearchItem>> Search(string pattern, int page)
        {
            return Task.FromResult(Enumerable.Empty<ISearchItem>());
        }

        public Task<bool> Html(int id, DirectoryInfo folder, string highlight = null)
        {
            //if (id == 0) // root
            //{
            //    return Task.FromResult(false);
            //}
            //Read(_bookFile.FullName);
            //EpubTextFile file = epub.Resources.Html.First(f => f.AbsolutePath.GetHashCode() == id);
            //File.WriteAllText(Path.Combine(folder.FullName, Path.ChangeExtension(file.AbsolutePath.GetHashCode().ToString(), LinkType.html.ToString())), file.TextContent);
            //foreach (EpubTextFile css in epub.Resources.Css)
            //{
            //    string filename = Path.Combine(folder.FullName, css.AbsolutePath);
            //    Directory.CreateDirectory(Path.GetDirectoryName(filename));
            //    File.WriteAllText(filename, css.TextContent);
            //}
            //foreach (EpubByteFile image in epub.Resources.Images)
            //{
            //    string filename = Path.Combine(folder.FullName, image.AbsolutePath);
            //    Directory.CreateDirectory(Path.GetDirectoryName(filename));
            //    File.WriteAllBytes(filename, image.Content);
            //}
            return Task.FromResult(true);
        }

        public Task<byte[]> ExternalFile(string name)
        {
            throw new NotImplementedException();
        }

        public bool Has(ViewType view)
        {
            switch (view)
            {
                case ViewType.Toc:
                    return true;
                case ViewType.Index:
                    return false;
                case ViewType.Search:
                    return false;
                case ViewType.Images:
                    return true;
            }

            return false;
        }

        ///////////////////////////////////////

        public EpubFormat ReadFormat()
        {
            var format = new EpubFormat {Ocf = OcfReader.Read(_bookFolder.LoadXml(Constants.OcfPath))};

            format.Paths.OcfAbsolutePath = Constants.OcfPath;

            format.Paths.OpfAbsolutePath = format.Ocf.RootFilePath;
            if (format.Paths.OpfAbsolutePath == null)
            {
                throw new EpubParseException("Epub OCF doesn't specify a root file.");
            }

            format.Opf = OpfReader.Read(_bookFolder.LoadXml(format.Paths.OpfAbsolutePath));

            //var navPath = format.Opf.FindNavPath();
            //if (navPath != null)
            //{
            //    format.Paths.NavAbsolutePath = navPath.ToAbsolutePath(format.Paths.OpfAbsolutePath);
            //    format.Nav = NavReader.Read(_bookFolder.LoadHtml(format.Paths.NavAbsolutePath));
            //}

            //var ncxPath = format.Opf.FindNcxPath();
            //if (ncxPath != null)
            //{
            //    format.Paths.NcxAbsolutePath = ncxPath.ToAbsolutePath(format.Paths.OpfAbsolutePath);
            //    format.Ncx = NcxReader.Read(_bookFolder.LoadXml(format.Paths.NcxAbsolutePath));
            //}

            //Resources = LoadResources(archive);
            //SpecialResources = LoadSpecialResources(archive);
            //CoverImage = LoadCoverImage();
            //TableOfContents = LoadChapters();

            return format;
        }

        private List<EpubChapter> LoadChapters()
        {
            EpubFormat format = ReadFormat();
            if (format.Nav != null)
            {
                var tocNav = format.Nav.Body.Navs.SingleOrDefault(e => e.Type == NavNav.Attributes.TypeValues.Toc);
                if (tocNav != null)
                {
                    return LoadChaptersFromNav(format.Paths.NavAbsolutePath, tocNav.Dom);
                }
            }

            if (format.Ncx != null)
            {
                return LoadChaptersFromNcx(format.Paths.NcxAbsolutePath, format.Ncx.NavMap.NavPoints);
            }

            return new List<EpubChapter>();
        }

        private static List<EpubChapter> LoadChaptersFromNav(string navAbsolutePath, XElement element,
            EpubChapter parentChapter = null)
        {
            if (element == null) throw new ArgumentNullException(nameof(element));
            var ns = element.Name.Namespace;

            var result = new List<EpubChapter>();
            var previous = parentChapter;

            var ol = element.Element(ns + NavElements.Ol);
            if (ol == null)
                return result;

            foreach (var li in ol.Elements(ns + NavElements.Li))
            {
                var chapter = new EpubChapter
                {
                    Parent = parentChapter,
                    Previous = previous
                };

                if (previous != null)
                    previous.Next = chapter;

                var link = li.Element(ns + NavElements.A);
                if (link != null)
                {
                    var id = link.Attribute("id")?.Value;
                    if (id != null)
                    {
                        chapter.Id = id;
                    }

                    var url = link.Attribute("href")?.Value;
                    if (url != null)
                    {
                        var href = new Href(url);
                        chapter.RelativePath = href.Path;
                        chapter.HashLocation = href.HashLocation;
                        chapter.AbsolutePath = chapter.RelativePath.ToAbsolutePath(navAbsolutePath);
                    }

                    var titleTextElement = li.Descendants().FirstOrDefault(e => !string.IsNullOrWhiteSpace(e.Value));
                    if (titleTextElement != null)
                    {
                        chapter.Title = titleTextElement.Value;
                    }

                    if (li.Element(ns + NavElements.Ol) != null)
                    {
                        chapter.SubChapters = LoadChaptersFromNav(navAbsolutePath, li, chapter);
                    }

                    result.Add(chapter);

                    previous = chapter.SubChapters.Any() ? chapter.SubChapters.Last() : chapter;
                }
            }

            return result;
        }

        private static List<EpubChapter> LoadChaptersFromNcx(string ncxAbsolutePath,
            IEnumerable<NcxNavPoint> navigationPoints, EpubChapter parentChapter = null)
        {
            var result = new List<EpubChapter>();
            var previous = parentChapter;

            foreach (var navigationPoint in navigationPoints)
            {
                var chapter = new EpubChapter
                {
                    Title = navigationPoint.NavLabelText,
                    Parent = parentChapter,
                    Previous = previous
                };

                if (previous != null)
                    previous.Next = chapter;

                var href = new Href(navigationPoint.ContentSrc);
                chapter.RelativePath = href.Path;
                chapter.AbsolutePath = href.Path.ToAbsolutePath(ncxAbsolutePath);
                chapter.HashLocation = href.HashLocation;
                chapter.SubChapters = LoadChaptersFromNcx(ncxAbsolutePath, navigationPoint.NavPoints, chapter);
                result.Add(chapter);

                previous = chapter.SubChapters.Any() ? chapter.SubChapters.Last() : chapter;
            }

            return result;
        }

        private EpubResources LoadResources(EpubFormat format)
        {
            var resources = new EpubResources();

            foreach (var item in format.Opf.Manifest.Items)
            {
                var path = item.Href.ToAbsolutePath(format.Paths.OpfAbsolutePath);
                FileInfo entry = _bookFolder.GetFile("." + path);

                if (entry == null)
                {
                    throw new EpubParseException($"file {path} not found in archive.");
                }

                if (entry.Length > int.MaxValue)
                {
                    throw new EpubParseException($"file {path} is bigger than 2 Gb.");
                }

                var href = item.Href;
                var mimeType = item.MediaType;

                EpubContentType contentType;
                contentType = ContentType.MimeTypeToContentType.TryGetValue(mimeType, out contentType)
                    ? contentType
                    : EpubContentType.Other;

                switch (contentType)
                {
                    case EpubContentType.Xhtml11:
                    case EpubContentType.Css:
                    case EpubContentType.Oeb1Document:
                    case EpubContentType.Oeb1Css:
                    case EpubContentType.Xml:
                    case EpubContentType.Dtbook:
                    case EpubContentType.DtbookNcx:
                    {
                        var file = new EpubTextFile
                        {
                            AbsolutePath = path,
                            Href = href,
                            MimeType = mimeType,
                            ContentType = contentType
                        };

                        resources.All.Add(file);

                        using (var stream = entry.OpenRead())
                        {
                            file.Content = stream.ReadToEnd();
                        }

                        switch (contentType)
                        {
                            case EpubContentType.Xhtml11:
                                resources.Html.Add(file);
                                break;
                            case EpubContentType.Css:
                                resources.Css.Add(file);
                                break;
                            default:
                                resources.Other.Add(file);
                                break;
                        }

                        break;
                    }
                    default:
                    {
                        var file = new EpubByteFile
                        {
                            AbsolutePath = path,
                            Href = href,
                            MimeType = mimeType,
                            ContentType = contentType
                        };

                        resources.All.Add(file);

                        using (var stream = entry.OpenRead())
                        {
                            if (stream == null)
                            {
                                throw new EpubException(
                                    $"Incorrect EPUB file: content file \"{href}\" specified in manifest is not found");
                            }

                            using (var memoryStream = new MemoryStream((int) entry.Length))
                            {
                                stream.CopyTo(memoryStream);
                                file.Content = memoryStream.ToArray();
                            }
                        }

                        switch (contentType)
                        {
                            case EpubContentType.ImageGif:
                            case EpubContentType.ImageJpeg:
                            case EpubContentType.ImagePng:
                            case EpubContentType.ImageSvg:
                                resources.Images.Add(file);
                                break;
                            case EpubContentType.FontTruetype:
                            case EpubContentType.FontOpentype:
                                resources.Fonts.Add(file);
                                break;
                            default:
                                resources.Other.Add(file);
                                break;
                        }

                        break;
                    }
                }
            }

            return resources;
        }

        //private EpubSpecialResources LoadSpecialResources()
        //{
        //    EpubFormat format = ReadFormat();
        //    var result = new EpubSpecialResources
        //    {
        //        Ocf = new EpubTextFile
        //        {
        //            AbsolutePath = Constants.OcfPath,
        //            Href = Constants.OcfPath,
        //            ContentType = EpubContentType.Xml,
        //            MimeType = ContentType.ContentTypeToMimeType[EpubContentType.Xml],
        //            Content = _bookFolder.LoadBytes(Constants.OcfPath)
        //        },
        //        Opf = new EpubTextFile
        //        {
        //            AbsolutePath = format.Paths.OpfAbsolutePath,
        //            Href = format.Paths.OpfAbsolutePath,
        //            ContentType = EpubContentType.Xml,
        //            MimeType = ContentType.ContentTypeToMimeType[EpubContentType.Xml],
        //            Content = _bookFolder.LoadBytes(format.Paths.OpfAbsolutePath)
        //        },
        //        HtmlInReadingOrder = new List<EpubTextFile>()
        //    };

        //    var htmlFiles = format.Opf.Manifest.Items
        //        .Where(item => ContentType.MimeTypeToContentType.ContainsKey(item.MediaType) && ContentType.MimeTypeToContentType[item.MediaType] == EpubContentType.Xhtml11)
        //        .ToDictionary(item => item.Id, item => item.Href);

        //    foreach (var item in format.Opf.Spine.ItemRefs)
        //    {
        //        if (!htmlFiles.TryGetValue(item.IdRef, out string href))
        //        {
        //            continue;
        //        }

        //        var html = Resources.Html.SingleOrDefault(e => e.Href == href);
        //        if (html != null)
        //        {
        //            result.HtmlInReadingOrder.Add(html);
        //        }
        //    }

        //    return result;
        //}
    }
}