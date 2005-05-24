/*
 * Band.m -- 
 *
 * Copyright (c) 2005 Directmedia GmbH
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */


#import "Band.h"

#include <regex.h>
#include <sys/stat.h>

int readblock(int countersize, FILE* fh,int blocknumber,unsigned long** blockpointerarray);


@implementation Band

-(id)initWithPath:(NSString*)_path
{
	NSDictionary* imageLocatorDict;
	NSString *key;
	NSString *majorminor;

	self = [super init];

	NSBundle *myBundle = [NSBundle mainBundle];

	imageLocatorDict = [NSDictionary dictionaryWithContentsOfFile:[myBundle pathForResource:@"ImageLocator" ofType:@"plist"]];
	if (imageLocatorDict == nil)
	{
		NSLog(@"Error: ImageLocator File nicht gefunden!");
		exit(1);
	}

	imageLocatorArray = nil;

	imageArray = nil;

	masterPath = [_path retain];
	digibibDict = [[NSMutableDictionary alloc] init];

	htmlDict = [[NSMutableDictionary alloc] init];

	coloredWordsDict = nil;

	blockpointerarray[0] = 0;
	blockpointerarray[1] = 0;
	blockpointerarray[2] = 0;
	blockpointerarray[3] = 0;
	blockpointerarray[4] = 0;

	NSLog(@"masterpath: %@",masterPath);

	TreeDKI_path = [Helper findFile:@"Data/Tree.dki" startPath:masterPath];
	TreeDKA_path = [Helper findFile:@"Data/TREE.DKA" startPath:masterPath];
	TextDKI_path = [Helper findFile:@"Data/TEXT.DKI" startPath:masterPath];
	Digibib_path = [Helper findFile:@"DATA/DIGIBIB.TXT" startPath:masterPath];
	IndexHTX_path = [Helper findFile:@"Data/Index.htx" startPath:masterPath];
	IndexWLX_path = [Helper findFile:@"Data/Index.wlx" startPath:masterPath];
	IndexPLX_path = [Helper findFile:@"Data/Index.plx" startPath:masterPath];
	IndexTTX_path = [Helper findFile:@"Data/Index.ttx" startPath:masterPath];
	HTML_path = [Helper findFile:@"HTML/HTMLs.idx" startPath:masterPath];
	HTMLdat_path = [Helper findFile:@"HTML/HTMLs.dat" startPath:masterPath];



	if ([[NSFileManager defaultManager] isReadableFileAtPath:TextDKI_path] == NO)
	{
		NSLog (@"%@: file not readable",TextDKI_path);
		// hier sollte nun abgebrochen werden !
		// am besten nen Alert
		return nil;
	}

	if ([[NSFileManager defaultManager] isReadableFileAtPath:IndexHTX_path] == NO)
	{
		NSLog (@"%@: file not readable",IndexHTX_path);
		// hier sollte nun abgebrochen werden !
		// am besten nen Alert
		return nil;
	}

	[TreeDKI_path retain];
	[TreeDKA_path retain];
	[TextDKI_path retain];
	[IndexHTX_path retain];
	[IndexWLX_path retain];
	[IndexPLX_path retain];
	[IndexTTX_path retain];
	[Digibib_path retain];
	[HTML_path retain];

//	linesInTree = [self initializeTables];
	NSLog(@"initializing digibibTable");
	[self loadDigibibTable];

	key = [NSString stringWithFormat:@"%@#%@",[digibibDict objectForKey:@"[Default]CDMajor"],[digibibDict objectForKey:@"[Default]CDMinor"]];

	registereinstellungen = [[[digibibDict objectForKey:@"[Default]CDMajor"] stringByAppendingString:@"_RegisterCheckboxen"] retain];

	Register = [[DBRegister alloc] initWithBand:self masterPath:masterPath fastArray:fastArray];

	NSString* majorString = [digibibDict objectForKey:@"[Default]CDMajor"];

	NSLog(@"Band Version (Major#Minor): %@",key);
//	NSLog(@"imageLocatordictArray: %@",[imageLocatorDict objectForKey:key]);
	imageLocatorArray = [[imageLocatorDict objectForKey:majorString] retain];

	NSDictionary* digibiballDict = [NSDictionary dictionaryWithContentsOfFile:[myBundle pathForResource:@"digibiball" ofType:@"plist"]];

	digibibxmlDict = [digibiballDict objectForKey:[digibibDict objectForKey:@"[Default]CDMajor"]];
	//NSLog(@"digibibxmldict %@",digibibxmlDict);
	[digibibxmlDict retain];

	[self loadTextTable];

	[self loadTreeTable];

	[self loadHTMLTable];

	[DBImageLoader loadImageTable:self];

	[self loadIndexHTX];

	// TODO remove this
	markierungen = [[NSMutableArray alloc] init];

	suchwort = nil;
	suchergebnisse = nil;
	searchWordsDict = nil;

	dkiFilehandleLock = [[NSLock alloc] init];
// SUCHE UND Markierungen
	
	majorminor = [NSString stringWithFormat:@"%@ - %@",[digibibDict objectForKey:@"[Default]CDMajor"],[digibibDict objectForKey:@"[Default]CDMinor"]];

	NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:IndexTTX_path];
	[myNSFileHandle retain];
	ttxhandle = fdopen([myNSFileHandle fileDescriptor],"r");

