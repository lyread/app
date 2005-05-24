/*
 * TabellenDataSource.m -- 
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

#import "TabellenDataSource.h"

static int stringSort(id num1, id num2, void *context);
static int stringReverseSort(id num1, id num2, void *context);
static int intSort(id num1, id num2, void *context);
static int intReverseSort(id num1, id num2, void *context);

@implementation TabellenDataSource

-(id)initWithTabelle:(NSDictionary*)_tabelleDict dataObject:(NSData*)_dataObject 
{
	self = [super init];

	tabDict = [_tabelleDict retain];
	blubArray = nil;

	lastColumn = nil;

	[self loadTabelleWithData:_dataObject];

	oddColor = [[NSColor colorWithCalibratedRed:0.929 green:0.953 blue:0.996 alpha:1] retain];
	evenColor = [[NSColor whiteColor] retain];

	return self;
}

-(void)dealloc
{
	[tabDict release];

	[oddColor release];
	[evenColor release];

	[super dealloc];
}

-(void)displayThisRow:(int)row
{
	int seite;

	if (row >= 0 && row < [blubArray count])
	{
		seite = [[[blubArray objectAtIndex:row] objectForKey:@"seite"] intValue];
		//NSLog(@"gewaehlte seite in der tabelle: %d",seite);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"displayPageWithNumberNote" object:[NSNumber numberWithInt:seite]];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	//NSLog(@"tableViewSelectionDidChange");

	int row = [[aNotification object] selectedRow];

	[self displayThisRow:row];
}

-(void)tableViewClickedAction:(id)sender
{
	//NSLog(@"tableViewClickedAction");

	int row = [sender clickedRow];

	[self displayThisRow:row];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	//NSLog(@"numberOfRowsInTableView: %d",[blubArray count]);
	return [blubArray count];
}

- (id)tableView:(NSTableView *)_aTableView objectValueForTableColumn:(NSTableColumn*)_aTableColumn row:(int)_rowIndex
{
	NSDictionary* dictAtRow = [blubArray objectAtIndex:_rowIndex];

	//NSLog(@"column: %@",[_aTableColumn identifier]);

	return [dictAtRow objectForKey:[_aTableColumn identifier]];
}

-(void)loadTabelleWithData:(NSData*)_dataObject
{
	NSString *string;
	int i,length;
	unsigned char* buffer;
	unsigned char zeichen;

	//NSLog(@"initializing Tabelle %@",[tabDict objectForKey:@"tabcaption"]);

	if ([_dataObject length] == 0)
	{
		NSLog(@"Keine Tabelle!");
		return;
	}

	//NSLog(@"Tabelle ist geladen");

	buffer = (unsigned char*)[_dataObject bytes];
	length = [_dataObject length];

	for (i=0;i<length;i++)
	{
		zeichen = buffer[i];

		if ((zeichen != 13) && (zeichen != 10))
		{
			buffer[i] = 255 - (zeichen - 32);
		}
	}

	string = [[NSString alloc] initWithData:_dataObject encoding:NSWindowsCP1252StringEncoding];
	[string autorelease];

	//NSLog(@"Tabelle ist ein String (Size: %d)",[string length]);

	if ([string length])
	{
		NSCharacterSet* myCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

		NSArray *zeilenArray = [string componentsSeparatedByString:@"\r\n"];

		//NSLog(@"Tabelle ist seperated (Lines: %d)",[zeilenArray count]);

		blubArray = [[NSMutableArray alloc] initWithCapacity:[zeilenArray count]];
		NSArray* tabArray = [tabDict objectForKey:@"tabfields"];

		NSEnumerator* myEnu = [tabArray objectEnumerator];
		NSMutableArray* keysArray = [[NSMutableArray alloc] init];

		// erstmal alle columns der tabelle in ein keyArry schmeissen

		NSString* name;
		while(name = [[myEnu nextObject] objectForKey:@"tabcolname"])
		{
			//NSLog(@"tabcolname: %@",name);
			[keysArray addObject:name];
		}

		NSEnumerator* enu = [zeilenArray objectEnumerator];
		[enu nextObject];

		IMP impNextObject = [enu methodForSelector:@selector(nextObject)];
		IMP impAddObject = [blubArray methodForSelector:@selector(addObject:)];

		NSString* line;
		while (line = impNextObject( enu, @selector( nextObject)))
		{
			line = [line stringByTrimmingCharactersInSet:myCharacterSet];

			if ([line length] > 0)
			{
				NSArray* itemsInLine;
				itemsInLine = [line componentsSeparatedByString:@"\t"];

				if ([keysArray count] == [itemsInLine count])
				{
					NSDictionary* itemDict = [NSDictionary dictionaryWithObjects:itemsInLine forKeys:keysArray];

					impAddObject(blubArray, @selector(addObject:),itemDict);
				}
			}
		}
	}
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (rowIndex %2)
		[aCell setBackgroundColor:oddColor];
	else
		[aCell setBackgroundColor:evenColor];
}

-(void)tableView:(NSTableView *)_tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	if (lastColumn == tableColumn)
	{
//		User clicked same column, change sort order
		sortDescending = !sortDescending;
	}
	else
	{
//		User clicked new column, change old/new column headers,
//		save new sorting selector, and re-sort the array.

		sortDescending = NO;

		if (lastColumn)
		{
			//// [_tableView setIndicatorImage:nil inTableColumn:lastColumn];	//// GS hat das nicht
			[lastColumn release];
		}

		lastColumn = [tableColumn retain];
		[_tableView setHighlightedTableColumn: tableColumn];
	}

//  Set the graphic for the new column header

	//// [_tableView setIndicatorImage: (sortDescending ? [NSImage imageNamed:@"NSDescendingSortIndicator"] : [NSImage imageNamed:@"NSAscendingSortIndicator"]) inTableColumn: tableColumn];	//// GS hat das nicht

	[self sorting:[tableColumn identifier]];

	[_tableView reloadData];
}

- (void)sorting:(NSString *)_name
{
	NSEnumerator* enu = [[tabDict objectForKey:@"tabfields"] objectEnumerator];

	NSDictionary* dict;

	// erstmal das richtige dict fuer das column suchen
	
	while (dict = [enu nextObject])
	{
		if (NSOrderedSame == ([_name compare:[dict objectForKey:@"tabcolname"]]))
		{
			break;
		}
	}

	NSString* type = [dict objectForKey:@"tabcolktype"];
//	NSLog(@"sorttype: %@",type);

	if (NSOrderedSame == [@"datehidden" compare:type])
	{
		_name = [NSString stringWithFormat:@"%@1",_name];

		if (sortDescending == NO)
			[blubArray sortUsingFunction:stringSort context:_name];
		else
			[blubArray sortUsingFunction:stringReverseSort context:_name];
	}
	else if (NSOrderedSame == [@"integer" compare:type])
	{
		if (sortDescending == NO)
			[blubArray sortUsingFunction:intSort context:_name];
		else
			[blubArray sortUsingFunction:intReverseSort context:_name];
	}
	else if (NSOrderedSame == [@"ansilower" compare:type])
	{
		if (sortDescending == NO)
			[blubArray sortUsingFunction:stringSort context:_name];
		else
			[blubArray sortUsingFunction:stringReverseSort context:_name];
	}
	else if (NSOrderedSame == [@"ansilowerstrip" compare:type])
	{
		if (sortDescending == NO)
			[blubArray sortUsingFunction:stringSort context:_name];
		else
			[blubArray sortUsingFunction:stringReverseSort context:_name];
	}
	else if (NSOrderedSame == [@"ansilowerstripold" compare:type])
	{
		if (sortDescending == NO)
			[blubArray sortUsingFunction:stringSort context:_name];
		else
			[blubArray sortUsingFunction:stringReverseSort context:_name];
	}
	else if (NSOrderedSame == [@"ansilowerstripold2" compare:type])
	{
		if (sortDescending == NO)
			[blubArray sortUsingFunction:stringSort context:_name];
		else
			[blubArray sortUsingFunction:stringReverseSort context:_name];
	}
	else if (NSOrderedSame == [@"boolean" compare:type])
	{
		if (sortDescending == NO)
			[blubArray sortUsingFunction:stringSort context:_name];
		else
			[blubArray sortUsingFunction:stringReverseSort context:_name];
	}
	else
	{
		NSLog(@"Unbekannter Sortierungstyp: %@",type);
		if (sortDescending == NO)
			[blubArray sortUsingFunction:stringSort context:_name];
		else
			[blubArray sortUsingFunction:stringReverseSort context:_name];
	}
}

static int stringSort(id num1, id num2, void *context)
{
	NSString* v1 = [num1 objectForKey:context];
	NSString* v2 = [num2 objectForKey:context];

	if (v1 == nil && v2 == nil) return NSOrderedSame;
	if ([v1 length] == 0 && [v2 length] == 0) return NSOrderedSame;

	if (v1 == nil) return NSOrderedDescending;
	if ([v1 length] == 0) return NSOrderedDescending;

	if (v2 == nil) return NSOrderedAscending;
	if ([v2 length] == 0) return NSOrderedAscending;

	return [v1 caseInsensitiveCompare: v2];
}

static int stringReverseSort(id num1, id num2, void *context)
{
	NSString* v1 = [num1 objectForKey:context];
	NSString* v2 = [num2 objectForKey:context];

	return [v2 caseInsensitiveCompare: v1];
}

static int intSort(id num1, id num2, void *context)
{
	int v1 = [[num1 objectForKey:context] intValue];
	int v2 = [[num2 objectForKey:context] intValue];
	
	if (v1 < v2)
		return NSOrderedAscending;
	else if (v1 > v2)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}

static int intReverseSort(id num1, id num2, void *context)
{
	int v2 = [[num1 objectForKey:context] intValue];
	int v1 = [[num2 objectForKey:context] intValue];

	if (v1 < v2)
		return NSOrderedAscending;
	else if (v1 > v2)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}

@end
