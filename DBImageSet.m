/*
 * DBImageSet.m -- 
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

NSString* imagePath = nil;

@implementation DBImageSet

-(id)initWithName:(NSString*)_name
{
	[super init];

	imageName = [_name retain];

	image1 = nil;
	image2 = nil;
	image3 = nil;

	imageDescription1 = nil;
	imageDescription2 = nil;

	return self;
}

-(void)dealloc
{
	[imageName release];
	[imageFilename release];

	[imageDescription1 release];
	[imageDescription2 release];

	[image1 release];
	[image2 release];
	[image3 release];

	[super dealloc];
}

-(NSString*)imageName
{
	return imageName;
}

-(id)band
{
	return imageBand;
}

-(void)setImageBand:(id)_band
{
	imageBand = _band;
}

-(void)setImageFilename:(NSString*)_filename
{
	imageFilename = [_filename retain];
}

-(NSString*)imageDescription1
{
	return imageDescription1;
}

-(void)setImageDescription1:(NSString*)_imageDescription1
{
	imageDescription1 = [_imageDescription1 retain];
}

-(NSString*)imageDescription2
{
	return imageDescription2;
}

-(void)setImageDescription2:(NSString*)_imageDescription2
{
	imageDescription2 = [_imageDescription2 retain];
}

-(int)pageNumber
{
	return pageNumber;
}

-(void)setPageNumber:(int)_pageNumber
{
	pageNumber = _pageNumber;
}

-(BOOL)hidden
{
	return hidden;
}

-(void)setHidden:(BOOL)_hidden
{
	hidden = _hidden;
}

// -----------------------------------------

-(void)setImageAddress1:(int)_addresse1
{
	imageAddress1 = _addresse1;
}

-(void)setImageSize1:(int)_size1
{
	imageSize1 = _size1;
}

-(void)setImage1:(NSImage*)_image1
{
	image1 = [_image1 retain];
}

-(void)setImageType1:(int)_type
{
	imageType1 = _type;
}

-(int)imageType1
{
	return imageType1;
}

-(void)setImageAddress2:(int)_addresse2
{
	imageAddress2 = _addresse2;
}

-(void)setImageSize2:(int)_size2
{
	imageSize2 = _size2;
}

-(void)setImage2:(NSImage*)_image2
{
	image2 = [_image2 retain];
}

-(void)setImageType2:(int)_type
{
	imageType2 = _type;
}

-(int)imageType2
{
	return imageType2;
}

-(void)setImageAddress3:(int)_addresse3
{
	imageAddress3 = _addresse3;
}

-(void)setImageSize3:(int)_size3
{
	imageSize3 = _size3;
}

-(void)setImage3:(NSImage*)_image3
{
	image3 = [_image3 retain];
}

-(void)setImageType3:(int)_type
{
	imageType3 = _type;
}

-(int)imageType3
{
	return imageType3;
}

-(NSImage*)imageWithNumber:(int)_size
{
	NSImage* image = nil;

	switch(_size)
	{
		case 1:
		{
			image = [self image1];
			break;
		}
		case 2:
		{
			image = [self image2];
			break;
		}
		case 3:
		{
			image = [self image3];
			break;
		}
	}

	return image;
}

-(NSImage*)image1
{
	int error;
	NSArray* myimageLocatorArray;

	if (image1 == nil)
	{
		FILE* imagehandle;

//		NSLog(@"imageAddress1: %010p",imageAddress1);
//		NSLog(@"imageSize1: %d",imageSize1);

		myimageLocatorArray = [imageBand imageLocatorArray];

		if (myimageLocatorArray != nil)		// Wenn bilder als File auf Medium liegen
		{
			image1 = [self imageFromFolder:@"Thumbs"];
			[image1 retain];
		}
		else	// wenn bilder in image.lib liegen
		{
			NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:imageFilename];
			imagehandle = fdopen([myNSFileHandle fileDescriptor],"r");

//			imagehandle = fopen([imageFilename cString],"r");
			if (imagehandle == 0) return nil;

			if (imageAddress1 == 0) return nil;

			error = fseek(imagehandle,imageAddress1,SEEK_SET);
			if (error) return nil;

			char* mem = malloc(imageSize1);
			int menge = fread(mem,1,imageSize1,imagehandle);
			if (menge != imageSize1) return nil;

			NSData* myImageData = [NSData dataWithBytesNoCopy:mem length:imageSize1 freeWhenDone:YES];
			image1 = [[NSImage alloc] initWithData:myImageData];

			fclose(imagehandle);

			[myNSFileHandle closeFile];
		}
	}

	NSSize imagesize = NSMakeSize(0,0);

	NSImageRep* imageRep = [[image1 representations] lastObject];

	imagesize.height = [imageRep pixelsHigh];

	if (imagesize.height != [imageRep size].height)
	{
		imagesize.width = [imageRep pixelsWide];
		[image1 setScalesWhenResized:YES];		// scalieren einschalten!
		[image1 setSize:imagesize];
	}

	return image1;
}

-(NSImage*)image2
{
	FILE* imagehandle;
	int error;
	NSArray* myimageLocatorArray;
	NSImage* myImage;

//	NSLog(@"imageAddress2: %010p",imageAddress2);
//	NSLog(@"imageSize2: %d",imageSize2);

	myimageLocatorArray = [imageBand imageLocatorArray];

	if (myimageLocatorArray != nil)
	{
		myImage = [self imageFromFolder:@"Small"];
	}
	else
	{
		NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:imageFilename];
		imagehandle = fdopen([myNSFileHandle fileDescriptor],"r");

//		imagehandle = fopen([imageFilename cString],"r");
		if (imagehandle == 0) return nil;

		if (imageAddress2 == 0) return nil;

		error = fseek(imagehandle,imageAddress2,SEEK_SET);
		if (error) return nil;

		char* mem = malloc(imageSize2);
		int menge = fread(mem,1,imageSize2,imagehandle);
		if (menge != imageSize2) return nil;

		NSData* myImageData = [NSData dataWithBytesNoCopy:mem length:imageSize2 freeWhenDone:YES];
		myImage = [[NSImage alloc] initWithData:myImageData];

		[myImage autorelease];

		fclose(imagehandle);

		[myNSFileHandle closeFile];
	}

	NSSize imagesize = NSMakeSize(0,0);
	NSImageRep* imageRep = [[myImage representations] lastObject];

	imagesize.height = [imageRep pixelsHigh];

	if (imagesize.height != [imageRep size].height)
	{
		imagesize.width = [imageRep pixelsWide];
		[myImage setScalesWhenResized:YES];		// scalieren einschalten!
		[myImage setSize:imagesize];
	}

	return myImage;
}

-(NSImage*)image3
{
	FILE* imagehandle;
	NSArray* myimageLocatorArray;
	NSImage* myImage;
	int error;

//	NSLog(@"imageAddress3: %010p",imageAddress3);
//	NSLog(@"imageSize3: %d",imageSize3);

	myimageLocatorArray = [imageBand imageLocatorArray];

	if (myimageLocatorArray != nil)
	{
		myImage = [self imageFromFolder:@"Huge"];
	}
	else
	{
		NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:imageFilename];
		imagehandle = fdopen([myNSFileHandle fileDescriptor],"r");

//		imagehandle = fopen([imageFilename cString],"r");
		if (imagehandle == 0) return nil;
		
		if (imageAddress3 == 0) return nil;

		error = fseek(imagehandle,imageAddress3,SEEK_SET);
		if (error) return nil;

		char* mem = malloc(imageSize3);
		int menge = fread(mem,1,imageSize3,imagehandle);
		if (menge != imageSize3) return nil;

		NSData* myImageData = [NSData dataWithBytesNoCopy:mem length:imageSize3 freeWhenDone:YES];
		myImage = [[NSImage alloc] initWithData:myImageData];

		fclose(imagehandle);

		[myNSFileHandle closeFile];
		[myImage autorelease];
	}

	NSSize imagesize = NSMakeSize(0,0);
	NSImageRep* imageRep = [[myImage representations] lastObject];

	imagesize.height = [imageRep pixelsHigh];

	if (imagesize.height != [imageRep size].height)
	{
		imagesize.width = [imageRep pixelsWide];
		[myImage setScalesWhenResized:YES];		// scalieren einschalten!
		[myImage setSize:imagesize];
	}

	return myImage;
}

-(NSData*)rawImage1
{
	FILE* imagehandle;
	NSData* myImageData = nil;
	NSArray* myimageLocatorArray;
	int error;

//	NSLog(@"rawImageAddress1: %010p",imageAddress1);
//	NSLog(@"rawImageSize1: %d",imageSize1);

	myimageLocatorArray = [imageBand imageLocatorArray];

	if (myimageLocatorArray != nil)
	{
		myImageData = [self imageDataFromFolder:@"Small"];
	}
	else
	{
		NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:imageFilename];
		imagehandle = fdopen([myNSFileHandle fileDescriptor],"r");

//		imagehandle = fopen([imageFilename cString],"r");
		if (imagehandle == 0) return nil;

		error = fseek(imagehandle,imageAddress1,SEEK_SET);
		if (error) return nil;

		if (imageAddress1 == 0) return nil;

		char* mem = malloc(imageSize1);
		int menge = fread(mem,1,imageSize1,imagehandle);
		if (menge != imageSize1) return nil;

		myImageData = [NSData dataWithBytesNoCopy:mem length:imageSize1 freeWhenDone:YES];

		fclose(imagehandle);

		[myNSFileHandle closeFile];
	}

	return myImageData;
}

-(NSData*)rawImage2
{
	FILE* imagehandle;
	NSData* myImageData = nil;
	NSArray* myimageLocatorArray;
	int error;

//	NSLog(@"rawImageAddress2: %010p",imageAddress2);
//	NSLog(@"rawImageSize2: %d",imageSize2);

	myimageLocatorArray = [imageBand imageLocatorArray];

	if (myimageLocatorArray != nil)
	{
		myImageData = [self imageDataFromFolder:@"Small"];
	}
	else
	{
		NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:imageFilename];
		imagehandle = fdopen([myNSFileHandle fileDescriptor],"r");

//		imagehandle = fopen([imageFilename cString],"r");
		if (imagehandle == 0) return nil;

		if (imageAddress2 == 0) return nil;

		error = fseek(imagehandle,imageAddress2,SEEK_SET);
		if (error) return nil;

		char* mem = malloc(imageSize2);
		int menge = fread(mem,1,imageSize2,imagehandle);
		if (menge != imageSize2) return nil;

		myImageData = [NSData dataWithBytesNoCopy:mem length:imageSize2 freeWhenDone:YES];

		fclose(imagehandle);

		[myNSFileHandle closeFile];
	}

	return myImageData;
}

-(NSData*)rawImage3
{
	FILE* imagehandle;
	NSData* myImageData = nil;
	NSArray* myimageLocatorArray;
	int error;

//	NSLog(@"rawImageAddress3: %010p",imageAddress3);
//	NSLog(@"rawImageSize3: %d",imageSize3);

	myimageLocatorArray = [imageBand imageLocatorArray];

	if (myimageLocatorArray != nil)
	{
		myImageData = [self imageDataFromFolder:@"Huge"];
	}
	else
	{
		NSFileHandle* myNSFileHandle = [NSFileHandle fileHandleForReadingAtPath:imageFilename];
		imagehandle = fdopen([myNSFileHandle fileDescriptor],"r");

//		imagehandle = fopen([imageFilename cString],"r");
		if (imagehandle == 0) return nil;

		if (imageAddress3 == 0) return nil;

		error = fseek(imagehandle,imageAddress3,SEEK_SET);
		if (error) return nil;

		char* mem = malloc(imageSize3);
		int menge = fread(mem,1,imageSize3,imagehandle);
		if (menge != imageSize3) return nil;

		myImageData = [NSData dataWithBytesNoCopy:mem length:imageSize3 freeWhenDone:YES];

		fclose(imagehandle);

		[myNSFileHandle closeFile];
	}

	return myImageData;
}

-(NSComparisonResult)comparator:(DBImageSet*)_imageSet
{
	int a = [self pageNumber];
	int b = [_imageSet pageNumber];

	if (a < b)
		return NSOrderedAscending;
	else if (a > b)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}

-(NSString*)getImagePfad:(NSString*)_foldername
{
	NSArray* myimageLocatorArray;
	myimageLocatorArray = [imageBand imageLocatorArray];
	int i;
	int imageNumber;
	
	NSCharacterSet* characterSet;

	characterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];

//	NSLog(@"imagename: %@",imageName);

	if ([imageBand majorNumber] == -15) {   // Liebig
		imageNumber = [[imageName substringWithRange:NSMakeRange(1,4)] intValue];
	}
	else {
		imageNumber = [[imageName stringByTrimmingCharactersInSet:characterSet] intValue];
	}
//	NSLog(@"imageNumber       : %d",imageNumber);

	for (i = 0 ; i < [myimageLocatorArray count] ; i++)
	{
//		NSLog(@"imagelocator index: %d",[[myimageLocatorArray objectAtIndex:i] intValue]);

		if (imageNumber < [[myimageLocatorArray objectAtIndex:i+1] intValue])
		{
			break;
		}
	}

	NSString* meisterPfad = [imageBand masterPath];

	NSString* pfad = [NSString stringWithFormat:@"/Images/%@/%02d/%@.jpg",_foldername, i, imageName];

//	NSLog(@"Pfad: %@",pfad);

	NSString* newpfad = [Helper findFile:pfad startPath:meisterPfad];

	return newpfad;
}

-(NSImage*)imageFromFolder:(NSString*)_foldername
{
	NSImage* myImage;

	NSString* newpfad = [self getImagePfad:_foldername];

	myImage = [[NSImage alloc] initWithContentsOfFile:newpfad];

	if (myImage == nil)
		NSLog(@"Error beim Image direkt laden (%@)",imageName);

	return [myImage autorelease];
}

-(NSData*)imageDataFromFolder:(NSString*)_foldername
{
	NSData* myImageData;

	NSString* newpfad = [self getImagePfad:_foldername];

	myImageData = [NSData dataWithContentsOfFile:newpfad];

	if (myImageData == nil)
		NSLog(@"Error beim ImageData direkt laden (%@)",imageName);

	return myImageData;
}

@end
