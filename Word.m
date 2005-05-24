/*
 * Word.m -- 
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

#import "Word.h"

@implementation Word

-(id)initWithWord:(NSString *)s Range:(NSRange) r Konkordanz:(int)_konkordanz Sigel:(NSString *)_sigel
{
	[super init];
	word = [s retain];
	sigel = [_sigel retain];
	konkordanz = _konkordanz;
	range = r;
	return self;
}

-(void)dealloc
{
	[word release];
	[sigel release];
	[super dealloc];
}
-(int)konkordanz
{
	return konkordanz;
}

-(NSString *)word
{
	return word;
}
-(NSString *)sigel
{
	return sigel;
}

-(NSRange)range
{
	return range;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"Word: %@ Position: %d  length: %d",word,range.location,range.length]; 
}

@end
