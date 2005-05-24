/*
 * DBSuche.h -- 
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
#import "Word.h"

@interface Band (Suche)

-(BOOL)initSuche:(NSString *)_suchstring startseite:(long)_startseite endseite:(long)_endseite maxwortabstand:(int)_maxwortabstand maxfundstellen:(int)_maxfundstellen grosskleinschreibung:(BOOL)_grosskleinschreibung schreibweisentolerant:(BOOL)_schreibweisentolerant;
-(BOOL)nextHit:(int *)_pageNum word:(int *)_wordNum;
-(BOOL)nextHitInWord;
-(BOOL)nextHitInExpression;
-(NSMutableDictionary *)sucheCreateToken:(int)_tokennum suchstring:(NSString *)_string;
-(NSMutableArray *)sucheCreateTokenlist:(NSString *)_suchstring;
-(NSMutableArray *)sucheFillSuchliste:(NSMutableArray *)_tokenlist;
-(DBSuchBitmap *)sucheSyntaxParser:(NSMutableArray *)_tokenlist;
-(enum suchtoken)sucheSyntaxNextToken;
-(BOOL)sucheSyntaxConsumeToken:(enum suchtoken)_tok;
-(DBSuchBitmap *)sucheSyntaxSuche;
-(DBSuchBitmap *)sucheSyntaxExpr;
-(DBSuchBitmap*)sucheSyntaxWord;
-(void)hashKey3ToHashKey4:(unsigned char *)_ibuff caseSensitive:(BOOL)_case outbuffer:(long *)_obuff count:(int *)_count;
-(long *)loadHashListForPage:(int)_pageNumber hashcount:(int *)_hashcount caseSensitive:(BOOL)_case;
-(BOOL)inWortabstand:(int)_distance page1:(int)_page1 word1:(int)_word1 page2:(int)_page2 word2:(int)_word2;
-(void)sucheStoppen;
-(int)HashTableEntries;
//-(void)setFundstellenTableView:(NSTableView *)_tv;
-(void)fillFundstelle:(NSMutableDictionary *)_dict;

@end

void findSmallestHit(int s1,int w1,int s2,int w2,int *rs,int *rw);
