/*
 * DBPage.h -- 
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

#import "DBPage.h"

#include <sys/types.h>
#include <regex.h>

#import "Band.h"
#import "Entry.h"

int isTrenner(unsigned char *_word,BOOL *unicode);
unichar makeunichar(unsigned char *_string);

NSMutableCharacterSet *trennerCharacterSet;
//NSCharacterSet *stripCharacterSet;
//NSCharacterSet *nonAlphaNumericCharacterSet;
//NSCharacterSet *ignoreCharacterSet;

NSDictionary *unicodedict;

NSFontManager *my_font_manager;
NSString* alotOfSpaces;
NSString* vladoTestString;

static float linespacing;

@implementation DBPage

-(id)initWithData:(NSData*)_data band:(id)_band textpagenumber:(long)_textpagenumber atomCount:(long)_atomCount wordCount:(long)_wordCount hexaddress:(long)_hexaddress;
{
	self = [super init];

	band = _band;
	showMarkierungen = YES;
        hasVorWort=NO;

	searchPosition = -1;

	nodenumber = 0;
	pageSigel = nil;

	fontSize = -1;

	enforceRedisplay = YES;

// Font raussuchen
	NSArray *fontnames = [NSArray arrayWithObjects:@"FreeSerif",@"Luxi Serif",@"Helvetica",@"FreeSans",@"Adobe Times",@"Times",@"Lucida",nil];

	NSFont *test_font;	
	NSEnumerator *font_enu = [fontnames objectEnumerator];
	NSString *testfontname;
	while (testfontname = [font_enu nextObject]) {
		test_font = [NSFont fontWithName:testfontname size:5];
		if (test_font) {
			fontName = [testfontname retain];
			//NSLog (@"Using Font : %@",testfontname);
			break;
		}
	}
	if (![test_font isMemberOfClass:[NSFont class]]) {	
		NSLog(@"Kein passender Font gefunden, bitte installieren sie einen der folgenden Fonts : %@",fontnames);
		
		exit(1);
	}
		
		
//fontName = @"Adobe Times";
//fontName = @"B&H Lucida";        // Wenn XFt backend
//fontName = @"FreeSans";
//fontName = @"FreeSerif";            // Bei libart backend (favorite)
//fontName = @"Lucida";            // Bei X backend
//fontName = @"Luxi Serif";            // Bei denis X backend
//fontName = @"Times";            // Bei denis X backend
////fontName = @"Helvetica";	// geht gerade nix anderes mehr 10.3.2005 (die bei GS haben ihre Fonts jetzt nach GNUSTEP_ROOT/System/Libray/Fonts verlagert frueher waren die bei GNUSTEP_ROOT/Local/Library/Fonts

	atomCount = _atomCount;
	wordCount = _wordCount;
	textpagenumber = _textpagenumber;
	pageBlock = [_data retain];
	pageBlocklength = [pageBlock length];
	hexaddress = _hexaddress;
	myCharacterSet = [NSCharacterSet whitespaceCharacterSet];
	newWordList = [[NSMutableArray alloc] initWithCapacity:100];

	return self;
}

-(void)dealloc
{
	[pageString release];
	[pageBlock release];
	[pageSigel release];
	[newWordList release];

	[super dealloc];
}

-(NSArray*)getArrayWithParents
{
	NSArray* myTreeArray = [band treeArray];
	NSMutableArray* myArray = [NSMutableArray arrayWithCapacity:10];

	Entry* nextEntry = [myTreeArray objectAtIndex:nodenumber];

	if ([nextEntry parent] != [myTreeArray objectAtIndex:nodenumber])
	{
		while (nextEntry != nil)
		{
			[myArray insertObject:nextEntry atIndex:0];
			nextEntry = [nextEntry parent];
		}
	}

	return myArray;
}

-(long)textpagenumber
{
	return textpagenumber;
}

-(id)band
{
	return band;
}

-(NSData*)pageblock
{
	return pageBlock;
}

-(long)atomCount
{
	return atomCount;
}

-(long)wordCount
{
	return wordCount;
}

-(long)konkordanznumber
{
	return konkordanznumber;
}

-(NSString*) textpagenumberAsString
{
	return [NSString stringWithFormat:@"%d",textpagenumber];
}

-(long)nodenumber
{
	return nodenumber;
}

-(long)hexaddress
{
	return hexaddress;
}

-(NSString*)titleFromTree
{
	NSArray* treeArray = [band treeArray];
	Entry* entry = [treeArray objectAtIndex:nodenumber];

	return [entry name];
}

-(NSString*)pageSigel
{
//	NSLog (@"Sigel: %@",pageSigel);
	return pageSigel;
}

-(NSMutableAttributedString*)getPageWithFontSize:(float)_fontSize suche:(BOOL)_sucheaktiv
{
//	NSLog(@"getPageWithFontSize: %0.f",_fontSize);

	if (fontSize != _fontSize)
	{
		fontSize = _fontSize;
		pageString = [self parsePageWithFontSize:fontSize suche:_sucheaktiv];
	}

	return pageString;
}

-(NSMutableAttributedString *)parsePageWithFontSize:(float)_fontsize suche:(BOOL)_sucheaktiv
{
	unsigned char* data;
	BOOL page_end = NO;
	NSData* temp_data;

	NSFont *bold_font,*italic_font,*bolditalic_font,*my_font;

	NSString* temp_string = nil;
	NSString* word = nil;

	NSFont *font;

	NSMutableString* temp2_string = nil;

	NSMutableAttributedString* backString;
	NSMutableAttributedString* ast;

	NSAttributedString* imageString;
	NSMutableAttributedString* returnString;
	NSMutableAttributedString* spaceString;

	NSRange myRange;

	NSString* atURL;
	NSURL* tempURL;
	DBImageSet* tempImageSet = nil;

	NSString* atlink = nil;
	
	int bold,italic,fontname,color,superscript,subscript;
	int autolink = 0,link2 = 0;

	int oldtoken = -9999;
	
	float fontsize = _fontsize;
	//float fontsize = 18.0;
	float newfontsize = 0;
	int num_tokens = 0;
	int i = 0;
	int len = 0;
	int _len = 0;
	int x = 0;
	int value;
	int linkrangebegin = 0;
	int urllinkrangebegin = 0;
	int hyphen = 0;
	int hyphen2 = 0;
	int hyphenck = 0;
	int atFont = 0;
	int atFarbe = 0;
	int word_start_pos = -1;
	int atVorWord=0;

	int positionAfterLastReturn = 0;

	atURL = nil;

	BOOL unicode = NO;
//	BOOL wordhasminussuffix=NO;

	bold=italic=fontname=color=superscript=subscript=0;

	int underline = -1;
	int zentriert = -1;

	NSMutableArray* zentriertArray = [[NSMutableArray alloc] init];

	data = (unsigned char *)[pageBlock bytes];

	backString = [[NSMutableAttributedString alloc] init];
	//NSLog(@"Fontsize: %f sucheaktiv: %d",fontsize,_sucheaktiv);
	if (_sucheaktiv) { ///GS
		fontsize=10.0;
	}
	my_font = [NSFont fontWithName:fontName size:fontsize];
	if (!my_font) NSLog(@"No font found %s:%d",__FILE__,__LINE__);
	bold_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask];
	if (!bold_font) NSLog(@"No font found %s:%d",__FILE__,__LINE__);
	bolditalic_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask|NSItalicFontMask];
	if (!bolditalic_font) NSLog(@"No font found %s:%d",__FILE__,__LINE__);
	italic_font = [my_font_manager convertFont:my_font toHaveTrait:NSItalicFontMask];
	if (!italic_font) NSLog(@"No font found %s:%d",__FILE__,__LINE__);

	NSString* zeichen = [NSString stringWithFormat:@"%C",NSAttachmentCharacter];
	imageString = [[[NSAttributedString alloc] initWithString:zeichen] autorelease];

	returnString = [[[NSMutableAttributedString alloc] initWithString:@"\n"] autorelease];
	[returnString addAttribute:NSFontAttributeName value:my_font range:NSMakeRange(0,1)];
	spaceString = [[[NSMutableAttributedString alloc] initWithString:@" "] autorelease];
	[spaceString addAttribute:NSFontAttributeName value:my_font range:NSMakeRange(0,1)];

	[backString appendAttributedString: returnString];  // erstmal ne leerzeile am anfang!
	[newWordList removeAllObjects];

	while (!page_end)
	{
		len = 0;
		num_tokens++;

		if (num_tokens >= 20000)
		{
			NSLog(@"mehr als 20000 token, wir brechen ab!");
			break;
		}

//		NSLog(@"token %d",data[i]);

		switch (data[i++])
		{
			case 0:		//	atBlanks
			{
				int numberOfSpaces = data[i++];
//				NSLog (@"atBlanks: %d",numberOfSpaces);
				NSString* tmpstring = [alotOfSpaces substringToIndex:numberOfSpaces];
				NSMutableAttributedString* temp = [[NSMutableAttributedString alloc] initWithString:tmpstring];
				[temp addAttribute:NSFontAttributeName value:my_font range:NSMakeRange(0,numberOfSpaces)];
				[backString appendAttributedString:temp];
				[temp release];
				break;
			}
			case 1:		//	atWord
			{
				len = data[i++];
				_len = (len & ~(0x80));				// _len wortlaenge

				if (_len == 1 && atFont != 0)
				{
					temp2_string = [[NSMutableString alloc] init];

					if (atFont == 1)
					{
						switch (data[i])
						{
							case 38:
//								[temp2_string appendString:[NSString stringWithUTF8String:""]];
								[temp2_string appendString:[NSString stringWithUTF8String:"▤"]];
								break;
							case 51:
								[temp2_string appendString:[NSString stringWithUTF8String:""]];
								break;
							case 65:
								[temp2_string appendString:[NSString stringWithUTF8String:"✌"]];		// 0x270C
								break;
							case 70:
								[temp2_string appendString:[NSString stringWithUTF8String:"☞"]];	// 0x261E
								break;
							case 164:
								[temp2_string appendString:[NSString stringWithUTF8String:"☉"]];	// 0x2609
								break;
							case 182:
								[temp2_string appendString:[NSString stringWithUTF8String:"✰"]];	// 0x2730
								break;
							case 240:
								[temp2_string appendString:[NSString stringWithUTF8String:"➝"]];	// 0x279D
								break;

							default:
								[temp2_string appendString:[NSString stringWithFormat:@"-%d-",data[i]]];
								NSLog(@"Font: %d  Char: %d",atFont,data[i]);
						}
					}
					else if (atFont == 2) 
					{
						switch (data[i])
						{
							case 45:
								[temp2_string appendString:[NSString stringWithUTF8String:"­"]]; // Zeichen ist unsichtbar
								break;
							case 200:
								[temp2_string appendString:[NSString stringWithUTF8String:"∪"]];
								break;
								
							default:
								[temp2_string appendString:[NSString stringWithFormat:@"-%d-",data[i]]];
								NSLog(@"Font: %d  Char: %d",atFont,data[i]);
						}
					}
					else
					{
						[temp2_string appendString:[NSString stringWithFormat:@"-%d-",data[i]]];
						NSLog(@"Font: %d  Char: %d",atFont,data[i]);
					}
				}
				else
				{
					unicode = NO;
					for (x = i ; x < i+_len-1;x++)
					{
						if (data[x] < 0x20)   // Es ist mindestens dezimal 20 (das ist bewiesen!)
						{
							unicode = YES;
							break;
						}
					}

					if (unicode == YES)
					{
						temp2_string = [[NSMutableString alloc] init];

						for (x = i ; x < i+_len;x++)
						{
							if (data[x] < 0x20)
							{
								unichar unizeichen;
//								NSLog(@"unicode: %02x:%02x",data[x],data[x+1]);
								unizeichen = data[x+1] - (data[x] + 1);
								unizeichen += 256 * (data[x] - 1);

//								NSLog(@"unicode: %04X",unizeichen);

								if (unizeichen >= 0x0700 && unizeichen < 0x1100)
									unizeichen += 0x1700;

								else if (unizeichen >= 0x1100 && unizeichen < 0x1200)
									unizeichen += (0xe000 - 0x1100);

								if (unizeichen >= 0x1200 && unizeichen < 0x1e00)
									NSLog(@"unicode: %04X",unizeichen);
								temp_string = [[NSString alloc] initWithCharacters:&unizeichen length:1];
								x++;
							}
							else
							{
								temp_data = [NSData dataWithBytes:&data[x] length:1];
								temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
							}

							if ([temp_string length] > 0)
								[temp2_string appendString:temp_string];

							[temp_string release];
						}
					}	// end if unicode == yes
					else	// kein unicode enthalten
					{
						temp_data = [NSData dataWithBytes:&data[i] length:_len];
						temp2_string = [[NSMutableString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
					}
				}
				//NSLog(@"atWord: %@",temp2_string);

// ---------------------------------------------------------------------------------------------------
// temp_string2 enthaelt das wort
// Einfuegen des wortes in die WORDLIST
				int backStringLength = [backString length]; // die beiden werden am ende auch
				int tmp2length = [temp2_string length];		// genutzt!

				if (atVorWord) {
					atVorWord=NO;
				}
				else {
					[self generateWordList:&data[i] Length:_len Range:NSMakeRange(backStringLength,tmp2length) Hyphen:hyphen||hyphen2||hyphenck  Font:atFont];
				}
					word = nil;
					word_start_pos = -1;
					hyphen = hyphenck = hyphen2 = 0;
//				ENDE einfuegen in die WORDLIST
// -----------------------------------------------------------------------------------------------------

				if (len > 0x80)	//	heisst blank am ende
				{
					//NSLog (@"atWord with a blank!");
					len = len - 0x80;
					num_tokens++;
					[temp2_string appendString:@" "];
					tmp2length++;
				}
				else {
					//NSLog (@"atWord without a blank!");
				}

				if (tmp2length > 0)
				{
					ast = [[NSMutableAttributedString alloc] initWithString:temp2_string];

					NSRange stringRange = NSMakeRange(0,tmp2length);

					if (superscript)
					{
						[ast addAttribute:NSSuperscriptAttributeName value:[NSNumber numberWithInt:1] range:stringRange];
					}
					else if (subscript)
					{
						[ast addAttribute:NSSuperscriptAttributeName value:[NSNumber numberWithInt:-1] range:stringRange];
					}

					if (bold && italic) font = bolditalic_font;
					else if (bold) font = bold_font;
					else if (italic) font = italic_font;
					else font = my_font;
					//NSLog(@"Font setzen!");
					[ast addAttribute:NSFontAttributeName value:font range:stringRange];
					//NSLog(@"Font setzen fertig!");
					[backString appendAttributedString:ast];

					[ast release];
				}

				[temp2_string release];

				break;
			}

			case 2:		//	atHardCRNew,
				//NSLog (@"atHardCRNew");
				[backString appendAttributedString: returnString];
				positionAfterLastReturn = [backString length];
				break;

			case 3:		//	atEndOfPage,
				//NSLog (@"atEndOfPage");
				page_end = YES;
				break;

			case 4:		//	atKursivAn,
				italic = 1;
				//NSLog (@"atKursivAn");
				break;

			case 5:		//	atKursivAus,
				italic = 0;
				//NSLog (@"atKursivAus");
				break;

			case 6:		//	atFettAn:
				//NSLog (@"atFettAn");
				bold = 1;
				break;

			case 7:		//	atFettAUS:
				//NSLog (@"atFettAUS");
				bold = 0;
				break;

			case 8:		//	atU,
			{
				value = data[i];
				//NSLog (@"atU: %d",value);
				i+=1;
				if (_sucheaktiv == NO)
				{
					newfontsize = 100.0;

					switch (value)
					{
						case 0:
							newfontsize = 100.0;
							bold = 0;
							italic = 0;
							break;
						case 1:
							newfontsize = 134.0;
							break;
						case 2:
							newfontsize = 122.0;
							break;
						case 3:
							newfontsize = 110.0;
							break;
						case 4:
							newfontsize = 100.0;
							bold = 1;
							break;
						case 5:
							newfontsize = 100.0;
							break;
						case 6:
							newfontsize = 100.0;
							italic = 1;
							break;
						default:
							NSLog(@"atU %d is unknown",value);
							break;
					}
					
					my_font = [my_font_manager convertFont:my_font toSize:fontsize*(newfontsize/100.0)];
					if (!my_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);

					bold_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask];
					if (!bold_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);
					bolditalic_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask|NSItalicFontMask];
					if (!bolditalic_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);
					italic_font = [my_font_manager convertFont:my_font toHaveTrait:NSItalicFontMask];
					if (!italic_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);
					
				}
				break;
			}

			case 9:	//	atLy:
			{
				NSLog (@"atLy");
			}

			case 10:	//	atImage:
			{
				int mywidth = (data[i+1]*256) + ((data[i]));
				i+=2;
				i+=2;
				len = data[i++];

				if (_sucheaktiv == NO)
				{
					zentriert = [backString length];		// bilder sind immer zentriert!
					NSLog (@"bild len: %d",len);
					temp_data = [NSData dataWithBytes:&data[i] length:len];
					temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
					NSLog(@"atImage: %@ width=%d",temp_string,mywidth);
						
					NSDictionary* imageDict = [band imageDict];
					DBImageSet* imageSet = [imageDict valueForKey:[[temp_string stringByDeletingPathExtension] lowercaseString]];
					NSImage* image = [imageSet image2];

					NSSize size = [image size];

					int finalwidth = ([band actualpageviewwidth] * mywidth / 1000.0) * 0.85;		// ein wenig runterskalieren!

					int newwidth = finalwidth;

					if (newwidth > size.width)
					{
						image = [imageSet image3];
						size = [image size];
					}

					int oldsize = size.width;

					size.width = finalwidth;
					size.height *= (size.width / oldsize);

					[image setScalesWhenResized:YES];		// scalieren einschalten!
					[image setSize:size];

					NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
					[(NSCell *)[attachment attachmentCell] setImage:image];

					[backString appendAttributedString: imageString];
					[backString addAttribute:NSAttachmentAttributeName value:attachment range:NSMakeRange([backString length]-1,1)];
					[attachment release];
					[temp_string release];

					myRange = NSMakeRange(zentriert,[backString length]-zentriert); // Zentriert ende!
					[zentriertArray addObject:[NSValue valueWithRange:myRange]];
					zentriert = -1;
				}
				else  // suche aktiv
				{
					[backString appendAttributedString: imageString];
				}
				break;
			}

			case 11:	//	atLink:
			{
				len = data[i++];
//				NSLog (@"len: %d",len);
				temp_data = [NSData dataWithBytes:&data[i] length:len];
				atlink = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
				//NSLog(@"atLink: %@",atlink);
				linkrangebegin = [backString length];
				[atlink autorelease];
				break;
			}

			case 12:	//	atELink:
			{
				//NSLog (@"atELink");

				myRange = NSMakeRange(linkrangebegin,[backString length]-linkrangebegin);

				if (link2)
				{
					//NSLog(@"link2: %d",link2);
					[backString addAttribute:NSLinkAttributeName value:[NSNumber numberWithInt:link2] range:myRange];
					[backString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:myRange];
				}
				else if (tempImageSet)
				{
					NSLog(@"imageName: %@",[tempImageSet imageName]);
					[backString addAttribute:NSLinkAttributeName value:tempImageSet range:myRange];
					[backString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:myRange];
				}
				else if (autolink)
				{
					//NSLog(@"autolink: %d",autolink);
					[backString addAttribute:NSLinkAttributeName value:[NSNumber numberWithInt:autolink] range:myRange];
					[backString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:myRange];
				}
				else if (atlink)
				{
					//NSLog(@"atlink: %@",atlink);
					NSString* tmpstring = [atlink stringByDeletingPathExtension];
					id tmpobject = [[band imageDict] objectForKey:tmpstring];

					if (tmpobject)
					{
						[backString addAttribute:NSLinkAttributeName value:tmpobject range:myRange];
						[backString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:myRange];
					}
				}
				
				tempImageSet = nil;
				linkrangebegin = 0;
				link2 = 0;
				autolink = 0;
				atlink = nil;
				break;
			}

			case 13:	//	atFont:
			{
				atFont = data[i];
				//NSLog (@"atFont: %d",atFont);
				i++;
				break;
			}

			case 14:	//	atFileName,
			{
				len = data[i++];
				//NSLog (@"len: %d",len);
				//temp_data = [NSData dataWithBytes:&data[i] length:len];
				//temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
				//NSLog(@"atFileName: %@",temp_string);
				//[temp_string release];
				break;
			}

			case 15:	//	atKonkor,
			{
				konkordanznumber = (data[i+1]*256) + data[i];	
				//NSLog (@"atKonkor: %d",konkordanznumber);
				i+=2;
				break;
			}
			case 16:	//	atNodeNumber
			{
				if (nodenumber == 0)
					nodenumber = ((data[i+1]*256)+data[i]) + 1;
				//NSLog (@"atNodeNumber: %d",nodenumber);
				i+=2;
				break;
			}

			case 17:	//	atHochAn
			{
				//NSLog (@"atHochAn");
				if (_sucheaktiv == NO)
				{
					superscript = 1;
					subscript = 0;

					my_font = [my_font_manager convertFont:my_font toSize:fontsize*0.66];
					bold_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask];
					bolditalic_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask|NSItalicFontMask];
					italic_font = [my_font_manager convertFont:my_font toHaveTrait:NSItalicFontMask];
				}
				break;
			}

			case 18:	//	atHochAus
			{
				//NSLog (@"atHochAus");
				if (_sucheaktiv == NO)
				{
					superscript = 0;

					my_font = [my_font_manager convertFont:my_font toSize:fontsize];
					bold_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask];
					bolditalic_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask|NSItalicFontMask];
					italic_font = [my_font_manager convertFont:my_font toHaveTrait:NSItalicFontMask];
				}
				break;
			}

			case 19:	//	atSigel,
			{
				len = data[i++];
//				//NSLog (@"len: %d",len);
				if (len > 0)
				{
					temp_data = [NSData dataWithBytes:&data[i] length:len];
					if ([temp_data length] > 0)
					{
						[pageSigel release];
						pageSigel = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
					}
				}
				//NSLog(@"atSigel: %@",pageSigel);
				break;
			}

			case 20:	//	atHeader {wird nicht mehr generiert - wurde es jemals?}
				//NSLog (@"atHeader");
				break;

			case 21:	//	atHyphen
				//NSLog (@"atHyphen");
				hyphen = 1;
				break;

			case 22:	//	atGesperrtAn		ACHTUNG: das ist underline !!!
				underline = [backString length];
				//NSLog (@"atGesperrtAn");
				break;

			case 23:	//	atGesperrtAus		ACHTUNG: das ist underline aus !!!
			{
				if (underline >= 0)
				{
					myRange = NSMakeRange(underline,[backString length]-underline);
					[backString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:1] range:myRange];
					
					underline = -1;
				}
				//NSLog (@"atGesperrtAus");
				break;
			}

			case 24:	//	atGriechischAn
				//NSLog (@"atGriechischAn");
				break;

			case 25:	//	atGriechischAus
				//NSLog (@"atGriechischAus");
				break;

			case 27:	//	atOneBlank:
				//NSLog (@"atOneBlank");
				[backString appendAttributedString: spaceString];
				break;

			case 28:	//	atLinieAn,
				//NSLog (@"atLinieAn");
				break;

			case 29:	//	atLinieAus,
				//NSLog (@"atLinieAus");
				break;

			case 30:	//	atTD,
				//NSLog (@"atTD");
				break;

			case 31:	//	atNil,
				//NSLog (@"atNil");
				break;

			case 128:	//	atLink2, {ersetzt atLink}
			{
				link2 = (data[i+2]*256*256)+(data[i+1]*256)+data[i];
				//NSLog(@"atLink2 zur seite: %d",link2);
				i+=4;
				len = data[i++];

				if (_sucheaktiv == NO)
				{
					linkrangebegin = [backString length];

//					//NSLog (@"len: %d",len);

					if (link2 == 0)
					{
						temp_data = [NSData dataWithBytes:&data[i] length:len];
						temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
						//NSLog(@"atLink2: %@",temp_string);
						tempImageSet = [[band imageDict] objectForKey:[[temp_string stringByDeletingPathExtension] lowercaseString]];
						[temp_string release];
					}
				}
				break;
			}
			case 129:	//	atID
				i++;
				//NSLog(@"atID");
				break;

			case 130:	//	atEID
				i++;
				//NSLog(@"atEID");
				break;

			case 131:	//	atTiefAn
			{
				//NSLog (@"atTiefAn");
				if (_sucheaktiv == NO)
				{
					subscript = 1;
					superscript = 0;
					
					my_font = [NSFont fontWithName:fontName size:fontsize*0.66];
					if (!my_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);	
					bold_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask];
					if (!bold_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);	
					bolditalic_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask|NSItalicFontMask];
					if (!bolditalic_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);	
					italic_font = [my_font_manager convertFont:my_font toHaveTrait:NSItalicFontMask];
					if (!italic_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);	
				}
				break;
			}
			case 132:	//	atTiefAus
			{
				//NSLog (@"atTiefAus");
				if (_sucheaktiv == NO)
				{
					subscript = 0;
					
					my_font = [NSFont fontWithName:fontName size:fontsize];
					if (!my_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);	
					bold_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask];
					if (!bold_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);	
					bolditalic_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask|NSItalicFontMask];
					if (!bolditalic_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);	
					italic_font = [my_font_manager convertFont:my_font toHaveTrait:NSItalicFontMask];
					if (!italic_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);	
				}
				break;
			}

			case 133:	//	atFarbe
			{
				atFarbe = data[i];
				i++;

				if (atFarbe)
				{
					//NSLog(@"atFarbe: %d",atFarbe);
				}
				break;
			}

			case 134:	//	atBildFliess
			{
			//	int mywidth = (data[i+1]*256) + data[i];
				i+=2;
			//	int myheight = (data[i+1]*256) + data[i];
				i+=2;
				len = data[i++];

				if (_sucheaktiv == NO)
				{

//					NSLog (@"len: %d",len);
					temp_data = [NSData dataWithBytes:&data[i] length:len];
					temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
					NSLog(@"atBildFliess: %@",temp_string);

					NSDictionary* imageDict = [band imageDict];
					DBImageSet* imageSet = [imageDict valueForKey:[[temp_string stringByDeletingPathExtension] lowercaseString]];
					NSImage* image = [imageSet image2];
					NSSize imagesize = [image size];

					float finalheight = [my_font defaultLineHeightForFont] + [my_font descender];
					int finalwidth = imagesize.width * finalheight / imagesize.height;

					imagesize.height = finalheight;
					imagesize.width = finalwidth;

					[image setScalesWhenResized:YES];		// scalieren einschalten!
					[image setSize:imagesize];

					NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
					[(NSCell *)[attachment attachmentCell] setImage:image];

					[backString appendAttributedString: imageString];
					[backString addAttribute:NSAttachmentAttributeName value:attachment range:NSMakeRange([backString length]-1,1)];
					[attachment release];
					[temp_string release];
				}
				else  // sind im suchmodus
				{
					[backString appendAttributedString: imageString];					
				}
				break;
			}

			case 135:	//	atSuchWord
			{
				len = data[i++];
				temp_data = [NSData dataWithBytes:&data[i] length:len];
				temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
				//NSLog(@"atSuchWord %@",temp_string);
				[self addToWordList:temp_string Range:NSMakeRange(0,0) AllowSplit:NO];
				[temp_string autorelease];
				break;
			}

			case 136:	//	atSG
			{
				//NSLog (@"atSG: %d",data[i]);
				newfontsize = fontsize * (data[i] / 100.0);
				i++;

				if (_sucheaktiv == NO)
				{
					my_font = [NSFont fontWithName:fontName size:newfontsize];
					if (!my_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);
					bold_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask];
					if (!bold_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);
					bolditalic_font = [my_font_manager convertFont:my_font toHaveTrait:NSBoldFontMask|NSItalicFontMask];
					if (!bolditalic_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);
					italic_font = [my_font_manager convertFont:my_font toHaveTrait:NSItalicFontMask];
					if (!italic_font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);
				}
				break;
			}

			case 137:	//	atCopyRight
				//NSLog(@"atCopyRight: %d",data[i]);
				i++;
				break;

			case 138:	//	atAutoLink
				linkrangebegin = [backString length];
				autolink = (data[i+2]*256*256)+(data[i+1]*256)+data[i];
				//NSLog (@"atAutoLink zu seite: %d",autolink);
				i+=4;
				break;

			case 139:	//	atSoftCRNew,
				//NSLog (@"atSoftCRNew");
				[backString appendAttributedString: returnString];
				positionAfterLastReturn = [backString length];
				break;

			case 140:	//	atHyphen2,
				//NSLog (@"atHyphen2");
				hyphen2 = 1;
				break;

			case 141:	//	atNewGesperrt,
				//NSLog (@"atNewGesperrt");
				break;

			case 142:	//	atENewGesperrt,
				//NSLog (@"atENewGesperrt");
				break;

			case 143:	//	atHZA
			{
				//NSLog (@"atHZA");

				if (_sucheaktiv == NO)
				{
					font = [my_font_manager convertFont:my_font toSize:fontSize/2];
					if (!font) NSLog(@"font not found %s:%d",__FILE__,__LINE__);
					
					int start = [backString length];
					
					[backString appendAttributedString: returnString];
					[backString appendAttributedString: spaceString];
					[backString addAttribute:NSFontAttributeName value:font range:NSMakeRange(start,2)];
				}
				break;
			}
			case 144:	//	atLI
				//NSLog (@"atLI");
				break;

			case 145:	//	atELI
				//NSLog (@"atELI");
				break;

			case 146:	//	atUL
				//NSLog (@"atUL");
				break;

			case 147:	//	atEUL
				//NSLog (@"atEUL");
				break;

			case 148:	//	atSetX offset linker rand pixel
			{
				int temp = (data[i+1]*256) + data[i];
				i+=2;
				
				if (temp)
				{
					//NSLog(@"atSetX: %d",temp);

					float xvalue = temp * [band actualpageviewwidth] / 1000.0;
					float spaceweite = [spaceString size].width;
					int zeilenlaenge = [backString length] - positionAfterLastReturn;

					NSRange myRange = NSMakeRange(positionAfterLastReturn,zeilenlaenge);

					float abziehen = [[backString attributedSubstringFromRange:myRange] size].width;
					float fillspace = xvalue - abziehen;

					if (fillspace >= 1)
					{
						int numberOfSpaces = fillspace / spaceweite;

						//NSLog(@"actualpageviewwidth: %d",[band actualpageviewwidth]);
//						NSLog(@"xvalue: %0.1f",xvalue);
//						NSLog(@"postitionAfterLastReturn: %d",positionAfterLastReturn);
//						NSLog(@"backString laenge: %d",[backString length]);
//						NSLog(@"zeilenlaenge: %d",zeilenlaenge);
//						NSLog(@"spaceweite: %0.1f",spaceweite);
//						NSLog(@"zeilenlaenge in pixel: %0.1f",abziehen);
//						NSLog(@"numberofSpaces: %d",numberOfSpaces);

						NSString* tmpstring = [alotOfSpaces substringToIndex:numberOfSpaces];
						NSMutableAttributedString* temp2 = [[NSMutableAttributedString alloc] initWithString:tmpstring];
						[temp2 addAttribute:NSFontAttributeName value:my_font range:NSMakeRange(0,numberOfSpaces)];

						[backString appendAttributedString: temp2];
					}
				//NSLog (@"atSetX");
				}
				break;
			}
			case 149:	//	atSV
				i+=8;
				break;

			case 150:   // atSVStichwort
			{
				len = data[i++];
//				//NSLog (@"len: %d",len);
				temp_data = [NSData dataWithBytes:&data[i] length:len];
				temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
				//NSLog(@"atSVStichwort: %@",temp_string);
				[temp_string release];
				break;
			}
			case 151:   // atKeinSVFF
				break;

			case 152:	//	atZ		(Zentriert)
				//NSLog (@"atZentriert");
				zentriert = [backString length];
				break;

			case 153:	//	atZE	(Zentriert Ende)
			{
				//NSLog (@"atZentriertEnde");

				if (zentriert >= 0)
				{
					myRange = NSMakeRange(zentriert,[backString length]-zentriert);
					[zentriertArray addObject:[NSValue valueWithRange:myRange]];
					zentriert = -1;
				}
				break;
			}
			case 154:	//	atR
				//NSLog (@"atR");
				break;

			case 155:	//	atER
				//NSLog (@"atER");
				break;

			case 156:	//	atE, {wird nicht mehr verwendet!!!}
				//NSLog (@"atE");
				i+=2;
				break;

			case 157:	//	atEE,
				//NSLog (@"atEE");
				break;

			case 158:	//	atBiblioPageNr,
				//NSLog (@"atBiblioPageNr");
				i+=4;
				break;

			case 159:	//	atNotFirstLine,
				//NSLog (@"atNotFirstLine");
				break;

			case 160:	//	atThumbXXX,
				//NSLog (@"atThumbXXX");
				break;

				case 161:	//	atENew,
				//NSLog (@"atENew");
				i+=3;
				break;

			case 162:	//	atURL,
			{
				//NSLog (@"atURL");
				len = data[i++];

				[atURL release];
				atURL = nil;

				urllinkrangebegin = [backString length];

				if (len > 0)
				{
					temp_data = [NSData dataWithBytes:&data[i] length:len];
					if ([temp_data length] > 0)
						atURL = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
				}
				break;
			}
			case 163:	//	atEURL
			{
				//NSLog (@"atEURL");
				//NSLog(@"URL: %@",atURL);
				
				myRange = NSMakeRange(urllinkrangebegin,[backString length]-urllinkrangebegin);

				[backString addAttribute:NSLinkAttributeName value:atURL range:myRange];
				[backString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:myRange];

				linkrangebegin = 0;
				link2 = 0;
				autolink = 0;
				[atURL release];
				atURL = nil;
				
				break;
			}
			case 164:	//	atWortAnker,
				//NSLog(@"atWortAnker");		// Vlado fragen
				break;
				
			case 165:	//	atThumbWWW,
				//NSLog(@"atThumbWWW");
				break;
				
			case 166:	//	atS,
				//NSLog(@"atS");
				break;

			case 167:	//	atKeinBlocksatzAn
				//NSLog (@"atKeinBlocksatzAn");
				break;

			case 168:	//	atKeinBlocksatzAus
				//NSLog (@"atKeinBlocksatzAus");
				break;

			case 169:	//	atNextBlankIsFixed,
				//NSLog(@"atNextBlankIsFixed");
				break;

			case 170:	//	atRestWord
			{
				len = data[i++];
				if (len > 0x80) {	// heisst blank am ende
					len = len - 0x80;
//					num_tokens++;
//					NSLog(@"Achtung, numtokens wurde manuell erhoeht!");
				}
				temp_data = [NSData dataWithBytes:&data[i] length:len];
				temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
				//NSLog(@"atRestWord %@",temp_string);

                                [self generateWordList:&data[i] Length:len Range:NSMakeRange([backString length],len) Hyphen:hyphen||hyphen2||hyphenck  Font:atFont];

//				[self addToWordList:[word stringByAppendingString:temp_string] Range:r AllowSplit:YES];
				
				[temp_string release];
				break;
			}
			case 171:	//	atVorWord
				len = data[i++];
				atVorWord=YES;
                                hasVorWort=YES;
//				temp_data = [NSData dataWithBytes:&data[i] length:len];
//				temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
//				NSLog(@"atVorWord %@",temp_string);
//				[temp_string release];
				break;

			case 172:	//	atHyphenCK
				//NSLog (@"atHyphenCK");
				hyphenck = 1;
				break;

			case 173:	//	atHebrAn
				//NSLog (@"atHebrAn");
				break;

			case 174:	//	atHebrAus
				//NSLog (@"atHebrAus");
				break;

			case 175:	//	atNodeNumber2
				if (nodenumber == 0)
					nodenumber = ((data[i+2]*256*256)+(data[i+1]*256)+data[i]) + 1;
				//NSLog (@"atNodeNumber2: %d",nodenumber);
				i+=4;
				break;

			case 176:	//	atDurchAn
				//NSLog (@"atDurchAn");
				break;
				
			case 177:	//	atDurchAus
				//NSLog (@"atDurchAus");
				break;
				
			case 178:	//	atSetY
				i+=2;
				//NSLog (@"atSetY");
				break;

			case 179:	//	atCor
				//NSLog (@"atCor");
				break;

			case 180:	//	atECor
				//NSLog (@"atECor");
				break;
				
			default:	// keinen passenden Tag gefunden!
				NSLog(@"pagenumber: %d  num_tokens: %d  pos: %d  Unknown token: %d",textpagenumber,num_tokens,i,data[i-1]);
				NSLog(@"token before: %d",oldtoken);
				page_end = YES;
				break;
		}

		oldtoken = data[i-1];

		i += len;
		if (i >= pageBlocklength)
		{
			//NSLog(@"pageblock ende: %d",i);
			page_end = YES;
		}
	}

//  nur wenn keine suche dann einen echten string aufbauen
	
	if (_sucheaktiv == NO)
	{

//		mal schauen ob ein atZentriert offen ist.

		if (zentriert >= 0)
		{
			myRange = NSMakeRange(zentriert,[backString length]-zentriert);
			[zentriertArray addObject:[NSValue valueWithRange:myRange]];
			zentriert = -1;
		}

		//  linken rand ein wenig einruecken (lineindent)

		NSMutableParagraphStyle* myParagraphStyle;

		myParagraphStyle = [[NSMutableParagraphStyle alloc] init];

		[myParagraphStyle setHeadIndent:40.0];
		[myParagraphStyle setFirstLineHeadIndent:40.0];
		[myParagraphStyle setLineSpacing:linespacing];

		[backString addAttribute:NSParagraphStyleAttributeName value:myParagraphStyle range:NSMakeRange(0,[backString length])];
		[myParagraphStyle release];

		//		jetzt erst alle zentrierten stellen setzen!

		NSEnumerator* enu = [zentriertArray objectEnumerator];
		myParagraphStyle = [[NSMutableParagraphStyle alloc] init];
		[myParagraphStyle setAlignment:NSCenterTextAlignment];
		NSValue* rangevalue;

		while (rangevalue = [enu nextObject])
		{
			[backString addAttribute:NSParagraphStyleAttributeName value:myParagraphStyle range:[rangevalue rangeValue]];
		}
		[myParagraphStyle release];
		[zentriertArray release];

//		[self colorizeWords: backString Foreground:YES];
//		[self colorizeWords: backString Foreground:NO];

		[self highlightSearchPosition:searchPosition string:backString];

		if (showMarkierungen)
			[self highlightMarkierungen:[[self band] markierungenDS] string:backString];

		if (i != pageBlocklength)
			NSLog(@"i = %d size = %d",i,pageBlocklength);

		if (atomCount != num_tokens && atomCount != 0)
			NSLog(@"num_tokens = %d soll_tokens = %d",num_tokens,atomCount);
		
		return backString;
	}
	else
		return nil;
}

-(void)setSearchPosition:(int)_p
{
	searchPosition = _p;
}

-(void)highlightSearchPosition:(int)_wordnum string:(NSMutableAttributedString*) _myAttributedString
{
	Word *w;
	if (_wordnum >= [newWordList count])
	{
//		NSLog(@"Wordnum %d too high for wordlist (%d) lastword : %@",_wordnum,[newWordList count],[[newWordList objectAtIndex:[newWordList count]-1] word]);
		return;
	}
	
	if (_wordnum != -1)
	{
		w = [newWordList objectAtIndex:_wordnum];
//		NSLog(@"Searchword to mark : %@",[w word]);
		[_myAttributedString addAttribute:NSBackgroundColorAttributeName value:[NSColor redColor] range:[w range]];
	}
}

-(void)setShowMarkierungen:(BOOL)_state
{
	showMarkierungen = _state;
}

-(BOOL)showMarkierungen
{
	return showMarkierungen;
}

-(void)highlightMarkierungen:(DBFundstellenDataSource *)_ds string:(NSMutableAttributedString*)_myAttributedString
{
	NSEnumerator *enu;
	NSDictionary *d;
	NSColor *c;
	NSRange range,startwortrange,endwortrange;	

	int page = [self textpagenumber];
	
	enu = [[_ds rows] objectEnumerator]; 

	while (d = [enu nextObject])
	{
		if ([[d objectForKey:@"Seite"] intValue] == page)
		{
			c = [d objectForKey:@"Farbe"];
			startwortrange = [[newWordList objectAtIndex:[[d objectForKey:@"StartWort"] intValue]] range];
			range.location = startwortrange.location;
			
			endwortrange = [[newWordList objectAtIndex:[[d objectForKey:@"EndWort"] intValue]] range];
			range.length = endwortrange.location + endwortrange.length - range.location;
			if ((range.location+range.length) > [_myAttributedString length])
                            range.length -=  (range.location+range.length) - [_myAttributedString length];
                            
                        [_myAttributedString addAttribute:NSBackgroundColorAttributeName value:c range:range];
		}
	}
}

-(NSString *)abschnitt
{
	Entry* entry = [[self getArrayWithParents] lastObject];
	return [entry name];	
}

-(NSString *)bereich
{
	NSArray *parentEntries;
	Entry* entry;
	
	parentEntries = [self getArrayWithParents];

	if ([parentEntries count] >=3)
		entry = [parentEntries objectAtIndex:2];
	else
		entry = [parentEntries objectAtIndex:1];

	return [entry name];
}

-(NSString *)konkordanz
{
	return pageSigel ? [NSString stringWithFormat:@"%@, %d",pageSigel,textpagenumber] : @"";
}

/*
                            Neue Wortliste
 enhaelt dictionarys mit den keys wordnumber,range
 wordnum ist wortnummer genau wie in der ttx
 range ist die range des wortes in der seite
*/

