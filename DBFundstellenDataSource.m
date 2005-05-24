/*
 * DBFundstellenDataSource.m -- 
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

/* DONE

Verfahren bei doppelten erarbeiten, im Moment fliegen bie einer cut,delete,backspace operation
alle identischen Eintraege raus sollte aber natuerlich nur die tatsaechlichen betreffen

*/

#import "DBFundstellenDataSource.h"

static int stringSort(id num1, id num2, void *context);
static int intSort(id num1, id num2, void *context);
static int unique_ID=0;

NSString *kMarkierungenTableViewName = @"Markierungen";
NSString *kFundstellenTableViewName = @"Fundstellen";
NSString *MarkierungenPasteBoardType = @"de.directmedia.www:MarkierungenPasteboardType";

@implementation DBFundstellenDataSource

-(id)initWithName:(NSString *)_name BandMajorMinor:(NSString *)_bandMajorMinor
{
	NSString *lastSaveName;
	[super init];

	rows = [[NSMutableArray alloc] initWithCapacity:50];
//	rowsLock = [[NSLock alloc] init];
	name = [_name retain];
	bandMajorMinor = [_bandMajorMinor retain];
	isSaved=YES;
	lastSaveName = [self lastSavedFilename];

	if (lastSaveName) {
		if (![self loadFromFile:lastSaveName]) {	// wenn nicht geklappt, beim naechsten mal nicht wieder versuchten; also denn eintrag aus den defaults loeschen!
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:lastSaveName];
		}
	}
	
	return self;
}
/*
 // TODO : naja hat zeit
- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{
//	return [getRowsFromData [NSData dataWithContentsOfFile:filename
}
*/

-(NSString *)lastSavedFilename
{
//	NSLog(@"lastSavedFilename : %@", [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@ - %@ MarkierungenLastSaveName",bandMajorMinor,name]]);
	return [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@ - %@ MarkierungenLastSaveName",bandMajorMinor,name]];
}

-(id)initWithCoder:(NSCoder *)_coder
{
	bandMajorMinor = [_coder decodeObject];
	name = [_coder decodeObject];
	rows = [_coder decodeObject];
	sortDescending = NO;
	lastColumn=nil;
	
	return self;
}

-(BOOL)loadFromFile:(NSString *)_filename
{
	BOOL rv=NO;
	BOOL oldSaveState=isSaved;
	id newrows;
	NSData *data;

	data = [NSData dataWithContentsOfFile:_filename];

	if (data)
	{
		newrows = [self getRowsFromData:data];
		if (newrows)
		{
			[self addObjectsFromArray:newrows];
			rv = YES;
			isSaved=oldSaveState;
		}
	}
	return rv;
}

-(BOOL)saveToFile:(NSString *)_filename
{
/*
speichert die daten ab und setzt in den app defaults auch noch den filename damit man beim naechsten starten diese diret wieder laden kann
*/
	NSData *data;
	BOOL rv;
	
	data = [self makeDataWithRows:rows];
	if ([data writeToFile:_filename atomically:YES])
	{
		// name in den defaults sichern
		[[NSUserDefaults standardUserDefaults] setObject:_filename forKey:[NSString stringWithFormat:@"%@ - %@ MarkierungenLastSaveName",bandMajorMinor,name]];
		isSaved=YES;
		rv = YES;
	}
	else
		rv = NO;
	return rv;
}

-(BOOL)hasUnsavedChanges
{
	if ([rows count])
	{
		return !isSaved;
	}
	else
		return NO;
}

-(void)setTableView:(NSTableView *)_tv
{
	tableView = _tv;
	[tableView setAutosaveName:[NSString stringWithFormat:@"%@ - %@",name,bandMajorMinor]];
	[tableView setAutosaveTableColumns:YES];
}

-(void)encodeWithCoder:(NSCoder *)_coder
{
	[_coder encodeObject:bandMajorMinor];
	[_coder encodeObject:name];
	[_coder encodeObject:rows];
}

-(void)dealloc
{
	[name release];
	[rows release];
//	[rowsLock release];

	[super dealloc];
}

-(NSMutableArray *)rows
{
	return rows;
}

-(void)removeAllObjects
{
	isSaved = YES;

//	[rowsLock lock];
	[rows removeAllObjects];
//	[rowsLock unlock];
}

-(void)addObject:(id)_obj
{
	isSaved = NO;

	[_obj setObject:[NSNumber numberWithInt:unique_ID++] forKey:@"ID"];

//	[rowsLock lock];
	[rows addObject:_obj];
//	[rowsLock unlock];
}

-(void)sorting:(NSString *)_colname
{
//	[rowsLock lock];
	[rows sortUsingFunction:([_colname isEqualToString:@"Seite"] ? intSort : stringSort) context:_colname];
//	[rowsLock unlock];
}

static int stringSort(id num1, id num2, void *context)
{
		NSString* v1 = [num1 objectForKey:context];
		NSString* v2 = [num2 objectForKey:context];
		
		return [v1 caseInsensitiveCompare: v2];
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

/* Datasource Methoden */

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	[aCell setDrawsBackground:YES];
	if (rowIndex %2)
		[aCell setBackgroundColor:[NSColor colorWithCalibratedRed:0.929 green:0.953 blue:0.996 alpha:1]];
	else
		[aCell setBackgroundColor:[NSColor whiteColor]];
}

-(void)tableView:(NSTableView *)_tableView didClickTableColumn:(NSTableColumn *)_tableColumn
{
	if (lastColumn == _tableColumn)
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
			////[_tableView setIndicatorImage:nil inTableColumn:lastColumn];	//// GS hat das nicht
			[lastColumn release];
		}
		lastColumn = [_tableColumn retain];
		[_tableView setHighlightedTableColumn: _tableColumn];
	}
	
