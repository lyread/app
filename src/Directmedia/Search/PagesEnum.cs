using Directmedia.Search.Index;
using Lucene.Net.Index;
using Lucene.Net.Util;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Directmedia.Search
{
    public class PagesEnum : DocsAndPositionsEnum
    {
        private readonly HashTable _hashTable;
        private readonly WordList _wordList;
        private readonly PagenumberList _pagenumberList;
        private readonly TextTable _textTable;

        private readonly WordListEntry _entry;
        private IEnumerator<int> _pagenumbers;

        private int[] _matchingWordsOffsets = null;
        private int _matchingWordsPosition;
        private int[] MatchingWordsOffsets
        {
            get
            {
                if (_matchingWordsOffsets == null)
                {
                    int[] hashes = _textTable.ReadHashes(_pagenumbers.Current);
                    _matchingWordsOffsets = hashes.Select((hash, i) => new { hash, i })
                          .Where(item => item.hash == _entry.Hash)
                          .Select(item => item.i).ToArray();
                    _matchingWordsPosition = -1;
                }
                return _matchingWordsOffsets;
            }
        }

        public PagesEnum(WordListEntry entry, HashTable hashTable, WordList wordList, PagenumberList pagenumberList, TextTable textTable)
        {
            _entry = entry;
            _hashTable = hashTable;
            _wordList = wordList;
            _pagenumberList = pagenumberList;
            _textTable = textTable;

            _pagenumbers = _pagenumberList.ReadPagenumbers(_entry).AsEnumerable().GetEnumerator(); // read all due to parallelism
        }

        public override int DocID
        {
            get
            {
                try
                {
                    return _pagenumbers.Current;
                }
                catch (InvalidOperationException)
                {
                    return -1;
                }
            }
        }
        public override int Freq => MatchingWordsOffsets.Length;

        /// <summary>
        /// First text page >= target.
        /// </summary>
        public override int Advance(int target)
        {
            int pagenumber;
            while ((pagenumber = NextDoc()) < target) ;
            return pagenumber;
        }

        /// <summary>
        /// Next text page.
        /// </summary>
        public override int NextDoc()
        {
            if (_pagenumbers.MoveNext())
            {
                _matchingWordsOffsets = null;
                return _pagenumbers.Current;
            }
            return NO_MORE_DOCS;
        }

        public override long GetCost() { return -1; }

        /// <summary>
        /// DocsAndPositionsEnum methods
        /// </summary>

        public override int StartOffset => MatchingWordsOffsets[_matchingWordsPosition];
        public override int EndOffset => MatchingWordsOffsets[_matchingWordsPosition] + 1;

        public override int NextPosition()
        {
            return ++_matchingWordsPosition < Freq ? _matchingWordsPosition : -1;
        }

        public override BytesRef GetPayload() { return null; }
    }
}
