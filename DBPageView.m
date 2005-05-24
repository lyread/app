/*
 * DBPageView.m -- 
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

#import "DBPageView.h"


@implementation DBPageView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
	NSLog(@"DBPageView initWithFrame");
        // Initialization code here.
		[self setEditable:NO];
		[self setRichText:YES];
		[self setSelectable:YES];
		NSColor *mycolor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.9412 alpha:1.0];
		[self setBackgroundColor: mycolor];
    }
    return self;
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}

-(void)keyDown:(NSEvent *)_evt
{
	unsigned short key;
	key = [_evt keyCode];
	NSLog(@"DBPapgeView event: %@ key: %d",_evt,key);

	switch (key) {
		case 100:   // prev page
			[NSApp sendAction:@selector(backpageButtonAction:) to:nil from:self];
			break;
		case 102:   // next page
			[NSApp sendAction:@selector(nextpageButtonAction:) to:nil from:self];
			break;
		case 105:   // 	prev page
			[NSApp sendAction:@selector(backpageButtonAction:) to:nil from:self];
			break;
		case 99:   // next page
			[NSApp sendAction:@selector(nextpageButtonAction:) to:nil from:self];
			break;
		default:
			[self interpretKeyEvents:[NSArray arrayWithObject:_evt]];
			break;
	}
}

@end