//  Set the graphic for the new column header
	////[_tableView setIndicatorImage: (sortDescending ? [NSImage imageNamed:@"NSDescendingSortIndicator"] : [NSImage imageNamed:@"NSAscendingSortIndicator"]) inTableColumn: _tableColumn]; //// GS hat das nicht
	[self sorting:[_tableColumn identifier]];
	
	[_tableView reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
//	[rowsLock lock];
	int count = [rows count];
//	[rowsLock unlock];

	return count;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
//	[rowsLock lock];

	int index = sortDescending ? [rows count] - rowIndex - 1 : rowIndex;

	[[rows objectAtIndex:index] setObject:anObject forKey:[aTableColumn identifier]];
//	[rowsLock unlock];
//	NSLog(@"Kommentar : %@ Column : %@",anObject,[aTableColumn identifier]);

	isSaved=NO;
}

-(void)tableViewClickedAction:(id)sender
{
	if ([sender clickedRow] >= 0)
		[self showPageForIndex:[sender clickedRow]];
}
	
-(void)showPageForIndex:(int)_index
{
	int index;
	int seite;
	int word;

	NSDictionary *dict;
	NSNumber *wordnumber;

//	[rowsLock lock];
	index = sortDescending ? [rows count] - _index - 1 : _index;
//	[rowsLock unlock];

	if (index >= 0)
	{
		seite = [[[rows objectAtIndex:index] objectForKey:@"Seite"] intValue];
//		[rowsLock lock];
		wordnumber = [[rows objectAtIndex:index] objectForKey:@"StartWort"];
//		[rowsLock unlock];
		word = wordnumber ? [wordnumber intValue] : -1;
//		NSLog(@"gewaehlte seite in der tabelle: %d",seite);
		
		dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:seite],[NSNumber numberWithInt:word],nil] forKeys:[NSArray arrayWithObjects:@"PageNumber",@"WordNumber",nil]];

//		NSLog(@"dict: %@",dict);

		[[NSNotificationCenter defaultCenter] postNotificationName:@"displayPageNotification" object:dict];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self showPageForIndex:[[aNotification object] selectedRow]];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	// nur bei der kommentarspalte sollte das moeglich sein !!!
	return ([[aTableColumn identifier] isEqualToString:@"Kommentar"]);
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSMutableDictionary *dict;
	BOOL textspalte;
	id rv;
	
	textspalte = [[aTableColumn identifier] isEqualToString:@"Text"];

//	[rowsLock lock];
	dict = [rows objectAtIndex:sortDescending ? [rows count] - rowIndex - 1 : rowIndex];