-(NSRange)getWordRangeForSelection:(NSRange)_selection
{
/*
 gibt start und endwortnummer fuer die selection zurueck
*/
	NSRange range;
	int suchstart,suchend,index;
	int startwortnum,endwortnum;
	int wortstart,wortend;
	
	startwortnum=-1;
	endwortnum=-1;
	suchstart = _selection.location;
	suchend = _selection.location + _selection.length;

	// durch wordlist loopen

	for (index = 0 ; index < [newWordList count] ; index++)
	{
		range = [[newWordList objectAtIndex:index] range];
		wortstart = range.location;
		wortend = wortstart+range.length;
//		if (NSLocationInRange(suchstart,range)) { // anfang gefunden

		if (NSLocationInRange(suchstart,range)) { // anfang gefunden
//			NSLog(@"suchstart: %d wortstart: %d",suchstart,wortstart);
			startwortnum=index;
			endwortnum=index;
		}

/*		if (wortstart == 0)
			NSLog(@"lastword %@",[[newWordList objectAtIndex:index] word]);
*/

//		NSLog(@"wortstart : %d",wortstart);
		if (wortstart < suchstart)
		{
			startwortnum=index+1;
			endwortnum=index+1;
		}

		if (startwortnum != -1)
		{
			if (suchend >= wortend || suchend >= wortstart)
				endwortnum=index;
		}
	}

	if (endwortnum < startwortnum)
		endwortnum=startwortnum;

	return NSMakeRange(startwortnum,endwortnum);
}

