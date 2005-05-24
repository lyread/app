/*
 * DBGaleryView.m -- 
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

#import "DBGaleryView.h"

@implementation DBGaleryView

- (id)initWithFrame:(NSRect)frame
{
	NSImageCell* imageCell;

	int imageCellWidth;
	int defaultImageWidth = 100;

    self = [super initWithFrame:frame];

    if (self)
	{
		float scrollXPosition,scrollYPosition,scrollWidth,scrollHeight;
		scrollWidth = 24;
		scrollXPosition = frame.origin.x + frame.size.width - scrollWidth;
		scrollYPosition = frame.origin.y;
		scrollHeight = frame.size.height;
		NSRect matrixFrame = NSMakeRect(frame.origin.x,frame.origin.y,frame.size.width-scrollWidth,frame.size.height);

		imageSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(scrollXPosition, scrollYPosition, scrollWidth, scrollHeight)];

		imageCell = [[NSImageCell alloc] init];
//		[imageCell setImageScaling:NSScaleProportionally];  // default
//		[imageCell setImageAlignment:NSImageAlignCenter];   // default
		[imageCell setImageFrameStyle:NSImageFrameGrayBezel];

		columns = matrixFrame.size.width / defaultImageWidth;
		imageCellWidth = matrixFrame.size.width / columns;

		if (columns == 0) columns = 1;

		rows = (matrixFrame.size.height/imageCellWidth+1);
		matrix = [[NSMatrix alloc] initWithFrame:matrixFrame mode:NSRadioModeMatrix prototype:imageCell numberOfRows:rows numberOfColumns:columns];

		[self setAutoresizesSubviews:YES];

		[imageSlider setMinValue:0.0];
		[imageSlider setAutoresizingMask:NSViewMinXMargin|NSViewHeightSizable];
		[imageSlider setTarget:self];
		[imageSlider setAction:@selector(scrollClick:)];
		[imageSlider setAllowsTickMarkValuesOnly:YES];

		[matrix setCellSize:NSMakeSize(imageCellWidth,imageCellWidth)];
		[matrix setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
		[matrix setTarget:self];
		[matrix setAction:@selector(imageClicked:)];
//		[matrix setDoubleAction:@selector(imageDoubleClicked:)];

		[self addSubview:matrix];
		[self addSubview:imageSlider];

		imageCount = 0;
//		NSLog(@"Rows : %d Cols: %d imageCellWidth:%d",rows,columns,imageCellWidth);
		[imageCell release];
	}
	return self;
}

-(void)dealloc
{
	[imageSets release];
	
	[super dealloc];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[imageSlider setFloatValue: [theEvent deltaY] + [imageSlider floatValue]];
	[self scrollClick:imageSlider];
}

-(void)scrollClick:(id)sender
{
//	NSLog(@"[sender floatValue]: %f",[sender floatValue]);
	startIndex = ((((imageCount+(columns-1))/columns)-1) - [sender floatValue]) * columns;
//	NSLog(@"startIndex: %d",startIndex);
	if (startIndex < 0) startIndex = 0;
	[self redisplay];
}

- (void)setFrameSize:(NSSize)newSize
{
	NSImageCell* imageCell;
	int imageCellWidth;
	int defaultImageWidth = 100;
	int oldrows,oldcols;

	[super setFrameSize:newSize];

	oldrows = rows;
	oldcols = columns;

	NSRect matrixFrame = [matrix frame];	
	imageCell = [[[NSImageCell alloc] init] autorelease];
	[imageCell setImageFrameStyle:NSImageFrameGrayBezel];
	[imageCell setImageScaling:NSScaleProportionally];

	columns = matrixFrame.size.width / defaultImageWidth;
	imageCellWidth = matrixFrame.size.width / columns;

	if (columns == 0) columns = 1;
	rows = (matrixFrame.size.height/imageCellWidth+1);

	[matrix renewRows:rows columns:columns];
	[matrix setCellSize:NSMakeSize(imageCellWidth,imageCellWidth)];

	[imageSlider setMaxValue:((imageCount+(columns-1))/columns)-1];

	int sliderValue = [imageSlider maxValue]+1;

	if (sliderValue > 50) sliderValue = 0;

	[imageSlider setNumberOfTickMarks:sliderValue];

//	NSLog(@"Rows: %d Cols: %d imageCellWidth:%d",rows,columns,imageCellWidth);

	if (oldrows != rows || oldcols != columns)
	{
		[self redisplay];
		[imageSlider setFloatValue:((int)[imageSlider floatValue]*oldcols)/columns];
	}
	else
		[matrix setNeedsDisplay:YES];
}

-(void)redisplay
{
	NSEnumerator *cellEnu;
	DBImageSet *imageSet;
	NSImageCell *cell;

	int i = 0;

	cellEnu = [[matrix cells] objectEnumerator];

	while (cell = [cellEnu nextObject])
	{
		if (imageCount > startIndex+i)
		{
			imageSet = [imageSets objectAtIndex:startIndex + i++];

			if (imageCount > 20)
				[cell setImage:[imageSet image1]];
			else
				[cell setImage:[imageSet image2]];

			/* OS X
			[matrix setToolTip:[imageSet imageDescription1] forCell:cell];
			*/
			[cell setRepresentedObject:imageSet];
//			NSLog(@"i: %d",i);
		}
		else
		{
			// alle weiteren Cell clearen
			[cell setImage:nil];
			/*
			// OS X
			[matrix setToolTip:nil forCell:cell];
			*/
			[cell setRepresentedObject:nil];
		}
	}

	[matrix setNeedsDisplay:YES];
//	NSLog(@"redisplay rows: %d cols: %d",[matrix numberOfRows],[matrix numberOfColumns]);
}

-(void)setImageSets:(NSArray *)_newImageSets
{
	[imageSets release];
	imageSets = [_newImageSets retain];

	startIndex = 0;

	if (imageSets != nil)
	{
		imageCount = [imageSets count];

		int sliderValue = [imageSlider maxValue]+1;
		if (sliderValue > 50) sliderValue = 0;

		[imageSlider setMaxValue:((imageCount+(columns-1)) / columns)-1];
		[imageSlider setNumberOfTickMarks:sliderValue];
		[imageSlider setFloatValue:imageCount/columns];

//		NSLog(@"maxValue: %f",[imageSlider maxValue]);
//		NSLog(@"imageCount: %d",imageCount);

		if (imageCount > 1000)
			[imageSlider setContinuous:NO];
		else
			[imageSlider setContinuous:YES];
	}
	else
	{
		imageCount = 0;
		[imageSlider setMaxValue:0];
		[imageSlider setNumberOfTickMarks:0];
		[imageSlider setFloatValue:0];
	}
	[self redisplay];
}

-(NSArray *)imageSets
{
	return imageSets;
}

-(void)setImageSize:(NSSize)newSize
{
	imageSize = newSize;
}

-(NSSize)imageSize
{
	return imageSize;
}

-(IBAction)setTarget:(id)sender
{
	target = sender;
}

-(IBAction)setAction:(SEL)aSelector
{
	selector = aSelector;
}

-(void)imageClicked:(id)sender
{
//	NSNumber *num;
	ImageController* imageController;

	DBImageSet* imageSet;

	imageSet = [[sender selectedCell] representedObject];

	if (imageSet == nil)
		return;

	imageController = [[ImageController alloc] initWithDBImageSet:imageSet];

//	num = [NSNumber numberWithInt:[imageSet pageNumber]];
//	[target performSelector:selector withObject:num];
}

@end
