/*
 * DBSuche.m -- 
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

#import "DBSuche.h"
#import "DBSuchBitmap.h"

NSString *kSuchStartFailed=@"SuchStartFailedNotification";
NSString *kSuchFinish=@"SucheFinishedNotification";
NSString *kSuchStopped=@"SucheStoppedNotification";
extern NSMutableDictionary *unicodedict;

@implementation Band (Suche)

-(void)sucheStarten:(NSDictionary *)_suchdict
{
	NSAutoreleasePool *pool;		// wird benoetigt da es sich um nen Thread handelt
	BOOL lastHit;
	NSMutableDictionary *dict;
	
	int pageNum,wordNum,fundstelle;
	pool = [[NSAutoreleasePool alloc] init];
	NSProgressIndicator *progressbar;
	
	sucheStoppen=NO;
	sucheAktiv=YES;
//	NSLog(@"Suchbegriff: %@",[_suchdict objectForKey:@"suchbegriff"]);
	progressbar = [_suchdict objectForKey:@"progressbar"];
	[progressbar setIndeterminate:YES];
	[progressbar startAnimation:self];
	[progressbar setUsesThreadedAnimation:YES];

	if ([self initSuche:[_suchdict objectForKey:@"suchbegriff"] startseite:[[_suchdict objectForKey:@"startseite"]intValue] endseite:[[_suchdict objectForKey:@"endseite"] intValue] maxwortabstand:[[_suchdict objectForKey:@"maxwortabstand"] intValue] maxfundstellen:[[_suchdict objectForKey:@"maxfundstellen"] intValue] grosskleinschreibung:[[_suchdict objectForKey:@"grosskleinschreibung"] intValue] schreibweisentolerant: [[_suchdict objectForKey:@"schreibweisentolerant"] intValue]]) {
		// suche erfolgreich gestartet

		// progressbar auf derterminat umschalten
		[progressbar stopAnimation:self];
		[progressbar setIndeterminate:NO];
		[progressbar setMinValue:0];
		[progressbar setMaxValue:[[_suchdict objectForKey:@"maxfundstellen"] intValue]];
		[progressbar setDoubleValue:1.0];
	}
	else	// suche starten failed send notification to controller
	{
		sucheFehlerMeldung = [NSString stringWithUTF8String:"ungültige Suchparameter!"];
		[[NSNotificationCenter defaultCenter] postNotificationName:kSuchStartFailed object:sucheFehlerMeldung];
		[progressbar setDoubleValue:0.0];
		[progressbar stopAnimation:self];
		[progressbar setNeedsDisplay:YES];
		[pool release];
		return;
	}

	pageNum=sucheStartseite;
	wordNum=1;
	fundstelle=0;

//	NSLog(@"Schreibweisentolerant: %d",[[_suchdict objectForKey:@"schreibweisentolerant"] intValue]);

	// Fundstellenliste aufbauen

	do {
		NSArray *values,*keys;
		lastHit=[self nextHit:&pageNum word:&wordNum];
		if (lastHit)	// treffer
		{
			values = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:pageNum],[NSNumber numberWithInt:wordNum],[NSNumber numberWithInt:wordNum],[NSNumber numberWithInt:1],[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1],nil];	// 5 ist der rote marker
			keys = [[NSArray alloc] initWithObjects:@"Seite",@"StartWort",@"EndWort",@"Tag",@"Farbe",nil];
			dict = [[NSMutableDictionary alloc] initWithObjects:values forKeys:keys];

// arrayWithObjects:@"Text",@"Seite",@"Range",@"Tag",@"Farbe",@"Konkordanz",@"Bereich",@"Abschnitt",nil]];

			[self fillFundstelle:dict];
			[fundstellenDS addObject:dict];
			[keys release];
			[values release];
			[dict release];
			
			fundstelle++;
			[progressbar setDoubleValue:fundstelle];

			if (fundstelle % 50)
			{
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
			}	
		}
	} while (fundstelle < sucheMaxFundstellen && lastHit && !sucheStoppen);
	
	sucheAktiv=NO;
	[progressbar setDoubleValue:0.0];
	[progressbar stopAnimation:self];

	if (!sucheStoppen)
//		[self performSelectorOnMainThread:@selector(sucheFinishedNotification:) withObject:[NSString stringWithFormat:@"%d%s Treffer",fundstelle,fundstelle >= sucheMaxFundstellen? "+" :""] waitUntilDone:NO];

		[[NSNotificationCenter defaultCenter] postNotificationName:kSuchFinish object:[NSString stringWithFormat:@"%d%s Treffer",fundstelle,fundstelle >= sucheMaxFundstellen? "+" :""]];
	else
		[[NSNotificationCenter defaultCenter] postNotificationName:kSuchStopped object:[NSNumber numberWithInt:fundstelle]];

	[pool release];
}

-(void)fillFundstelle:(NSMutableDictionary *)_dict
{
	DBPage *page;
	NSString *konkordanz,*abschnitt,*bereich;
	NSMutableArray *wordlist;
	NSString *text,*sigel;
	Word *theword;
	int startwort,seite,konkordanznummer;
	
	seite = [[_dict objectForKey:@"Seite"] intValue];
	startwort = [[_dict objectForKey:@"StartWort"] intValue];

	if ([sucheLetzteGesuchteSeite textpagenumber] != seite)
	{
		[sucheLetzteGesuchteSeite release];
		page = [self textPageData:seite];
		sucheLetzteGesuchteSeite = [page retain];
		[page parsePageWithFontSize:40.0 suche:YES];		// muss sein damit Instanzvariablen in DBPage gesetzt werden
	}
	else
	{
//		NSLog(@"+");
		page = sucheLetzteGesuchteSeite;
	}

	wordlist = [page newWordList];
	
	abschnitt = [page abschnitt];
	bereich = [page bereich];
	if (startwort > [wordlist count]) {				// hier wort was nicht mehr in der wordlist ist!!!
//		NSLog(@"Wort : %d > wordlistcount:%d seite:%d",startwort,[wordlist count],seite);
		return;
	}

	if (startwort == [wordlist count]) {				// hier wort was nicht mehr in der wordlist ist!!!
		startwort--;
		[_dict setObject:[NSNumber numberWithInt:startwort] forKey:@"StartWort"];						// naja ist halt das letzte wort nur ist das leider auch noch getrennt
	}
	
	theword = [wordlist objectAtIndex:startwort];
	
	text = [theword word];
	konkordanznummer = [theword konkordanz];
	sigel = [theword sigel];
	
	konkordanz = sigel && konkordanznummer ? [NSString stringWithFormat:@"%@, %d",sigel,konkordanznummer] : sigel;

	if (!konkordanz)
		konkordanz=@"";
	if (!bereich)
		bereich=@"";
	if (!abschnitt)
		abschnitt=@"";
	if (!text)
		text=@"";
	
	[_dict setObject:konkordanz forKey:@"Konkordanz"];
	[_dict setObject:bereich forKey:@"Bereich"];
	[_dict setObject:abschnitt forKey:@"Abschnitt"];
	[_dict setObject:text forKey:@"Text"];
}

-(void)sucheStoppen
{
	sucheStoppen=YES;
}

-(BOOL)initSuche:(NSString *)_suchstring startseite:(long)_startseite endseite:(long)_endseite maxwortabstand:(int)_maxwortabstand maxfundstellen:(int)_maxfundstellen grosskleinschreibung:(BOOL)_grosskleinschreibung schreibweisentolerant:(BOOL)_schreibweisentolerant
{
	BOOL rv=NO;
	enum suchwortteile {ksuchwort,ksuchund,ksuchoder};
        
	/*
	Suchbeispiele : (goethe UND schiller) ODER ^h[oauie]ffm[aeiuo]nn$
        Wortabstand: 50 gross/klein aus und SCHREIBWEISENTOLERANT
        Suchoperatoren : "UND", "(", ")", "ODER", " " 

	 1a. Suchstring in token zerlegen!
         1b. Suchstring in einen suchbaum umwandeln, dann mit dem tiefsten knoten anfangen (Baum traversieren): 
	 2. wenn SCHREIBWEISENTOLERANT oder regexp auf regexp schalten sonst nicht, das pro wort entscheiden
	 3. aus denn UND,ODER nen expression machen und die speichern
	 4. fuer jedes suchwort eine bitmap mit allen treffern generieren braucht also seiten * suchwoerter + suchwoerter * hashtablesize bits
            sowie fuer jedes suchwort noch eine bitmap mit der groesse hashtable mit hashkey als index, damit man spaeter nicht nochmal
            aus den woertern hashkeys machen muss um die treffer in der ttx zu finden.
	   A. bei regexp die wortliste durchwandern
	   B. bei normalen woertern den hash index benutzen
	 5. Alle diese Daten speichern damit bei nextTreffer darauf zurueckgegriffen wird
	 */
	sucheLetzteGesuchteSeite=nil;
	sucheStartseite=_startseite;
	sucheEndseite=_endseite;