-(NSString *)textForWordRange:(NSRange)_wortrange
{
	NSRange r;
	NSMutableString *text;
	NSEnumerator *enu;
	Word *w;

	text = [NSMutableString stringWithCapacity:5];

	r = NSMakeRange(_wortrange.location,_wortrange.length-_wortrange.location+1);
	enu = [[newWordList subarrayWithRange:r] objectEnumerator];

	while (w = [enu nextObject])
	{
		[text appendString:[w word]];
		[text appendString:@" "];
	}
	return text;
}

+(void)initialize
{
	my_font_manager = [[NSFontManager sharedFontManager] retain];
	alotOfSpaces = [[NSString alloc] initWithCString:"                                                                                                                                              "];
	vladoTestString = [[NSString alloc] initWithUTF8String:"Weise zu nähern wußte, betrat sie seinen Palast in den"];
	unicodedict = [Helper unicodeDictionary];
//	NSLog(@"merkwuerdiges zeichen : %X",[[[NSString alloc] initWithUTF8String:""] characterAtIndex:0]);
	
}

-(void)generateWordList:(unsigned char *)_word Length:(int)_len Range:(NSRange)_range Hyphen:(BOOL)_hyphen Font:(int)_font
{
	/* _word c string in winansi encoding ohne unicode translation
	   _range ist die Range in unserer Seite
	   _len ist die wortlaenge
	   _hyphen ist gesetzt wenn ein hyphen vor diesem wort gefunden wurde
	*/
	// wort muss an trennern getrennt werden
	// TODO hyphen beruecksichtigen
	NSString *displayword;
	NSRange nr;
	NSRange pr;
	NSString *prevWordString;
	Word *prevWord;
	Word* tmpword;
	BOOL unicode;
	
	int wortstart=-1;
	int position=0;

	prevWord=nil;

	if (_hyphen) { // wort an das vorherige anhaengen
		prevWord = [[newWordList objectAtIndex:[newWordList count]-1] retain];
		[newWordList removeObjectAtIndex:[newWordList count]-1];
	}
	
	while (position < _len) { // jedes zeichen des wortes untersuchen
		if (isTrenner(&_word[position],&unicode)) { //handelt sich um einen trenner
			if (position >= wortstart && wortstart != -1) {
				if (prevWord) {
					// neue range bestimmen
					pr = [prevWord range];
					nr = NSMakeRange(pr.location,pr.length+_range.length+1);
					//wort zusammensetzen
					prevWordString = [[prevWord word] substringToIndex:[[prevWord word] length]];
					displayword = [NSString stringWithFormat:@"%@%@",prevWordString,[self wordForVladoString:&_word[wortstart] Length:position-wortstart Font:_font]];
					tmpword = [[Word alloc] initWithWord:displayword Range:nr Konkordanz:konkordanznumber Sigel:pageSigel];
					[prevWord release];
					prevWord=nil;
				}
				else {
					displayword = [self wordForVladoString:&_word[wortstart] Length:position-wortstart Font:_font];				
					tmpword = [[Word alloc] initWithWord:displayword Range:_range Konkordanz:konkordanznumber Sigel:pageSigel];
				}
				[newWordList addObject:tmpword];
				[tmpword release];
				wortstart=-1;
			}
		}
	  else if (wortstart == -1) {
		  wortstart=position;
	  }
            if (unicode) // wenn da unicode ist noch einen weiter
                position++;
	  position++;
	}

	if (wortstart != -1) {// haben noch nen restwort drinnen !!!
		if (prevWord) {
			// neue range bestimmen
			pr = [prevWord range];
			nr = NSMakeRange(pr.location,pr.length+_range.length+1);
			//wort zusammensetzen
			prevWordString = [[prevWord word] substringToIndex:[[prevWord word] length]];
			displayword = [NSString stringWithFormat:@"%@%@",prevWordString,[self wordForVladoString:&_word[wortstart] Length:position-wortstart Font:_font]];
			tmpword = [[Word alloc] initWithWord:displayword Range:nr Konkordanz:konkordanznumber Sigel:pageSigel];
			[prevWord release];
			prevWord=nil;
		}
		else {
			displayword = [self wordForVladoString:&_word[wortstart] Length:position-wortstart Font:_font];				
			tmpword = [[Word alloc] initWithWord:displayword Range:_range Konkordanz:konkordanznumber Sigel:pageSigel];
		}
		[newWordList addObject:tmpword];
		[tmpword release];
	}
}