//	ttxhandle = fopen([[self IndexTTX_path] cString],"r");

	fundstellenDS = [[DBFundstellenDataSource alloc] initWithName:kFundstellenTableViewName BandMajorMinor:majorminor];

	markierungenDS = [[DBFundstellenDataSource alloc] initWithName:kMarkierungenTableViewName BandMajorMinor:majorminor];
// END SUCHE	

	return self;
}

-(NSString *)registereinstellungen
{
	return registereinstellungen;
}

-(void)dealloc
{
	[fundstellenDS release];
	[markierungenDS release];

	[TreeDKI_path release];
	[TreeDKA_path release];
	[TextDKI_path release];
	[IndexHTX_path release];
	[IndexWLX_path release];
	[IndexPLX_path release];
	[IndexTTX_path release];
	[Digibib_path release];

	[registereinstellungen release];

	[htmlDict release];
	[HTMLData release];

	[digibibxmlDict release];
	[imageArray release];
	[imageDict release];
	[digibibDict release];
	[masterPath release];
	[treeArray release];
	[fastArray release];
	[markierungen release];
	[IndexHTXTable release];
	[Register release];
	[dkiFilehandleLock release];

	fclose(textdkihandle);
	fclose(ttxhandle);

	[super dealloc];
}

-(NSMutableDictionary*) digibibDict
{
	return digibibDict;
}

-(DBFundstellenDataSource *)markierungenDS
{
	return markierungenDS;
}

-(DBFundstellenDataSource *)fundstellenDS
{
	return fundstellenDS;
}

-(NSMutableArray *)markierungen
{
	return markierungen;
}

-(NSString *)masterPath
{
	return masterPath;
}

-(NSString*)TreeDKI_path
{
	return TreeDKI_path;
}

-(NSString *)IndexTTX_path
{
	return IndexTTX_path;
}

-(NSString *)IndexWLX_path
{
	return IndexWLX_path;
}

-(NSString *)IndexPLX_path;
{
	return IndexPLX_path;
}

-(NSArray*) tabellenArray
{
	NSArray* tabellenArray;

	tabellenArray = [digibibxmlDict objectForKey:@"tables"];
	return tabellenArray;
}

-(NSData *)IndexHTXTable
{
	return IndexHTXTable;
}

-(void)loadIndexHTX
{
	NSLog(@"initializing Index(HTX)");
	IndexHTXTable = [[NSData alloc] initWithContentsOfFile:IndexHTX_path];
	HashTableEntries = [IndexHTXTable length] / 4;
	NSLog(@"Hashtable Entries: %d",HashTableEntries);
}

