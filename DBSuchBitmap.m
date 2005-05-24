/*
 * DBSuchBitmap.m -- 
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

#import "DBSuchBitmap.h"
#import "schreibweisentoleranz.h"


@implementation DBSuchBitmap

-(DBSuchBitmap *)init:(Band *)_band caseSensivity:(BOOL)_case
{
// Designated initializer
    [super init];

    band = _band;
    HashTableEntries = [band HashTableEntries];
    maxpages = [band lastpagenumber];
    pages = calloc(maxpages+1,sizeof(unsigned char));      // malloc does not clear the mem
	words = calloc(HashTableEntries,sizeof(unsigned char));
    caseSensivity = _case;
    actualPageNum=1;
    actualWordNum=0;
    lastTTXPage=-1;
    wordlist=nil;
    matches=YES;

    return self;
}

-(DBSuchBitmap *)initWithWord:(NSString *)_word  schreibweisentoleranz:(BOOL)_tolerant caseSensivity:(BOOL)_case band:_band firstPage:(int)_sucheStartseite lastPage:(int)_sucheEndseite
{
	NSString *expression;
	firstPageNum=_sucheStartseite;
	lastPageNum=_sucheEndseite;
	schreibweisentoleranz=_tolerant;

	// das word ist noch immer case sensitiv damit spaeter in der auswertung noch drauf eingegangen werden kann
	self = [self init:_band caseSensivity:_case]; 
	
//	NSLog(@"suchword : %@",_word);
	wordlist = [[NSMutableArray alloc] init];
	[wordlist addObject:_word];

	if ([self sucheCheckForRegularExpression:_word] || schreibweisentoleranz)
	{
		matches=NO;
		regexp=YES;
		if ([_word characterAtIndex:0] != '^') { // dann ranhaengen
			_word = [NSString stringWithFormat:@"^%@",_word];
//			NSLog(@"regexpression ^ ranhaengen");
		}
		if ([_word characterAtIndex:[_word length]-1] != '$') {  // dann ranhaengen
			_word = [NSString stringWithFormat:@"%@$",_word];
//			NSLog(@"regexpression $ ranhaengen");
		}
		if (schreibweisentoleranz) {
//			NSLog(@"Schreibweisentoleranz : %@",expression);
			expression = [NSString stringWithCString:phoneticAtom([_word lossyCString],0)];
		}
		else
			expression = _word;
//		NSLog(@"expression : %@",expression);
		if (![self getSuchRegExpBitmap:expression]) {  // falls es nen fehler mit der expression gab dann nil zurueck 
			[self autorelease];
			return nil;
		}
	}
	else {
		regexp=NO;
		if(![self getSuchBitmap:_word]) {// falls da was schiefging mit nil zurueck
			[self autorelease];
			return nil;
		}
	}
	//        NSLog(@"DBSuchBitmap : %@",[self description]);
	return self;
}



-(void)dealloc
{
    [wordlist release];
    free(pages);
    free(words);
	free(TTXhashlist);
    [super dealloc];
}

-(NSString *)description
{
	int i;
        NSString *pagestring,*hashstring;
        pagestring = @"";
        hashstring = @"";
        
        
	for (i = 0 ; i <maxpages ; i++) {
		if (pages[i]) {
			pagestring = [pagestring stringByAppendingString:[NSString stringWithFormat:@",%d",i]];
		}
	}
	for (i = 0 ; i < HashTableEntries ; i++) {
		if (words[i]) {
			hashstring = [hashstring stringByAppendingString:[NSString stringWithFormat:@",%p",i]];
		}
	}
	
	return [NSString stringWithFormat:@"Words %@\nMatches %d\nRegular expression:%d\npagenums : %@\nhashes : %@",wordlist,matches,regexp,pagestring,hashstring];
		
}

-(BOOL)getSuchBitmap:(NSString *)_word
{
/*
erzeugt die beiden bitmaps aus dem suchwort, wobei die hashbitmap hier nur das eine wort markiert hat !
RETURNS YES on Success NO on failure
TODO : bei einem hash braucht man keine ganze bitmap fuer die hashes
*/
	BOOL found=NO;
	BOOL rv=YES;
	unsigned long filepos=0;
	NSString  *foundstring;
	long hitcount,wordlistposition,realhash;
	unsigned long hash;
	
	// HIER NUN endlich die UNICODE konvertierung machen
	NSMutableString *ucfreesearchword;
	NSDictionary *unicodedict;
	unicodedict = [Helper unicodeDictionary];
	ucfreesearchword = [[NSMutableString alloc] initWithString:_word];
	unichar uc;
	int i;
	for (i = 0 ; i < [_word length] ; i ++) {
		uc = [ucfreesearchword characterAtIndex:i];
		if (uc > 255) { // 
			[ucfreesearchword replaceCharactersInRange:NSMakeRange(i,1) withString:[unicodedict objectForKey:[NSString stringWithFormat:@"%C",uc]]];
//			NSLog(@"UC in searchstring : %@",ucfreesearchword);
		}
	}	

	hash =[self hashHTX:[ucfreesearchword lowercaseString]];
	
	while (!found && hash < HashTableEntries) {
		filepos = [band offsetOfSearchHash:hash];
		if (filepos == 0) {
//			NSLog(@"word not found");
			break;
		}
		foundstring = [self getSearchWord:filepos count:&hitcount hash:&realhash position:&wordlistposition];
		
//		NSLog(@"foundstring :%@",foundstring);
		if ([foundstring caseInsensitiveCompare:ucfreesearchword] == NSOrderedSame) {
//			NSLog(@"found word:%@ #:%d pagelistpos:%p realhash:%p!", foundstring, hitcount, wordlistposition,realhash);
			[self makeSuchBitmap:wordlistposition count:hitcount];
			words[realhash]=1;
			found=YES;
		}
		hash++;
	}

	actualHash = realhash;  // da wir uns nicht im regular expr. modus  befinden haben wir auch nur einen 	
	if (caseSensivity) { // schauen ob das word gross, wenn ja den hash entsprechend anpassen
		if ([[ucfreesearchword lowercaseString] characterAtIndex:0] != [ucfreesearchword characterAtIndex:0])
		{
			// ist gross
			actualHash |= 0x800000;
		}
	}