-(void)addToWordList:(NSString *)_word Range:(NSRange)_range AllowSplit:(BOOL)_split
{
//	NSRange r;
	int position,wortstart;
	Word *tmpword;
	tmpword = [[Word alloc] initWithWord:_word Range:NSMakeRange(0,0) Konkordanz:konkordanznumber Sigel:pageSigel];
	[newWordList addObject:tmpword];
	[tmpword release];
	return;
//	NSLog(@"addToWordList: %@",_word);
// NICHT Trenner Character
// ['0'..'9', 'a'..'z', 'A'..'Z', #138, #140, #154, #156, #192..#255];

	int wordLength = [_word  length];
	
	if (wordLength == 0)
		return;

//	r = [_word rangeOfCharacterFromSet:trennerCharacterSet];

	wortstart=-1;
	position=0;
	
	while (position < wordLength) { // jedes zeichen des wortes untersuchen
		if ([trennerCharacterSet characterIsMember:[_word characterAtIndex:position]]) { //handelt sich um einen trenner
			// pruefen ob schon ein wort da ist
			if (position >= wortstart && wortstart != -1) {
				NSRange wr;
				wr = NSMakeRange(_range.location+wortstart,position-wortstart);
				Word* tmpword = [[Word alloc] initWithWord:[_word substringWithRange:NSMakeRange(wortstart,position-wortstart)] Range:wr Konkordanz:konkordanznumber Sigel:pageSigel];
				[newWordList addObject:tmpword];
				[tmpword release];
				wortstart=-1;
			}
		}
		else if (wortstart == -1) {
			wortstart=position;
		}
		position++;
	}
	if (wortstart != -1) {// haben noch nen restwort drinnen !!!
		Word* tmpword = [[Word alloc] initWithWord:[_word substringWithRange:NSMakeRange(wortstart,position-wortstart)] Range:_range Konkordanz:konkordanznumber Sigel:pageSigel];
		[newWordList addObject:tmpword];
		[tmpword release];
	}
	
/*
	// woerter mit -,'. drinnen als n woerter speichern
	if (r.length && r.location >= 0 && r.location < wordLength && _split)
	{
		rest = _word;

		do {
			if ([[rest substringFromIndex:r.location+1] rangeOfCharacterFromSet:trennerCharacterSet].location != 0)
			{
//				NSString *cleanstring;
//				cleanstring = [[rest substringFromIndex:r.location+1] stringByTrimmingCharactersInSet:trennerCharacterSet];
//				rest  = [rest stringByTrimmingCharactersInSet:trennerCharacterSet];
				if ([rest length]) {
					Word* tmpword = [[Word alloc] initWithWord:[rest substringToIndex:r.location] Range:_range Konkordanz:konkordanznumber Sigel:pageSigel];
					[newWordList addObject:tmpword];
					[tmpword release];
				}
			}

			rest = [rest substringFromIndex:r.location+1];
			r = [rest rangeOfCharacterFromSet:trennerCharacterSet];
		 } while (r.length > 0);

//		rest  = [rest stringByTrimmingCharactersInSet:trennerCharacterSet];
		if ([rest length] >= 1)
		{
			Word* tmpword = [[Word alloc] initWithWord:rest Range:_range Konkordanz:konkordanznumber Sigel:pageSigel];
			[newWordList addObject:tmpword];
			[tmpword release];
		}

	}
	else if (r.length && r.location > 0 && r.location < (wordLength-1) && !_split)
	{   // word soll nur am ersten trenner nicht gesplitet werden, an allen weiteren schon !!
		NSRange zweiterTrenner;
		zweiterTrenner = [[_word substringFromIndex:r.location +1] rangeOfCharacterFromSet:trennerCharacterSet];
		zweiterTrenner.location+=r.location; 
		NSLog(@"NO SPLIT\nRange : %d - %d \t\t%@",zweiterTrenner.location,zweiterTrenner.length,_word);

		Word* tmpword = [[Word alloc] initWithWord:_word Range:_range Konkordanz:konkordanznumber Sigel:pageSigel];
		[newWordList addObject:tmpword];
		[tmpword release];
		if (zweiterTrenner.length >=1) {
			[self addToWordList:[_word substringFromIndex:r.location +1] Range:NSMakeRange(_range.location+zweiterTrenner.location,_range.length-zweiterTrenner.location-1) AllowSplit:YES];
		}
	}
	else
	{
		Word* tmpword = [[Word alloc] initWithWord:_word Range:_range Konkordanz:konkordanznumber Sigel:pageSigel];
		[newWordList addObject:tmpword];
		[tmpword release];
	}
 */
}