-(unsigned long)hashHTX:(NSString *)word
{
//  Result := (((Result*ord(w[i]) mod HashTableEntries)+1)*ord(w[i]) mod HashTableEntries)+1;

	unsigned long Result = 1;
	unsigned int i;
	for (i = 0;  i < [word length]; i++)
	{
		int ord = [word characterAtIndex:i];
		Result = (((Result * ord % HashTableEntries)+1) * ord % HashTableEntries)+1;
	}

	NSLog(@"Hash: %010p",Result);
	return Result-1;
}

-(BOOL)sucheCheckForRegularExpression:(NSString *)_word
{
    NSRange r;
    // durch das wort laufen und auf auffaelige zeichen achten !
    r = [_word rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@".*+[]$^"]];
    
    return (r.length >= 1);
}

-(unsigned long)offsetOfSearchHash:(long)_hash
{
	const unsigned long *table = [IndexHTXTable bytes];
	return table[_hash];
}

-(NSImage*)loadCoverImage
{
	NSString* coverfilename;
	NSString* majorstring;

	int majorversion = [[digibibDict objectForKey:@"[Default]CDMajor"] intValue];

	if (majorversion < 0)
	{
		majorversion = abs(majorversion);
		majorstring = [NSString stringWithFormat:@"m%d",majorversion];
	}
	else
	{
		majorstring = [NSString stringWithFormat:@"%d",majorversion];
	}

	coverfilename = [NSString stringWithFormat:@"DATA/COVER%@.BMP",majorstring];
	coverfilename = [Helper findFile:coverfilename startPath:masterPath];
//	NSLog(@"coverfilename: %@",coverfilename);

	NSImage* coverimage = [[NSImage alloc] initWithContentsOfFile:coverfilename];

	return [coverimage autorelease];
}

-(int)loadDigibibTable
{
	NSData *myData = [NSData dataWithContentsOfFile:Digibib_path];

	if (myData == nil)
	{
		NSBundle *myBundle = [NSBundle mainBundle];
		myData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/DIGIBIB.TXT",[myBundle resourcePath]]];
	}

	NSString *s,*group=nil;
	NSEnumerator *enu;
	NSCharacterSet* myCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	s = [[NSString alloc] initWithData:myData encoding:NSWindowsCP1252StringEncoding];
	[s autorelease];

	NSCharacterSet* charset = [NSCharacterSet characterSetWithCharactersInString:@"&"];

	if ([s length])
	{
		NSArray *array = [s componentsSeparatedByString:@"\n"];
		enu = [array objectEnumerator];

		while (s = [enu nextObject])
		{
			s = [s stringByTrimmingCharactersInSet:myCharacterSet];
			array = [s componentsSeparatedByString:@"="];

			if ([array count] == 2)		// key value pair
			{
				int i,len;

				NSString* value = [array lastObject];
//				NSLog(@"value1: %@",value);

				len = [value length];

//				10.2: The method stringByTrimmingCharacters: would sometimes return an empty string (if the only character not to be trimmed was the last one). This has been fixed.
				if (len > 1) // umgeht fehler in 10.2 !!!
					value = [value stringByTrimmingCharactersInSet:charset];

				len = [value length];
				
				for (i=0 ; i < len && [value characterAtIndex:i] != '[' ; i++);
				
				value = [value substringToIndex:i];
				
				[digibibDict setObject:value forKey:[group stringByAppendingString:[array objectAtIndex:0]]];
			}
			else
			{
//				NSLog(@"%@",s);
				[group release];
				group = [[array lastObject]retain];
			}
		}
	}
	else
	{
		NSLog(@"No digiBib.txt");
	}

	int i;
	NSString* object;
	unichar mychar = 'A';

	fastArray = [[NSMutableArray alloc] init];
	
	for (i=0;i<26;i++)
	{
		object = [digibibDict objectForKey:[NSString stringWithFormat:@"[Stichwoerter]Gruppe%d",((mychar+i)-'A')+1]];
		if (object == nil)
		{
//			NSLog(@"nil kategorie %@",_zeile);
			object = [NSString stringWithFormat:@"%c",mychar+i];
		}
		[fastArray addObject:object];
	}

//	NSLog(@"%@",fastArray);

//	NSLog(@"%@",digibibDict);
	return 1;
}

