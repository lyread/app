/*
 * Entry.h -- 
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
#import <DBPage.h>
#import <Band.h>

@class Band;

@interface Entry : NSObject
{
	Entry* parent;
	NSString *name;
	short level;
	long linkNumber;
	int textPageNumber;
	int index;
	int numberOfAllChildren;
	int treeArrayIndex;

	Band* band;
	NSMutableArray *children;
}

-(NSString *)name;
-(int)level;
-(long)linkNumber;
-(id)initWithName:(NSString *)_name level:(int)_level linkNumber:(int)link band:(Band*)_root treeArrayIndex:(int)treeArrayIndex;
-(int)numberOfChildren;

-(int)numberOfAllChildren;
-(int)index;
-(void)setIndex:(int)_blub;
-(void)addNumberOfAllChildren:(int) blubber;

-(void) killAllChildren;
-(Entry *)childAtIndex:(int) index;
-(void)addChild:(Entry *) entry;
-(Entry *) lastChild;
-(Entry *) parent;
-(void) setParent:(Entry*) _parent;
-(Band*) band;
-(long) textPageNumber;
-(DBPage*)textPageData;
-(Entry*)nextEntrySameLevel;
-(int)lastPageSameLevel;
-(NSArray*)children;

// is YES wenn die pagenum ein unterseite des Entrys ist
-(BOOL)isPagenumInSubTree:(int)pagenun;					// DENIS

@end