[ucfreesearchword release];
	matches = found;
	return rv;
}

-(BOOL)getSuchRegExpBitmap:(NSString *)_expression
{
/*
erzeugt die beiden bitmaps aus dem suchwort, wobei die hashbitmap fuer jedes wort das matched einen eintrag erzeugt
RETURNS YES on Success NO on failure
*/
	BOOL rv=YES;
	FILE *wlxfile,*plxfile;
	int i,pagenum=0;
	unsigned char buff[4],b;
	char *exp_winencoding;

	int PagelistIndexSize;
	
	int count,k;
	static unsigned char buffer[512];
	unsigned char startchar,endchar;
	long p,h,c;
	BOOL lastword=NO;
	NSMutableArray *wlxposition,*wlxcount;
	regex_t	preg;
	NSRange r1,r2;
	
	NSString *firstletter;
	NSData *exp_data;
	
	wlxposition = [[NSMutableArray alloc]init];
	wlxcount = [[NSMutableArray alloc]init];

//	NSLog(@"expression : %@",_expression);
	// TODO Band sollte checken ob die PLX,WLX,TTX lesbar sind
	NSFileHandle* myNSFileHandle1 = [NSFileHandle fileHandleForReadingAtPath:[band IndexPLX_path]];
	plxfile = fdopen([myNSFileHandle1 fileDescriptor],"r");

	NSFileHandle* myNSFileHandle2 = [NSFileHandle fileHandleForReadingAtPath:[band IndexWLX_path]];
	wlxfile = fdopen([myNSFileHandle2 fileDescriptor],"r");

//	plxfile = fopen([[band IndexPLX_path] cString],"r");
//	wlxfile = fopen([[band IndexWLX_path] cString],"r");

        // check ob expression mit einem normalen buchstaben beginnt, wenn ja dann zum anfang in der wlx springen (ist eine kleine optimierung)
        // man den ersten buchstaben nehmen da alle einzelbuchstaben als woerter im wlx vorhanden sind, warscheinlich mit einem treffercount von 0
        // hinter dem buchstaben darf kein * oder ? sein weil das heisst das das zeichen auch fehlen darf
	r1 = [_expression rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvxyz"]];
	r2 = [_expression rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@".*+[]$(?)"]];
//	if (r1.location == 1 && r1.length >= 1 && r2.location != 2 && ([_expression characterAtIndex:0] == '^')) {
//		NSLog(@"expression started with a character!");
            // also ersten buchstaben nehmen
		firstletter = [NSString stringWithFormat:@"%C",[_expression characterAtIndex:1]];
		fseek(wlxfile,[self offsetOfSearchWord:firstletter],SEEK_SET);
		startchar = ([_expression lossyCString])[1];
		endchar = startchar+1;
//		NSLog(@"startchar : %c endchar : %c",startchar,endchar);
//	}
//	else
//	{
	// an startpostion im wlx springen
		fseek(wlxfile,0,SEEK_SET);  // scheint kein magic oder sowas zu geben
		endchar='z'+1;
//	}

	// hier schleife durch die ganze wlx
	// jedes wort testen falls match dann die seiten aus der plx holen
	// regexp bauen
	// TODO FUTURE : case sensivity bei regexp beachten
    // windows encoding NSWindowsCP1252StringEncoding
	exp_data = [[_expression lowercaseString] dataUsingEncoding:NSWindowsCP1252StringEncoding allowLossyConversion:YES];
	
	exp_winencoding = calloc([exp_data length] + 1, 1);

	strncpy(exp_winencoding, [exp_data bytes], [exp_data length]);
//	NSLog(@"windows string : %s",exp_winencoding);
	
	if (regcomp(&preg, exp_winencoding, REG_EXTENDED | REG_NOSUB | REG_ICASE) != 0)
	{
		// regular expr is wrong
		NSRunAlertPanel(@"Fehler beim Suchen", @"Die regexp : %@ ist ungueltig!",@"OK", nil, nil,_expression);
		// NSLog(@"DBSuchBitmap.m : getSuchRegExpBitmap : regluar expression creation failed");
		rv = NO;
	}
	else {  // regular expr is good
            while (!lastword)
			{
                    // read next word aus wlx
                    if (fread(&p,1,4,wlxfile) == 4 && fread(&h,1,4,wlxfile) == 4 && fread(&c,1,4,wlxfile) == 4) { //sieht aus als ist da noch ein wort
                            p = NSSwapLittleLongToHost(p);
                            h = NSSwapLittleLongToHost(h);
                            c = NSSwapLittleLongToHost(c);
                            i=0;
                            while ((fread(&(buffer[i++]),1,1,wlxfile)) && buffer[i-1] != 0);
                            buffer[i]=0;
                            if (buffer[0] == endchar)
                                    break;
                    // word testen
                            if (0 == regexec(&preg,buffer,0,0,0)) { // TODO : hier noch die windows encoding machen
                                                                    // wenn ja dann position in plx speichern
								
                                    [wlxposition addObject:[NSNumber numberWithInt:p]];
                                    [wlxcount addObject:[NSNumber numberWithInt:c]];
                                    words[h]=1;
                                    matches=YES;
    //				NSLog(@"regmatch : %s",buffer);
                            }
                    }
                    else
                            lastword=YES;
            } // END : while (!lastword)
            regfree(&preg);
            // alle positionen in plx lesen und in bitmap speichern
            if ([Helper isMagic:plxfile])   // magic number
            {
                    fseek(plxfile,32,SEEK_SET);
                    fread(&b,1,1,plxfile);
                    PagelistIndexSize = b + 1;
//                    NSLog(@"PageIndexSize %d",PagelistIndexSize);
            }
            else {
                    PagelistIndexSize = 4;
            }
            
            count = [wlxposition count];
            for (i=0 ; i < count ; i++) {
                    p = [[wlxposition objectAtIndex:i] intValue];
                    c = [[wlxcount objectAtIndex:i] intValue];
                    
                    fseek(plxfile,p,SEEK_SET);
    //		NSLog(@"position in wlx file: %p count:%d",p,c);
                    for (k = 0 ; k < c ; k++,pagenum=0) 
                    {
                            fread(&buff,1,PagelistIndexSize,plxfile);
                            pagenum = [self plxPagenumber:buff PagelistIndexSize:PagelistIndexSize];
                            // in die pages bitmap einfuegen
							if ((pagenum >= firstPageNum) && (pagenum <= lastPageNum))
								pages[pagenum] = 2;
                            // in die hashes bitmap einfuegen
                    }
            }
            fclose(plxfile);
            fclose(wlxfile);

			[myNSFileHandle1 closeFile];
			[myNSFileHandle2 closeFile];
        }
	free(exp_winencoding);
	return rv;
}

