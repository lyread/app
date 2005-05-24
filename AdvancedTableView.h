/*
 * AdvancedTableView.h -- 
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

#import <AppKit/AppKit.h>
#import "DBRegister.h"
#import "Band.h"

@interface AdvancedTableView : NSTableView
{
/*	// OS X
	IBOutlet NSScrollView* registerScrollView;
	IBOutlet NSTextField* springezuText;
	IBOutlet NSTextField* springezuTextField;
	IBOutlet NSBox* kategoriebox;
*/
	// GNUstep
	id registerScrollView;
	id springezuText;
	id springezuTextField;
	id kategoriebox;

//	NSTextField* textView;
	NSMutableString *filter;
	NSTimer *timer;
	NSMatrix *kategoriematrix;
}
/*
	// OS X
- (IBAction) springezuAction:(id)sender;
*/
// GNUstep
-(void)springezuAction:(id)sender;

-(BOOL)applyfilter:(NSString *)_newfilter;
-(void)addChars:(NSString *)chars;
-(void)makeKategorieCheckboxes;
-(void)kategoryCheckboxClicked:(id)sender;

@end