-(NSMutableArray *)newWordList
{
	return newWordList;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"Seite : %d\nAtoms : %d",textpagenumber,atomCount];
}

/*
-(void)colorizeWords:(NSMutableAttributedString*) _myAttributedString Foreground:(BOOL)_foreground
{
	NSDictionary* coloredWordsDict = nil;

	NSEnumerator *wordenu,*colwordenu;
	NSString *colword;
	Word *w;
	regex_t	preg;
	int rv;

	if (!_foreground)	// heisst wir haben es mit woertern aus der suche zu tun also wird der hintergrund gefaerbt nicht der FG
		coloredWordsDict = [band searchWordsDict];
	else
		coloredWordsDict = [band coloredWordsDict];

	if (coloredWordsDict == nil)
		return;

	wordenu = [wordlist objectEnumerator];
	colwordenu = [coloredWordsDict keyEnumerator];

//	NSLog(@"colworddict : %@",coloredWordsDict);
	while (colword = [colwordenu nextObject])
	{
		if ((rv=regcomp(&preg,[colword UTF8String], REG_EXTENDED|REG_ICASE)) != 0)
		{
			NSLog(@"Error in regcomp!");
		}
		else
		{
			while (w = [wordenu nextObject]) 
			{
				if (0 == regexec(&preg,[[w word]UTF8String],0,0,0))
				{
//					NSLog(@"RE match");
					if (_foreground)
						[_myAttributedString addAttribute:NSForegroundColorAttributeName value:[coloredWordsDict objectForKey:colword] range:[w range]];
					else
						[_myAttributedString addAttribute:NSBackgroundColorAttributeName value:[coloredWordsDict objectForKey:colword] range:[w range]];
				}
			}
		}
		//	if ([[w word] caseInsensitiveCompare:colword] == NSOrderedSame) {
		wordenu = [wordlist objectEnumerator];
		regfree(&preg);
	}
}
*/