//	NSLog(@"Suche startseite : %d endseite : %d Toleranz: %d",sucheStartseite,sucheEndseite,_schreibweisentolerant);
	smallestWord=-1;
	smallestSeite=-1;
	
        sucheCaseSensivity = _grosskleinschreibung;
		sucheSchreibweisentolerant = _schreibweisentolerant;
        SucheTokenList = [self sucheCreateTokenlist:_suchstring];
        if (SucheTokenList) {   // wurde liste erstellt
            SucheTokenList=[self sucheFillSuchliste:SucheTokenList];
            if (SucheTokenList) {   // wurde liste erstellt
                    SucheBitmap = [self sucheSyntaxParser:SucheTokenList];
                    if (SucheBitmap) {  // alles ok suche kann beginnen
                        rv = YES;
//						NSLog(@"initSuche : SucheBitmap : %@",SucheBitmap);
                        [SucheBitmap retain];
                        [SucheTokenList retain];
                    }
            }
        }
        else { 
            rv=NO;
        }
		sucheAktuelleseite=_startseite;

		sucheMaxwortabstand=_maxwortabstand;
		sucheMaxFundstellen=_maxfundstellen;
		sucheAktuelleswort=0;
		endeSuche=noMoreHits=NO;
		
        return rv;
}

-(BOOL)nextHit:(int *)_pageNum word:(int *)_wordNum
{
	/*
	 nextHit: returns YES if a match was found, NO on failure
	 and sets the two references passed appropriate
	*/
	BOOL found=NO;
	
	do {
		int s,w;
		iniCandPage=iniCandWord=candPage=candWord=smallestSeite=smallestWord=-1;
		sucheSyntaxActualTokenNum = -1;
		sucheSyntaxActualToken = [self sucheSyntaxNextToken];
		sucheSyntaxActualTokenNum = 0;
	
		found = [self nextHitInExpression];

		findSmallestHit(iniCandPage,iniCandWord,candPage,candWord,&s,&w);
		iniCandWord=w;
		iniCandPage=s;
		
		sucheAktuelleswort=smallestWord+1;
		sucheAktuelleseite=smallestSeite;

//		NSLog(@"%d : %d",sucheAktuelleseite,sucheAktuelleswort);
		endeSuche = (sucheAktuelleseite >= lastpagenumber || sucheAktuelleseite == -1 || sucheAktuelleseite == 0);
		// TODO : sollte noch ne seite mehr sein aber erstmal zum test eins frueher aufhoeren
	} while(!found && !endeSuche);

	*_pageNum=iniCandPage;
	*_wordNum=iniCandWord;
//	if (found)
//		NSLog(@"Suche : Treffer!");

	return found;
}