-(NSString *)getSearchWord:(unsigned long)index count:(long*)c hash:(long*)h position:(long*)p
{
	NSString *s;
	FILE *f;
	int cnt,i;
	static char buffer[512];
	long w1,w2,w3;

	NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:[band IndexWLX_path]];
	f = fdopen([myNSFileHandle fileDescriptor],"r");

//	f = fopen([[band IndexWLX_path] cString],"r");
	fseek(f,index,SEEK_SET);

	cnt = fread(&w1,1,4,f);
	cnt = fread(&w2,1,4,f);
	cnt = fread(&w3,1,4,f);

	*p = NSSwapLittleLongToHost(w1);
	*h = NSSwapLittleLongToHost(w2);
	*c = NSSwapLittleLongToHost(w3);

	fread(&buffer,1,512,f);

	//NSLog(@"w1: %010p w2: %010p w3: %d string: %s",w1,w2,w3,buffer);
	fclose(f);

	[myNSFileHandle closeFile];

	for (i=0 ; buffer[i] != 0; i++);

	s = [[NSString alloc] initWithData:[NSData dataWithBytes:&buffer length:i] encoding:NSWindowsCP1252StringEncoding];
	return [s autorelease]; 
}

-(unsigned long)hashHTX:(NSString *)_word
{
//  Result := (((Result*ord(w[i]) mod HashTableEntries)+1)*ord(w[i]) mod HashTableEntries)+1;
	
	unsigned long Result = 1;
	unsigned int i;
	unsigned char *c;
	NSData *stringdata = [_word dataUsingEncoding:NSWindowsCP1252StringEncoding allowLossyConversion:YES];
	c = (unsigned char *)[stringdata bytes];
	for (i = 0;  i < [_word length]; i++)
	{
//		int ord = [_word characterAtIndex:i];
		int ord = c[i];
		Result = (((Result * ord % HashTableEntries)+1) * ord % HashTableEntries)+1;
	}
	
//	NSLog(@"Hash: %010p",Result);
	return Result-1;
}