-(void)hoeheistegal:(BOOL)_flag
{
	hoeheistegal = _flag;
}

-(void)enforceRedisplay:(BOOL)_flag
{
	enforceRedisplay = _flag;
}

-(void)displayPageInView:(NSTextView*)_view
{
	NSMutableAttributedString* parsedString;
	NSTextStorage* textStorage;
	NSFont* my_font;

	static float oldfontSize;
	static float oldViewWidth=1000;
	static float oldViewHeight=1464;

	NSSize stringSize;

	NSRect pageviewbounds = [_view bounds];
//	NSLog (@"PAGEVIEW: weite: %.0f  hoehe: %.0f",pageviewbounds.size.width,pageviewbounds.size.height);

	float hoehe = (pageviewbounds.size.height);
	float weite = (pageviewbounds.size.width) - 40 - 8;

	//NSLog(@"PAGEVIEW (old)h: %0.f   w: %0.f   oldfontsize: %0.f",oldViewHeight,oldViewWidth,oldfontSize);

	if (abs(weite) != abs(oldViewWidth) || abs(hoehe) != abs(oldViewHeight))
	{
		fontSize = 5;

		[band setactualpageviewwidth:(int)pageviewbounds.size.width];

		NSMutableAttributedString* myAString = [[NSMutableAttributedString alloc] initWithString:vladoTestString];
		NSRange stringrange = NSMakeRange(0,[myAString length]);
		my_font = [NSFont fontWithName:fontName size:fontSize];
		if(!my_font) NSLog(@"font %@ not found fs:%f %s:%d",fontName,fontSize,__FILE__,__LINE__);

		if (hoeheistegal == YES) hoehe = 999999;

		do
		{
			//NSLog (@"CSTRING: viewhoehe: %0.f viewweite: %0.f weite: %.0f hoehe(*28): %.0f",hoehe,weite,stringSize.width,(stringSize.height)*27.0);

			fontSize++;
			linespacing = fontSize / 17.0;
			my_font = [my_font_manager convertFont:my_font toSize:fontSize];
			if(!my_font) NSLog(@"font %@ not found fs:%f %s:%d",fontName,fontSize,__FILE__,__LINE__);
			[myAString addAttribute:NSFontAttributeName value:my_font range:stringrange];
			stringSize = [myAString size];
		}
		while ((stringSize.width < weite) && (((stringSize.height+linespacing) * 28.0) < hoehe));

		[myAString release];

		//NSLog (@"CSTRING: viewhoehe: %0.f viewweite: %0.f weite: %.0f hoehe(*28): %.0f",hoehe,weite,stringSize.width,(stringSize.height)*27.0);

		fontSize--;
	}
	else
	{
		fontSize = oldfontSize;
		linespacing = (fontSize+1.0) / 17.0;
	}

	if (oldfontSize == fontSize && enforceRedisplay == NO)
	{
		//return;
	}

	oldfontSize = fontSize;
	oldViewWidth = weite;
	oldViewHeight = hoehe;

	parsedString = [self parsePageWithFontSize:fontSize suche:NO];

	enforceRedisplay = NO;

	textStorage = [_view textStorage];
	[textStorage setAttributedString:parsedString];
	[_view setNeedsDisplay:YES];

	//NSLog(@" DBPage : Frame: %0.f x %0.f Bounds : %0.f x %0.f",[_view frame].size.width,[_view frame].size.height,[_view bounds].size.width,[_view bounds].size.height);
	//NSLog(@"END displayPageInView()");
}

