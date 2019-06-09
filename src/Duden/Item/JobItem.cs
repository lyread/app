﻿using Book.Item;
using Book.Util;
using System;
using System.IO;
using System.Security.Cryptography;

namespace Duden.Item
{
    public class JobItem : IJobItem, IProgress<double>
    {
        public int Id => Title.GetHashCode();
        public string Title => _file.Name;

        public event EventHandler<ProgressEventArgs> ProgressChanged;

        private FileInfo _file;

        public JobItem(FileInfo file)
        {
            _file = file;
        }

        public bool Run()
        {
            try
            {
                using (Stream inStream = new CryptoStream(new ProgressStream(_file.OpenRead(), this), new DudenCipher().CreateDecryptor(), CryptoStreamMode.Read))
                using (Stream outStream = new FileStream(Path.ChangeExtension(_file.FullName, "sqlite3"), FileMode.CreateNew, FileAccess.Write))
                {
                    inStream.CopyTo(outStream);
                }
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        public void Report(double progress)
        {
            ProgressChanged.Invoke(this, new ProgressEventArgs(progress));
        }
    }
}
