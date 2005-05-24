/*
 * DBGaleryView.h -- 
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

#import "DBImageSet.h"
#import "ImageController.h"

@interface DBGaleryView : NSControl
{
	NSSlider *imageSlider;
	NSMatrix *matrix;
	NSArray *imageSets;
	NSSize imageSize;
	id target;
	SEL selector;
	
	int startIndex;
	int columns,rows,imageCount;
}

-(void)setImageSets:(NSArray *)newImageSets;
-(NSArray *)imageSets;

-(void)redisplay;
-(void)setImageSize:(NSSize)newSize;
-(NSSize)imageSize;

// GNUStep
-(void)setTarget:(id)sender;
-(void)setAction:(SEL)aSelector;

/* // OS X
-(IBAction)setTarget:(id)sender;
-(IBAction)setAction:(SEL)aSelector;
*/
-(void)scrollClick:(id)sender;


@end
