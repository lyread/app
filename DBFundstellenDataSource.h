/*
 * DBFundstellenDataSource.h -- 
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

extern NSString *kMarkierungenTableViewName;
extern NSString *kFundstellenTableViewName;
extern NSString *MarkierungenPasteBoardType;


@interface DBFundstellenDataSource : NSResponder <NSCoding>
{
	NSMutableArray *rows;
	BOOL sortDescending;
	BOOL isSaved;
	NSTableColumn* lastColumn;
	NSTableView* tableView;
	NSString *name,*bandMajorMinor;
	NSLock *rowsLock;
}

-(void)setTableView:(NSTableView *)_tv;
-(id)initWithName:(NSString *)_name BandMajorMinor:(NSString *)_bandMajorMinor;
-(void)removeAllObjects;
-(void)addObject:(id)_obj;
-(void)sorting:(NSString *)name;
-(NSMutableArray *)rows;
-(NSArray *)getRowsFromData:(NSData *)_data;
-(NSData *)makeDataWithRows:(NSArray *)_rows;
-(NSMutableArray *)arrayOfSelectedItems;
-(void)showPageForIndex:(int)_index;
-(void)setIsSaved:(BOOL)_state;
-(void)addObjectsFromArray:(NSArray *)_array;
-(NSString *)tabFormat;
-(BOOL)hasUnsavedChanges;
-(BOOL)saveToFile:(NSString *)_filename;
-(BOOL)loadFromFile:(NSString *)_filename;
-(NSString *)lastSavedFilename;


@end
