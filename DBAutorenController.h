/*
 * DBAutorenController.h -- 
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
#import "Helper.h"

@class Controller;

@interface DBAutorenController : NSWindowController
{
	id tableView;

	id anonymTextField;
	id unteresTextField;
	id oberesTextField;

	Controller* controller;

	NSArray* autoren;
	NSString* title;
	NSString* anonym;
	NSString* infotext;
	NSString *browser;
}
-(id) initWithParentObject:(id)_controller Autoren:(id)_autoren Infotext:(NSString *)_infotext;
-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
-(int)numberOfRowsInTableView:(NSTableView *)aTableView;
-(void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
-(void)Browserauswahl:(id)_sender;
-(void)ArtikelImWeb:(id)_sender;
-(void)DisskusionImWeb:(id)_sender;
-(void)openInBrowser:(NSString *)_url;
-(NSString *)rewriteLinks:(NSString *)_in port:(int)_port;


@end
