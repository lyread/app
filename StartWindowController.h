/*
 * StartWindoController.h -- 
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

#import "Helper.h"
#import "Controller.h"

@class Controller;

@interface StartWindowController : NSWindowController
{
	//IBOutlet NSImageView* imageView;
	id imageView;

	//IBOutlet NSTextField* titleField;
	id titleField;
	//IBOutlet NSTextField* pathTextField;
	id pathTextField;

	//IBOutlet NSButton* fromcdButton;
	id fromcdButton;
	//IBOutlet NSButton* newbandButton;
	id newbandButton;

	//IBOutlet NSProgressIndicator* startWindowProgressIndicator;
	id startWindowProgressIndicator;

	Controller* controller;

	NSString* masterpath;
	NSString* oldmasterpath;
}

-(IBAction) selectBandFromCDAction:(id)sender;
-(IBAction) selectNewBandAction:(id)sender;

-(id) initWithParentObject:(id)_controller;

-(NSString*) searchForDigiBib;
-(NSDictionary*) loadDigibibTableFromPath:(NSString*)_path;
-(int) showThisPath:_path;

@end
