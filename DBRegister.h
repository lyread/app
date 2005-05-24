/*
 * DBRegister.h -- 
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
#import <AppKit/AppKit.h>

#import "DBRegisterEntry.h"
#import "Helper.h"

@interface DBRegister : NSObject
{
	NSMutableArray *registerArray;
	NSMutableArray *filteredRegisterArray;
	NSMutableDictionary *kategorieDict;
	NSString *filter;

//	Controller* controller;

	id band;		// wird nur gespeichert aber nicht aufgerufen!

	NSTableColumn* lastColumn;
	BOOL sortDescending;
}

-(id)initWithBand:(id)_band masterPath:(NSString*)_masterPath fastArray:(NSArray*)_fastArray;
//controller:(Controller*)_controller;
-(void)loadLemmataTable:(NSString*)_masterPath fastArray:(NSArray*)_fastArray;

-(int)PageForIndex:(int)i;
-(int)indexForFilter:(NSString *)f;
-(NSArray *)kategories;
-(void)kategorySelection:(NSArray *)kategories;
-(int)count;
-(id)band;

- (void)sorting:(NSString *)_name;
-(int)pageNumberForTitle:(NSString *)_title;


@end
