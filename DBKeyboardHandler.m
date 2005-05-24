/*
 * DBKeyboardHandler.m -- 
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

#import "DBKeyboardHandler.h"


@implementation DBKeyboardHandler

-(BOOL)acceptsFirstResponder
{
	return YES;
}

-(void)keyDown:(NSEvent *)_evt
{
	unsigned short key;
	key = [_evt keyCode];
//	NSLog(@"DBPapgeView event: %@",_evt);

	switch (key) {
		case 116:   // prev page
			[NSApp sendAction:@selector(backpageButtonAction:) to:nil from:self];
			break;
		case 121:   // next page
			[NSApp sendAction:@selector(nextpageButtonAction:) to:nil from:self];
			break;
		case 123:   // 	prev page
			[NSApp sendAction:@selector(backpageButtonAction:) to:nil from:self];
			break;
		case 124:   // next page
			[NSApp sendAction:@selector(nextpageButtonAction:) to:nil from:self];
			break;
		default:
			[self interpretKeyEvents:[NSArray arrayWithObject:_evt]];
			break;
	}
}

@end