-(BOOL)nextHitInWord
{
    DBSuchBitmap *bm;

    switch (sucheSyntaxActualToken) {
        case OPEN:
            if (![self sucheSyntaxConsumeToken:OPEN])
                    return NO;
//            NSLog(@"OPEN");
            [self nextHitInExpression];
            if (![self sucheSyntaxConsumeToken:CLOSE])
                    return NO;
//            NSLog(@"CLOSE");
            break;
        case WORD:
            bm = [[SucheTokenList objectAtIndex:sucheSyntaxActualTokenNum] objectForKey:@"bitmap"];
            if (![self sucheSyntaxConsumeToken:WORD])
                    return NO;
//            NSLog(@"WORD");
			if ([bm getNextCandidate:sucheAktuelleseite Word:sucheAktuelleswort Bitmap:SucheBitmap])
			{ // haben einen treffer
//				NSLog(@"Candidate found for hash : %p page:%d word:%d !",sucheAktuellesHash,[bm candidatePageNum],[bm candidateWordNum]);
				int ss,sw;
				
				candPage=[bm candidatePageNum];
				candWord=[bm candidateWordNum];
				findSmallestHit(candPage,candWord,smallestSeite,smallestWord,&ss,&sw);
				smallestSeite=ss;
				smallestWord=sw;
				return YES;
            }
            break;
        default:
            NSLog(@"sucheSyntaxWord switch default reached. UNKNOWN token");
            break;
    }
    return NO;
}

