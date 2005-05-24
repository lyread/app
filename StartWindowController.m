/*
 * StartWindowController.m -- 
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

#import "StartWindowController.h"
#import "BMPImage.h"

@implementation StartWindowController

- (id)initWithParentObject:(id)_controller
{
	self = [super initWithWindowNibName:@"StartWindow"];

	controller = _controller;

	masterpath = nil;

	[self showWindow:self];

	return self;
}

-(void)dealloc
{
	[masterpath release];
	[super dealloc];
}

-(void) awakeFromNib
{
	NSString* file;
	NSString* pfad = nil;
	NSString* tmppath = nil;

	[fromcdButton setEnabled:NO];

	[[self window] registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	[[self window] setDelegate:self];

	file = [self searchForDigiBib];		// auf cd checken (oder eventuell auf platte!)

	if (file != nil)
	{
		pfad = [file stringByDeletingLastPathComponent];
		tmppath = [[pfad stringByDeletingLastPathComponent] retain];
	}

	if ((tmppath == nil) || ([self showThisPath:tmppath] == 0))
	{
		tmppath = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastLoadedBand"];
		[self showThisPath:tmppath];
	}
}

-(int) showThisPath:_path
{
	NSString* pfad;
	NSString* file;
	NSString* coverfilename;
	NSString* majorstring;
	NSString* caption;
	NSDictionary* dict;
	NSImage* coverimage;

	int majo,minor;

	[masterpath release];
	masterpath = [_path retain];

	if (masterpath == nil) return 0;

	NSLog(@"masterpath: %@",masterpath);

	pfad = [NSString stringWithFormat:@"%@/Data",masterpath];
	pfad = [Helper findFile:pfad startPath:masterpath];

	file = [NSString stringWithFormat:@"%@/Data/digibib.txt",masterpath];

	dict = [self loadDigibibTableFromPath:file];

	if (dict == nil)
	{
		[pathTextField setStringValue:@""];
		[titleField setStringValue:@""];
		[fromcdButton setEnabled:NO];
		[imageView setImage:nil];
		return 0;
	}

	majo = [[dict objectForKey:@"[Default]CDMajor"] intValue];
	minor = [[dict objectForKey:@"[Default]CDMinor"] intValue];
	caption = [dict objectForKey:@"[Default]Caption"];

	if (majo < 0)
	{
		majo = abs(majo);
		majorstring = [NSString stringWithFormat:@"m%d",majo];
	}
	else
	{
		majorstring = [NSString stringWithFormat:@"%d",majo];
	}

	NSBundle *myBundle = [NSBundle mainBundle];

//	coverfilename = [NSString stringWithFormat:@"%@/COVER%@.BMP",pfad,majorstring];
	coverfilename = [NSString stringWithFormat:@"%@/cover%@.bmp",pfad,majorstring];
	NSLog(@"coverfilename %@",coverfilename);
	coverfilename = [Helper findFile:coverfilename startPath:pfad];

	coverimage = [[BMPImage alloc] initWithData:[NSData dataWithContentsOfFile:coverfilename]];

	NSLog(@"coverimage: %@",coverimage);
	NSLog(@"imagefiletypes : %@",[NSImage imageFileTypes]);
	if (majo == 1 && minor == 5)
	{
		[coverimage autorelease];
		coverimage = [[BMPImage alloc] initWithData:[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/COVER1B.BMP",[myBundle resourcePath]]]];
	}
	else if (coverimage == nil && majo == 1)
	{
		[coverimage autorelease];
		coverimage = [[BMPImage alloc] initWithData:[NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/COVER1.BMP",[myBundle resourcePath]]]];
	}

	[coverimage autorelease];

	[imageView setImage:coverimage];
	[fromcdButton setEnabled:YES];
	[fromcdButton highlight:YES];

	[titleField setStringValue:caption];
	[pathTextField setStringValue:masterpath];

	return 1;
}

-(NSString*)searchForDigiBib
{
	NSEnumerator* enu;
	NSString* object;

	NSFileManager* nsmanager = [NSFileManager defaultManager];

	NSArray* mountpoints = [nsmanager directoryContentsAtPath:@"/Volumes/"];

	enu = [mountpoints objectEnumerator];

	while (object = [enu nextObject])
	{
		NSString* path;
		NSString* newstring;

		path = [NSString stringWithFormat:@"/Volumes/%@",object];

		NSLog(@"checking: %@",path);

		newstring = [Helper findFile:@"data/digibib.txt" startPath:path];
		if ([[newstring lowercaseString] hasSuffix:@"digibib.txt"])
		{
			if ([nsmanager isReadableFileAtPath:newstring] == YES)
			{
				NSLog(@"was gefunden: %@",newstring);
				return newstring;
			}
		}

		// oder ist eventuell nur text.dki (wegen Band 1)

		newstring = [Helper findFile:@"data/text.dki" startPath:path];
		if ([[newstring lowercaseString] hasSuffix:@"text.dki"])
		{
			if ([nsmanager isReadableFileAtPath:newstring] == YES)
			{
				NSLog(@"was gefunden (ist wohl Band 1): %@",newstring);
				return newstring;
			}
		}
	}

	NSLog(@"keine CD eingelegt!");

	return nil;
}

-(NSDictionary*)loadDigibibTableFromPath:(NSString*)_path
{
	NSString *s,*group=nil;
	NSEnumerator *enu;
	NSMutableDictionary* digibibDict;
	NSData *myData;

	NSCharacterSet* myCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	if (_path == nil)
	{
		NSLog(@"Konnte DigiBib Dict nicht laden(1)");
		return nil;
	}

	myData = [NSData dataWithContentsOfFile:[Helper findFile:_path startPath:masterpath]];

	if(myData == nil)
	{
		NSBundle *myBundle = [NSBundle mainBundle];

		NSString* newstring = [Helper findFile:@"data/text.dki" startPath:masterpath];
		if ([[newstring lowercaseString] hasSuffix:@"text.dki"])
		{
			NSFileManager* nsmanager = [NSFileManager defaultManager];

			if ([nsmanager isReadableFileAtPath:newstring] == YES)
			{
				myData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/DIGIBIB.TXT",[myBundle resourcePath]]];
  
				NSLog(@"was gefunden (ist wohl Band 1): %@",newstring);
			}
		}

		if(myData == nil)
		{
			NSLog(@"Konnte DigiBib Dict nicht laden(2)");
			return nil;
		}
	}

	s = [[NSString alloc] initWithData:myData encoding:NSWindowsCP1252StringEncoding];
	[s autorelease];

	NSCharacterSet* charset = [NSCharacterSet characterSetWithCharactersInString:@"&&"];

	if ([s length])
	{
		digibibDict = [[NSMutableDictionary alloc] init];
		[digibibDict autorelease];

		NSArray *array = [s componentsSeparatedByString:@"\n"];
		enu = [array objectEnumerator];

		while (s = [enu nextObject])
		{
			s = [s stringByTrimmingCharactersInSet:myCharacterSet];

			array = [s componentsSeparatedByString:@"="];

			if ([array count] == 2)		// key value pair
			{
				int i,len;

				NSString* value = [array lastObject];
//				NSLog(@"value1: %@",value);

				len = [value length];

//				10.2: The method stringByTrimmingCharacters: would sometimes return an empty string (if the only character not to be trimmed was the last one). This has been fixed.
				if (len > 1) // umgeht fehler in 10.2 !!!
					value = [value stringByTrimmingCharactersInSet:charset];
				
				len = [value length];

				for (i=0 ; i < len && [value characterAtIndex:i] != '[' ; i++);

				value = [value substringToIndex:i];

				[digibibDict setObject:value forKey:[group stringByAppendingString:[array objectAtIndex:0]]];
			}
			else
			{
//				NSLog(@"%@",s);
				[group release];
				group = [[array lastObject] retain];
			}
		}

		return digibibDict;
	}

	NSLog(@"No digiBib.txt");
	return nil;
}

- (IBAction) selectBandFromCDAction:(id)_sender
{
	id blub;

	[startWindowProgressIndicator startAnimation:self];

	NSFileManager* filemanager = [NSFileManager defaultManager];
	const char* unixfilename = [filemanager fileSystemRepresentationWithPath:masterpath];

	NSLog(@"path: %s",unixfilename);

	blub = [controller loadBand:masterpath];
	[[NSUserDefaults standardUserDefaults] setObject:masterpath forKey:@"lastLoadedBand"];

	[startWindowProgressIndicator stopAnimation:self];
}

- (IBAction) selectNewBandAction:(id)_sender
{
	NSOpenPanel* myOpenPanel;

	myOpenPanel = [NSOpenPanel openPanel];

	[myOpenPanel setCanChooseDirectories:YES];

	if (NSOKButton == [myOpenPanel runModalForDirectory:nil file:nil types:nil])
	{
		NSLog(@"Lade diesen Band: %@",[[myOpenPanel filenames] lastObject]);
		[self showThisPath:[[myOpenPanel filenames] lastObject]];
	}
}

// drag&drop delegates:

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard;
	NSDragOperation sourceDragMask;

	sourceDragMask = [sender draggingSourceOperationMask];
	pboard = [sender draggingPasteboard];

	if([[pboard types] containsObject:NSFilenamesPboardType])
	{
		oldmasterpath = [masterpath retain];
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];

		if ([self showThisPath:[files lastObject]])
			return NSDragOperationCopy;
	}

	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[self showThisPath:oldmasterpath];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard;
	NSDragOperation sourceDragMask;

	sourceDragMask = [sender draggingSourceOperationMask];
	pboard = [sender draggingPasteboard];

	if ([[pboard types] containsObject:NSFilenamesPboardType])
	{
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];

		if ([self showThisPath:[files lastObject]])
			return YES;
	}

	return NO;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	exit(0);
}

@end