-(BOOL)loadTextTable
{
/* ** loadTextTable **
 checks if text.dki is readable and reads pagecount (lastpagenumber) 
 
 returns YES on Success
 NO on failure
*/
	unsigned long tmp_long;

	NSFileHandle* myNSFileHandle = [[NSFileHandle fileHandleForReadingAtPath:TextDKI_path] retain];
// ??? NSFileHandle wozu retain, wird doch nur hier gebraucht oder ?

	textdkihandle = fdopen([myNSFileHandle fileDescriptor],"r");

	if (textdkihandle == 0) {
		NSLog (@"loadTextTable() : Could not open file %@",TextDKI_path);
		return NO;
	}

	magic = [Helper isMagic:textdkihandle];
	if (!magic) {
		fseek(textdkihandle,0,SEEK_SET);
	}
	else {
		if (4 != (fread(&tmp_long,1,4,textdkihandle))) {
			NSLog (@"loadTextTable() : Could not read version in file %@",TextDKI_path);
			return NO;
		}
		NSLog (@"Versionnumber: %d",tmp_long);
	}

	lastpagenumber = readblock(4,textdkihandle,0,blockpointerarray) - 1;

	NSLog (@"lastpagenumber: %d",lastpagenumber);

	return YES;
}

-(DBPage*)textPageData:(long)_seite;
{
	DBPage* myPage;
	unsigned short tmp_word;

	long atomCount = 0;
	long wordCount = 0;

	long pageAddress = 0;

	unsigned long* treetab = 0;
	unsigned long* texttab = 0;

	if (blockpointerarray != 0)
	{
		treetab = blockpointerarray[4];
		texttab = blockpointerarray[0];

		if ((treetab == 0) || (texttab == 0))
		{
			NSLog(@"Text- and/or TreeTable is not initialized!");
		}
	}
	else
	{
		NSLog(@"Blockpointerarray is not initialized!");
	}

	pageAddress = (texttab[_seite-1]);

	[dkiFilehandleLock lock];
	if (textdkihandle == 0) NSLog (@"Text.dki open filehandle error 2");

	fseek(textdkihandle,pageAddress,SEEK_SET);

	if (2 != (fread(&tmp_word,1,2,textdkihandle))) {
		NSLog(@"textPageData() : error, reading pagesize");
		return nil;
	}
	unsigned int pagesize = tmp_word;

//	NSLog(@"pagesize: %d",pagesize);

	if (magic == YES)
	{
		if (2 != (fread(&tmp_word,1,2,textdkihandle))) {
			NSLog(@"textPageData() : error, reading atomcount");
			return nil;
		}
		atomCount = tmp_word;

//		NSLog(@"atomCount: %d",atomCount);

		if ( 2 != (fread(&tmp_word,1,2,textdkihandle))) {
			NSLog(@"textPageData() : error, reading wordcount");
			return nil;
		}

		wordCount = tmp_word;

//		NSLog(@"wordCount: %d",wordCount);
	}

	if (magic == NO)
		pagesize -= 2;

	char* mem = malloc(pagesize);
	if (0 == mem) {
		NSLog(@"textPageData() : error, malloc(%d)",pagesize);
		return nil;
	}
	
	if (pagesize != (fread(mem,1,pagesize,textdkihandle))) {
		NSLog(@"textPageData() : error, reading pagedata");
		return nil;
	}
		
	[dkiFilehandleLock unlock];

	NSData* myPageData = [NSData dataWithBytesNoCopy:mem length:pagesize freeWhenDone:YES];

	myPage = [[DBPage alloc] initWithData:myPageData band:self textpagenumber:_seite atomCount:atomCount wordCount:wordCount hexaddress:pageAddress];
	[myPage autorelease];

//	blub = fread(&tmp_word,1,2,textdkihandle);
//	if (blub != 2) NSLog(@"Error fasdf");
//	NSLog(@"next size: %d", my_get_short(tmp_word));

	return myPage;
}