-(BOOL)nextHitInExpression
{
/* 
benutzt die tokenlist und die bitmap um den naechsten hit zu finden und gibt
YES wenn treffer!
NO wenn keine weiteren treffer vorhanden sind
*/
	int prevCandPage,prevCandWord;
	
    if ([self nextHitInWord]) {	
		iniCandPage = candPage;
		iniCandWord = candWord;
// mal schauen ob das hier gut ist
//		prevCandPage=candPage;
//		prevCandWord=candWord;

	}
    
    while (sucheAktuelleseite <= lastpagenumber)
	{
        switch (sucheSyntaxActualToken)
		{
            case UND:
                if (![self sucheSyntaxConsumeToken:UND])
                    return NO;
//                NSLog(@"UND");
				prevCandPage=candPage;
				prevCandWord=candWord;
//				NSLog(@"UND1: %d:%d",prevCandPage,prevCandWord);
                [self nextHitInWord];
//				NSLog(@"UND2: %d:%d",candPage,candWord);
                if (prevCandPage != -1 && candPage != -1) {
                // evtl. Treffer also weiter den kleineren finden
					int ss,sw,bs,bw;
					findSmallestHit(prevCandPage,prevCandWord,candPage,candWord,&ss,&sw);
					// den abstand bestimmen falls der kleiner maxwortabstand dann bingo
					// welcher ist der groessere
					bs = prevCandPage >= candPage ? prevCandPage : candPage;
					if (prevCandPage == candPage) {
						bw = candWord > prevCandWord ? candWord : prevCandWord;
					}
					else 
						bw = prevCandPage > candPage ? prevCandWord : candWord;
					if ([self inWortabstand:sucheMaxwortabstand page1:ss word1:sw page2:bs word2:bw])
					{
						candPage=ss;
						candWord=sw;
//						NSLog(@"Treffer UND Operator");
					}
					else { // kein treffer candidate ungueltig
						candPage = -1;
						candWord = -1;
					}
					
                }
					else { // kein treffer candidate ungueltig
						candPage = -1;
						candWord = -1;
					}
					continue;
            case ODER:
                if (![self sucheSyntaxConsumeToken:ODER])
                    return NO;
//                NSLog(@"ODER");
				prevCandPage=candPage;
				prevCandWord=candWord;
                [self nextHitInWord];
                if (prevCandPage != -1 || candPage != -1) {
                // Treffer also weiter den kleineren finden
					int s,w;
					findSmallestHit(prevCandPage,prevCandWord,candPage,candWord,&s,&w);
					candPage=s;
					candWord=w;
//					NSLog(@"Treffer ODER Operator");
                }
				else { // kein treffer candidate ungueltig
						candPage = -1;
						candWord = -1;
				}
                continue;
            case BLANK:
                if (![self sucheSyntaxConsumeToken:BLANK])
                    return NO;
//                NSLog(@"BLANK");
				prevCandPage=candPage;
				prevCandWord=candWord;
                [self nextHitInWord];
                if (prevCandPage == candPage && prevCandWord == candWord-1) {
                // echter Treffer also weiter
//					NSLog(@"Treffer BLANK Operator");
                }
                else { // kein treffer candidate ungueltig
                    candPage = -1;
                    candWord = -1;
                }
                continue;
            case END:   // hier nix mehr consume weil ist ja ende, ausserdem holt consume schon das naechste, aber das existiert ja nicht!
//                NSLog(@"END");
                break;
            case CLOSE:   
//                NSLog(@"CLOSE");
				return (candPage!=-1) ? YES : NO;
                break;				
            default:
                NSLog(@"nextHitInExpression : default case: Should not happen!");
                return NO;
                break;
        }
        break;  // fuer die while schleife , kommt nur hier an wenn END token gefunden wurde!
    }
    return (candPage!=-1) ? YES : NO;
}

/* Erzeugt ein mutabledictionary mit den keys _tokennum und _word */
-(NSMutableDictionary *)sucheCreateToken:(int)_tokennum suchstring:(NSString *)_string
{
//	NSLog(@"token : %d\t\t value : %@",_tokennum,_string ? _string : @"empty");
	return [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:_tokennum],_string?_string:@"",nil] forKeys:[NSArray arrayWithObjects:@"token",@"word",nil]];
}

