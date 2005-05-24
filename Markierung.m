/*
 * Markierung.m -- 
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

#import "Markierung.h"

@implementation Markierung

-(id)initWithRange:(NSRange)r pageNumber:(long)p string:(NSString *)s color:(NSColor *)c
{
	[super init];
	range = r;
	pagenumber = p;
	string = [s retain];
	color = [c retain];
	
	return self;
}

-(void)dealloc
{
	[string release];
	[color release];
	[super dealloc];
}

-(int)pagenumber
{
	return pagenumber;
}

-(NSString *)string
{
	return string;
}

-(NSColor *)color
{
	return color;
}

-(NSRange)range
{
	return range;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"page: %d color: %@ range: %d,%d text: %@",pagenumber,color,range.location,range.length,string];
}

@end
