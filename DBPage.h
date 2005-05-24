/*
 * DBPage.h -- 
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

#import "Word.h"

@interface DBPage : NSObject
{
	id band;
	long textpagenumber;
	long atomCount;
	long wordCount;
	long hexaddress;
	int Words;
	int searchPosition;

	long nodenumber;
	long konkordanznumber;

	float fontSize;

	NSString *fontName;

	BOOL hoeheistegal;
	BOOL showMarkierungen;
	BOOL enforceRedisplay;
        BOOL hasVorWort;
	NSString* pageSigel;

	NSCharacterSet* invertedcharset;

	NSMutableAttributedString* pageString;
	NSMutableArray *newWordList;
	NSData* pageBlock;
	int pageBlocklength;
	NSCharacterSet* myCharacterSet;
}

-(id)initWithData:(NSData*)_data band:(id)_band  textpagenumber:(long)_textpagenumber atomCount:(long)_atomCount wordCount:(long)_wordCount hexaddress:(long)_hexaddress;

-(NSString*)pageSigel;

-(long)textpagenumber;
-(NSData*)pageblock;
-(long)atomCount;
-(long)wordCount;
-(long)konkordanznumber;
-(NSString*) textpagenumberAsString;
-(long)nodenumber;
-(long)hexaddress;
-(id)band;
-(NSMutableAttributedString *)getPageWithFontSize:(float)_fontSize suche:(BOOL)_sucheaktiv;
-(NSMutableAttributedString *)parsePageWithFontSize:(float)_fontsize suche:(BOOL)_sucheaktiv;
//-(void)colorizeWords:(NSMutableAttributedString*) _myAttributedString Foreground:(BOOL)_foreground;
-(NSArray*)getArrayWithParents;
-(void)setSearchPosition:(int)_p;
-(void)setShowMarkierungen:(BOOL)_state;
-(NSString *)konkordanz;
-(NSString *)bereich;
-(NSString *)abschnitt;

//-(void)highlightMarkierungen:(DBFundstellenDataSource*)_ds string:(NSMutableAttributedString*)_blub;
-(NSString *)textForWordRange:(NSRange)_wortrange;
-(void)highlightMarkierungen:(id)_ds string:(NSMutableAttributedString *)_blub;
-(void)highlightSearchPosition:(int)_wordnum string:(NSMutableAttributedString *) _myAttributedString;
-(NSMutableArray *)newWordList;
-(NSString *)titleFromTree;

-(void)displayPageInView:(NSTextView *)_view;
-(void)hoeheistegal:(BOOL)_flag;
-(void)enforceRedisplay:(BOOL)_flag;
-(NSRange)getWordRangeForSelection:(NSRange)_selection;
-(void)addToWordList:(NSString *)_word Range:(NSRange)_range AllowSplit:(BOOL)_split;
-(void)generateWordList:(unsigned char *)_word Length:(int)_len Range:(NSRange)_range Hyphen:(BOOL)_hyphen Font:(int)_font;
-(NSString *)wordForVladoString:(unsigned char *)_string Length:(int)_len Font:(int)_font;
-(NSString *)facsimile;

@end
