/*
 * Entry.m -- 
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

#import "Entry.h"

@implementation Entry

-(id)initWithName:(NSString *)text level:(int)_level linkNumber:(int)_linknumber band:(Band*)_band treeArrayIndex:(int)_treeArrayIndex
{
	NSCharacterSet* myCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	self = [super init];

	name = [text stringByTrimmingCharactersInSet:myCharacterSet];
	[name retain];

	children = nil;
	parent = nil;
	level = _level;
	linkNumber = _linknumber;
	band = _band;
	treeArrayIndex = _treeArrayIndex;

	return self;
}

-(void)dealloc
{
	[children release];

	[name release];
	[super dealloc];
}

-(NSString *)name
{
	return name;
}

-(long)linkNumber
{
	return linkNumber;
}

-(int)level
{
	return level;
}

-(int)numberOfChildren
{
	return [children count];
}

-(void)addChild:(Entry *) _entry
{
	if (children == nil)
		children = [[NSMutableArray alloc] init];

	[_entry setParent:self];

	[children addObject:_entry];
	[_entry setIndex:[self numberOfChildren]-1];
	[self addNumberOfAllChildren:1];
}

-(Entry *)lastChild
{
	return [children lastObject];
}

-(NSArray*)children
{
	return children;
}

-(Entry *)childAtIndex:(int) _index
{
	return [children objectAtIndex:_index];
}

-(int)numberOfAllChildren
{
	return numberOfAllChildren;
}

-(int)index
{
	return index;
}

-(void)setIndex:(int)_index
{
	index = _index;
}

-(long)textPageNumber
{
//	NSLog (@"LineInTree: %d -> Page in Text: %d",linkNumber,[band pageNumberFromTree:linkNumber]);

	if (linkNumber == 23232323) return 1;
	
	if (linkNumber>1)
		return [band pageNumberFromTree:linkNumber];
	else
		return 0;
}

-(DBPage*)textPageData
{
	DBPage* page = 0;

	if (linkNumber>1)
	{
		page = [band textPageData:[self textPageNumber]];

		if (page == 0)
		{
			NSLog (@"pageAddress is NULL!");
		}
		return page;
	}
	return nil;
}

-(void)addNumberOfAllChildren:(int)count
{
	numberOfAllChildren++;

	if ([self parent] != nil)
	{
		[[self parent] addNumberOfAllChildren:1];
	}
}

-(Entry*)parent
{
	return parent;
}

-(void)setParent:(Entry*) _parent
{
	parent = _parent;
}

-(Band*)band
{
	return band;
}

-(int)lastPageSameLevel
{
	if (band == nil)
		NSLog(@"Interner Fehler: Kein Band gesetzt in Entry!");

	NSArray* myTreeArray = [band treeArray];

	int max;

	if ((treeArrayIndex+1) >= [myTreeArray count])
		max = [band lastpagenumber];
	else
	{
		Entry* myEntry = [self nextEntrySameLevel];
		if (myEntry != nil)
			max = ([myEntry textPageNumber]) - 1;
		else
			max = [band lastpagenumber];
	}

//	NSLog(@"max: %d",max);
//	NSLog(@"lastpagenumber: %d",[band lastpagenumber]);

	return max;
}

-(Entry*)nextEntrySameLevel
{
	int startindex;
	Entry* testEntry;

	testEntry = self;
	startindex = index;

	while ([[testEntry parent] numberOfChildren] <= startindex+1)
	{
//		NSLog (@"name: %@",[testEntry name]);
		startindex = [testEntry index];
		testEntry = [testEntry parent];

		if ([testEntry parent] == nil || [testEntry band] == nil)
		{
			return nil;
		}
	}

	testEntry = [[testEntry parent] childAtIndex:[testEntry index] +1];	

	return testEntry;
}

// is YES wenn die pagenum ein unterseite des Entrys ist
-(BOOL)isPagenumInSubTree:(int)pagenum
{
	int minPage = [self textPageNumber];
	int maxPage = [self lastPageSameLevel];

	if (minPage <= pagenum && maxPage >= pagenum)
		return YES;
	else
		return NO;
}

-(void) killAllChildren
{
	[children makeObjectsPerformSelector:@selector(killAllChildren)];
	[children release];
	children = nil;
	numberOfAllChildren = 0;
}

@end