-(long)pageAddress:(int)_seite
{
	long pageAddress = 0;

	unsigned long* treetab = 0;
	unsigned long* texttab = 0;

	if (blockpointerarray != 0)
	{
		treetab = blockpointerarray[4];
		texttab = blockpointerarray[0];

		if ((treetab == 0) || (texttab == 0))
		{
			NSLog(@"Text- and/or TreeTable is not initialized!");
		}
	}
	else
	{
		NSLog(@"Blockpointerarray is not initialized!");
	}

	pageAddress = (texttab[treetab[_seite-2]-1]);

//	NSLog(@"pageaddress: %d",pageAddress);

	return pageAddress;
}

-(long)pageNumberFromTree:(long)_treelinenumber
{
	unsigned long* treetab = 0;
	unsigned long* texttab = 0;

	if (blockpointerarray != 0)
	{
		treetab = blockpointerarray[4];
		texttab = blockpointerarray[0];

		if ((treetab == 0) || (texttab == 0))
		{
			NSLog(@"Text- and/or TreeTable is not initialized!");
		}
	}
	else
	{
		NSLog(@"Blockpointerarray is not initialized!");
	}

	return treetab[_treelinenumber-2];
}

-(int) loadTreeTable
{
	FILE *fh = 0;

	int treetablecountersize;

	unsigned short wordcounter;

// erstmal die TreeLines laden damit wir die pointersize wissen!

	NSLog(@"initialize Tree Array");
	NSArray* temp_tree_array = [self initializeTree];

//	NSString* filename = TreeDKA_path;

	NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:TreeDKA_path];
	fh = fdopen([myNSFileHandle fileDescriptor],"r");

//	fh = fopen([filename cString],"r");
	if (fh == 0) NSLog (@"file open error!");

//	stat([filename cString],&sb);
//	NSLog(@"Size in Bytes : %qd",sb.st_size);

	treetablecountersize = 2;
	if ([temp_tree_array count] > 65535) treetablecountersize = 4;

//	NSLog (@"treetablecountersize: %d",treetablecountersize);

	wordcounter = readblock(treetablecountersize,fh,1,blockpointerarray);
	wordcounter = readblock(treetablecountersize,fh,2,blockpointerarray);
	wordcounter = readblock(treetablecountersize,fh,3,blockpointerarray);
	wordcounter = readblock(treetablecountersize,fh,4,blockpointerarray);

	fclose (fh);

	[myNSFileHandle closeFile];
	
	return 0;
}