-(void)makeSuchBitmap:(int)_wordlistposition count:(int)_count
{
	FILE *f;
	int i,pagenum=0;
	unsigned char buff[4],b;
	
	int PagelistIndexSize;
	
	NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:[band IndexPLX_path]];
	f = fdopen([myNSFileHandle fileDescriptor],"r");

//	f = fopen([[band IndexPLX_path] cString],"r");
	
	if ([Helper isMagic:f])   // magic number
	{
		fseek(f,32,SEEK_SET);
		fread(&b,1,1,f);
		PagelistIndexSize = b + 1;
//		NSLog(@"PageIndexSize %d",PagelistIndexSize);
	}
	else
	{
		PagelistIndexSize = 4;
	}
	
	fseek(f,_wordlistposition,SEEK_SET);
//	NSLog(@"Position %p",_wordlistposition);
	
	for (i = 0 ; i < _count ; i++,pagenum=0) 
	{
		// TODO OPTIMIZE : man kann auch gleich alle laden und alle auf einmal wandeln
		fread(&buff,1,PagelistIndexSize,f);
		pagenum = [self plxPagenumber:buff PagelistIndexSize:PagelistIndexSize];
		if ((pagenum >= firstPageNum) && (pagenum <= lastPageNum))
			pages[pagenum] = 2;
	}

	fclose(f);

	[myNSFileHandle closeFile];
}

-(int)plxPagenumber:(unsigned char*)_buff PagelistIndexSize:(int)_indexsize
{
	int pagenum = 0;
	switch (_indexsize) 
	{
		case 1:
			NSLog(@"Error PagelistIndexSize=1");
			break;
		case 2:
			pagenum = _buff[0] + (_buff[1] << 8);
			break;
		case 3:
			pagenum = _buff[0] + (_buff[1] << 8) + (_buff[2] << 16);
			break;
		case 4:
			pagenum = _buff[0] + (_buff[1] << 8) + (_buff[2] << 16) + (_buff[3] << 24);
			break;
		default:
			NSLog(@"Error PagelistIndexSize > 4");
			pagenum = 0;
			break;
	}
	return pagenum;
}

-(unsigned long)offsetOfSearchWord:(NSString *)_word
{
	long hash;
	hash = [self hashHTX:_word];
//	NSLog(@"offsetOfSearchWord : %@",_word);
	const unsigned long *table = [[band IndexHTXTable] bytes];
	return NSSwapLittleLongToHost(table[hash]);
}

-(BOOL)sucheCheckForRegularExpression:(NSString *)_word
{
    NSRange r;
    // durch das wort laufen und auf auffaelige zeichen achten !
    r = [_word rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@".*+[]$^(?)"]];
    
    return (r.length >= 1);
}

