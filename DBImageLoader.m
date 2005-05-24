/*
 * DBImageLoader.m -- 
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

#import "DBImageLoader.h"

@implementation DBImageLoader

+(int)loadImageTable:(id)_sender
{
	char *filenames[]={"IMAGES/IMAGES.LIB","IMAGES/WM01.LIB","IMAGES/WM02.LIB","IMAGES/WM03.LIB","IMAGES/WM04.LIB","IMAGES/WM05.LIB","IMAGES/WM06.LIB","IMAGES/WM07.LIB","IMAGES/WM08.LIB","IMAGES/WM09.LIB","IMAGES/WM10.LIB","IMAGES/WM11.LIB","IMAGES/WM12.LIB","IMAGES/WM13.LIB","IMAGES/WM14.LIB","IMAGES/WM15.LIB","IMAGES/WM15.LIB","IMAGES/WM16.LIB","IMAGES/WM17.LIB","IMAGES/WM18.LIB","IMAGES/WM19.LIB","IMAGES/WM20.LIB"};

	FILE* imagehandle = 0;
	FILE* imagetexthandle;

	NSString* filename;
	NSString* ImageLib_path;
	NSString *imageFilename;
	NSMutableArray* imageArray;
	NSMutableDictionary* imageDict;

	unsigned long tmp_long;
	unsigned short tmp_word;
	unsigned char tmp_char;
	int imagenumber;

	BOOL imageMagic;
	int totalImages = 0;

	totalImages = 0;
	imagehandle = 0;
	int filenum = 0;

	imageDict = [[NSMutableDictionary alloc] init];
	imageArray = [[NSMutableArray alloc] init];

	do
	{
		NSLog(@"initializing imageTable %d",filenum);

		filename = [NSString stringWithCString:filenames[filenum]];
		ImageLib_path = [Helper findFile:filename startPath:[_sender masterPath]];

		NSFileHandle* myNSFileHandle1 = [NSFileHandle fileHandleForReadingAtPath:ImageLib_path];
		NSLog(@"Imagelib filename: %@",ImageLib_path);

		if (myNSFileHandle1 != nil)
			imagehandle = fdopen([myNSFileHandle1 fileDescriptor],"r");

		//	imagehandle = fopen([ImageLib_path cString],"r");
		if (imagehandle == 0)
		{
			NSLog (@"Keine Images! (%@)",ImageLib_path);
			return 0;
		}

		char* bla = malloc(3000000);			// Diskcache Beschleuniger!
		fread(bla,1,3000000,imagehandle);
		free(bla);
		fseek(imagehandle,0,SEEK_SET);

		NSFileHandle* myNSFileHandle2 = [NSFileHandle fileHandleForReadingAtPath:ImageLib_path];
		imagetexthandle = fdopen([myNSFileHandle2 fileDescriptor],"r");

		if (imagetexthandle == 0)
		{
			NSLog (@"Keine ImageTexte! (%@)",ImageLib_path);
			return 0;
		}

		if (![Helper isMagic:imagehandle])
		{
			imageMagic = NO;
			fseek(imagehandle,0,SEEK_SET);
		}
		else
		{
			imageMagic = YES;
			if (fread(&tmp_long,1,4,imagehandle) != 4)
			{
				NSLog(@"Image-text-2");
				return 1;
			}
			//		NSLog (@"Image Versionnumber: %d",NSSwapLittleLongToHost(tmp_long));
		}

		//  Anzahl der Bilder einlesen:

		if (fread(&tmp_long,1,4,imagehandle) != 4)
		{
			NSLog(@"Image-text-3");
			return 1;
		}

		imagenumber = NSSwapLittleLongToHost(tmp_long);

		if (imagenumber >= 200000)  // XXX warum maximal 200k Bilder ?
		{
			NSLog(@"Zuviele Bilder! (%d)",imagenumber);
			imagenumber = 0;
			return 1;
		}

		NSLog (@"Number of images: %d",imagenumber);

		if (fread(&tmp_long,1,4,imagehandle) != 4)
		{
			NSLog(@"Image-text-4");
			return 1;
		}

		int textstart = NSSwapLittleLongToHost(tmp_long);
//		NSLog (@"Image textstart: %010p",textstart);

		fseek(imagehandle,16,SEEK_CUR);

//		hiddenImageArray = [[NSMutableArray alloc] initWithCapacity:imagenumber];

		totalImages = imagenumber;

		while (imagenumber > 0)
		{
			imageFilename = [self readImageFilename:imagehandle];

			if (!imageFilename) // kein Name also ist was schief gelaufen !!
			{
				NSLog(@"Error reading Imagefilename!");
				break;
			}

//			NSLog (@"number: %d  string: %@",imagenumber,imageFilename);

			DBImageSet* myImageSet = [[DBImageSet alloc] initWithName:imageFilename];

			[myImageSet setImageBand:_sender];
			[myImageSet setImageFilename:ImageLib_path];

			if ([imageDict objectForKey:[imageFilename lowercaseString]] != nil) {
				NSBeep();
				NSLog(@"imagename occured twice (%@)",[imageFilename lowercaseString]);
			}
			[imageDict setObject:myImageSet forKey:[imageFilename lowercaseString]];

			if ( fread(&tmp_char,1,1,imagehandle) != 1)
			{
				NSLog(@"Image-hidden-read failed");
				return 1;
			}
			else
			{
				[myImageSet setHidden:tmp_char==0?NO:YES];
				if (tmp_char == 0)
					[imageArray addObject:myImageSet];
			}

			if (fread(&tmp_long,1,4,imagehandle) != 4)
			{
				NSLog(@"Image-text-1");
				return 1;
			}

			int textseite = NSSwapLittleLongToHost(tmp_long)>>4;
			[myImageSet setPageNumber:textseite];
			
//		NSLog (@"Bild ist auf Seite: %d",textseite);
// ------------ neu Description setzen ----------------------------------
			[myImageSet setImageDescription1:[self readImageDescription:imagehandle textFileHandle:imagetexthandle textStartOffset:textstart]];
			[myImageSet setImageDescription2:[self readImageDescription:imagehandle textFileHandle:imagetexthandle textStartOffset:textstart]];

//			NSLog(@"name  : %@",[myImageSet imageName]);
//			NSLog(@"desc 1: %@",[myImageSet imageDescription1]);
//			NSLog(@"desc 2: %@",[myImageSet imageDescription2]);

// ----------------------------------------------------------------------
			int i;
			
			int weite,hoehe;
			int adresse;
			int imagesize;
			int imageType;
			
			for (i = 1 ; i<=5 ; i++)
			{
// ---------------------------- hoehe, weite, addresse, imagesize, imagetype
// Structure
/*
	struct imgStructure = {
		unsigned short weite,
		unsigned short hoehe,
		unsigned long addresse,
		unsigned long bytecount,
		unsigned char type};
*/
// ----------

				if (fread(&tmp_word,1,2,imagehandle) != 2)
				{
					NSLog(@"Image-text-8");
					return 1;
				}
				weite = NSSwapLittleShortToHost(tmp_word);
