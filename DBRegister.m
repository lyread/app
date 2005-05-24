/*
 * DBRegister.m -- 
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

#import "DBRegister.h"

int registerStringSort(id num1, id num2, void *context);

@implementation DBRegister

-(id)initWithBand:(id)_band masterPath:(NSString*)_masterPath fastArray:(NSArray*)_fastArray
{
	[super init];

	registerArray = [[NSMutableArray alloc] init];
	filteredRegisterArray = [[NSMutableArray alloc] init];
	kategorieDict = [[NSMutableDictionary alloc] init];
	band = _band;

	[self loadLemmataTable:_masterPath fastArray:_fastArray];

	if (registerArray && [registerArray count] == 0)
		return nil;

	return self;
}

-(void)dealloc
{
	[registerArray release];
	[filteredRegisterArray release];
	[kategorieDict release];

	[super dealloc];
}

-(void)loadLemmataTable:(NSString*)_masterPath fastArray:(NSArray*)_fastArray
{
	NSString *string;
	NSEnumerator *enu;
	DBRegisterEntry* registerEntry;

	NSLog(@"initializing lemmataTable");

	NSString* Lemmata_path = [Helper findFile:@"DATA/LEMMATA.TXT" startPath:_masterPath];

	NSData *myData = [NSData dataWithContentsOfFile:Lemmata_path];

	if ([myData length] == 0)
	{
		NSLog(@"Keine Lemmata!");
		return;
	}

	NSLog(@"Lemmata ist geladen");

	string = [[NSString alloc] initWithData:myData encoding:NSWindowsCP1252StringEncoding];
	[string autorelease];

	NSLog(@"Lemmata ist ein String (Size: %d)",[string length]);

	if ([string length])
	{
		NSArray *array = [string componentsSeparatedByString:@"\r"];

		NSLog(@"Lemmata ist seperated (Lines: %d)",[array count]);

		enu = [array objectEnumerator];
		NSString* line;
		while (line = [enu nextObject])
		{
			if ([line length] > 4)
			{
				registerEntry = [[DBRegisterEntry alloc] initWithText:line fastArray:_fastArray];
				if (registerEntry)
				{
					if ([registerEntry kategorie])
					{
						[registerArray addObject:registerEntry];
						[filteredRegisterArray addObject:registerEntry];
						[kategorieDict setObject:registerEntry forKey:[registerEntry kategorie]];
					}
				}
				[registerEntry release];
			}
		}

		NSLog (@"Lines In Lemmata: %d",[registerArray count]);
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int index;
	int seite;
	int row;

	row = [[aNotification object] selectedRow];
	index = sortDescending ? [filteredRegisterArray count] - row - 1 : row;

	if (index >= 0)
	{
		seite = [[filteredRegisterArray objectAtIndex:index] pageNumber];
//		NSLog(@"gewaehlte seite im register: %d",seite);
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"displayPageWithNumberNote" object:[NSNumber numberWithInt:seite]];
	}
}

-(void)tableViewClickedAction:(id)sender
{
	int index;
	int seite;
	int row;

	row = [sender selectedRow];
	index = sortDescending ? [filteredRegisterArray count] - row - 1 : row;
	
	if (index >= 0)
	{
		seite = [[filteredRegisterArray objectAtIndex:index] pageNumber];
//		NSLog(@"gewaehlte seite im register: %d",seite);
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"displayPageWithNumberNote" object:[NSNumber numberWithInt:seite]];
	}
}

-(id)band
{
	return band;	
}

-(NSArray *)kategories
{
	return [kategorieDict allKeys];
}

// This method is called when a kategory checkbox is clicked
// kategories is an array with all visible kategories

-(void)kategorySelection:(NSArray *)kategories
{
	DBRegisterEntry *registerEntry;
	[filteredRegisterArray removeAllObjects];
	NSEnumerator *enu = [registerArray objectEnumerator];

	while (registerEntry = [enu nextObject])
	{
		if ([registerEntry matchkategory:kategories])
		{
			[filteredRegisterArray addObject:registerEntry];
		}
	}
}

-(int)PageForIndex:(int)i
{
	return [[filteredRegisterArray objectAtIndex:i] pageNumber];
}

-(int)count
{
	return [registerArray count];
}

-(NSString*)description
{
	return [registerArray description];
}

-(int)indexForFilter:(NSString *)_searchstring
{
	NSEnumerator *enu;
	DBRegisterEntry *entry;
	int index = 0;

	if (sortDescending == NO)
		enu = [filteredRegisterArray objectEnumerator];
	else
		enu = [filteredRegisterArray reverseObjectEnumerator];

	while (entry = [enu nextObject])
	{
		if ([[[entry stichwort] lowercaseString] hasPrefix:_searchstring])
		{
			return index;
		}
		index++;
	}

	return -1;
}

-(int)numberOfRowsInTableView:(NSTableView*)tv
{
	return [filteredRegisterArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	int row = sortDescending ? [filteredRegisterArray count] - rowIndex - 1 : rowIndex;

	if ([@"stichwort" compare:[aTableColumn identifier]] == NSOrderedSame)
		return [[filteredRegisterArray objectAtIndex:row] stichwort];
	else
		return [[filteredRegisterArray objectAtIndex:row] kategorie];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (rowIndex %2)
		[aCell setBackgroundColor:[NSColor colorWithCalibratedRed:0.929 green:0.953 blue:0.996 alpha:1]];
	else
		[aCell setBackgroundColor:[NSColor whiteColor]];
}

-(void)tableView:(NSTableView *)_tableView didClickTableColumn:(NSTableColumn *)_tableColumn
{
	if (lastColumn == _tableColumn)
	{
//		NSLog(@"User clicked same column, change sort order");
		sortDescending = !sortDescending;
	}
	else
	{
//		User clicked new column, change old/new column headers,
//		save new sorting selector, and re-sort the array.

		sortDescending = NO;

		if (lastColumn)
		{
			////[_tableView setIndicatorImage:nil inTableColumn:lastColumn];	//// GS hat das nicht
			[lastColumn release];
		}

		lastColumn = [_tableColumn retain];
		[_tableView setHighlightedTableColumn: _tableColumn];
	}
	
//  Set the graphic for the new column header
	
	//// [_tableView setIndicatorImage: (sortDescending ? [NSImage imageNamed:@"NSDescendingSortIndicator"] : [NSImage imageNamed:@"NSAscendingSortIndicator"]) inTableColumn: _tableColumn];	//// GS hat das nicht

	[self sorting:[_tableColumn identifier]];

	[_tableView reloadData];
}

- (void)sorting:(NSString *)_name
{
	[filteredRegisterArray sortUsingFunction:registerStringSort context:_name];
}

int registerStringSort(id num1, id num2, void *context)
{
	NSString* v1;
	NSString* v2;

	if ([@"stichwort" compare:context] == NSOrderedSame)
	{
		v1 = [num1 stichwort];
		v2 = [num2 stichwort];
	}
	else
	{
		v1 = [num1 kategorie];
		v2 = [num2 kategorie];
	}

	return [v1 caseInsensitiveCompare: v2];
}
// Wikipedia
-(int)pageNumberForTitle:(NSString *)_title
{
	DBRegisterEntry *entry;
	NSEnumerator *enu = [registerArray objectEnumerator];
	while (entry = [enu nextObject]) {
		if ([[entry stichwort] isEqualToString:_title]) {
			return [entry pageNumber];
		}
	}
	NSBeep();
	return -1;
}


@end