int readblock(int countersize, FILE* fh,int blocknumber,unsigned long** blockpointerarray)
{
/* readblock()
	reads some bytes from the TOC of the text.dki file ???
	RETURNS : pagecount in this band
*/
    unsigned i;

    unsigned short tmp_word;
    unsigned long tmp_long;

    unsigned long pointercounter = 0;
    unsigned long longpointer;
    unsigned long* blocks;

//  NSLog (@"%d. Block:",blocknumber);

    if (countersize == 2)   // zwei byte zeiger < 64k Seiten
    {
        if (countersize != (fread(&tmp_word,1,countersize,fh))) {
			NSLog(@"readblock() : error reading block %d , countersize : %d",blocknumber,countersize);
			return -1;
		}
        pointercounter = 1 + tmp_word;
    }
    else if (countersize == 4)  // vier byte zeiger > 64k Seiten
    {
        if (countersize != (fread(&tmp_long,1,countersize,fh))) {
			NSLog(@"readblock() : error reading block %d , countersize : %d",blocknumber,countersize);
			return -1;
		}
        pointercounter = 1 + tmp_long;
    }
    else {
		NSLog(@"readblock() : error pointercounter != 2 && !=4");
		return -1;
	}

    blocks = (unsigned long*) malloc(pointercounter*4);
	// ??? where is the free() call for this ?

//  NSLog(@"0x%04x : %05d",pointercounter,pointercounter);

	for (i = 0; i < pointercounter; i++) {
		if (4 != (fread(&longpointer,1,4,fh))) {
			NSLog(@"readblock() : error reading block number : %d",blocknumber);
			return -1;
		}
		
		longpointer = longpointer;
		blocks[i] = longpointer;
//		NSLog(@"%03d: 0x%08x: %08d",i,longpointer,longpointer);
	}

//	NSLog(@"firstitem: %010p",blocks[0]);
//	NSLog(@"lastitem : %010p",blocks[pointercounter-2]);

	blockpointerarray[blocknumber] = blocks;
	return pointercounter;  // this is lastpagenumber + 1 !!!
}

-(NSArray*)initializeTree;
{
	int lastlevel = 0;
	int linelevel = 1;
	int linenumber = 1;
	int n;

	NSEnumerator *enu;
	NSString* line;

	Entry* parent = 0;
	Entry* myEntry;

	NSLog(@"initializing TreeTable");

	NSData *myData = [NSData dataWithContentsOfFile: TreeDKI_path];
	NSString* temp_string = [[NSString alloc] initWithData:myData encoding:NSWindowsCP1252StringEncoding];

	NSArray* temp_tree_array = [temp_string componentsSeparatedByString:@"\n"];
	[temp_string release];

	if ([temp_tree_array count] > 0)
	{
		treeArray = [[NSMutableArray alloc] initWithCapacity:[temp_tree_array count]];

		enu = [temp_tree_array objectEnumerator];
		line = [enu nextObject];

		myEntry = [[Entry alloc] initWithName:line level:linelevel linkNumber:23232323 band:self treeArrayIndex:[treeArray count]];

		[treeArray addObject:myEntry];
		[treeArray addObject:myEntry];

		parent = myEntry;

		while (line = [enu nextObject])
		{
			if ([line length] == 0)
				continue;

			linenumber++;

			for (linelevel = 0 ; [line characterAtIndex:linelevel] == ' ' ; linelevel++);
			
			if (linelevel > lastlevel)
			{
				parent = [parent lastChild] != nil ? [parent lastChild] : parent;
			}
			else if (linelevel < lastlevel)
			{
				for (n = (lastlevel - linelevel); n > 0 ;n--)
				{
//					NSLog(@"%d,%d",linelevel,lastlevel);
					parent = [parent parent];
				}
			}
			
			lastlevel = linelevel;
			
			myEntry = [[Entry alloc] initWithName:line level:linelevel linkNumber:linenumber band:self treeArrayIndex:[treeArray count]];
			
			[treeArray addObject:myEntry];
			[parent addChild:myEntry];
			//NSLog(@"treeentry: %@",myEntry);	
			[myEntry release];
		}
	}
	
	NSLog(@"Lines in Tree.dki: %d",linenumber);
	return temp_tree_array;
}

-(int)lastpagenumber
{
	return lastpagenumber;
}

-(int)actualpageviewwidth
{
	return actualpageviewwidth;
}

-(void)setactualpageviewwidth:(int)_actualpageviewwidth
{
	actualpageviewwidth = _actualpageviewwidth;
}

-(int)totalImages
{
	return [imageArray count];
}

-(NSArray*)treeArray
{
	return treeArray;
}

-(NSDictionary*)imageDict
{
	return imageDict;
}

-(DBRegister*)Register
{
	return Register;
}

-(NSArray*)imageArray
{
	return imageArray;
}

