using Directmedia.Search.Index;
using Lucene.Net.Index;
using Lucene.Net.Util;
using System.Collections.Generic;

namespace Directmedia.Search
{
    public class WordsEnum : TermsEnum, IComparer<BytesRef>
    {
        private readonly HashTable _hashTable;
        private readonly WordList _wordList;
        private readonly PagenumberList _pagenumberList;
        private readonly TextTable _textTable;

        private int _currentPosition = -1; // in hash table
        private WordListEntry _currentEntry;

        public WordsEnum(HashTable hashTable, WordList wordList, PagenumberList pagenumberList, TextTable textTable)
        {
            _hashTable = hashTable;
            _wordList = wordList;
            _pagenumberList = pagenumberList;
            _textTable = textTable;
        }

        public override long Ord => _currentPosition;
        public override BytesRef Term => _currentEntry != null ? new BytesRef(_currentEntry.Word) : null;
        public override int DocFreq => _currentEntry != null ? _currentEntry.Count : -1; // number of text pages containing current word
        public override long TotalTermFreq => -1;

        public override SeekStatus SeekCeil(BytesRef text)
        {
            string word = text.Utf8ToString();
            int hash = _hashTable.Hash(word);
            if (hash < _currentPosition) // avoid endless loop
            {
                return SeekStatus.END;
            }
            else if (hash == _currentPosition)
            {
                Next();
            }
            else
            {
                SeekExact(hash);
            }
            return _currentEntry != null ? _currentEntry.Word == word ? SeekStatus.FOUND : SeekStatus.NOT_FOUND : SeekStatus.END;
        }

        public override void SeekExact(long hash)
        {
            if (hash >= _hashTable.Length)
            {
                _currentEntry = null;
            }
            _currentPosition = (int)hash;
            _currentEntry = _wordList.ReadEntry(_hashTable.ReadOffset(_currentPosition));
        }

        public override BytesRef Next()
        {
            SeekExact(_currentPosition + 1);
            return Term;
        }

        public override DocsEnum Docs(IBits liveDocs, DocsEnum reuse, DocsFlags flags) { return CreatePagesEnum(); }
        public override DocsAndPositionsEnum DocsAndPositions(IBits liveDocs, DocsAndPositionsEnum reuse, DocsAndPositionsFlags flags) { return CreatePagesEnum(); }
        private PagesEnum CreatePagesEnum() { return _currentEntry != null ? new PagesEnum(_currentEntry, _hashTable, _wordList, _pagenumberList, _textTable) : null; }

        public override IComparer<BytesRef> Comparer => this;

        public int Compare(BytesRef x, BytesRef y)
        {
            return _hashTable.Hash(x.Utf8ToString()) - _hashTable.Hash(y.Utf8ToString());
        }
    }
}