//				NSLog(@"weite: %d",weite);

				if (fread(&tmp_word,1,2,imagehandle) != 2)
				{
					NSLog(@"Image-text-9");
					return 1;
				}
				hoehe = NSSwapLittleShortToHost(tmp_word);

				if (fread(&tmp_long,1,4,imagehandle) != 4)
				{
					NSLog(@"Image-text-10");
					return 1;
				}
				adresse = NSSwapLittleLongToHost(tmp_long);

				if (fread(&tmp_long,1,4,imagehandle) != 4)
				{
					NSLog(@"Image-text-11");
					return 1;
				}
				imagesize = NSSwapLittleLongToHost(tmp_long);

				if (fread(&tmp_char,1,1,imagehandle) != 1)
				{
					NSLog(@"Image-text-12");
					return 1;
				}
				imageType = tmp_char;

// ------------------------------------------------------------------------------
// ---------- N E U
/*
if (fread(imgstruct,13,1) != 1)
{
	NSLog(@"Fehler beim lesen der Image Details");
	return 1;
}
*/
// -------------------------------------------------------------------------------
//			NSLog(@"Type: %d",imageType);

				if (weite && hoehe)
				{
					switch (i)
					{
						case 1:
							[myImageSet setImageAddress1:adresse];
							[myImageSet setImageSize1:imagesize];
							[myImageSet setImageType1:imageType];
	//						NSLog(@"Type1: %d",imageType);
							break;
						case 2:
							[myImageSet setImageAddress2:adresse];
							[myImageSet setImageSize2:imagesize];
							[myImageSet setImageType2:imageType];
	//						NSLog(@"Type2: %d",imageType);
							break;
						case 3:
							[myImageSet setImageAddress3:adresse];
							[myImageSet setImageSize3:imagesize];
							[myImageSet setImageType3:imageType];
	//						NSLog(@"Type3: %d",imageType);
							break;
						default:
							NSLog(@"Mehr als drei Bilder!");
							break;
					}
					
//				NSLog (@"%d. weite: %d hoehe: %d",i,weite,hoehe);
//				NSLog (@"%d. adresse: %010p",i,adresse);
//				NSLog (@"%d. imagesize: %d",i,imagesize);
//				NSLog (@"%d. imagetyp: %d",i,imageType);
				}
			}

			[myImageSet release];

			imagenumber--;
		}
		fclose(imagetexthandle);
		fclose(imagehandle);

		[myNSFileHandle1 closeFile];
		[myNSFileHandle2 closeFile];

		filenum++;
	}
	while ([_sender majorNumber] == 100 & filenum < 22);

	[imageArray sortUsingSelector:@selector(comparator:)];
