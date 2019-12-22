using Book;
using Plugin.SimpleAudioPlayer;
using System;
using System.IO;
using System.Threading.Tasks;
using Xamarin.Essentials;
using Xamarin.Forms;
using static Book.LinkType;

namespace Lyread.ViewModels
{
    public class DocumentViewModel : BookViewModel
    {
        public int Id { get; set; }
        public string Pattern { get; set; }

        public DocumentViewModel()
        {
            Title = string.Format("Seite {0} ff.", Id);
        }

        public string DocumentUri()
        {
            Uri cacheUri = DependencyService.Get<IPlatformService>().CacheUri;
            Uri htmlUri = new Uri(cacheUri, html.ToString() + "/");
            Uri uri = new Uri(htmlUri, Path.ChangeExtension(Id.ToString(), html.ToString()));
            return string.Format("{0}#{1}", uri.AbsoluteUri, Id.ToString());
        }

        public async Task<bool> CancelNavigation(Uri uri)
        {
            if (DependencyService.Get<IPlatformService>().IsLocal(uri))
            {
                return await Local(uri);
            }
            else
            {
                Device.OpenUri(uri);
                return true;
            }
        }
        public async Task<bool> Local(Uri uri)
        {
            string filename = Path.GetFileName(uri.AbsolutePath);
            if (Enum.TryParse(Path.GetExtension(filename).Replace(".", string.Empty), out LinkType type))
            {
                switch (type)
                {
                    case html:
                        Id = int.Parse(Path.GetFileNameWithoutExtension(filename));
                        OnPropertyChanged(nameof(Id));
                        await Book.Html(Id, new DirectoryInfo(Path.Combine(FileSystem.CacheDirectory, html.ToString())), Pattern);
                        return false;
                    case pdf:
                        byte[] pdfData = await Book.ExternalFile(filename);
                        if (pdfData != null)
                        {
                            string pdfPath = Path.Combine(FileSystem.CacheDirectory, filename);
                            File.WriteAllBytes(pdfPath, pdfData);
                            await DependencyService.Get<IPlatformService>().LaunchPdf(new FileInfo(pdfPath));
                        }
                        break;
                    case mp3:
                        Task.Run(async () =>
                        {
                            byte[] bytes = await Book.ExternalFile(filename);
                            if (bytes != null)
                            {
                                ISimpleAudioPlayer player = CrossSimpleAudioPlayer.Current;
                                player.Load(new MemoryStream(bytes));
                                player.Play();
                            }
                        });
                        break;
                }
            }
            return true;
        }
    }
}
