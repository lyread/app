/*
 * ImageController.m -- 
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

#import "ImageController.h"

@implementation ImageController

- (id)initWithDBImageSet:(DBImageSet*)_imageSet
{
	self = [super initWithWindowNibName:@"ImageViewer"];

	if ([_imageSet image3] == nil && [_imageSet image2] == nil)
	{
		[self autorelease];
		return nil;
	}

	imageSet = [_imageSet retain];

	[self showWindow:self];
	return self;
}

-(void)dealloc
{
	[imageSet release];
	[super dealloc];
}

-(void)awakeFromNib
{
	NSImage* myImage = [imageSet image3];

	if (myImage == nil)
		myImage = [imageSet image2];

	NSSize size = [myImage size];
	if(size.width < 800 && size.height < 600)
		scalevalue = 50;
	else
		scalevalue = 25;

	[scalePopUpButton selectItemAtIndex:[scalePopUpButton indexOfItemWithTag:scalevalue]];

	[[self window] setDelegate:self];
	[self setImageInView];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self autorelease];
}

- (IBAction) scalevaluePopUpMenu:(id)_sender
{
	scalevalue = [[_sender selectedItem] tag];
	[self changeImageInView:0];
}

- (IBAction) nextButtonAction:(id)sender
{
	[self changeImageInView:+1];
}

- (IBAction) backButtonAction:(id)sender
{
	[self changeImageInView:-1];
}

- (IBAction) changeImageInView:(int)_newIndex
{
	NSArray* imageArray;
	DBImageSet* newImageSet;
	int newIndex;

	if (_newIndex != 0)
	{
		imageArray = [[imageSet band] imageArray];		
		newIndex = [imageArray indexOfObject:imageSet] + _newIndex;
		newImageSet = [imageArray objectAtIndex:newIndex];
		[imageSet release];
		imageSet = [newImageSet retain];
	}

	[self setImageInView];	
}

-(void)setImageInView
{
	NSString* tmpstring = nil;
	NSImage* myImage = nil;

	tmpstring = [imageSet imageDescription1];

	if (tmpstring == nil)
		tmpstring = [imageSet imageName];

	[[self window] setTitle:tmpstring];
	[descriptionField setStringValue:tmpstring];

	myImage = [imageSet image3];

	if (myImage == nil)
		myImage = [imageSet image2];

	NSSize size = [myImage size];

	NSString* tmpString2 = [NSString stringWithUTF8String:"Aufloesung"];

	NSString* tooltipstring = [NSString stringWithFormat:@"%@: %0.f*%0.f",tmpString2,size.width,size.height];

	[myImage setScalesWhenResized:YES];
	NSSize mysize = [myImage size];
	mysize.width *= (scalevalue/100);
	mysize.height *= (scalevalue/100);
	[myImage setSize:mysize];

	[imageView setToolTip:tooltipstring];

	[imageView setImage:myImage];

	NSRect myFrame = [imageView frame];

	myFrame.size = [myImage size];

	[imageView setFrameSize:myFrame.size];

	[self setButtons];

	[imageScrollView setNeedsDisplay:YES];
}

-(void)setButtons
{
	Band* myBand;
	NSArray* imageArray;
	int newIndex;

	myBand = [imageSet band];

	imageArray = [myBand imageArray];

	newIndex = [imageArray indexOfObject:imageSet];

	if ([imageSet hidden])
	{
		[backButton setEnabled:NO];
		[nextButton setEnabled:NO];
		return;
	}

	if (newIndex >= 1)
		[backButton setEnabled:YES];
	else
		[backButton setEnabled:NO];

	if (newIndex < ([imageArray count]-1))
		[nextButton setEnabled:YES];
	else
		[nextButton setEnabled:NO];
}

- (IBAction) saveButtonAction:(id)sender
{
	NSSavePanel* mySavePanel;

//	NSLog(@"scrollsize: %0.fx%0.f",[imageScrollView frame].size.width,[imageScrollView frame].size.height);
//	NSLog(@"imagesize: %0.fx%0.f",[imageView frame].size.width,[imageView frame].size.height);

	mySavePanel = [NSSavePanel savePanel];
	[mySavePanel setTitle:@"digiBib Bild Speichern"];
	[mySavePanel setAccessoryView:accView];
	[mySavePanel beginSheetForDirectory:nil file:nil modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void) savePanelDidEnd:(NSSavePanel*)_sheet returnCode:(int)_returnCode contextInfo:(void*)_contextInfo
{
	NSData* savethispic = nil;
	NSString* myfilename;

	if (_returnCode == NSOKButton)
	{
		NSImage *img;
		NSBitmapImageRep* imageRep;

		img = [imageSet image3];
		if (img == nil) img = [imageSet image2];
		else if (img == nil) img = [imageSet image1];

		myfilename = [NSMutableString stringWithString:[_sheet filename]];
//		NSString* extension = [myfilename pathExtension];
//		NSLog(@"Image: %@",img);
		imageRep = [[img representations] lastObject];

		if (imageRep == nil)
		{
			NSRunAlertPanel(@"Fehler",@"Beim Speichern des Bildes ist ein Fehler aufgetreten!",@"OK",nil,nil);
			return;
		}

		//if ([[formatPopUpButton selectedItem] tag] == 4) // RAW format, so wie auf der CD/DVD
		if (1) // RAW format, so wie auf der CD/DVD
		{
			NSString* newmyfilename;
			NSData* rawImageData;
			int imageType;

			rawImageData = [imageSet rawImage3];
			imageType = [imageSet imageType3];
			if (rawImageData == nil)
			{
				rawImageData = [imageSet rawImage2];
				imageType = [imageSet imageType2];
			}
			else if (rawImageData == nil)
			{
				rawImageData = [imageSet rawImage1];
				imageType = [imageSet imageType1];
			}

			if (imageType == 2)
			{
				newmyfilename = [myfilename stringByAppendingPathExtension:@"jpg"];
			}
			else if (imageType == 3)
			{
				newmyfilename = [myfilename stringByAppendingPathExtension:@"jpg"];
			}
			else
			{
				NSLog(@"rawImage size: %d",[rawImageData length]);
				NSLog(@"unknown imagetype: %d",imageType);
				newmyfilename = myfilename;
			}

			[rawImageData writeToFile:newmyfilename atomically:NO];
			return;
		}

		switch ([[formatPopUpButton selectedItem] tag])
		{
			case 0: // JPEG
				myfilename = [myfilename stringByAppendingPathExtension:@"jpg"];
				savethispic = [imageRep representationUsingType:NSJPEGFileType properties:nil];
				break;
			case 1: // TIFF
				myfilename = [myfilename stringByAppendingPathExtension:@"tiff"];
				savethispic = [imageRep TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:255.0];
				break;
			case 2: // PNG
				myfilename = [myfilename stringByAppendingPathExtension:@"png"];
				savethispic = [imageRep representationUsingType:NSPNGFileType properties:nil];
				break;
			case 3: // GIF
				myfilename = [myfilename stringByAppendingPathExtension:@"gif"];
				savethispic = [imageRep representationUsingType:NSGIFFileType properties:nil];
				break;
		}
		
		[savethispic writeToFile:myfilename atomically:NO];
	}
} 

@end
