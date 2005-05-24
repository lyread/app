/*
 * Band.h -- 
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "DBPage.h"
#import "DBRegister.h"
#import "Entry.h"
#import "DBImageSet.h"
#import "DBRegisterEntry.h"
#import "Helper.h"
#import "DBImageLoader.h"
#import "DBFundstellenDataSource.h"

// Suchen
@class DBSuchBitmap;
enum suchtoken {ODER,UND,BLANK,OPEN,CLOSE,WORD,NIX,END};


@interface Band : NSObject
{
	NSString *bandname;
	unsigned long* blockpointerarray[5];
	NSData *IndexHTXTable;

	NSImageView* myView;

	NSString* masterPath;

	DBRegister* Register;

	NSString* TreeDKI_path;
	NSString* IndexHTX_path;
	NSString* TreeDKA_path;
	NSString* TextDKI_path;
	NSString* Digibib_path;
	NSString* IndexWLX_path;
	NSString* IndexPLX_path;
	NSString* IndexTTX_path;
	NSString* suchwort;
// Wikipedia Stuff
	NSString* HTML_path;
	NSString* HTMLdat_path;
	NSMutableDictionary* htmlDict;
	NSData* HTMLData;


	NSString* registereinstellungen;	// Register
	NSMutableArray* fastArray;

	NSMutableDictionary *digibibDict;	// digigbib.txt
	NSDictionary* digibibxmlDict;		// XML datei

	NSMutableDictionary* imageDict;		// alle Bilder auch die hidden
	NSMutableArray* imageArray;			// nur die bilder welche nicht hidden sind!
	NSMutableArray* hiddenImageArray;

	NSMutableArray *markierungen;

	NSArray *directoryTree;
	NSArray *suchergebnisse;
	NSArray *imageLocatorArray;
	int lastpagenumber;
	int totalImages;

	BOOL magic;
	BOOL imageMagic;

	FILE* textdkihandle;

	NSMutableArray* treeArray;

	NSDictionary* coloredWordsDict;
	NSDictionary* searchWordsDict;

	int linesInTree;
	int HashTableEntries;

	// Suchen
	DBFundstellenDataSource *fundstellenDS,*markierungenDS;
	FILE *ttxhandle;
	DBSuchBitmap *SucheBitmap;
	NSMutableArray *SucheTokenList;
	NSTableView *fundstellenTableView;
	NSString *sucheAusdruck;
	NSString *sucheFehlerMeldung;
	DBPage *sucheLetzteGesuchteSeite;
	NSLock *dkiFilehandleLock;
	
	BOOL sucheStoppen;
	BOOL sucheSchreibweisentolerant;
    BOOL sucheCaseSensivity;
	BOOL endeSuche;
	BOOL noMoreHits;
	BOOL sucheAktiv;
	
	int sucheStartseite;
	int sucheEndseite;
	int sucheMaxwortabstand;
	int sucheMaxFundstellen;
	int sucheAktuelleseite;
	int sucheAktuelleswort;
	int sucheAktuellesHash;
	int sucheSyntaxActualTokenNum;
    int sucheActualStartPage;
    int SucheStartWort;
    int candPage,candWord,iniCandPage,iniCandWord;
	
    int smallestWord,smallestSeite;
	int port;
    
	enum suchtoken sucheSyntaxActualToken; 
	// END Suchen
	int actualpageviewwidth;
}

-(id)initWithPath:(NSString*)_path;
-(long) pageAddress:(int)linenumber;

-(NSArray*)treeArray;

-(NSMutableDictionary*) digibibDict;

-(NSImage*)imageWithName:(NSString*)_imagename resolution:(int)_resolution;
-(DBPage*)textPageData:(long)linenumber;

-(NSImage*) loadCoverImage;
-(BOOL) loadTextTable;
-(int) loadTreeTable;
-(int) loadDigibibTable;
-(void) loadIndexHTX;
-(NSArray*)initializeTree;

-(long) pageNumberFromTree:(long)_treelinenumber;
-(int) lastpagenumber;
-(int) totalImages;

-(NSMutableArray *)markierungen;

-(NSString*) TreeDKI_path;
-(NSDictionary*) imageDict;
-(NSArray*) imageArray;
-(NSArray*) hiddenImageArray;
-(DBRegister*)Register;
-(NSArray*) tabellenArray;

-(void)setColoredWordsDict:(NSDictionary *)_colored_words;
-(void)setSearchWordsDict:(NSDictionary *)_search_words;
-(NSArray *)imageLocatorArray;
-(NSString *)masterPath;

-(NSDictionary*)coloredWordsDict;
-(NSDictionary*)searchWordsDict;

-(unsigned long)offsetOfSearchHash:(long)hash;

-(NSString *)IndexTTX_path;
-(NSString *)IndexWLX_path;
-(NSString *)IndexPLX_path;
-(NSData *)IndexHTXTable;

-(DBFundstellenDataSource *)markierungenDS;
-(DBFundstellenDataSource *)fundstellenDS;

-(NSString *)registereinstellungen;
-(NSString *)getHTMLPage:(NSString *)htmlname;

-(void)setImageArray:(NSArray*)_array;
-(void)setImageDict:(NSDictionary*)_dict;

-(void)setactualpageviewwidth:(int)_actualpageviewwidth;
-(int)actualpageviewwidth;
-(int)majorNumber;
-(int)minorNumber;
-(void)loadHTMLTable;
-(int)httpdport;
-(void)set_httpdport:(int)_port;

@end
