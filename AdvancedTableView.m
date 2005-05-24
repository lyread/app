/*
 * AdvancedTableView.m -- 
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

#import "AdvancedTableView.h"

@implementation AdvancedTableView

- (id)initWithFrame:(NSRect)frame 
{
	self = [super initWithFrame:frame];

	if (self)
	{
//		Initialization code here.
		filter = [[NSMutableString alloc] init];
		timer = nil;
		[self setAutoresizesAllColumnsToFit:YES];
		[self sizeToFit];
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
//  Drawing code here.
}

-(void)makeKategorieCheckboxes
{
	NSEnumerator *enu,*cellenu;
	NSString *kat;
	NSButtonCell *buttonCell;
	int rows;
	float maxWidth=0;
	float maxHeight=0;
	int cols = 1;

	if (kategoriebox == nil) 
	{
		kategoriebox = (NSBox *)kategoriematrix;
	}

//	NSLog(@"kategoriebox: %@",kategoriebox);
	rows = [[(DBRegister *)[self dataSource] kategories] count]+1 / cols;
	buttonCell = [[NSButtonCell alloc] init];
	[buttonCell setButtonType:NSSwitchButton];
	[buttonCell setTarget:self];
	[buttonCell setState:NSOffState];
	[buttonCell setAction:@selector(kategoryCheckboxClicked:)];

	rows = [[[self dataSource] kategories] count];
	kategoriematrix = [[NSMatrix alloc] initWithFrame:[kategoriebox frame] mode:NSHighlightModeMatrix prototype:buttonCell numberOfRows:rows numberOfColumns:cols];

	[kategoriematrix setAutoresizingMask:[kategoriebox autoresizingMask]];

	[[kategoriebox superview] replaceSubview:kategoriebox with:kategoriematrix];

	enu = [[[self dataSource] kategories] objectEnumerator];
	cellenu = [[kategoriematrix cells] objectEnumerator];

	if ([[self dataSource] band] != nil)
	{
		NSArray *presets;

		presets = [[NSUserDefaults standardUserDefaults] objectForKey:[[[self dataSource] band] registereinstellungen]];
		
		while (kat = [enu nextObject])
		{
			id cell;
//		NSLog(@"%@",kat);
			cell = [cellenu nextObject];
			[cell setTitle:kat];

			if (presets && [presets containsObject:kat] || !presets)
				[cell setState:NSOnState];

			maxHeight = [cell cellSize].height;
			maxWidth = [cell cellSize].width > maxWidth ? [cell cellSize].width : maxWidth;
		}
	}

	[self kategoryCheckboxClicked:self];

	[kategoriematrix setCellSize:NSMakeSize(maxWidth,maxHeight)];

	NSRect oldframe = [kategoriematrix frame];
	[kategoriematrix sizeToFit];
	NSRect newframe = [kategoriematrix frame];

	float diff = oldframe.size.height - newframe.size.height;

	newframe.origin.y += diff;
	[kategoriematrix setFrame:newframe];

	newframe = [kategoriematrix frame];

	NSRect aframe = [springezuText frame];
	aframe.origin.y = newframe.origin.y - 21;
	[springezuText setFrame:aframe];

	NSRect bframe = [springezuTextField frame];
	bframe.origin.y = newframe.origin.y - 21;
	[springezuTextField setFrame:bframe];

	NSRect tmpframe = [registerScrollView frame];
	tmpframe.size.height = bframe.origin.y - 10;
	[registerScrollView setFrame:tmpframe];

//	[kategoriematrix setNeedsDisplay:YES];
//	[springezuText setNeedsDisplay:YES];
//	[springezuTextField setNeedsDisplay:YES];
	[[registerScrollView superview] setNeedsDisplay:YES];

//	[kategoriematrix setNeedsDisplay:YES];
	kategoriebox = nil;
}

-(void)kategoryCheckboxClicked:(id)sender
{
	NSMutableArray *cats;
	NSEnumerator *cellenu;
	NSButtonCell *cell;

	if ([self dataSource] != nil)
	{
		cats = [[NSMutableArray alloc] init];
		cellenu = [[kategoriematrix cells] objectEnumerator];
		
		while (cell = [cellenu nextObject])
		{
			if ([cell intValue])
			{
				[cats addObject:[cell title]];
			}
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:cats forKey:[[[self dataSource] band] registereinstellungen]];
		[[self dataSource] kategorySelection:[cats autorelease]];
	}

	[self reloadData];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSLog(@"Advanced Table View keyDown");

	if (timer) 
	{
		[timer invalidate];
	}
	
	[self addChars:[theEvent characters]];
	timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
}

-(void)timerFired:(id)userinfo
{
	[filter setString:@""];
	timer = nil;
}

-(void)addChars:(NSString *)chars
{
	[filter appendString:[chars lowercaseString]]; 
	if (![self applyfilter:filter])
	{
		[filter setString:@""];
		timer = nil;
	}
}

-(BOOL)applyfilter:(NSString *)_newfilter
{
	int newindex;
	newindex = [[self dataSource] indexForFilter:_newfilter];

	NSLog(@"filter: %@",_newfilter);

	if (newindex == -1)
	{
		NSLog(@"No match!");
		NSBeep();
		return NO;
	}
	else
	{
		[self scrollRowToVisible:newindex];
		[self selectRow:newindex byExtendingSelection:NO];
		return YES;
	}
}

- (IBAction) springezuAction:(id)sender
{
	if ([sender stringValue])
	{
		if ([[sender stringValue] length])
		{
			if (![self applyfilter:[[sender stringValue] lowercaseString]])
				[sender setStringValue:@""];
		}
	}
}

@end