//	[hiddenImageArray sortUsingSelector:@selector(comparator:)];

	NSLog(@"normal Images: %d",[imageArray count]);
	NSLog(@"hidden Images: %d",[imageDict count] - [imageArray count]);
	NSLog(@"Total Images: %d",[imageDict count]);

	if (totalImages > 0)
	{
		[_sender setImageArray:imageArray];
		[_sender setImageDict:imageDict];
	}

	[imageArray release];
	[imageDict release];

	return 0;
}

+(NSString *)readImageFilename:(FILE *)_f
{
	unsigned char namelen,*mem;
	NSString *imageFilename;

	if (fread(&namelen,1,1,_f) != 1)
	{
		NSLog(@"Image-text-5");
		return nil;
	}

	if (!(mem=malloc(9)))
	{
		NSLog(@"No Memory left, exiting!");
		return nil;
	}

	if (8 != fread(mem,1,8,_f))
	{
		NSLog(@"Image-text-5a");
		return nil;
	}
	mem[namelen]=0;

	NSData* myImageNameData = [NSData dataWithBytesNoCopy:mem length:namelen freeWhenDone:YES];
	if (!myImageNameData)
	{
		NSLog(@"No Memory left for NSData, exiting!");
		return nil;
	}

	imageFilename = [[NSString alloc] initWithData: myImageNameData encoding:NSWindowsCP1252StringEncoding];

	return [imageFilename autorelease];
}

+(NSString *)readImageDescription:(FILE *)_f textFileHandle:(FILE *)_ftext textStartOffset:(int)_textStart
{
	unsigned long tmp_long;
	NSString *imageDescription;
	NSString *rv = nil;

	if (fread(&tmp_long,1,4,_f) != 4)
	{
		NSLog(@"Image-text-3");
		return nil;
	}

	int textdesc1 = NSSwapLittleLongToHost(tmp_long);

	if (fread(&tmp_long,1,4,_f) != 4)
	{
		NSLog(@"Image-text-4");
		return nil;
	}

	int textdesclength1 = NSSwapLittleLongToHost(tmp_long);

	if (textdesclength1 > 0)
	{
		fseek(_ftext,_textStart+textdesc1,SEEK_SET);
		char *mem = malloc(textdesclength1);

		if (fread(mem,1,textdesclength1,_ftext) != textdesclength1)
		{
			NSLog(@"Image-text-5");
			return nil;				
		}

		NSData* myImageTextData = [NSData dataWithBytesNoCopy:mem length:textdesclength1 freeWhenDone:YES];
		imageDescription = [[NSString alloc] initWithData: myImageTextData encoding:NSWindowsCP1252StringEncoding];
		rv = [imageDescription autorelease];
	}

	return rv;
}

@end
