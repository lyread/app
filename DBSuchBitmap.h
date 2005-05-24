/*
 * DBSuchBitmap.h -- 
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
#include <regex.h>
#include <sys/stat.h>
#import "Band.h"
#import "DBSuche.h"

@interface DBSuchBitmap : NSObject
{
	unsigned char *pages,*candpages;   // bitmap fuer die seitenzahlen
	unsigned char *words;   // bitmap fuer die word hashes
	Band *band;
	NSMutableArray *wordlist;   // hier sind dann alle woerter drin die in der bitmap gespeichert wurden (was ist mit regexp)
	BOOL matches,regexp,caseSensivity,schreibweisentoleranz;
	int HashTableEntries,maxpages;
	int actualTTXPositionNum,actualPageNum,actualWordNum,actualWordPositionOnPage,actualHash,actualHashNum;
	long *TTXhashlist;
	int TTXMaximumNum;      // enthaelt die anzahl der hashes auf der aktuellen seite
	int lastTTXPage;

	BOOL TTXmagic;
	BOOL lastHash;
	int candidatePageNum,candidateWordNum;
		
	int firstPageNum,lastPageNum;
}

//-(DBSuchBitmap *)UND:(DBSuchBitmap *)_bm wortabstand:(int)_wortabstand startpage:(int)_startpage startwort:(int)_startwort;
//-(DBSuchBitmap *)ODER:(DBSuchBitmap *)_bm startpage:(int)_startpage startwort:(int)_startwort;
//-(DBSuchBitmap *)FOLGT:(DBSuchBitmap *)_bm startpage:(int)_startpage startwort:(int)_startwort;	

-(DBSuchBitmap *)FOLGT:(DBSuchBitmap *)_bm;
-(DBSuchBitmap *)UND:(DBSuchBitmap *)_bm;
-(DBSuchBitmap *)ODER:(DBSuchBitmap *)_bm;
-(DBSuchBitmap *)init:(Band *)_band caseSensivity:(BOOL)_case;
-(DBSuchBitmap *)initWithWord:_word  schreibweisentoleranz:(BOOL)_tolerant caseSensivity:(BOOL)_case band:_band firstPage:(int)_sucheStartseite lastPage:(int)_sucheEndseite;
-(NSString *)getSearchWord:(unsigned long)index count:(long*)c hash:(long*)h position:(long*)p;
-(unsigned long)hashHTX:(NSString *)word;
-(BOOL)getSuchBitmap:(NSString *)_word;
-(void)makeSuchBitmap:(int)_wordlistposition count:(int)_count;
-(unsigned long)offsetOfSearchWord:(NSString *)w;
-(int)plxPagenumber:(unsigned char*)_buff PagelistIndexSize:(int)_indexsize;
-(BOOL)getSuchRegExpBitmap:(NSString *)_expression;
-(BOOL)sucheCheckForRegularExpression:(NSString *)_word;
-(void)extend;
-(int)nextWordHash;
-(BOOL)lastHash;
-(BOOL)getNextCandidate:(int)_seite Word:(int)_word Bitmap:(DBSuchBitmap*)_bitmap;

-(BOOL)getSuchBitmap:(NSString *)_word;
-(BOOL)folgtAufSeite:(int)_page Word:(int)_word;

-(int)candidatePageNum;
-(int)candidateWordNum;
-(BOOL)nextHashPositionFromTTX;
-(BOOL)nextHashForPage;
-(void)setPosition:(int)pageNum;

-(Band *)band;
-(NSMutableArray *)wordlist;

-(unsigned char *)pages;
-(unsigned char *)words;

@end