//	[rowsLock unlock];

	if (![dict objectForKey:[aTableColumn identifier]])
	{
//		parsen und die Werte ins dict fuellen (lazy filling)
//		sollte eigentlich nicht mehr vorkommen weil das in  suchStarten schon passiert
//		[self fillFundstelle:dict];
//		NSLog(@"DBFundstellenDataSource.m - (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex :: should not reach here");
		// ist ok denn nicht alle DS haben auch alle Felder die die tv verlangt
		rv =  @"";
	}
	else
	{
		rv = [dict objectForKey:[aTableColumn identifier]];
		if (textspalte && [name isEqualToString:kMarkierungenTableViewName]) // dann den text vor der ausgabe farbig machen
		{
			unsigned int len;
			NSMutableString* string;
			len = [(NSString *)rv length];
			string = [NSMutableString stringWithCapacity:100];
			[string setString:rv];
			[string replaceOccurrencesOfString:@"\n"withString:@" " options:0 range:NSMakeRange(0,len)];
			//// GS hat keine farbe in den textzellen von dem tableview
			rv = [[NSMutableString alloc] initWithString:string];
			//// [rv addAttribute:NSBackgroundColorAttributeName value:[dict objectForKey:@"Farbe"] range:NSMakeRange(0,len)];
			[rv autorelease];
		}
	}
		return rv;;
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard
{
	return NO;
}

- (BOOL)acceptsFirstResponder
{
//	NSLog(@"acceptsFirstResponder");
	return YES;
}

-(void)paste:(id)_sender
{
	NSPasteboard *pboard;
	NSArray *ma;

	pboard = [NSPasteboard generalPasteboard];
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:MarkierungenPasteBoardType]])
	{
		ma = [self getRowsFromData:[pboard dataForType:MarkierungenPasteBoardType]];

		if (ma != nil)  // gueltige Daten
		{
			[self addObjectsFromArray:ma];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"markierungenChanged" object:nil];
			[tableView reloadData];
			isSaved=NO;
		}
		else
		{
			NSLog(@"paste : falsche MajorMinor aus ClipboardData!");
		}
	}
}

-(void)delete:(id)_sender
{
	NSMutableArray *ma;

//	NSLog(@"delete : %@",_sender);

	ma = [self arrayOfSelectedItems];

//	[rowsLock lock];
	[rows removeObjectsInArray:ma];
//	[rowsLock unlock];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"markierungenChanged" object:nil];
	[tableView reloadData];
	isSaved=NO;
}

-(void)addObjectsFromArray:(NSArray *)_array
{
	NSEnumerator *enu;
	NSMutableDictionary *dict;
	
	enu = [_array objectEnumerator];

	while (dict =[enu nextObject])
	{
		[self addObject:dict];
	}
	isSaved=NO;
}

-(void)setIsSaved:(BOOL)_state
{
	isSaved=_state;
}

-(NSMutableArray *)arrayOfSelectedItems
{
	NSMutableArray *ma;
	NSEnumerator *enu;
	
	id num;
	int index;
	
	ma = [NSMutableArray arrayWithCapacity:10];
	enu = [tableView selectedRowEnumerator];

//	[rowsLock lock];
	while (num = [enu nextObject])
	{
//		NSLog(@"num : %@",num);
		index = [num intValue];

		index = sortDescending ? [rows count] - index - 1 : index;

		[ma addObject:[rows objectAtIndex:index]];
	}
//	[rowsLock unlock];

	return ma;
}

-(NSArray *)getRowsFromData:(NSData *)_data
{
/*
checkt ob data majorminor ok und gibt die rows zurueck
 Wird beim Speichern und im Clipboard verwendet
 INPUT : data wie im clipboard oder aus nen file
 OUTPUT : rows oder nil wenn version nicht stimmt
 
 TODO : evtl. noch ne fehlermeldung wenn version falsch!!!
 */
	NSDictionary *dict;
	NSArray *rv;
	
//	NSLog(@"data %@",_data);
	if (_data == nil)
	{
		rv = nil;
	}
	else
	{
		dict = [NSUnarchiver unarchiveObjectWithData:_data];
		if ([[dict objectForKey:@"bandMajorMinor"] isEqualToString:bandMajorMinor])
		{
			rv = [dict objectForKey:@"rows"];
		}
		else
		{
			rv = nil;
		}
	}
	
	return rv;
}

