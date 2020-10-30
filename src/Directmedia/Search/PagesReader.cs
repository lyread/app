using Book.Util;
using Directmedia.Search.Index;
using Lucene.Net.Index;
using Lucene.Net.Util;
using System;
using System.Collections.Generic;
using System.IO;

namespace Directmedia.Search
{
    public class PagesReader : AtomicReader
    {
        private readonly HashTable _hashTable;
        private readonly WordList _wordList;
        private readonly PagenumberList _pagenumberList;
        private readonly TextTable _textTable;

        public PagesReader(DirectoryInfo dataFolder)
        {
            _hashTable = new HashTable(dataFolder.GetFileIgnoreCase("index.htx"));
            _wordList = new WordList(dataFolder.GetFileIgnoreCase("index.wlx"));
            _pagenumberList = new PagenumberList(dataFolder.GetFileIgnoreCase("index.plx"));
            _textTable = new TextTable(dataFolder.GetFileIgnoreCase("index.ttx"));

            NumDocs = _textTable.NumberOfPages;
            Fields = new DirectmediaFields(new Words(_hashTable, _wordList, _pagenumberList, _textTable));
        }

        public override int NumDocs { get; } // number of text pages
        public override int MaxDoc => NumDocs; // text pages start at 1
        public override Fields Fields { get; }

        public override NumericDocValues GetNormValues(string field) { return new DirectmediaNumericDocValues(); }
        public override Fields GetTermVectors(int docID) { return Fields; }




        // for highlighter
        public override void Document(int docID, StoredFieldVisitor visitor)
        {
            visitor.StringField(new FieldInfo("1", false, 1, false, true, false, IndexOptions.NONE, DocValuesType.NONE, DocValuesType.NONE, new Dictionary<string, string>()), "test1");
        }



        public override IBits LiveDocs => null; // nothing deleted
        protected override void DoClose() { }

        public override FieldInfos FieldInfos => throw new NotImplementedException();
        public override void CheckIntegrity() { throw new NotImplementedException(); }
        public override BinaryDocValues GetBinaryDocValues(string field) { throw new NotImplementedException(); }
        public override IBits GetDocsWithField(string field) { throw new NotImplementedException(); }
        public override NumericDocValues GetNumericDocValues(string field) { throw new NotImplementedException(); }
        public override SortedDocValues GetSortedDocValues(string field) { throw new NotImplementedException(); }
        public override SortedSetDocValues GetSortedSetDocValues(string field) { throw new NotImplementedException(); }

        public new void Dispose()
        {
            base.Dispose();
            _hashTable.Dispose();
            _wordList.Dispose();
            _pagenumberList.Dispose();
            _textTable.Dispose();
        }
    }

    class DirectmediaFields : Fields
    {
        private readonly Words _words;

        public DirectmediaFields(Words words)
        {
            _words = words;
        }

        public override int Count => -1;
        public override IEnumerator<string> GetEnumerator() { yield break; }
        public override Terms GetTerms(string field) { return _words; }
    }

    class Words : Terms
    {
        private readonly HashTable _hashTable;
        private readonly WordList _wordList;
        private readonly PagenumberList _pagenumberList;
        private readonly TextTable _textTable;

        public Words(HashTable hashTable, WordList wordList, PagenumberList pagenumberList, TextTable textTable)
        {
            _hashTable = hashTable;
            _wordList = wordList;
            _pagenumberList = pagenumberList;
            _textTable = textTable;
        }

        public override bool HasOffsets => true;
        public override bool HasPositions => true;
        public override bool HasPayloads => true;

        public override int DocCount => -1; // TODO from wordlist.count, or WordsEnum.DocFreq?
        public override long SumTotalTermFreq => -1; // total number of tokens for this field
        public override long SumDocFreq => -1; // total number of postings for this field

        public override TermsEnum GetIterator(TermsEnum reuse) { return new WordsEnum(_hashTable, _wordList, _pagenumberList, _textTable); }

        public override TermsEnum GetEnumerator()
        {
            throw new NotImplementedException();
        }

        public override long Count => throw new NotImplementedException();
        public override bool HasFreqs => throw new NotImplementedException();
        public override IComparer<BytesRef> Comparer => throw new NotImplementedException();
    }

    class DirectmediaNumericDocValues : NumericDocValues
    {
        public override long Get(int docID) { return docID; }
    }
}