-(NSString *)facsimile
{
	// return the name of the image or nil if no facsimile
	int major,sterne=0;
	NSString* rv = nil;
	NSString* sigel = nil;
	NSString *bandnummer;
	
	major = [band majorNumber];
	sigel = [self pageSigel];
	
	switch (major)
	{
		case 40:		// Adelung
			if ([sigel hasPrefix:@"Adelung-GKW Bd. "])
			{
				// sterne zaehlen
				if ([sigel hasSuffix:@"*"])
				{
					sterne=1;
				}
				else if ([sigel hasSuffix:@"**"])
				{
					sterne=2;
				}

				bandnummer=[sigel substringWithRange:NSMakeRange(16,1)];

				if ([bandnummer isEqualToString:@"1"])
				{
					if (sterne) 
						rv = [NSString stringWithFormat:@"ade0%04d",sterne == 1 ? konkordanznumber : konkordanznumber+1000];
					else	// keine sterne
						rv = [NSString stringWithFormat:@"ade1%04d", konkordanznumber];
				}
				else
				{
					if (sterne == 1)
					{
						rv = [NSString stringWithFormat:@"ade%@0000", bandnummer];
					}
					else
					{
						rv = [NSString stringWithFormat:@"ade%@%04d", bandnummer, konkordanznumber];								}
				}
			}
			break;

		case 61:	// shakespeare
			if ([sigel hasPrefix:@"Shakespeare-First Folio"])
			{
				rv = [NSString stringWithFormat:@"shak%04d",konkordanznumber];
			}
			break;

		case 100:	// Meyer
			if ([sigel hasPrefix:@"Meyer Bd."]) {
				int nummer =[[sigel substringFromIndex:10] intValue];
				rv = [NSString stringWithFormat:@"wm%02d%04d",nummer,konkordanznumber];
//				NSLog(@"faxname : %@",[NSString stringWithFormat:@"wm%02d%04d",nummer,konkordanznumber]);
			}
			break;

		case 106:	// Heiligenlexikon
		{
			if ([sigel hasPrefix:@"HL"])
			{
				int bandnummer=[[sigel substringFromIndex:7] intValue];
				rv = [NSString stringWithFormat:@"hl%02d%04d",bandnummer,konkordanznumber];
			}
			break;
		}

		case 118:	// Damen Conversations
		{
			if ([sigel hasPrefix:@"Damen"])
			{
				int bandnummer=[[sigel substringFromIndex:13] intValue];
				rv = [NSString stringWithFormat:@"dc%02d%04d",bandnummer,konkordanznumber];
			}
			break;
		}

		default:
			rv = nil;
			break;
	}
	return rv;
}

