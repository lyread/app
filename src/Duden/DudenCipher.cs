using System;
using System.Security.Cryptography;

namespace Duden
{
    public class DudenCipher : SymmetricAlgorithm
    {
        private readonly AesManaged _aes = new AesManaged {Mode = CipherMode.ECB, Padding = PaddingMode.None};

        public override void GenerateKey() => KeyValue = new byte[]
        {
            0x4A, 0x25, 0xAA, 0x6A, 0xB2, 0x4E, 0xC2, 0x64, 0x84, 0xD9, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        };

        public override void GenerateIV() => IVValue = new byte[16];

        public override ICryptoTransform CreateEncryptor(byte[] key, byte[] iv) =>
            new DudenTransform(_aes.CreateEncryptor(key, iv));

        public override ICryptoTransform CreateDecryptor(byte[] key, byte[] iv) =>
            new DudenTransform(_aes.CreateDecryptor(key, iv));
    }

    class DudenTransform : ICryptoTransform
    {
        private readonly ICryptoTransform _aesTransform;
        private static readonly int AesBlockSize = 320;

        private static readonly byte[] XorMask =
            {0x10, 0x01, 0xF5, 0x16, 0xD4, 0x9D, 0x93, 0xE2, 0x40, 0x02, 0xDF, 0xCF, 0x1A, 0x34, 0x63, 0x00};

        public bool CanReuseTransform => true;
        public bool CanTransformMultipleBlocks => false;
        public int InputBlockSize => 1024;
        public int OutputBlockSize => 1024;

        public DudenTransform(ICryptoTransform aesTransform)
        {
            _aesTransform = aesTransform;
        }

        public int TransformBlock(byte[] inputBuffer, int inputOffset, int inputCount, byte[] outputBuffer,
            int outputOffset)
        {
            _aesTransform.TransformBlock(inputBuffer, inputOffset, AesBlockSize, outputBuffer, outputOffset);
            for (int i = AesBlockSize; i < inputCount; i++)
            {
                outputBuffer[outputOffset + i] =
                    (byte) (inputBuffer[inputOffset + i] ^ XorMask[i & XorMask.Length - 1]);
            }

            return inputCount;
        }

        public byte[] TransformFinalBlock(byte[] inputBuffer, int inputOffset, int inputCount)
        {
            return Array.Empty<byte>();
        }

        public void Dispose()
        {
            _aesTransform.Dispose();
        }
    }
}