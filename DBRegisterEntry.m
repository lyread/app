/*
 * DBRegisterEntry.m -- 
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

#import "DBRegisterEntry.h"

@implementation DBRegisterEntry

-(id)initWithText:(NSString *)_zeile fastArray:(NSArray*)_fastArray
{
	NSArray* myArray;

	[super init];
	
	NSCharacterSet* myCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	myArray = [_zeile componentsSeparatedByString:@"#"];

	if ([myArray count] == 2)
	{
		text = [myArray objectAtIndex:0];

		text = [text stringByTrimmingCharactersInSet:myCharacterSet];

		if ([text length] < 1)
		{
			[self autorelease];
			return nil;
		}

		NSString* lastObject = [myArray lastObject];

		pagenumber = [[lastObject substringFromIndex:1] intValue];

		unichar c = [lastObject characterAtIndex:0];

		if (c >= 'A' && c <= 'Z')
			kategorie = [_fastArray objectAtIndex:(c-'A')];
		else
			NSLog(@"Warning! unichar is not a char!");

		if ([kategorie length] <= 1)
		{
			[self autorelease];
			return nil;
		}

		[kategorie retain];
		[text retain];
	}
	return self;
}

-(NSString*)stichwort
{
	return text;
}

-(NSString*)kategorie
{
	return kategorie;
}

-(BOOL)matchkategory:(NSArray *)kats
{
	NSEnumerator *enu;
	NSString *cat;
	enu = [kats objectEnumerator];

	while (cat = [enu nextObject])
	{
		if ([cat isEqualToString:[self kategorie]]) 
		{
			return YES;
		}
	}
	return NO;
}

-(int)pageNumber
{
	return pagenumber;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"text: %@ kategorie: %@ pagenumber: %d",text,kategorie,pagenumber];
}

@end
