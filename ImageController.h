/*
 * ImageController.h -- 
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
#import "Band.h"

@interface ImageController : NSWindowController 
{
	id imageView;
	id imageScrollView;
	id descriptionField;
	id backButton;
	id nextButton;
	id accView;
	id formatPopUpButton;
	id scalePopUpButton;

	DBImageSet* imageSet;

	float scalevalue;
}

- (IBAction) nextButtonAction:(id)sender;
- (IBAction) backButtonAction:(id)sender;
- (IBAction) saveButtonAction:(id)sender;

- (IBAction) scalevaluePopUpMenu:(id)_sender;

- (id) initWithDBImageSet:(DBImageSet*)imageSet;
- (void) setImageInView;
- (void) changeImageInView:(int)diff;
- (void) setButtons;

@end