-(NSMutableArray *)sucheCreateTokenlist:(NSString *)_suchstring
{
/*  sucheCreateSuchbaum: Erzeugt aus dem suchstring eine tokenliste.
Die tokenliste hat als elemente dicts mit den keys : (enum suchtoken) token
RETURNS tokenliste on success nil on failure
*/
	char buffer[256];
	int i,wordlen,toknum;
	const char *suchstring;
	char c;
	enum suchtoken lasttoken=NIX;
	
	NSMutableArray *tokenlist;
	NSMutableString *teilsuchwort;
	teilsuchwort = [[NSMutableString alloc]init];

	suchstring = [[_suchstring stringByAppendingString:@" "] lossyCString];
	
// lexikalische analyse
// vorher noch die codierung nach windows machen
	tokenlist = [[[NSMutableArray alloc] init] autorelease];
	toknum=wordlen=i=0;
	do { 
		c = suchstring[i];
		if (c == ' ') { // altes wort zu ende also gibts auch nen neues BLANK token
			if (wordlen > 0) { // da war schon ein wort, checken was fuer ein wort
				if ((wordlen == 3 && strncmp("UND",buffer,3) == 0)) { // wenn es ein UND o. ODER dann entspr. token erzeugen
					[tokenlist addObject:[self sucheCreateToken:(int)UND suchstring:nil]];
					lasttoken=UND;
					wordlen=0;
					[teilsuchwort setString:@""];
				}
				else if ((wordlen == 4 && strncmp("ODER",buffer,4) == 0)) {
					[tokenlist addObject:[self sucheCreateToken:(int)ODER suchstring:nil]];
					lasttoken=ODER;					
					wordlen=0;
					[teilsuchwort setString:@""];
				}
				else { //handelt sich um ein echtes suchwort
					//erstmal noch die null am stringende reinpumpen
					buffer[wordlen]=0;
					[tokenlist addObject:[self sucheCreateToken:(int)WORD suchstring:[teilsuchwort copy]]];
					lasttoken=WORD;
					wordlen=0;
					[teilsuchwort setString:@""];
				}
			}
			if (lasttoken != BLANK) { // wordlen == 00 -> es ist ein BLANK token, falls der letzte noch keiner war dann ein BLANK generieren
				[tokenlist addObject:[self sucheCreateToken:(int)BLANK suchstring:nil]];
				lasttoken=BLANK;
			}
		}
		else if (c == '<') {
			// offene klammer
			if (wordlen > 0) {
				buffer[wordlen]=0;
				[tokenlist addObject:[self sucheCreateToken:(int)WORD suchstring:[teilsuchwort copy]]];
				lasttoken=WORD;
			}
			wordlen=0;
			[teilsuchwort setString:@""];

			
			[tokenlist addObject:[self sucheCreateToken:(int)OPEN suchstring:nil]];
			lasttoken=OPEN;
		}
		else if (c == '>') {
			// geschlossene klammer
			if (wordlen > 0) {
				buffer[wordlen]=0;
				[tokenlist addObject:[self sucheCreateToken:(int)WORD suchstring:[teilsuchwort copy]]];
				lasttoken=WORD;
			}
			wordlen=0;
			[teilsuchwort setString:@""];
			[tokenlist addObject:[self sucheCreateToken:(int)CLOSE suchstring:nil]];
			lasttoken=CLOSE;
		}
		else { // wort oder teil eines tokens
			buffer[wordlen++]=c;
			if (i < [_suchstring length]) {
				[teilsuchwort appendFormat:@"%C",[_suchstring characterAtIndex:i]];
//				NSLog(@"teilsuchwort : %@",teilsuchwort);
			}		
		}
		i++;
	} while (i <= strlen(suchstring));

 // END : 	for (i = 0 ; i < strlen(suchstring) ; i++) {
//	NSLog(@"lexed tokenlist %@",tokenlist);
	// die liste cleanen und die ueberfluessigen BLANK tokens entfernen
	NSEnumerator *enu;
	NSDictionary *akdict,*prevdict;
	NSMutableArray *resultarray;
	enum suchtoken prevtoken=NIX,aktoken;
	prevdict = nil;
	BOOL skip=NO,delprev=NO;
	enu = [tokenlist objectEnumerator];
	resultarray = [[NSMutableArray alloc]init];
	
	while (akdict = [enu nextObject]) {
		aktoken = [[akdict objectForKey:@"token"] intValue];
		switch (prevtoken) {
			case BLANK:
				if (aktoken == BLANK)
					skip=YES;
				if (aktoken == UND || aktoken == ODER || aktoken == CLOSE)
					delprev=YES;
				break;
			case OPEN:
				if (aktoken == BLANK)
					skip=YES;
				break;
			case CLOSE:
				skip=NO;
				break;
			case WORD:
				skip=NO;
				break;
			case UND:
				if (aktoken == BLANK)
					skip=YES;
				break;
			case ODER:
				if (aktoken == BLANK)
					skip=YES;
				break;
			default:
				skip=NO;
				delprev=NO;
				break;
		}
		if (delprev)
			[resultarray removeLastObject];
		if (!skip)
			[resultarray addObject:akdict];
		skip=NO;
		delprev=NO;
		prevtoken=aktoken;
	}
	if (prevtoken == BLANK)													// letztes BLANK token immer loeschen
		[resultarray removeLastObject];
	[resultarray addObject:[self sucheCreateToken:(int)END suchstring:nil]];

//	NSLog(@"result list : %@",resultarray);
	[teilsuchwort release];
        return resultarray;
}

