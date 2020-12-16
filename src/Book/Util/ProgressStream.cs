using System;
using System.IO;

namespace Book.Util
{
    public class ProgressStream : Stream
    {
        private readonly Stream _stream;
        private readonly IProgress<double> _progres;

        public ProgressStream(Stream stream, IProgress<double> progress)
        {
            _stream = stream;
            _progres = progress;
        }

        public override bool CanRead => _stream.CanRead;

        public override long Position
        {
            get => _stream.Position;
            set => throw new NotImplementedException();
        }

        public override long Length => _stream.Length;
        public override bool CanSeek => false;
        public override bool CanWrite => false;

        public override int Read(byte[] buffer, int offset, int count)
        {
            int total = _stream.Read(buffer, offset, count);
            _progres.Report((double) Position / Length);
            return total;
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            throw new NotImplementedException();
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            throw new NotImplementedException();
        }

        public override void Flush()
        {
            throw new NotImplementedException();
        }

        public override void SetLength(long value)
        {
            throw new NotImplementedException();
        }
    }
}