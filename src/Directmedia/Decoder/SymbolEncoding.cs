namespace Directmedia.Decoder
{
    /// <summary>
    /// Decoder for single characters in text.dki files.
    /// </summary>
    public class SymbolEncoding : ByteMappingEncoding
    {
        protected override int ToUtf32(byte b)
        {
            switch (b)
            {
                case 45: return 0xad;
                case 200: return 0x222a;
                default: return b;
            }
        }
    }
}