-(NSString *)wordForVladoString:(unsigned char *)_string Length:(int)_len Font:(int)_font
{

//  erzeugt aus einem PC-encodet String einen NSString mit allen noetigen umwandlungen (unicode u. spezielle Zeichen)

	NSMutableString *returnString,*temp_string;
	NSData *temp_data;
	BOOL unicode;
	int x; // index im _string
	int i=0;// index im _string ?

	returnString = [[NSMutableString alloc] init];

	if (_len == 1 && _font != 0)
	{
		if (_font == 1)
		{
			switch (_string[i])
			{
				case 38:
					[returnString appendString:[NSString stringWithUTF8String:"▤"]];    // 0x25A4
					break;
				case 51:
					[returnString appendString:[NSString stringWithUTF8String:""]];	//  0xF09D
					break;
				case 65:
					[returnString appendString:[NSString stringWithUTF8String:"✌"]];		// 0x270C
					break;
				case 70:
					[returnString appendString:[NSString stringWithUTF8String:"☞"]];	// 0x261E
					break;
				case 164:
					[returnString appendString:[NSString stringWithUTF8String:"☉"]];	// 0x2609
					break;
				case 182:
					[returnString appendString:[NSString stringWithUTF8String:"✰"]];	// 0x2730
					break;
				case 240:
					[returnString appendString:[NSString stringWithUTF8String:"➝"]];	// 0x279D
					break;

				default:
					[returnString appendString:[NSString stringWithFormat:@"-%d-",_string[i]]];
					NSLog(@"Font: %d  Char: %d",_font,_string[i]);
			}
		}
		else if (_font == 2) 
		{
			switch (_string[i])
			{
				case 45:
					[returnString appendString:[NSString stringWithUTF8String:"­"]]; // Zeichen ist unsichtbar
					break;
				case 200:
					[returnString appendString:[NSString stringWithUTF8String:"∪"]];
					break;
					
				default:
					[returnString appendString:[NSString stringWithFormat:@"-%d-",_string[i]]];
					NSLog(@"Font: %d  Char: %d",_font,_string[i]);
			}
		}
		else
		{
			[returnString appendString:[NSString stringWithFormat:@"-%d-",_string[i]]];
			// NSLog(@"Font: %d  Char: %d",_font,_string[i]);
		}
	}
	else
	{
		unicode = NO;

		for (x = i ; x < i+_len-1;x++)
		{
			if (_string[x] < 0x20)
			{
				unicode = YES;
				break;
			}
		}

		if (unicode == YES)
		{
			for (x = i ; x < i+_len;x++)
			{
				if (_string[x] < 0x20)
				{
					unichar unizeichen;
					unizeichen=makeunichar(&_string[x]);
					temp_string = [[NSString alloc] initWithCharacters:&unizeichen length:1];
					x++;
				}
				else
				{
					temp_data = [NSData dataWithBytes:&_string[x] length:1];
					temp_string = [[NSString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
				}

				if ([temp_string length] > 0)
					[returnString appendString:temp_string];

				[temp_string release];
			}
		}	// end if unicode == yes
		else	// kein unicode enthalten
		{
			temp_data = [NSData dataWithBytes:&_string[i] length:_len];
			returnString = [[NSMutableString alloc] initWithData:temp_data encoding:NSWindowsCP1252StringEncoding];
		}
	}
	return [returnString autorelease];
}

+(NSString *)hexdump:(NSString *)_string
{
	// hexdumps a string
	NSMutableString *rv;
	int len,i;
	len = [_string length];
	rv = [[NSMutableString alloc] init];
	
	for (i=0 ; i <len;i++) {
		[rv appendFormat:@"%X:",[_string characterAtIndex:i]];
	}
	return rv;
}

@end

unichar makeunichar(unsigned char *_string)
{
	unichar unizeichen;
	int x;
	x=0;
	
	unizeichen = _string[x+1] - (_string[x] + 1);
	unizeichen += 256 * (_string[x] - 1);

	if (unizeichen >= 0x0700 && unizeichen < 0x1100)
		unizeichen += 0x1700;
	
	else if (unizeichen >= 0x1100 && unizeichen < 0x1200)
		unizeichen += (0xe000 - 0x1100);

/*	if (unizeichen >= 0x1200 && unizeichen < 0x1e00)
		NSLog(@"unicode: %04X",unizeichen);
*/
	return unizeichen;
}

int isTrenner(unsigned char *_word,BOOL *unicode)
{
	// ['0'..'9', 'a'..'z', 'A'..'Z', #138, #140, #154, #156,#192..#255];

	unsigned char f;
	unichar uni;
	f=_word[0];
	*unicode=NO;

	if (f < 0x20) { // unicode
//		NSLog(@"UNICODE");
		*unicode=YES;
		NSString *alternatestring;
		uni = makeunichar(&_word[0]);
		alternatestring = [unicodedict objectForKey:[NSString stringWithFormat:@"%C",uni]];
//		NSLog(@"unicodedict : %@",unicodedict);
		if ([alternatestring length])
			f = (unsigned char) [alternatestring characterAtIndex:0];
		else
			return 1;
	}
	if ((f >= '0' && f <='9') || (f >= 'a' && f <= 'z') || (f >= 'A' && f <= 'Z') || f == 138 || f == 140 || f == 154 || f == 156 || (f >= 192 && f <255)) {
		return 0;
	}
	else {
		return 1;
	}
}