-(NSData *)makeDataWithRows:(NSArray *)_rows
{
/*
 Wird beim Speichern und im Clipboard verwendet
 INPUT : array mit den rows die gespeichert werden
 OUTPUT : NSData mit den rows und einen majorminor number
*/
	NSDictionary *dict;
	
	dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:bandMajorMinor,_rows,nil] forKeys:[NSArray arrayWithObjects:@"bandMajorMinor",@"rows",nil]];
	
	return [NSArchiver archivedDataWithRootObject:dict];
}

-(void)cut:(id)_sender
{
	NSPasteboard *pboard;
	NSMutableArray *ma;

	pboard = [NSPasteboard generalPasteboard];

	ma = [self arrayOfSelectedItems];

//	[rowsLock lock];
	[rows removeObjectsInArray:ma];
//	[rowsLock unlock];

	[pboard declareTypes:[NSArray arrayWithObject:MarkierungenPasteBoardType] owner:nil];
	[pboard setData:[self makeDataWithRows:ma] forType:MarkierungenPasteBoardType];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"markierungenChanged" object:nil];
	[tableView reloadData];
	isSaved=NO;
}

-(NSString *)tabFormat
{
	NSEnumerator *enu,*fieldenu;
	NSMutableString *rv;
	NSDictionary *dict;
	NSArray *array;
	NSString *tmpstring,*firstline,*key;
	id obj;
	
	firstline = [NSString stringWithString:bandMajorMinor];
	array = [NSArray arrayWithObjects:@"Seite",@"Text",@"StartWort",@"EndWort",@"Kommentar",@"Bereich",@"Abschnitt",@"Konkordanz",@"Tag",nil];
	tmpstring = [array componentsJoinedByString:@"\t"];
	rv = [NSMutableString stringWithFormat:@"%@\n%@\n",firstline,tmpstring];

//	[rowsLock lock];
	enu = [rows objectEnumerator];
	
	while (dict = [enu nextObject])
	{
		fieldenu = [array objectEnumerator];
		while (key = [fieldenu nextObject])
		{
			obj = [dict objectForKey:key];
			if ([obj isKindOfClass:[NSNumber class]])
				[rv appendFormat:@"%d",[obj intValue]];
			else if ([obj isKindOfClass:[NSString class]])
				[rv appendString:obj];
			[rv appendString:@"\t"];
		}
		[rv replaceCharactersInRange:NSMakeRange([rv length]-1,1) withString:@"\n"];
	}	

//	[rowsLock unlock];
	return rv;
}

-(void)copy:(id)_sender
{
	NSPasteboard *pboard;
	NSMutableArray *ma;
	
	pboard = [NSPasteboard generalPasteboard];
	
	ma = [self arrayOfSelectedItems];
	
	[pboard declareTypes:[NSArray arrayWithObject:MarkierungenPasteBoardType] owner:nil];
	[pboard setData:[self makeDataWithRows:ma] forType:MarkierungenPasteBoardType];
}

- (void)keyDown:(NSEvent *)theEvent
{
	//NSLog(@"FundstellenDS keyDown : '%@'",[theEvent characters]);
	// GS : Hier ist es die Delete Taste und nicht Backspace
	if ([[theEvent characters]characterAtIndex:0] == NSDeleteFunctionKey)   // dieser '' character ist ein backspace
		[self delete:self];
}

-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSString *action;
	
	BOOL selection;
	BOOL clipboard;
	BOOL markierungen;

//	NSLog(@"menutag: %d",tag);
//	NSLog(@"validate Menu Item %@",[menuItem title]);

	markierungen = [name isEqualToString:@"Markierungen"];
	
	action = NSStringFromSelector([menuItem action]);
//	NSLog(@"validate menu action %@",action);

	selection = [[self arrayOfSelectedItems] count] >= 1;

	clipboard = [self getRowsFromData:[[NSPasteboard generalPasteboard] dataForType:MarkierungenPasteBoardType]] != nil;
	
	if ([action isEqualToString:@"copy:"] && selection)
		return YES;
	else if ([action isEqualToString:@"cut:"] && selection)
		return YES;
	else if ([action isEqualToString:@"paste:"] && clipboard && markierungen)
		return YES;
	else if ([action isEqualToString:@"delete:"] && selection)
		return YES;

	return NO;
}

@end