-(NSMutableArray *)sucheFillSuchliste:(NSMutableArray *)_tokenlist
{
/* Erzeugt die bitmaps in der tokenliste fuer alle words unter dem key (DBSuchBitmap) bitmap
RETURNS tokenliste falls erfolgreich sonst nil
*/
    NSEnumerator *enu;
    NSMutableDictionary *tok;
    DBSuchBitmap *bm;

    enu = [_tokenlist objectEnumerator];
    while ((tok = [enu nextObject]) && !sucheStoppen) {
        if ([[tok objectForKey:@"token"] intValue] == WORD) {
            // eine suchbitmap dafuer erzeugen
//			NSLog(@"sucheFillSuchliste token %d word : %@",[[tok objectForKey:@"token"] intValue],[tok objectForKey:@"word"]);
            bm = [[DBSuchBitmap alloc] initWithWord:[tok objectForKey:@"word"] schreibweisentoleranz:sucheSchreibweisentolerant caseSensivity:sucheCaseSensivity band:self firstPage:sucheStartseite lastPage:sucheEndseite];
//            NSLog(@"%@",bm);
            if (!bm) {  // Fehler bei erstellung der bitmap also suche abbrechen !
                [_tokenlist release];   // alte tokenliste und die bitmaps darin loeschen
                return nil;
            }
            [tok setObject:[bm autorelease] forKey:@"bitmap"];
        }
    }
    return _tokenlist;
}


-(DBSuchBitmap *)sucheSyntaxParser:(NSMutableArray *)_tokenlist
{
/*
Diese Methode parst die Tokenliste und erzeugt die finale Bitmap welche spaeter von nextTreffer verwendet wird.
Wenn Fehler beim Aufbau des Baumes auftreten wird nil zurueckgeliefert und die Variable suchBitmap wird auf nil gesetzt.
RETURNS YES on success NO on failure
*/
	SucheTokenList = _tokenlist;
	sucheSyntaxActualTokenNum = -1;
        sucheSyntaxActualToken = [self sucheSyntaxNextToken];
	sucheSyntaxActualTokenNum = 0;
        SucheBitmap = [self sucheSyntaxSuche];
        return SucheBitmap;
}

-(enum suchtoken)sucheSyntaxNextToken
{
/* gibt das naechste token (lookahead) in einer such zurueck ohne es als aktuelles token zu setzen */
	return [[[SucheTokenList objectAtIndex:sucheSyntaxActualTokenNum+1] objectForKey:@"token"]intValue];
}

-(BOOL)sucheSyntaxConsumeToken:(enum suchtoken)_tok
{
/* erhoeht die tokenumber und checkt ob der richtige token,  YES on success */
        if (sucheSyntaxActualToken == _tok) {
            if (sucheSyntaxActualTokenNum < [SucheTokenList count]-1) {
                sucheSyntaxActualToken = [[[SucheTokenList objectAtIndex:++sucheSyntaxActualTokenNum] objectForKey:@"token"]intValue];
            }
            else {
                NSLog(@"DBSuche : sucheSyntaxConsumeToken : should not be reached !");
                return NO;
            }
            return YES;
        }
        else
            return NO;
}

-(DBSuchBitmap *)sucheSyntaxSuche
{
    sucheActualStartPage = sucheAktuelleseite;
//	NSLog(@"sucheSyntaxSuche : sucheActualStartPage : %d",sucheActualStartPage);
    return [self sucheSyntaxExpr];
}

-(DBSuchBitmap *)sucheSyntaxExpr
{
/* expr :== expr UND word
	| expr ODER word 
	| expr BLANK word
	| word
*/
    DBSuchBitmap *bm;
    bm = [self sucheSyntaxWord];
	if (bm== nil)	// Fehler bei sucheSyntaxWord
		return nil;
    while (1) {
        switch (sucheSyntaxActualToken) {
            case UND:
                if (![self sucheSyntaxConsumeToken:UND])
                    return nil;
//                NSLog(@"UND");
                bm = [bm UND:[self sucheSyntaxWord]];
                continue;
            case ODER:
                if (![self sucheSyntaxConsumeToken:ODER])
                    return nil;
//                NSLog(@"ODER");
                bm = [bm ODER:[self sucheSyntaxWord]];
                continue;
            case BLANK:
                if (![self sucheSyntaxConsumeToken:BLANK])
                    return nil;
//                NSLog(@"BLANK");
                bm = [bm FOLGT:[self sucheSyntaxWord]];
                continue;
            case END:   // hier nix mehr consume weil ist ja ende, ausserdem holt consume schon das naechste, aber das existiert ja nicht!
//                NSLog(@"END");
                break;
            case CLOSE:   // wieder zurueckkehren mit den tollen bitmap
				return bm;
//                NSLog(@"CLOSE");
                break;
            default:
                NSLog(@"sucheSyntaxExpr : default case: Should not happen!");
                return nil;
                break;
        }
        break;  // fuer die while schleife , kommt nur hier an wenn END token gefunden wurde!
    }
    return bm;
}

