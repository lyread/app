/*
 * DBImageSet.h -- 
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

#import "Band.h"
#import "Helper.h"

@interface DBImageSet : NSObject
{
	NSString* imageName;

	NSString* imageFilename;

	NSString* imageDescription1;
	NSString* imageDescription2;

	id imageBand;

	int pageNumber;
	BOOL hidden;

	int imageAddress1;
	int imageSize1;
	NSImage* image1;
	int imageType1;

	int imageAddress2;
	int imageSize2;
	NSImage* image2;
	int imageType2;

	int imageAddress3;
	int imageSize3;
	NSImage* image3;
	int imageType3;
}

-(id)initWithName:(NSString*)_name;
-(NSString*)imageName;

-(void)setHidden:(BOOL)_hidden;
-(BOOL)hidden;

-(void)setPageNumber:(int)_pageNumber;
-(int)pageNumber;

-(void)setImageBand:(id)_image;
-(id)band;
-(void)setImageFilename:(NSString*)_blub;

-(void)setImage1:(NSImage*)_image;
-(void)setImageSize1:(int)_blub;
-(void)setImageAddress1:(int)_blub;
-(void)setImageType1:(int)_type;
-(int)imageType1;

-(void)setImage2:(NSImage*)_image;
-(void)setImageSize2:(int)_blub;
-(void)setImageAddress2:(int)_blub;
-(void)setImageType2:(int)_type;
-(int)imageType2;

-(void)setImage3:(NSImage*)_image;
-(void)setImageSize3:(int)_blub;
-(void)setImageAddress3:(int)_blub;
-(void)setImageType3:(int)_type;
-(int)imageType3;

-(NSImage*)imageWithNumber:(int)_size;
-(NSImage*)image1;
-(NSImage*)image2;
-(NSImage*)image3;
-(NSData*)rawImage1;
-(NSData*)rawImage2;
-(NSData*)rawImage3;

-(void)setImageDescription1:(NSString*)_imageDescription1;
-(void)setImageDescription2:(NSString*)_imageDescription2;
-(NSString*)imageDescription1;
-(NSString*)imageDescription2;

-(NSImage*)imageFromFolder:(NSString*)_foldername;
-(NSData*)imageDataFromFolder:(NSString*)_foldername;

-(NSString*)getImagePfad:(NSString*)_foldername;

@end