-(void)extend
{
/*
erweitert die eintraege ind der bitmap,
wird gebraucht damit die und verknuepfung funktioniert.
*/
    unsigned char *bm,*newpages;
    int i;
    bm = [self pages];
    newpages = calloc(maxpages+1,1);

    for (i=maxpages-1 ; i >= 1 ; i--) {
        if (bm[i]) {
            newpages[i+1]=1;
            newpages[i-1]=1;
            newpages[i]=1;
        }
    }
    free(pages);
    pages=newpages;
}

-(DBSuchBitmap *)FOLGT:(DBSuchBitmap *)_bm
{
/*
FOLGT Verknuepfung
Beide suchbitmaps werden FOLGT verknuepft
Eine neue Bitmap wird erstellt und zurueckgeliefert (autoreleased)
*/ 
    return [self UND:_bm];
}

-(DBSuchBitmap *)UND:(DBSuchBitmap *)_bm
{
/*
UND Verknuepfung
Beide suchbitmaps werden UND verknuepft
Eine neue Bitmap wird erstellt und zurueckgeliefert (autoreleased)
*/ 
    int i;
    DBSuchBitmap *bitmap;
    unsigned char *bm1,*bm2,*bm,*words0,*words1,*words2;

	if (_bm == nil)
		return nil;
	
//	NSLog(@"UND : bm1 %@ bm2 %@",self,_bm);
    bitmap = [[DBSuchBitmap alloc] init:band caseSensivity:caseSensivity];

    [self extend];

    bm = [bitmap pages];
    bm1 = [self pages];
    bm2 = [_bm pages];
    
    words0 = [bitmap words];
    words1 = [self words];
    words2 = [_bm words];
    
    for (i = 1 ; i <= maxpages ; i++) {
		if (bm1[i] && bm2[i]) { 
			bm[i] = 1;
			bm[i-1] = 1;
			bm[i+1] = 1;
		}
    }
    // UNKNOWN muss man hier die hashkey auch noch zusammenfuehren ?
    // erstmal kopieren wir nur die erste wordlist !
    //for (i = 0 ; i < HashTableEntries ; i++)
    //    words1[i] = words1[i] | words2[i];
    memcpy(words0,words1,HashTableEntries);
//	NSLog(@"result bm:%@",bitmap);
    return [bitmap autorelease];
}

-(DBSuchBitmap *)ODER:(DBSuchBitmap *)_bm
{
/*
ODER Verknuepfung
Beide suchbitmaps werden ODER verknuepft
*/ 
    int i;
    DBSuchBitmap *bitmap;
    unsigned char *bm1,*bm2,*bm,*words0,*words1,*words2;

	if (_bm == nil)
		return nil;
    bitmap = [[DBSuchBitmap alloc] init:band caseSensivity:caseSensivity];

    bm = [bitmap pages];
    bm1 = [self pages];
    bm2 = [_bm pages];
    
    words0 = [bitmap words];
    words1 = [self words];
    words2 = [_bm words];
    
    for (i = 1 ; i < maxpages ; i++) {
        bm[i] = bm1[i] | bm2[i];
    }
    for (i = 0 ; i < HashTableEntries ; i++)
        words0[i] = words1[i] | words2[i];
        
    return [bitmap autorelease];
}


-(int)nextWordHash
{
/* liefert den naechsten hash aus der hashbitmap,
wenn es am ende ankommt geht es beim naechsten durchlauft wieder von vorne los
*/
	int rv=0;
	
    if (lastHash) {
        lastHash=NO;
        actualHashNum=0;
    }
    while (actualHashNum <= HashTableEntries) {
        if (words[actualHashNum])
            break;
        actualHashNum++;
    }
    if (actualHashNum >= HashTableEntries) {
        lastHash=YES;
    }
    if (words[actualHashNum])
        rv = actualHashNum;
	actualHashNum++;
	return rv;
}

-(BOOL)lastHash
{
	if (lastHash) {
		lastHash=NO;
		actualHashNum=0;
		return YES;
	}
    return NO;
}

