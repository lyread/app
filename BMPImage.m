/*
 * BMPImage.m -- 
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

#import "BMPImage.h"

@implementation BMPImage

-(id) initWithData:(NSData *)bilddaten
{
	unsigned char* bildanfang;
	unsigned long* tmplong;
	unsigned short* tmpshort;

	self = [super init];

	if (self)
	{
		if (strncmp([bilddaten bytes],"BM",2) != 0)
			return nil;

		bildanfang = (unsigned char*)[bilddaten bytes];

		tmplong = (unsigned long*)&bildanfang[2];
		int groesse = NSSwapLittleLongToHost(*tmplong);

		tmplong = (unsigned long*)&bildanfang[10];
		int pixelanfang = NSSwapLittleLongToHost(*tmplong);

		tmplong = (unsigned long*)&bildanfang[18];
		int breite = NSSwapLittleLongToHost(*tmplong);

		tmplong = (unsigned long*)&bildanfang[22];
		int hoehe = NSSwapLittleLongToHost(*tmplong);

		tmpshort = (unsigned short*)&bildanfang[28];
		int farbbits = NSSwapLittleShortToHost(*tmpshort);

		tmplong = (unsigned long*)&bildanfang[30];
		int compression = NSSwapLittleLongToHost(*tmplong);

		//NSLog(@"pixelanfang: %d",pixelanfang);
		//NSLog(@"groesse: %d",groesse);
		//NSLog(@"breite: %d",breite);
		//NSLog(@"hoehe: %d",hoehe);
		//NSLog(@"farbbits: %d",farbbits);
		//NSLog(@"compression: %x",compression);

		if (compression != 0)
		{
			NSLog(@"bmp with compression is not supported!");
			return nil;
		}

		NSImage* destImage;
		NSBitmapImageRep* destImageRep;

		long dst_rowbytes = breite * 4;
		dst_rowbytes += 3;
		dst_rowbytes /= 4;
		dst_rowbytes *= 4;

		long src_rowbytes = breite * farbbits / 8;
		src_rowbytes += 3;
		src_rowbytes /= 4;
		src_rowbytes *= 4;

		//NSLog(@"src_rowbytes: %d",src_rowbytes);
		//NSLog(@"dst_rowbytes: %d",dst_rowbytes);

		destImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:(void *)nil
							pixelsWide:breite
															   pixelsHigh:hoehe
															bitsPerSample:8
														  samplesPerPixel:4
																 hasAlpha:YES
																 isPlanar:NO
														   colorSpaceName:NSDeviceRGBColorSpace
															  bytesPerRow:dst_rowbytes
															 bitsPerPixel:32];

		if (destImageRep == nil)
			return nil;

		unsigned char* image = [destImageRep bitmapData];

		int i,n,count=0;
		int blub = 0;
		int zeile;

		for (n=0;n<hoehe;n++)
		{
			unsigned char tempvalue;

			int offset = 0;

			for (i = 0 ; i <breite ; i++)
			{
				zeile = (hoehe - n -1) * src_rowbytes;

				if (farbbits==32)
				{
					image[blub++] = bildanfang[(pixelanfang+zeile)+offset+2];
					image[blub++] = bildanfang[(pixelanfang+zeile)+offset+1];
					image[blub++] = bildanfang[(pixelanfang+zeile)+offset+0];
					image[blub++] = 255;	// Kommt eigentlich aus der Datei 
					offset+=4;
				}
				else if (farbbits==24)
				{
					image[blub++] = bildanfang[(pixelanfang+zeile)+offset+2];
					image[blub++] = bildanfang[(pixelanfang+zeile)+offset+1];
					image[blub++] = bildanfang[(pixelanfang+zeile)+offset+0];
					image[blub++] = 255;
					offset+=3;
				}
				else if (farbbits==16)
				{
					unsigned char red,green,blue;

					unsigned short myshort = bildanfang[pixelanfang+zeile+offset+1] << 8;
					myshort += bildanfang[pixelanfang+zeile+offset];

					red = (myshort >> 10) & 63;
					green = (myshort >> 5) & 63;
					blue = myshort & 63;

					image[blub++] = red << 3;
					image[blub++] = green << 3;
					image[blub++] = blue << 3;
					image[blub++] = 255;
					offset+=2;
				}
				else if (farbbits==8)
				{
					tempvalue = bildanfang[(pixelanfang+zeile)+offset];

					image[blub++] = bildanfang[56+(tempvalue*4)];
					image[blub++] = bildanfang[55+(tempvalue*4)];
					image[blub++] = bildanfang[54+(tempvalue*4)];
					image[blub++] = 255;
					offset++;
				}
				else if (farbbits==4)
				{
					tempvalue = bildanfang[(pixelanfang+zeile)+(offset>>1)];

					if (offset%2)
						tempvalue &= 0xf;
					else
						tempvalue >>= 4;

					image[blub++] = bildanfang[56+(tempvalue*4)];
					image[blub++] = bildanfang[55+(tempvalue*4)];
					image[blub++] = bildanfang[54+(tempvalue*4)];
					image[blub++] = 255;
					offset++;
				}
				else if (farbbits==1)
				{
					tempvalue = bildanfang[(pixelanfang+zeile)+(offset>>3)];

					int rest = offset % 8;

					switch (rest)
					{
						case 0:
							tempvalue >>= 0;
							break;
						case 1:
							tempvalue >>= 1;
							break;
						case 2:
							tempvalue >>= 2;
							break;
						case 3:
							tempvalue >>= 3;
							break;
						case 4:
							tempvalue >>= 4;
							break;
						case 5:
							tempvalue >>= 5;
							break;
						case 6:
							tempvalue >>= 6;
							break;
						case 7:
							tempvalue >>= 7;
							break;
						default:
							break;
					}

					tempvalue &= 1;
					image[blub++] = bildanfang[56+(tempvalue*4)];
					image[blub++] = bildanfang[55+(tempvalue*4)];
					image[blub++] = bildanfang[54+(tempvalue*4)];
					image[blub++] = 255;
					offset++;
				}
			}
			blub += (dst_rowbytes-(breite*4));
		}

		[self initWithSize:NSMakeSize(breite,hoehe)];
		[self addRepresentation:destImageRep];
		[destImageRep release];

		return self;
	}
}
@end