-(DBSuchBitmap*)sucheSyntaxWord
{
    DBSuchBitmap *bm;

    switch (sucheSyntaxActualToken) {
        case OPEN:
            if (![self sucheSyntaxConsumeToken:OPEN])
                    return nil;
//			NSLog(@"OPEN");
            bm = [self sucheSyntaxExpr];
            if (![self sucheSyntaxConsumeToken:CLOSE])
                    return nil;
//			NSLog(@"CLOSE");
            break;
        case WORD:
            bm = [[SucheTokenList objectAtIndex:sucheSyntaxActualTokenNum] objectForKey:@"bitmap"];
            if (![self sucheSyntaxConsumeToken:WORD])
                    return nil;
//			NSLog(@"WORD");
            break;
        default:
            NSLog(@"sucheSyntaxWord switch default reached. UNKNOWN token");
			return nil;
            break;
    }
    return bm;
}

-(void)hashKey3ToHashKey4:(unsigned char *)_ibuff caseSensitive:(BOOL)_case outbuffer:(long *)_obuff count:(int *)_count
{
// DONE : Gross und Kleinschreibung beruecksichtigen
// TODO : die hashes welche keine sind rausschmeissen, und die anzahl der entf. zurueckgeben
    int i,cnt;
    long mask;
	long correctedhash;

	cnt = 0;
    mask = _case ? 0xffffffff : 0xff7fffff;
    for (i = 0 ; i < *_count ; i ++) {
		correctedhash = ((_ibuff[i*3+0] + _ibuff[i*3+1] * 0x100 + _ibuff[i*3+2] * 0x10000) ) & mask;

		if ((correctedhash & 0x7FFFFF) < (0x7FFFFF - 0x200))  {
			_obuff[cnt] = correctedhash; 
			cnt++;
		}
		else { // es ist eine id oder sowas 
//			NSLog(@"hashKey3ToHashKey4 : id encountered position : %i",i);
		}
	}
	*_count = cnt;
}

-(BOOL)inWortabstand:(int)_distance page1:(int)_page1 word1:(int)_word1 page2:(int)_page2 word2:(int)_word2
{
	BOOL rv=NO;
	int wordcount;
	long *ttxlist;
	ttxlist = [self loadHashListForPage:_page1 hashcount:&wordcount caseSensitive:sucheCaseSensivity];
	free(ttxlist);
	// TODO den wirklichen abstand messen am besten innerhalb der ttx (Dazu braucht man aber wieder den hashkey)
	if (_page2 > _page1+1) {	// zu weit weg kann kein hit sein 
		rv = NO;
	}
	else if (_page1 == _page2) {
		rv = (_word2 - _word1 < _distance);
	}
	else if (_page2 == _page1+1) {
		rv =  ((wordcount-_word1+_word2) < _distance);
	}

//	NSLog(@"inWortabstand : dist: %d %d:%d/%d %d:%d",_distance,_page1,_word1,wordcount,_page2,_word2);
	return rv;
}

