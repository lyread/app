/*
 * DBPrintView.m -- 
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

#import "DBPrintView.h"

@implementation DBPrintView

-(id)initWithArray:(NSArray*)_pageArray printInfo:(NSPrintInfo*)_printInfo
{
	NSTextView* textView;
	NSTextField* konkoTextField;
	NSTextField* titleTextField;
	NSTextField* bottomTextField;

	int weite;

	NSLog(@"initWithArray");

	pageArray = [_pageArray retain];

	pages = [pageArray count];

	if(pages > 0)
	{
		NSRect theFrame;
		NSRect textFrame;
		NSRect bottomTextFrame;
		NSRect konkoTextFrame;
		NSRect titleTextFrame;
		NSRect seiteTextFrame;
		NSSize paperSize;

		textFrame = NSMakeRect(0,0,0,0);

		NSLog(@"Anzahl der Seiten: %d",pages);

		paperSize = [_printInfo paperSize];

		// das ganz grosse View zum drucken

		theFrame.origin = NSMakePoint(0,0);
		theFrame.size.width = paperSize.width;
		theFrame.size.height = paperSize.height * pages;

		// das dbpage View

		textFrame.size.width = paperSize.width * 0.90;  // nur 90% breit drucken
		textFrame.size.height = paperSize.height - 40;
		textFrame.origin.x = paperSize.width * 0.05;	// 5% fuer den linken rand

		NSLog(@"papersize width: %0.f  height: %0.f",paperSize.width,paperSize.height);

		rectHeight = paperSize.height;

		self = [super initWithFrame:theFrame];

		NSEnumerator* enu = [pageArray reverseObjectEnumerator];

		DBPage* dbpage;
		while(dbpage = [enu nextObject])
		{
			NSLog(@"druckseite parsen: %d",[dbpage textpagenumber]);

			textView = [[NSTextView alloc] initWithFrame:textFrame];
			[dbpage setSearchPosition:-1];
			[dbpage setShowMarkierungen:NO];
			[dbpage displayPageInView:textView];

			NSLog(@"textlength: %d",[[textView textStorage] length]);

			NSLog(@"framehoehe: %.0f",[textView frame].size.height);

			// Konkordanznumber

			konkoTextFrame = textFrame;
			konkoTextFrame.size.height = 20;
			konkoTextFrame.origin.y = textFrame.origin.y + paperSize.height - 20;
			konkoTextField = [[NSTextField alloc] initWithFrame:konkoTextFrame];
			[konkoTextField setIntValue:[dbpage textpagenumber]];
			[konkoTextField sizeToFit];
			[konkoTextField setEditable:NO];
			[konkoTextField setSelectable:NO];
			[konkoTextField setDrawsBackground:NO];
			[konkoTextField setBordered:NO];
			NSLog(@"Konkordanz end");
			// Ueberschrift

			titleTextFrame = textFrame;
			titleTextFrame.size.height = 20;
			titleTextFrame.origin.y = textFrame.origin.y + paperSize.height - 20;
			titleTextField = [[NSTextField alloc] initWithFrame:titleTextFrame];

			[titleTextField setStringValue:[dbpage titleFromTree]];

			[titleTextField sizeToFit];

			weite = [titleTextField frame].size.width;
			titleTextFrame.origin.x = (textFrame.size.width/2) - (weite/2);
			[titleTextField setFrame:titleTextFrame];

			[titleTextField setEditable:NO];
			[titleTextField setSelectable:NO];
			[titleTextField setDrawsBackground:NO];
			[titleTextField setBordered:NO];

			NSLog(@"Ueberschrift end");
			// Sigel, Seitenzahl

			seiteTextFrame = textFrame;
			seiteTextFrame.size.height = 20;
			seiteTextFrame.origin.y = textFrame.origin.y + paperSize.height - 20;
			NSTextField* seiteTextField = [[NSTextField alloc] initWithFrame:seiteTextFrame];

			if ([dbpage pageSigel] != nil && [[dbpage pageSigel] length] > 0)
			{
				[seiteTextField setStringValue:[NSString stringWithFormat:@"%@, %d",[dbpage pageSigel],[dbpage konkordanznumber]]];
			}
			else if ([dbpage konkordanznumber] > 0)
				[seiteTextField setStringValue:[NSString stringWithFormat:@"%d",[dbpage konkordanznumber]]];

			[seiteTextField sizeToFit];

			weite = [seiteTextField frame].size.width;
			seiteTextFrame.origin.x = textFrame.size.width - weite - 10;
			[seiteTextField setFrame:seiteTextFrame];

			[seiteTextField setEditable:NO];
			[seiteTextField setSelectable:NO];
			[seiteTextField setDrawsBackground:NO];
			[seiteTextField setBordered:NO];

			NSLog(@"Sigel");
			// Fussnote

			bottomTextFrame = textFrame;
			bottomTextFrame.size.height = 20;
//			bottomTextFrame.origin.y = textFrame.origin.y;
			bottomTextField = [[NSTextField alloc] initWithFrame:bottomTextFrame];
			//[bottomTextField setStringValue:[[[dbpage band] digibibDict] objectForKey:@"[Default]Signet"]];
			[bottomTextField setStringValue:@"aelkj;lajsdfljalsdjfajdfj"];
			[bottomTextField setEditable:NO];
			[bottomTextField setSelectable:NO];
			[bottomTextField setDrawsBackground:NO];
			[bottomTextField setBordered:NO];

			//[self addSubview:seiteTextField positioned:NSWindowAbove relativeTo:nil];
			[self addSubview:seiteTextField];
			//[self addSubview:titleTextField positioned:NSWindowAbove relativeTo:nil];
			[self addSubview:titleTextField];
			//[self addSubview:konkoTextField positioned:NSWindowAbove relativeTo:nil];
			[self addSubview:konkoTextField];
			//[self addSubview:bottomTextField positioned:NSWindowAbove relativeTo:nil];
			[self addSubview:bottomTextField];
			//[self addSubview:textView positioned:NSWindowBelow relativeTo:nil];
			[self addSubview:textView];

			textFrame.origin.y += paperSize.height;
		}

		return self;
	}
	else
	{
		[pageArray release];
		return nil;
	}
}

-(void)dealloc
{
	[pageArray release];
	[super dealloc];
}

//how many pages?
-(BOOL)knowsPageRange:(NSRange*)rptr
{
	NSLog(@"Es hat mich nach den Seiten gefragt! (%d)",[pageArray count]);

	rptr->location = 1;
	rptr->length = [pageArray count];
	return YES;
}

//where will the drawing for page 'pagenum' happen?
-(NSRect)rectForPage:(int)_pageNum
{
	NSRect theResult;

	NSRect myBounds = [self bounds];

	theResult.size.width = myBounds.size.width;
	theResult.size.height = rectHeight;

	theResult.origin.x = myBounds.origin.x;
	theResult.origin.y = NSMaxY(myBounds) - (_pageNum * theResult.size.height);
	
	return theResult;
}

@end