-(BOOL)getNextCandidate:(int)_seite Word:(int)_word Bitmap:(DBSuchBitmap*)_bitmap
{
	actualPageNum = _seite;
	actualWordNum = _word;
	actualHashNum = 0;
	candpages=[_bitmap pages];
	
//	NSLog(@"getNextCandidate: Seite:%d Word:%d self:%@ withBitmap:%@",_seite,_word,self,_bitmap);
//	NSLog(@"getNextCandidate: Seite:%d Word:%d",_seite,_word);
	
	if (actualPageNum == -1) {
		candidatePageNum=-1;
		candidateWordNum=-1;
		return NO;
	}
	
	if (regexp) {   // haben viele hashes
		while (actualPageNum < maxpages) {
			while (![self lastHash]) {		// schleife fuer alle hashes
				actualHash = [self nextWordHash];
				if ([self nextHashPositionFromTTX]) {
					// treffer also aufhoeren und zureckkehren
					candidatePageNum = actualPageNum;
					return YES;
				}
			}
			// vor zur naechsten verdaechtigen seite
			do {
				actualPageNum++;
				if (candpages[actualPageNum]) {
					actualWordNum=0;
					break;
				}
			} while (actualPageNum < maxpages);
		}
	}
	
	else {  // haben nur einen hash
        while (actualPageNum < maxpages) {
            if ([self nextHashPositionFromTTX]) {
                // treffer also aufhoeren und zureckkehren
                candidatePageNum = actualPageNum;
//				NSLog(@"Treffer pagenum :%d wordnum:%d",candidatePageNum,candidateWordNum);
                return YES;
            }
            else {
                // vor zur naechsten verdaechtigen seite
				// DONE : hier als bitmap nicht die eigene sondern die kummulierte !!!
				do {
					actualPageNum++;
                    if (candpages[actualPageNum]) {
						actualWordNum=0;
                        break;
					}
				} while (actualPageNum < maxpages);
            }
        }
	}
//	NSLog(@"getNextCandidate : Kein Treffer");
	return NO;
}

-(BOOL)folgtAufSeite:(int)_page Word:(int)_word
{
    return ((candidatePageNum == _page) && (_word+1 == candidatePageNum));
}

-(int)candidatePageNum
{
    return candidatePageNum;
}

-(int)candidateWordNum
{
    return candidateWordNum;
}

-(BOOL)nextHashPositionFromTTX
{
	/*
	 die wortposition fuer den hash auf der seite ermitteln, koennen auch wieder viele sein nur den naechsten geben
	 RETURNS : sets actualWordNum auf die nummer des wortes welches mit dem hash match
	 RETURNS : YES on success
	 */
    BOOL found=NO;
    
	if (lastTTXPage != actualPageNum) {
		if (TTXhashlist)		// hatten wir schon eine im speicher diese dann auch wieder freigeben
			free(TTXhashlist);
		TTXhashlist = [band loadHashListForPage:actualPageNum hashcount:&TTXMaximumNum caseSensitive:regexp ? NO : caseSensivity];
		lastTTXPage = actualPageNum;
		actualHashNum=actualTTXPositionNum=0;
	}
	if (TTXhashlist == NULL)
		return found;

	actualTTXPositionNum = actualWordNum;
	for ( ; actualTTXPositionNum < TTXMaximumNum && !found ; actualTTXPositionNum++) {
		// schleife fuer die einzelnen hashes auf einer seite
		if (actualHash == TTXhashlist[actualTTXPositionNum]) {  // hash gefunden
			actualWordNum = actualTTXPositionNum;
			candidateWordNum = actualTTXPositionNum;
			found = YES;
		}
	}
	// actualWordNum ist richtig, actualTTXPostionNum steht 1 weiter, macht also beim naechsten durchgang an der richtigen stelle weiter
	return found;
}

-(BOOL)nextHashForPage
{
/* nextHashForPage gibt den naechsten hash aus der words bitmap zurueck
    falls diese funktion ans ende der words bitmap stoesst wird lastHash gesetzt
    wenn die funktion dann wieder aufgerufen wird faengt sie wieder mit dem ersten hash aus der words bitmap an
    RETURNS YES if there is a hash to Return
*/
    BOOL found=NO;
    
	if (!regexp) {
		NSLog(@"nextHashForPage called without regexp mode, this should not happen");
		return YES;
	}
	
    if (lastHash) {
        actualHashNum=0;
        lastHash=NO;
    }
    for (;actualHashNum < HashTableEntries; actualHashNum++) {
        if (words[actualHashNum]) {
            actualHash=actualHashNum;
            found=YES;
            break;
        }
    }
    if (actualHashNum==HashTableEntries-1) {
        lastHash=YES;
    }
    return found;
}

-(void)setPosition:(int)pageNum
{
    actualPageNum = pageNum;
}

-(Band *)band
{
    return band;
}

-(unsigned char *)pages
{
    return pages;
}

-(unsigned char *)words
{
    return words;
}

-(NSMutableArray *)wordlist
{
    return wordlist;
}



@end