-(long *)loadHashListForPage:(int)_pageNumber hashcount:(int *)_hashcount caseSensitive:(BOOL)_case
{
/* liest aus der ttx die hashes fuer die aktuelle seite ein */
// DONE : die bereichsteile rausfiltern und dann denn hashcount korrigieren

	unsigned long tmp_long;
	unsigned long ttxpagenumbers;
	int readcount,hashcount;
	unsigned char *tmp_hashliste;
	long *outbuff;
	long offset_start,offset_end;
	BOOL oldStyleTTX=NO;
	
	if (_pageNumber == 0 || _pageNumber == -1) 
	{
		NSLog(@"loadHashListForPage : %d does not exist, too small!",_pageNumber);
		return NULL;
	}

	if (ttxhandle == 0)
	{
		NSLog (@"%@ file open error(1)",[self IndexTTX_path]);
		return NULL;
	}
	
	if (fseek(ttxhandle,0,SEEK_SET) != 0)
	{
		NSLog(@"%@ file seek error errno: %d (3)",[self IndexTTX_path],errno);
		return NULL;
	}
	
	readcount = fread(&tmp_long,1,4,ttxhandle);
	if (readcount != 4)
	{
		NSLog(@"%@ file read error errno: %d (2)",[self IndexTTX_path],errno);
		return NULL;
	}

//	NSLog(@"loadHashListForPage : page %d",_pageNumber);
	ttxpagenumbers=NSSwapLittleLongToHost(tmp_long);
//	NSLog (@"TTX Seitenanzahl: %d",ttxpagenumbers);
        // zum offset _pageNumber seeken
		//	NSLog(@"pagenum : %d",_pageNumber);
	if (fseek(ttxhandle,((ttxpagenumbers) * sizeof(long)) + 2 * sizeof(long), SEEK_SET) != 0)
	{
		NSLog(@"%@ file seek error errno: %d (2a)",[self IndexTTX_path],errno);
		return NULL;
	}

	if ( 4 != fread(&tmp_long,1,4,ttxhandle))
	{
		NSLog(@"%@ file read error errno: %d (2b)",[self IndexTTX_path],errno);
		return NULL;
	}
	oldStyleTTX = (tmp_long == 0) ? YES : NO;
		
	if (fseek(ttxhandle,((_pageNumber - 1) * sizeof(long)) + sizeof(long), SEEK_SET) != 0)
	{
		NSLog(@"%@ file seek error errno: %d (3)",[self IndexTTX_path],errno);
		return NULL;
	}

	// offset lesen
	if ( 4 != fread(&tmp_long,1,4,ttxhandle))
	{
			NSLog(@"%@ file read error errno: %d (4)",[self IndexTTX_path],errno);
			return NULL;
	}

	offset_start = NSSwapLittleLongToHost(tmp_long);

        if (fseek(ttxhandle,(_pageNumber * sizeof(long)) + sizeof(long), SEEK_SET)!= 0)
		{
			NSLog(@"%@ file seek error errno: %d (5)",[self IndexTTX_path],errno);
			return NULL;
		}
        
        if (4 != fread(&tmp_long,1,4,ttxhandle))
		{
			NSLog(@"%@ file read error errno: %d (6)",[self IndexTTX_path],errno);
			return NULL;
		}

		if (_pageNumber == lastpagenumber) {	// ACHTUNG
			// TODO : berechnen wie viele eintraege da noch sind, oder einfach bis ende lesen bzw. mit seek die position bestimmen dann von filesize abziehen und durch 3 teilen
			NSLog(@"loadHashListForPage(): _pageNumber == lastpagenumber ");
			return NULL;
		}
		else
		{
			offset_end = NSSwapLittleLongToHost(tmp_long);
		}
		
//      NSLog (@"Offset of Page %d : %d", _pageNumber, offset_start);
        hashcount = offset_end-offset_start;
//        NSLog (@"Offsets of Page %d : start : %d end : %d", _pageNumber, offset_start, offset_end);
//        NSLog (@"number of hashes on page %d : %d", _pageNumber, hashcount);
		if (oldStyleTTX) {
//			NSLog(@"oldStyleTTX");
			offset_start = ((offset_start-1) * 3 ) + ((105600+1) * sizeof(long)) + 1 * sizeof(long);	// OLD_MAX_PAGES = 105600  DKIndex.pas
		}
		else {
			offset_start = ((offset_start-1) * 3 ) + ((ttxpagenumbers+1) * sizeof(long)) + 1 * sizeof(long);
		}
//        NSLog (@"Offset in ttx after calculation of Page %d : %d", _pageNumber, offset_start);

        // seeken zum anfang der hashlist fuer diese seite
        if (fseek(ttxhandle,offset_start,SEEK_SET) != 0)
		{
			NSLog(@"%@ file seek error errno: %d (7)",[self IndexTTX_path],errno);
			return NULL;
		}

        // daten einlesen (wieviel und welches format ?)
        tmp_hashliste = malloc(hashcount * sizeof(unsigned char) * 3);
        if (tmp_hashliste == NULL) {
		NSLog(@"malloc(%d) failed",hashcount * 3);
                return NULL;
	}
            
        outbuff = malloc(hashcount * sizeof(long));
        if (hashcount != fread(tmp_hashliste,3,hashcount,ttxhandle) ) {     // fread gibt die anzahl der objekte zurueck die gelesen wurden !!
			NSLog(@"%@ file read error errno: %d (8)",[self IndexTTX_path],errno);
			return NULL;
		}

// hashes nach 4 byte hashes wandeln
// TODO die  komischen hashes welche sprecher usw anzeigen hier in hashKey3ToHashKey4 loeschen, und hashcount korrigieren vieleicht als rv vn hashKey3ToHashKey4 die anzahl die mal von hashcount abziehen muss
//		NSLog(@"Hashkeys fuer page : %d",_pageNumber);
        [self hashKey3ToHashKey4:tmp_hashliste caseSensitive:_case outbuffer:outbuff count:&hashcount];
        free(tmp_hashliste);
        *_hashcount=hashcount;
        return outbuff;
}

-(int)HashTableEntries
{
	return HashTableEntries;
}

@end

void findSmallestHit(int s1,int w1,int s2,int w2,int *rs,int *rw)
{
/* gibt den kleinsten treffers in die ref zurueck */
	*rs = s1 <= s2 ? s1 : s2;
	*rs = *rs == -1 ? ((s1 < s2) ? s2 : s1) : *rs;
	if (s1 != s2) {
		*rw = *rs == s1 ? w1 : w2;
	}
	else if (s1 == s2)
		*rw = w1 <= w2 ? w1 : w2;
}
