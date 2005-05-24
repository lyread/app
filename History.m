/*
 * History.m -- 
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

#import "History.h"


@implementation History

-(id)initWithMaximum:(unsigned)s
{
	[super init];
	maximum = s;
	position = 0;
	list = [[NSMutableArray alloc] init];
	return self;
}

-(unsigned)maximum
{
	return maximum;
}

-(unsigned)position
{
	return position;
}

-(unsigned)count
{
	return [list count];
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"History: max: %d pos: %d\n%@",maximum,position,list];
}

-(void)addObject:(id)obj
{
	if (position < [list count]) { // alle dahinter entfernen
		[list removeObjectsInRange:NSMakeRange(position,[list count]-position)];
	}
	
	if ([list count] < maximum) {
		[list insertObject:obj atIndex:position];
		position++;
	}
	else {
		// hist voll also vorne rausschmeissen
		[list removeObjectAtIndex:0];
		[list insertObject:obj atIndex:position-1];
	}
//	NSLog(@"history : %@",list);
}

-(BOOL)canBackward
{
	return position > 1;
}

-(BOOL)canForward
{
	return position < [list count];
}

-(id)backward
{
	position--;
	return [list objectAtIndex:position-1];
}

-(id)forward
{
	position++;
	return [list objectAtIndex:position-1];
}

@end