-(NSArray*)hiddenImageArray
{
	return hiddenImageArray;
}

-(NSImage*)imageWithName:(NSString*)_string resolution:(int)_int
{
	NSImage* image = nil;

	DBImageSet* myImageSet = [imageDict objectForKey:_string];

	switch (_int)
	{
		case 1:
			image = [myImageSet image1];
			break;
		case 2:
			image = [myImageSet image2];
			break;
		case 3:
			image = [myImageSet image3];
			break;
		default:
			NSLog(@"Imagenumber not supported right now!");
			break;
	}

	return image;
}

-(void)setSearchWordsDict:(NSDictionary *)_search_words
{
	searchWordsDict = [_search_words retain];
}

-(void)setColoredWordsDict:(NSDictionary *)_colored_words
{
	coloredWordsDict = [_colored_words retain];
}

-(NSArray *)imageLocatorArray
{
	return imageLocatorArray;
}

-(void)setImageArray:(NSArray*)_array
{
	[imageArray release];
	imageArray = [_array retain];
}

-(void)setImageDict:(NSDictionary*)_dict
{
	[imageDict release];
	imageDict = [_dict retain];
}

-(NSDictionary*)coloredWordsDict
{
	return coloredWordsDict;
}

-(NSDictionary*)searchWordsDict
{
	return searchWordsDict;
}

-(int)majorNumber
{
	return [[digibibDict objectForKey:@"[Default]CDMajor"] intValue];
}

-(int)minorNumber
{
	return [[digibibDict objectForKey:@"[Default]CDMinor"] intValue];
}
-(void)loadHTMLTable
{
	NSLog(@"load HTMLtable");

	NSData *myData = [NSData dataWithContentsOfFile:HTML_path];

	NSString *s = nil;
	NSEnumerator *enu;
	NSCharacterSet* my1CharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];

	s = [[NSString alloc] initWithData:myData encoding:NSWindowsCP1252StringEncoding];
	[s autorelease];

	NSLog(@"HTMLtable %d",[s length]);

	if ([s length])
	{
		NSArray *array = [s componentsSeparatedByString:@"\n"];
		enu = [array objectEnumerator];

		while (s = [enu nextObject])
		{
			s = [s stringByTrimmingCharactersInSet:my1CharacterSet];
			array = [s componentsSeparatedByString:@"\t"];

			if ([array count] == 3)		// key value pair
			{
//				NSLog(@"name: %@  start: %@  laenge: %@",[array objectAtIndex:0],[array objectAtIndex:1],[array lastObject]);

				int start = [[array objectAtIndex:1] intValue];
				int laenge = [[array lastObject] intValue];

				NSRange range = NSMakeRange(start,laenge);

				NSValue* value = [NSValue valueWithRange:range];

				[htmlDict setObject:value forKey:[array objectAtIndex:0]];
			}
		}
	}
	else
	{
		NSLog(@"No HTMLs.idx");
	}

	HTMLData = [[NSData dataWithContentsOfMappedFile:HTMLdat_path] retain];

	//	NSLog(@"%@",htmlDict);
}

-(NSString*)getHTMLPage:(NSString*)htmlname
{
	NSValue* myValue = [htmlDict objectForKey:htmlname];

	if (myValue == nil)
	{
		NSLog(@"filename in htmlDict not found!");
		return nil;
	}

	NSRange myRange = [myValue rangeValue];

	if (HTMLData != nil)
	{
		if ((myRange.location + myRange.length) > [HTMLData length])
			NSLog(@"Ende von Range groesser als HTMLs.dat");

		NSData* htmlpagedata = [HTMLData subdataWithRange:myRange];

		return [[[NSString alloc] initWithData:htmlpagedata encoding:NSWindowsCP1252StringEncoding] autorelease];
	}
	else return nil;
}

-(int)httpdport;
{
       return port;
}

-(void)set_httpdport:(int)_port;
{
       port=_port;
}


@end
