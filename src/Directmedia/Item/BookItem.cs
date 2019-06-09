using Book;
using Book.Item;
using Book.Util;
using Directmedia.Text;
using Directmedia.Util;
using IniFileParser;
using IniFileParser.Model;
using IniFileParser.Model.Configuration;
using Lyread.Text;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using static Book.LinkType;
using static Directmedia.Util.Constants;

namespace Directmedia.Item
{
    public class BookItem : IBookItem
    {
        static BookItem()
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
        }

        private readonly DirectoryInfo _bookFolder;
        private DirectoryInfo DataFolder => _bookFolder.GetSubdirectoryIgnoreCase(Constants.DataFolder);
        private DirectoryInfo ImagesFolder => _bookFolder.GetSubdirectoryIgnoreCase(Constants.ImagesFolder);
        private IniData Ini => new IniFileParser.IniFileParser(new IniStringParser(new IniParserConfiguration { AllowDuplicateSections = true, AllowDuplicateKeys = true })).ReadFile(DataFolder.GetFileIgnoreCase(DigibibTxt).FullName, Encoding.GetEncoding(1252));

        public BookItem(DirectoryInfo bookFolder)
        {
            _bookFolder = bookFolder;
        }

        public int Id
        {
            get
            {
                try
                {
                    return Convert.ToInt32(Regex.Replace(Ini[Default][Major], "[^0-9]", string.Empty));
                }
                catch (Exception)
                {
                    return 0;
                }
            }
        }
        public string Title
        {
            get
            {
                try
                {
                    return Ini[Default][Caption];
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
                    string filename = string.Format("Cover{0}.bmp", Ini[Default][Major].Replace('-', 'm'));
                    return File.ReadAllBytes(DataFolder.GetFileIgnoreCase(filename).FullName);
                }
                catch (Exception)
                {
                    using (Stream inStream = GetType().Assembly.GetManifestResourceStream("Directmedia.cover.png"))
                    using (MemoryStream outStream = new MemoryStream())
                    {
                        inStream.CopyTo(outStream);
                        return outStream.ToArray();
                    }
                }
            }
        }

        public Task<ITocItem> QueryToc(string pattern, IEnumerable<ICategoryItem> categories)
        {
            DirectoryInfo dataFolder = DataFolder;
            FileInfo treeDki = dataFolder.GetFileIgnoreCase(TreeDki);
            FileInfo treeDka = dataFolder.GetFileIgnoreCase(TreeDka);
            TocItem root = TocUtil.LoadTree(treeDki, treeDka);
            return Task.FromResult<ITocItem>(root);
        }

        public Task<IEnumerable<IIndexItem>> QueryIndex(string pattern, IEnumerable<ICategoryItem> categories, int page)
        {
            FileInfo lemmataTxt = DataFolder.GetFileIgnoreCase(LemmataTxt);
            if (lemmataTxt.Exists)
            {
                return Task.FromResult(IndexUtil.LoadLemmata(lemmataTxt, pattern, categories, page).AsEnumerable<IIndexItem>());
            }
            return Task.FromResult(Enumerable.Empty<IIndexItem>());
        }

        public Task<IEnumerable<ICategoryItem>> QueryCategories()
        {
            FileInfo lemmataTxt = DataFolder.GetFileIgnoreCase(LemmataTxt);
            if (lemmataTxt.Exists)
            {
                return Task.FromResult(IndexUtil.LoadCategories(lemmataTxt, Ini).AsEnumerable<ICategoryItem>());
            }
            return Task.FromResult(Enumerable.Empty<ICategoryItem>());
        }

        public Task<IEnumerable<IImageItem>> QueryImages()
        {
            DirectoryInfo imagesFolder = ImagesFolder;
            if (imagesFolder.Exists)
            {
                return Task.FromResult(ImageUtil.LoadImages(imagesFolder, false));
            }
            return Task.FromResult(Enumerable.Empty<IImageItem>());
        }

        public Task<IEnumerable<ISearchItem>> Search(string pattern, int page)
        {
            return Task.FromResult(SearchUtil.Search(pattern, DataFolder, page));
        }

        public Task<bool> Html(int pagenumber, DirectoryInfo folder, string highlight)
        {
            string filename = Path.Combine(folder.FullName, Path.ChangeExtension(pagenumber.ToString(), html.ToString()));
            ISet<int> highlightedOffsets = string.IsNullOrWhiteSpace(highlight) ? new HashSet<int>() : SearchUtil.HighlightedOffsets(pagenumber, highlight, DataFolder);
            using (HtmlWriter writer = new HtmlWriter(new FileStream(filename, FileMode.Create, FileAccess.Write), pagenumber, highlightedOffsets))
            {
                TocItem item = FindItem(pagenumber);
                IEnumerable<Page> pages = PageUtil.LoadPages(DataFolder.GetFileIgnoreCase(TextDki), item.Pagenumber, item.Pagecount);
                foreach (Page page in pages)
                {
                    PageUtil.Parse(page, writer);
                }
                DumpImages(writer.ImageIdsToExtensions, folder);
            }

            return Task.FromResult(true);
        }

        private TocItem FindItem(int pagenumber)
        {
            DirectoryInfo dataFolder = DataFolder;
            FileInfo tocDki = dataFolder.GetFileIgnoreCase(TreeDki);
            FileInfo tocDka = dataFolder.GetFileIgnoreCase(TreeDka);
            TocItem item = TocUtil.LoadTree(tocDki, tocDka);
            while (item.Pagenumber != pagenumber || item.Pagecount == 0)
            {
                List<TocItem> childrenReverse = item.ChildrenConcrete.AsEnumerable().Reverse().ToList();
                TocItem child = childrenReverse.Find(c => c.Pagenumber <= pagenumber);
                if (child == null)
                {
                    break;
                }
                item = child;
            }
            while (item.Pagecount == 0 && item.ParentConcrete != null)
            {
                item = item.ParentConcrete;
            }
            return item;
        }

        private void DumpImages(Dictionary<int, string> imageIdsToExtensions, DirectoryInfo folder)
        {
            DirectoryInfo imagesFolder = ImagesFolder;
            if (imageIdsToExtensions.Any() && imagesFolder.Exists)
            {
                ImageUtil.LoadImages(imagesFolder, true)
                    .Where(image => imageIdsToExtensions.ContainsKey(image.Id))
                    .ToList()
                    .ForEach(image => File.WriteAllBytes(Path.Combine(folder.FullName, Path.ChangeExtension(image.Filename, imageIdsToExtensions[image.Id])), image.Huge));
            }
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
                    try
                    {
                        return DataFolder.GetFileIgnoreCase(LemmataTxt).Length != 0; // lemmata.txt can be empty
                    }
                    catch (Exception)
                    {
                        return false;
                    }
                case ViewType.Search:
                    return true;
                case ViewType.Images:
                    return true;
            }
            return false;
        }
    }
}