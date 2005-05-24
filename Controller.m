/*
 * Controller.m -- 
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

#import "Controller.h"

#include <sys/types.h>
#include <regex.h>


@implementation Controller

-(id)init
{
	NSString *kSuchStartFailed=@"SuchStartFailedNotification";
	NSString *kSuchFinish=@"SucheFinishedNotification";
	NSString *kSuchStopped=@"SucheStoppedNotification";
// Wikipedia Notifications
 	NSString *kzeigeSeiteAusRegister=@"zeigeSeiteAusRegisterNotification";
	NSString *kzeigeBildMitName=@"zeigeBildMitNameNotification";


        //NSLog(@"Instatiate Controller");
	[super init];

	bildschirmmodus = 3;
// Font lister
//    	NSLog(@"Fonts %@",[[NSFontManager sharedFontManager] availableFonts]);
	swController = [[StartWindowController alloc] initWithParentObject:self];

//	colored_words = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:[NSColor redColor],nil] forKeys:[NSArray arrayWithObjects:@"^goethe$",nil]];

	masterRootEntry = [[Entry alloc] initWithName:@"Digitale Bibliothek" level:0 linkNumber:0 band:nil treeArrayIndex:0];
	datasource = [[DataSource alloc] initWithRoot:masterRootEntry];

	historyTimeInterval = 1.5;
	historyTimer = [[NSTimer scheduledTimerWithTimeInterval:historyTimeInterval target:self selector:@selector(history) userInfo:nil repeats:YES] retain];
	history = [[History alloc] initWithMaximum:10u];

// SUCHE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sucheFailedNotification:) name:kSuchStartFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sucheFinishedNotification:) name:kSuchFinish object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sucheStoppedNotification:) name:kSuchStopped object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayPageNotification:) name:@"displayPageNotification" object:nil];
// Wikipedia
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zeigeSeiteAusRegisterNotification:) name:kzeigeSeiteAusRegister object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zeigeBildMitNameNotification:) name:kzeigeBildMitName object:nil];


	notescount = 0;
	suchergebnisse = nil;
	suchbegriff = nil;
	lastMarkerTag = 0;  // der default marker stift
	aktuellerTrefferWordNum = -1;
// END SUCHE
	return self;
}

-(void)dealloc
{
	[historyTimer invalidate];
    [historyTimer release];
    [history release];

	[colored_words release];
	[super dealloc];
}

-(void)awakeFromNib
{
	id resp,keyboardHandler;
	[self configureRegisterView];
	[NSApp setDelegate:self];

// einfuegen von DBKeyboardHandler
//	resp = [mainWindow nextResponder];
//	keyboardHandler = [[DBKeyboardHandler alloc] init];
//	[keyboardHandler setNextResponder:resp];
//	[mainWindow setNextResponder:keyboardHandler];
	
	[pageView setHorizontallyResizable:NO];
	[pageView setVerticallyResizable:NO];

	[outlineview setDataSource:datasource];
	[outlineview setDelegate:self];
	[outlineview setAutoresizesAllColumnsToFit:YES];

	[tabellenView setAllowsEmptySelection:YES];
	[tabellenView setDrawsGrid:NO];
	[tabellenView setDrawsGrid:YES];

	// [pageView setBoundsSize:NSMakeSize(1000,1464)];
	// [pageView setNeedsDisplay:YES];

	[mainTabView selectFirstTabViewItem:self];

//	NSLog(@"indentation: %f",[outlineview indentationPerLevel]);
	[outlineview setIndentationPerLevel:10.0];

//	f = [[[contentTabView tabViewItemAtIndex:2] view] frame];
//	NSLog(@"Frame : origin: %f %f size: %f %f",f.origin.x, f.origin.y, f.size.width, f.size.height);

//	[imageMatrix removeFromSuperview];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewFrameChangedNotifications:) name:NSViewFrameDidChangeNotification object:[mainWindow contentView]];

	[[mainWindow contentView] setPostsFrameChangedNotifications:YES];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayPageWithNumberNote:) name:@"displayPageWithNumberNote" object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayPageWithNumberNoteRedisplay:) name:@"markierungenChanged" object:nil];

	//[NSTimer scheduledTimerWithTimeInterval:0.07 target:self selector:@selector(nextpageForTimer) userInfo:nil repeats:YES];

	[self contentViewFrameChangedNotifications:nil];

	pageViewHeightDiff = [pageBoxView frame].size.height - [pageView frame].size.height;
	pageViewWidthDiff = [pageBoxView frame].size.width - [pageView frame].size.width;

//  SUCHE
	[suchoptionenInAktivBox retain];
	[suchoptionenInAktivBox setBorderType:NSNoBorder];
//	[suchoptionenInAktivBox setHidden:YES];
	[suchoptionenAktivBox retain];
//	NSLog(@"pageview menu %@",[pageView menu]);
//	[pageView setMenu:markierungenMenu];
//  END SUCHE

}

-(void)showFacsimile:(id)_sender
{
	if ([actualPageInView facsimile])
	{
		//NSLog(@"showFacsimile: %@",[actualPageInView facsimile]);
		[[ImageController alloc] initWithDBImageSet:[[[self band] imageDict] objectForKey:[actualPageInView facsimile]]];
	}
}

-(void)configureRegisterView
{
	[registerView setDrawsGrid:YES];
	[registerView setRowHeight:13];

	NSTableColumn* a = [[NSTableColumn alloc] initWithIdentifier:@"stichwort"];
	[a setEditable:NO];
	[[a headerCell] setStringValue:@"Stichwort"];
	[[a dataCell] setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];

	NSTableColumn* b = [[NSTableColumn alloc] initWithIdentifier:@"kategorie"];
	[b setEditable:NO];
	[[b headerCell] setStringValue:@"Kategorie"];
	[[b headerCell] setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
	[[b dataCell] setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];

	[registerView addTableColumn:a];
	[registerView addTableColumn:b];
	[registerView setContinuous:YES];
	[registerView setAllowsEmptySelection:YES];
	[registerView setNeedsDisplay:YES];

	//// GNUstep hat hier Probleme
	//// [registerView sizeLastColumnToFit];
	//// [registerView setAutoresizesAllColumnsToFit:NO];
}

-(void)history
{
	if ([actualPageInView textpagenumber] == histprevpage && histinpage != histprevpage && histprevpage != fromhistpage)
	{
		[history addObject:[NSNumber numberWithInt:histprevpage]];
		histinpage = histprevpage;
		fromhistpage = -1;
		[self updateHistoryButtons];
//		NSLog(@"%@",history);
	}
	histprevpage = [actualPageInView textpagenumber];
}

// Delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return NO;
}

-(Band*)loadBand:(NSString*)_directoryPath
{
	Band* myBand;
	NSArray* treeArray;

	if (_directoryPath == nil)
	{
		NSLog(@"Pfad fuer Band ist nicht gesetzt!");
		return nil;
	}

	myBand = [[Band alloc] initWithPath:_directoryPath];

	if (myBand != nil)
	{
		//[Info7 setStringValue:[NSString stringWithFormat:@"pages: %d",[myBand lastpagenumber]]];

		//[infoImageView setImage:[myBand loadCoverImage]];

		NSString* tmpstring = [[myBand digibibDict] objectForKey:@"[Default]Caption"];
		if (tmpstring == nil)
			tmpstring = @"";

		NSLog(@"mainWindowTitle: %@",tmpstring);
		[mainWindow setTitle:tmpstring];

		treeArray = [myBand treeArray];
		
		NSLog(@"loadBand() index 0");
		[masterRootEntry addChild:[treeArray objectAtIndex:0]];

		//NSLog(@"treeArray %@",treeArray);
		//NSLog(@"Controller:206");
		[outlineview reloadItem:[outlineview itemAtRow:0] reloadChildren:YES];
		//NSLog(@"Controller:208");
		[outlineview collapseItem:[outlineview itemAtRow:0] collapseChildren:YES];
		//NSLog(@"Controller:210");
		[outlineview expandItem:[outlineview itemAtRow:0]];
		//NSLog(@"Controller:212");
		[outlineview reloadData];
		[outlineview expandItem:[outlineview itemAtRow:1]];
		//NSLog(@"Controller:214");

		//NSLog(@"Controller:212");
		[myBand setColoredWordsDict:colored_words];
		[self displayPage:[myBand textPageData:1]];

		//NSLog(@"Controller:216");
		if ([[myBand imageArray] count] > 0)
		{
			[self setPopUpMenu:actualPageInView popupbutton:abbildungenPopUpButton];
			[galeryview setImageSets:[myBand imageArray]];
		}
		else
		{
			[galeryview setImageSets:nil];
			[abbildungenPopUpButton removeAllItems];
			NSString* tmpString = [NSString stringWithUTF8String:"Keine Abbildungen für diesen Band verfügbar!"];
			[abbildungenPopUpButton addItemWithTitle:tmpString];
		}

		DBRegister* myRegister = [myBand Register];

		//NSLog(@"Controller:232");
		if (myRegister != nil)
		{
			[registerTextField setStringValue:@""];
			[registerTextField setEditable:YES];
			[registerTextField setSelectable:YES];
			[registerView setDataSource:myRegister];
			[registerView setDelegate:myRegister];
			[registerView makeKategorieCheckboxes];
			[registerView setDrawsGrid:NO];
			[registerView setDrawsGrid:YES];
		}
		else
		{
			[registerView setDataSource:nil];
			[registerView setDelegate:nil];
			[registerView makeKategorieCheckboxes];
			NSString* tmpString = [NSString stringWithUTF8String:"Kein Register für diesen Band verfügbar!"];
			[registerTextField setStringValue:tmpString];
			[registerTextField setEditable:NO];
			[registerTextField setSelectable:NO];
		}

		[registerView setTarget:myRegister];
		[registerView setAction:@selector(tableViewClickedAction:)];

		NSDictionary* digibibDict = [myBand digibibDict];
		NSString* regViewString = [[digibibDict objectForKey:@"[Default]CDMajor"] stringByAppendingString:@"_RegisterViewValues"];
		[registerView setAutosaveName:regViewString];
		[registerView setAutosaveTableColumns:YES];	
		[registerView sizeToFit];
		[registerView setAutoresizesAllColumnsToFit:YES];

		[[swController window] orderOut:self];
		[mainWindow makeKeyAndOrderFront:self];

		// Tabellen einrichten

		[tabellenPopUpButton removeAllItems];
		[tabellenView setDataSource:nil];
		[tabellenView setDelegate:nil];
		[tabellenView reloadData];

		NSArray* tabellenArray = [myBand tabellenArray];

		if ([tabellenArray count])
		{
			NSEnumerator* enu = [tabellenArray objectEnumerator];
			NSMutableDictionary* tabDict;

			while (tabDict = [enu nextObject])		// einmal durch alle Tabellen
			{
				NSString* filename = [Helper findFile:[NSString stringWithFormat:@"Data/%@",[tabDict objectForKey:@"tabfilename"]] startPath:[myBand masterPath]];

				NSData *dataObject = [NSMutableData dataWithContentsOfFile:filename];

				TabellenDataSource* mydatasource = [[TabellenDataSource alloc] initWithTabelle:tabDict dataObject:dataObject];

				[tabDict setObject:mydatasource forKey:@"DataSource"];

				NSString* title = [tabDict objectForKey:@"tabcaption"];
				[tabellenPopUpButton addItemWithTitle:title];
				NSMenuItem* menuitem = [tabellenPopUpButton itemWithTitle:title];
				[menuitem setRepresentedObject:tabDict];
			}

			[self tabellenPopUpButtonAction:tabellenPopUpButton];
			[tabellenView reloadData];	//// GS	
			[tabellenView setNeedsDisplay:YES];	//// GS
		}
		else
		{
			NSString* title = [NSString stringWithUTF8String:"Keine Tabelle für diesen Band verfügbar!"];
			[tabellenPopUpButton addItemWithTitle:title];
		}

//		SUCHE

		[fundstellenTableView setDataSource:[myBand fundstellenDS]];
		[[myBand fundstellenDS] setTableView:fundstellenTableView];
		[fundstellenTableView setDelegate:[myBand fundstellenDS]];
		[fundstellenTableView setTarget:[myBand fundstellenDS]];
		[fundstellenTableView setAction:@selector(tableViewClickedAction:)];
		[[myBand fundstellenDS] setNextResponder:[fundstellenTableView nextResponder]];
		[fundstellenTableView setNextResponder:[myBand fundstellenDS]];
		[fundstellenTableView setDrawsGrid:NO];
		[fundstellenTableView setDrawsGrid:YES];
// nanohttpd
		nanohttpd *webserver = [[nanohttpd alloc] initWithBand:myBand];
		[webserver start];
		[myBand set_httpdport:[webserver port]];

// MARKIERUNGEN
		[markierungenTableView setDataSource:[myBand markierungenDS]];
		// GS Table font kleiner machen
		NSEnumerator *colenu;
		NSTableColumn *col;
		colenu = [[markierungenTableView tableColumns] objectEnumerator];
		while (col = [colenu nextObject]) {
			[[col headerCell] setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
			[[col dataCell] setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
		}
		colenu = [[fundstellenTableView tableColumns] objectEnumerator];
		while (col = [colenu nextObject]) {
			[[col headerCell] setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
			[[col dataCell] setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
		}
		// END GS modification
		[[myBand markierungenDS] setTableView:markierungenTableView];
		[markierungenTableView setDelegate:[myBand markierungenDS]];
		[markierungenTableView setTarget:[myBand markierungenDS]];
		[markierungenTableView setAction:@selector(tableViewClickedAction:)];
		[[myBand markierungenDS] setNextResponder:[markierungenTableView nextResponder]];
		[markierungenTableView setNextResponder:[myBand markierungenDS]];
		[markierungenTableView setDrawsGrid:NO];
		[markierungenTableView setDrawsGrid:YES];
	}

	return myBand;
}

- (IBAction)tabellenPopUpButtonAction:(id)_sender
{
	NSDictionary* repObject = [[_sender selectedItem] representedObject];

	//NSLog(@"Gewaehlte Tabelle: %@",[repObject objectForKey:@"tabcaption"]);

	NSArray* colArray = [[repObject objectForKey:@"tabvisiblecols"] componentsSeparatedByString:@";"];

	TabellenDataSource* tabdatasource = [repObject objectForKey:@"DataSource"];
	[tabellenView setDataSource:tabdatasource];
	[tabellenView setDelegate:tabdatasource];

	[tabellenView setTarget:tabdatasource];
	[tabellenView setAction:@selector(tableViewClickedAction:)];

	NSEnumerator* enu = [colArray objectEnumerator];

	NSArray* tabfieldsArray = [repObject objectForKey:@"tabfields"];

	NSDictionary* columnDict;
	NSString* columnstring;

	// erstmal alle alten Columns entfernen!

	NSArray* oldColumnsArray = [tabellenView tableColumns];
	NSTableColumn* oldTableColumn;
	NSEnumerator* enu3 = [oldColumnsArray objectEnumerator];

	while (oldTableColumn = [enu3 nextObject])
	{
		[tabellenView removeTableColumn:oldTableColumn];
	}

	// jetzt neue hinzufuegen

	while (columnstring = [enu nextObject])
	{
		NSEnumerator* enu2 = [tabfieldsArray objectEnumerator];

		while (columnDict = [enu2 nextObject])
		{
			if (NSOrderedSame == [columnstring compare:[columnDict objectForKey:@"tabcolname"]])
			{
				NSTableColumn* columntitel = [[NSTableColumn alloc] initWithIdentifier:columnstring];
				[columntitel setEditable:NO];
				[[columntitel headerCell] setStringValue:[columnDict objectForKey:@"tabcollongname"]];
				//NSLog(@"headerCell : %@",[[columntitel headerCell] stringValue]);

				if ([@"r" compare:[columnDict objectForKey:@"tabcolalign"]] == NSOrderedSame)
					[[columntitel dataCell] setAlignment:NSRightTextAlignment];
				[[columntitel dataCell] setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
				[[columntitel headerCell] setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
				//NSLog(@"datacell : %@",[columntitel dataCell]);

				[tabellenView addTableColumn:columntitel];
				//NSLog(@"addTableColumn: %@",columnstring);
			}
		}
	}

	NSString* regViewString = [repObject objectForKey:@"tabhandle"];
	[tabellenView setRowHeight:13];
	[tabellenView setAllowsEmptySelection:YES];
	[tabellenView setDrawsGrid:YES];
	[tabellenView setAutosaveName:regViewString];
	[tabellenView setAutosaveTableColumns:YES];	
	[tabellenView setAutoresizesAllColumnsToFit:YES];
	[tabellenView sizeToFit];
	[tabellenView setNeedsDisplay:YES];	//// GS
	[tabellenView reloadData];		//// GS
	//NSLog (@"tablecolumns %@",[tabellenView tableColumns]);
	//NSLog (@"Datasource %@",[tabellenView dataSource]);
}

-(int)selectItemNumberInTreeView:(int)_zeile band:(Band*)_band
{
	NSArray* mytreeArray;
	Entry* myItem;

	mytreeArray = [_band treeArray];

	myItem = [mytreeArray objectAtIndex:_zeile];

	//NSLog([myItem name]);

	[self selectItemInTreeView:myItem];

	return 0;
}

-(int)selectItemInTreeView:(Entry*)_myItem
{
	Entry* tmpItem;

	if ([outlineview rowForItem:_myItem] == -1)
	{
		NSMutableArray* array = [NSMutableArray arrayWithCapacity:5];

		tmpItem = [_myItem parent];

		while (([outlineview isItemExpanded:tmpItem]) != YES)
		{
			[outlineview expandItem:tmpItem];
			[outlineview reloadData]; //// GS only
			[array addObject:tmpItem];
			tmpItem = [tmpItem parent];
		}

		while ([array count] > 0)
		{
			[outlineview expandItem:[array lastObject]];
			[outlineview reloadData]; //// GS only
			[array removeLastObject];
		}
	}

	//NSLog (@"name: %@",[myItem name]);
	[outlineview expandItem:[_myItem parent]];
	[outlineview reloadData]; //// GS only
	//NSLog (@"Row: %d",[outlineview rowForItem:_myItem]);

	[outlineview selectRow:[outlineview rowForItem:_myItem] byExtendingSelection:NO];
	[outlineview scrollRowToVisible: [outlineview selectedRow]];

	return [outlineview rowForItem:_myItem];
}

#pragma mark -
#pragma mark OutlineView Methoden

- (void)outlineViewSelectionIsChanging:(NSNotification *)_notification
{
	[self outlineViewSelectionDidChange:_notification];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	Entry* selectedEntry;
	NSOutlineView* myOutlineView;

	if (notification != nil)
	{
		myOutlineView = [notification object];

		if (myOutlineView != nil)
		{
			selectedEntry = [myOutlineView itemAtRow:[myOutlineView selectedRow]];

			if (selectedEntry != nil)
			{
				int linkNumber = [selectedEntry linkNumber];

//				//NSLog (@"linknumber: %d",linkNumber);

				[Info1 setStringValue:[NSString stringWithFormat:@"Line in Tree: %d",linkNumber]];

				if (linkNumber != [actualPageInView nodenumber])
				{
					DBPage* myTextPage = [selectedEntry textPageData];
//					//NSLog (@"seite: %d",[myTextPage textpagenumber]);
					[self displayPage:myTextPage];
				}
			}
		}
	}
}

#pragma mark -

-(void)pagesliderAction:_sender
{
	int newpagenumber = [_sender intValue];

	if ([actualPageInView textpagenumber] != newpagenumber)
	{
		[self displayPageWithNumber:newpagenumber];
	}
}

-(void)nextpageForTimer
{
	int newpagenumber = [actualPageInView textpagenumber] + 1;

	Band* myBand = [actualPageInView band];

	if (newpagenumber <= [myBand lastpagenumber])
	{
		[self displayPageWithNumber:newpagenumber];
	}
}

-(void)nextpageButtonAction:_sender
{
	int newpagenumber = [actualPageInView textpagenumber] + 1;

	Band* myBand = [actualPageInView band];
//	NSLog (@"band : %@",myBand);
	//NSLog (@"nextpageButtonAction %d lastpagenumber: %d",newpagenumber,[myBand lastpagenumber]);


	if (newpagenumber <= [myBand lastpagenumber])
	{
		[self displayPageWithNumber:newpagenumber];
	}
}

-(void)backpageButtonAction:_sender
{
	int newpagenumber = [actualPageInView textpagenumber] - 1;

	//NSLog (@"backpageButtonAction: %d",newpagenumber);
	if (newpagenumber >= 1)
	{
		[self displayPageWithNumber:newpagenumber];
	}
}

#pragma mark -
#pragma mark Historie Methoden

// kann nur geklickt werden wenn auch ne history da ist
-(void)historyButtonAction:_sender
{
	NSNumber *num=nil;

	if ([_sender isEqual:historyBackButton])
	{
		num = [history backward];
	}
	else if ([_sender isEqual:historyForwardButton])
	{
		num = [history forward];
	}

//	NSLog(@"num: %d",[num intValue]);
	fromhistpage = [num intValue];
	[self updateHistoryButtons];
	DBPage* myTextPage = [[actualPageInView band] textPageData: [num intValue]];
	[self displayPage:myTextPage];
}

-(void)updateHistoryButtons
{
	[historyBackButton setEnabled:[history canBackward]];
//	[historyBackButton setTitle:[NSNumber numberWithInt:[history position]-1]];
	[historyForwardButton setEnabled:[history canForward]];
//	[historyForwardButton setTitle:[NSNumber numberWithInt:[history count] - [history position]]];
}
#pragma mark -


#pragma mark Markierungen Methoden

- (IBAction) markerClickedAction:(id)sender
{
//	NSCursor *c;
	
	if (lastMarker == sender)
	{
		[sender setState:YES];
		[sender setNeedsDisplay:YES];
		return;
	}

	if (lastMarker != sender)
		[lastMarker setState:NO];
	
	lastMarker = sender;
	
	if ([sender state])
		lastMarkerTag = [sender tag];
	else
		lastMarkerTag = 0;
}
#pragma mark -

-(void)displayPageWithNumberNoteRedisplay:(NSNotification*)_note
{
	[actualPageInView enforceRedisplay:YES];
	[self displayPage:actualPageInView];
}

-(void)displayPageWithNumberNote:(NSNotification*)_note
{
	//NSLog(@"displayPageWithNumberNote called");
	[self displayPage:[[actualPageInView band] textPageData:[(NSNumber*)[_note object] intValue]]];
}

- (IBAction) konkordanzTextFieldAction:(id)_sender
{
	int num = [_sender intValue];

	[self displayPageWithNumber:num];
}

-(void)displayPageWithNumber:(int)num
{
	Band* band = [actualPageInView band];

	//NSLog(@"displayPageWithNumber: %d lastpagenumber: %d",num,[band lastpagenumber]);
	if (num > 0 && num <= [band lastpagenumber])
		[self displayPage:[band textPageData:num]];
}

- (IBAction) printwordlistAction:(id)sender
{
	//NSLog(@"Wordlist for page: %d \n%@",[actualPageInView textpagenumber],[actualPageInView newWordList]);
}

-(void)displayPage:(DBPage*)_dbpage
{
	int tmpnumber = [_dbpage textpagenumber];

	if (tmpnumber == 0) return;  // es gibt keine seite null!

	if (bildschirmmodus == 1)
	{
		[scrollView setHasVerticalScroller:YES];
		[_dbpage hoeheistegal:YES];
	}
	else
	{
		[scrollView setHasVerticalScroller:NO];
		[_dbpage hoeheistegal:NO];
	}

	makierungChanged = NO;
//	vorherigerTrefferWordNum = aktuellerTrefferWordNum;
//	aktuellerTrefferWordNum = -1;
	[_dbpage displayPageInView:pageView];

	//NSLog(@"seite: %d",[_dbpage textpagenumber]);

	if (actualPageInView != _dbpage)
	{
		NSString* tmpstring;

		if (_dbpage != nil)
		{
			// facsimile hide or show
			//// GS TEST
			[[mainMenu itemWithTitle:@"Facsimile anzeigen"] setTarget:[actualPageInView facsimile] != nil ? self : nil];
			if ([actualPageInView facsimile])
			{
				if (!([mainMenu itemWithTitle:@"Facsimile anzeigen"]))
				{
					[[mainMenu addItemWithTitle:@"Facsimile anzeigen" action:@selector(showFacsimile:) keyEquivalent:@""] setTarget:self];
				}
			}
			else {  // das menu weghauen
				if (([mainMenu itemWithTitle:@"Facsimile anzeigen"]))
				{
					 [mainMenu removeItem:[mainMenu itemWithTitle:@"Facsimile anzeigen"]];
					
				}
			}
			if ([actualPageInView textpagenumber] != tmpnumber)
			{
				/* GS auskommentiert da die info outlets nicht mehr da sind weil wir keine drawers haben unter GS 
				[Info2 setStringValue:[NSString stringWithFormat:@"Pagenumber: %d",tmpnumber]];
				[Info3 setStringValue:[NSString stringWithFormat:@"Pagesize: %d",[[_dbpage pageblock] length]]];
				[Info4 setStringValue:[NSString stringWithFormat:@"atoms : %d",[_dbpage atomCount]]];
				[Info5 setStringValue:[NSString stringWithFormat:@"words : %d",[_dbpage wordCount]]];
				[Info6 setStringValue:[NSString stringWithFormat:@"adress: %010p",[_dbpage hexaddress]]];
				*/

//				[self updatePopUpMenu: _dbpage];		// veraltet, aber erstmal nicht loeschen
				[self setPopUpMenu: _dbpage popupbutton:suchbereichseingrenzungPopUpButton];
				if ([[[_dbpage band] imageArray] count] > 1)
					[self setPopUpMenu:_dbpage popupbutton:abbildungenPopUpButton];
				tmpstring = [_dbpage textpagenumberAsString];
				if (tmpstring == nil)
					tmpstring = @"";
				[seitenField setStringValue:tmpstring];

				tmpstring = [_dbpage titleFromTree];
				if (tmpstring == nil)
					tmpstring = @"";
				[treetextField setStringValue:tmpstring];
				[sigelField setStringValue:@""];	// erstmal loeschen wegen Grafikmuell. Apple Error ?
				[sigelField display];

				if ([_dbpage pageSigel] != nil)
				{
					tmpstring = [NSString stringWithFormat:@"%@, %d",[_dbpage pageSigel],[_dbpage konkordanznumber]];
					[sigelField setStringValue:tmpstring];
					NSSize sigelframesize = [sigelField frame].size;
					sigelframesize.width += 1;
					[sigelField setFrameSize:sigelframesize];
				}

				[sigelField sizeToFit];

				// Um eins erhoehen, sonst verschwindet beim resize die seitennummer!

				
				[sigelField setNeedsDisplay:YES];

//				[self updateInfoFields];		// groesse der infofields anpassen!

//				erst am ende die seite merken fuers naechste mal zum checken!

				[actualPageInView release];
				actualPageInView = [_dbpage retain];

//				fuer die folgenden muss actualPageInView gesetzt sein!

				[self selectPageInTreeView:_dbpage];
				[self setSliderFromDBPage: _dbpage];
			}
		}
	}
	return;
}

-(void) updateInfoFields
{
	float treeFieldEnde;

	NSRect scrollframe = [scrollView frame];
	float rechterscrollrand = scrollframe.origin.x;
	rechterscrollrand += scrollframe.size.width;

	treeFieldEnde = rechterscrollrand;

	NSRect frame2 = [sigelField frame];
//	frame2.origin.x = rechterscrollrand - (frame2.size.width + 3);
	treeFieldEnde -= (frame2.size.width + 3 + 5);

	NSRect treefieldframe = [treetextField frame];
	float treefieldstart = treefieldframe.origin.x;

	[treetextField setFrameSize:NSMakeSize(treeFieldEnde - treefieldstart,treefieldframe.size.height)];
	[sigelField setFrameOrigin:NSMakePoint((rechterscrollrand - (frame2.size.width + 3)),frame2.origin.y)];
	[treetextField setNeedsDisplay:YES];
	[sigelField setNeedsDisplay:YES];
}

// aendert nur die selection des popupbutton!

-(void) updatePopUpMenu:(DBPage*)_dbpage
{
//	NSLog(@"updatePopUpMenu");

	id selectedItem;	// Ist eigentlich NSMenuItem*
	Entry* entry;

	int pagenumber;
	int newIndex;

	selectedItem = [abbildungenPopUpButton selectedItem];
	entry = [selectedItem representedObject];

	pagenumber = [_dbpage textpagenumber];

	if ([entry isPagenumInSubTree:pagenumber] == NO)
	{
		newIndex = [abbildungenPopUpButton indexOfSelectedItem] - 1;

		if (newIndex >= 0)
			[abbildungenPopUpButton selectItemAtIndex: newIndex];

		[self abbildungStichwortPopUpButtonAction:abbildungenPopUpButton];
	}
}

-(void) setPopUpMenu:(DBPage*)_dbpage popupbutton:(NSPopUpButton *)_button
{
//	NSLog(@"setPopUpMenu");

	[_button removeAllItems];

	NSArray* myArray;
	myArray = [_dbpage getArrayWithParents];

	if ([myArray count] > 1)
	{
		NSMutableString* spaces = [NSMutableString string];
		NSMutableString* string;

		NSEnumerator* enu = [myArray objectEnumerator];

		[enu nextObject];		// nullte object weglassen!

		Entry* object;
		while(object = [enu nextObject])
		{
			string = [NSMutableString stringWithString:[object name]];
			[string insertString:spaces atIndex:0];

//			NSLog(@"eintrag: %@",string);

			[_button addItemWithTitle:string];
			[[_button itemWithTitle:string] setRepresentedObject:object];

			[spaces appendString:@"  "];
		}

		[_button selectItemAtIndex:globalAbbildungenindexOfSelectedItem];

		if ([@"bilder" compare:[[mainTabView selectedTabViewItem] identifier]] == NSOrderedSame)
		{
			[self abbildungStichwortPopUpButtonAction:_button];
		}
	}
}

-(void)selectPageNumberInTreeView:(int)_pagenumber band:(Band*)_band
{
	[self selectPageInTreeView: [_band textPageData:_pagenumber]];
//	[self displayPage: [_band textPageData:_pagenumber]];
}

-(void)selectPageInTreeView:(DBPage*)_dbpage
{
	Entry* selectedEntry;
	Entry* anEntry;

	if (_dbpage != nil && [outlineview selectedRow] != -1)
	{
		selectedEntry = [outlineview itemAtRow:[outlineview selectedRow]];

//		NSLog(@"selectPageInTreeView() selected entry : %@",selectedEntry);
		if ([selectedEntry textPageNumber] == [_dbpage textpagenumber])
			return;

		NSArray* myTreeArray = [[_dbpage band] treeArray];
//		NSLog(@"[dbpage nodenumber] %d",[_dbpage nodenumber]);
//		NSLog(@"got treeArray, count %d",[myTreeArray count]);

//		NSLog(@"selectPageInTreeView() index %d",[_dbpage nodenumber]);
		anEntry = [myTreeArray objectAtIndex:[_dbpage nodenumber]];

		[self selectItemInTreeView:anEntry];

	}
}

-(void)setSliderFromDBPage:(DBPage*)_dbpage
{
	int max,pos,min;
	unsigned int index;

	if (_dbpage != nil)
	{
		Band* actualBand = [_dbpage band];
		NSArray* myTreeArray = [actualBand treeArray];

		pos = [_dbpage textpagenumber];

		index = [_dbpage nodenumber];

//		NSLog(@"pagenumber: %d  nodennumber: %d",pos,index);

//		NSLog(@"setSliderFromDBPage() index %d",index);
		min = [[myTreeArray objectAtIndex:index] textPageNumber];

		if ((index+1) >= [myTreeArray count])
			max = [actualBand lastpagenumber];
		else {
			max = ([[myTreeArray objectAtIndex:index+1] textPageNumber]) - 1;
		}

		if (pos < min || pos > max)
			NSLog(@"Error in Slider: first/pos/last %d/%d/%d",min,pos,max);

//		int sliderValue = (max-min)+1;                // MacOSX Only
//		if (sliderValue > 50) sliderValue = 0;
//		[pageslider setNumberOfTickMarks:sliderValue];

		[pageslider setMinValue:min];
		[pageslider setMaxValue:max];
		[pageslider setIntValue:pos];
	}
}

- (void)openFileReq:(id)_sender
{
	if ([self band])
	{
		if ([[[self  band] markierungenDS] hasUnsavedChanges] )
		{
			NSString* tmpString = [NSString stringWithUTF8String:"Möchten Sie Ihre Markierungen vorher speichern?"];
			if (NSAlertDefaultReturn==NSRunAlertPanel(@"",tmpString,@"Ja",@"Nein",nil))
				[self menuMarkierungenSpeichernAction:self];
		}
	}

	[mainWindow orderOut:self];		// erstmal mainWindow ausblenden!

	NSEnumerator* winEnu = [[NSApp windows] objectEnumerator];

	NSWindow* myWindow;
	while (myWindow = [winEnu nextObject])
	{
//		NSLog(@"title: %@",[myWindow title]);

		if ([[myWindow windowController] isMemberOfClass:[ImageController class]])
		{
			[myWindow performClose:self];
		}
	}

	Band* band = [actualPageInView band];

	if (sucheAktiv) // suche anhalten
	{
		[[self band] sucheStoppen];	
	}	

	[actualPageInView release];
	actualPageInView = nil;

	[[swController window] makeKeyAndOrderFront:self];

	[outlineview collapseItem:[outlineview itemAtRow:0] collapseChildren:YES];
	[masterRootEntry killAllChildren];
	[outlineview reloadItem:[outlineview itemAtRow:0] reloadChildren:YES];

	[galeryview setImageSets:nil];
	[abbildungenPopUpButton removeAllItems];

	[fundstellenTableView setDelegate:nil];
	[fundstellenTableView setDataSource:nil];

	[markierungenTableView setDelegate:nil];
	[markierungenTableView setDataSource:nil];

	[band autorelease];
}

- (IBAction)abbildungStichwortPopUpButtonAction:(id)_sender;
{
//	NSLog(@"abbildungStichwortPopUpButtonAction");

	id selectedItem;
	Entry* selectedEntry;

	int mypagenumber;
	int endseite = 0;
	int anfangsseite;

	selectedItem = [_sender selectedItem];

	if (selectedItem != nil)
	{
//		NSLog(@"name: %@",[_sender titleOfSelectedItem]);
//		NSLog(@"indexOfSelectedItem: %d",[_sender indexOfSelectedItem]);

		globalAbbildungenindexOfSelectedItem = [_sender indexOfSelectedItem];
		
		selectedEntry = [selectedItem representedObject];

		if (selectedEntry != nil)
		{
			Band* actualBand = [selectedEntry band];

//			NSLog (@"anfang name: %@",[selectedEntry name]);
//			NSLog (@"anfang: %d",[selectedEntry textPageNumber]);
			anfangsseite = [selectedEntry textPageNumber];
			endseite = [selectedEntry lastPageSameLevel];

//			NSLog (@"ende: %d",[nextEntry textPageNumber]);
//			NSLog (@"ende name: %@",[nextEntry name]);

			NSArray *imgArray;
			DBImageSet* myImageSet;
			NSMutableArray *filteredimagesets;

			int imagesNumber = 0;
			unsigned int i;

			imgArray = [actualBand imageArray];

			filteredimagesets = [NSMutableArray array];

			for (i=0;i<[imgArray count];i++)
			{
				//NSLog(@"abbildungStichwortPopUpButtonAction() index %d",i);
				myImageSet = [imgArray objectAtIndex:i];

				mypagenumber = [myImageSet pageNumber];

				if (mypagenumber >= anfangsseite && mypagenumber < endseite)
				{
					imagesNumber++;
					[filteredimagesets addObject:myImageSet];
				}
			}

//			//NSLog(@"images: %d",imagesNumber);

			[galeryview setImageSets:filteredimagesets];
		}
	}
}

- (IBAction)abbildungStichwortTextFieldAction:(id)sender
{
	regex_t	preg;
	int rv;

	NSMutableArray *filteredimagesets;
	NSArray *imgArray;
	DBImageSet* myImageSet;
	NSEnumerator *imgEnu;

	Band* actualBand = [actualPageInView band];

	imgArray = [actualBand imageArray];
	imgEnu = [imgArray objectEnumerator];

	filteredimagesets = [NSMutableArray array];

	if ([[sender stringValue] length] == 0)
	{
		[abbildungentrefferTextField setStringValue:[NSString stringWithFormat:@"Treffer: %d",[imgArray count]]];
		[galeryview setImageSets:imgArray];

		return;
	}

	if ((rv=regcomp(&preg,[[sender stringValue] UTF8String], REG_EXTENDED|REG_ICASE)) != 0)
	{
		NSLog(@"Error in regcomp!");
	}

	while (myImageSet = [imgEnu nextObject])
	{
		NSString* searchString = [[myImageSet imageDescription1] stringByAppendingString:[myImageSet imageDescription1]];

		if ([searchString length])
		{
			if (0 == regexec(&preg,[searchString UTF8String],0,0,0))
			{
//					//NSLog(@"RE match: %@",searchString);
				[filteredimagesets addObject:myImageSet];
			}
		}
	}
	[abbildungentrefferTextField setStringValue:[NSString stringWithFormat:@"Treffer: %d",[filteredimagesets count]]];
	[abbildungentrefferTextField displayIfNeeded];

	[galeryview setImageSets:filteredimagesets];

//	[self displayMatrix:filteredimagesets];
}

-(NSColor *)getColorForMarker:(int)_markerNum
{
	switch (_markerNum)
	{
		case 1:
			return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1];
			break;
		case 2:
			return [NSColor colorWithCalibratedRed:0 green:1.0 blue:1.0 alpha:1];			
			break;
		case 3:
			return [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1];			
			break;
		case 4:
			return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.0 alpha:1];
			break;
	}
	return [NSColor purpleColor];
}

-(void)textViewDidChangeSelection:(NSNotification *)note
{
	NSRange range,wortrange;
	DBFundstellenDataSource *ds;
	NSDictionary *dict;
	NSString *markedtext;
	int pageNumber;
	NSColor *markerColor;
	NSString *konkordanz,*bereich,*abschnitt;
	
	range = [[note object] selectedRange];
	pageNumber = [actualPageInView textpagenumber];

	if ([[note object] isEqual:pageView] && lastMarkerTag != 0)
	{
		if (range.length)
		{
//			string = [[[note object] string] substringWithRange:range];
// TODO : nicht den markierten text sondern den korrigierten text von dbpage speichern
//			//NSLog(@"string markierung : %@ seite:%d",string,pageNumber);
			markerColor = [self getColorForMarker:lastMarkerTag];

			abschnitt = [actualPageInView abschnitt];
			konkordanz = [actualPageInView konkordanz];
			bereich = [actualPageInView bereich];
			wortrange = [actualPageInView getWordRangeForSelection:range];
			//NSLog(@"Wortrange %d : %d",wortrange.location,wortrange.length);

			if (wortrange.length != -1)
			{
				markedtext = [actualPageInView textForWordRange:wortrange];
				dict = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:markedtext,[NSNumber numberWithInt:pageNumber],[NSNumber numberWithInt:wortrange.location],[NSNumber numberWithInt:wortrange.length],[NSNumber numberWithInt:lastMarkerTag],markerColor,konkordanz,bereich,abschnitt,nil] forKeys:[NSArray arrayWithObjects:@"Text",@"Seite",@"StartWort",@"EndWort",@"Tag",@"Farbe",@"Konkordanz",@"Bereich",@"Abschnitt",nil]];
				
				ds = [[actualPageInView band] markierungenDS];
				
				[ds addObject:dict];
				[markierungenTableView reloadData];
				makierungChanged = YES;
				[actualPageInView enforceRedisplay:YES];
				[self displayPage:actualPageInView];
			}
		}
	}
}
- (BOOL)textView:(NSTextView *)aTextView clickedOnLink:(id)_link atIndex:(unsigned)_index
{
	//NSLog(@"clickedOnLink!");
	if ([_link isKindOfClass:[NSNumber class]])
	{
		DBPage* myTextPage = [[actualPageInView band] textPageData:[_link intValue]];
		[self displayPage:myTextPage];
	}
	else if ([_link isMemberOfClass:[NSURL class]])
	{
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		[workspace openURL:_link];
	}
	else if ([_link isMemberOfClass:[DBImageSet class]])
	{
		ImageController* imageController;
		imageController = [[ImageController alloc] initWithDBImageSet:_link];
	}
	else if ([_link respondsToSelector:@selector(getCharacters:)]) // interne o. hyperlink
	{
		//NSLog(@"open HTML Page: %@",_link);
		NSString *internalfilemarker = @"internalfile://";
		
		if ([_link hasPrefix:internalfilemarker])
		{
			NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
			[workspace openFile:[_link substringFromIndex:[internalfilemarker length]]];
			return YES;
		}
		else if ([_link hasPrefix:@"http://"])
		{
			[[DBAutorenController alloc] initWithParentObject:self Autoren:_link Infotext:nil];
			return YES;
		}
		else
		{
			NSString *wikipediainfotext;
			switch ([[self band] majorNumber]) {
				case -76:
					wikipediainfotext = @"Dieser Artikel stammt aus der Wikipedia vom 1.9.2004 02:00 Uhr";
					break;
				case -84:
					wikipediainfotext = @"Dieser Artikel stammt aus der Wikipedia vom 3.3.2005 00:00 Uhr";
					break;
				default:
					wikipediainfotext = @"Dieser Artikel stammt aus der Wikipedia";
			}	
			[[DBAutorenController alloc] initWithParentObject:self Autoren:_link Infotext:wikipediainfotext];
			return  YES;
		}
	}
	else if (_link != nil)  // eigentlich muesste man auf NSString testen, aber wir kriegen hier immer nur NSCFString auf das man nicht testen kann!
	{
		NSLog(@"unknown clicked: %@");
		[[NSWorkspace sharedWorkspace] openFile:_link];
		return YES;
	}

	return NO;
}

-(Band *)band
{
	return [actualPageInView band];
}

// Suchen Funktionen

- (IBAction) showsuchoptionenAction:(id)sender
{
	NSRect oldframe;
	NSRect buttonframe;
	NSRect optionsframe;
	NSView *newView;

	//NSLog(@"showsuchoptionenAction");
	buttonframe = [sender frame];
	if ([sender state] == 1)   // aktiv einschalten
	{
		newView = suchoptionenAktivBox;
		[[suchoptionenBox superview] replaceSubview:suchoptionenBox with:suchoptionenAktivBox];
	}
	else  // passive einschalten
	{
//		NSLog(@"showsuchoptionenAction 2");
		newView = suchoptionenInAktivBox;		
		[[suchoptionenAktivBox superview] replaceSubview:suchoptionenAktivBox with:suchoptionenInAktivBox];
	}

	optionsframe = [newView frame];
	// GS outcomment [newView setFrameOrigin:NSMakePoint(optionsframe.origin.x,buttonframe.origin.y-optionsframe.size.height-8)];
	[newView setFrameOrigin:NSMakePoint(optionsframe.origin.x,buttonframe.origin.y-optionsframe.size.height-8)]; // GS new
	[[newView superview] setNeedsDisplay:YES];
	optionsframe = [newView frame];

	//tableview groesse aendern
	oldframe = [[[fundstellenTableView superview] superview] frame];

	// GS outcomment [[[fundstellenTableView superview] superview] setFrame:NSMakeRect(oldframe.origin.x,oldframe.origin.y, oldframe.size.width,optionsframe.origin.y+8)];
	[[[fundstellenTableView superview] superview] setFrame:NSMakeRect(oldframe.origin.x,oldframe.origin.y, oldframe.size.width,optionsframe.origin.y-12)]; // GS new

	[[[[fundstellenTableView superview] superview] superview] setNeedsDisplay:YES];
}

-(void)displayPageNotification:(NSNotification*)_not
{
	DBPage *page;
	if ([[_not object] objectForKey:@"WordNumber"])
		aktuellerTrefferWordNum = [[[_not object] objectForKey:@"WordNumber"] intValue];
	else
		aktuellerTrefferWordNum=-1;

//	NSLog(@"displayPageNotification number:%d",[[[_not object] objectForKey:@"PageNumber"] intValue]);
	page = [[actualPageInView band] textPageData:[[[_not object] objectForKey:@"PageNumber"] intValue]];
	[page setSearchPosition:aktuellerTrefferWordNum];
	[self displayPage:page];
}

#pragma mark -
#pragma mark Suchen Methoden

-(void)suchenButtonstateChangeTo:(BOOL)_state Message:(NSString *)_msg
{
	sucheAktiv = _state;
	[suchenButton setTitle:_state ? @"Stopp" :@"Suchen"];
	[suchbeergebnissTextField setStringValue:_msg];

	[suchbeergebnissTextField display];
	[suchProgressIndicator display];
	[fundstellenTableView reloadData];
}

-(void)sucheStopped:(NSString *)_msg
{
	[self suchenButtonstateChangeTo:NO Message:_msg];
}

-(void)sucheStoppedNotification:(NSNotification *)_note
{
	[self performSelectorOnMainThread:@selector(sucheStopped:) withObject:@"Suche angehalten" waitUntilDone:NO];
}

-(void)sucheFailed:(NSString *)_msg
{
	NSRunAlertPanel(@"Fehler",@"%@",@"OK", nil, nil,_msg);
	[self suchenButtonstateChangeTo:NO Message:@"Fehler beim Suchen!"];
}

-(void)sucheFailedNotification:(NSNotification *)_note
{
	[self performSelectorOnMainThread:@selector(sucheFailed:) withObject:[_note object] waitUntilDone:NO];	
}

-(void)sucheFinished:(NSString *)_msg
{
	[self suchenButtonstateChangeTo:NO Message:_msg];
	
	if ([[[[self band] fundstellenDS] rows] count] >= 1)
	{		
		[fundstellenTableView selectRow:0 byExtendingSelection:NO];
		[fundstellenTableView setNeedsDisplay:YES];
	}
}

-(void)sucheFinishedNotification:(NSNotification *)_note
{
	[self performSelectorOnMainThread:@selector(sucheFinished:) withObject:[_note object] waitUntilDone:NO];
}

- (IBAction) suchen:(id)sender
{
	id selectedItem;
	Entry *entry;
	int minPage,maxPage,wortabstand,maxfundstellen;

	[suchbegriff release];
	[suchergebnisse release];

	selectedItem = [suchbereichseingrenzungPopUpButton selectedItem];
	entry = [selectedItem representedObject];
	minPage = [entry textPageNumber];
	minPage = minPage > 1 ? minPage : 1;
	minPage = [abaktuellerSeiteButton state] ? [actualPageInView textpagenumber] : minPage;
	maxPage = [entry lastPageSameLevel];

	wortabstand = [maximalerWortabstandTextField intValue];
	maxfundstellen = [[[maximaleFundstellenPopUpButton selectedItem] title] intValue];

//	aktuellerTrefferNum = 1;

	//NSLog(@"minpage : %d",minPage);
	//NSLog(@"Maxpage : %d",maxPage);
	//NSLog(@"Maxfundstellen : %d",maxfundstellen);
	//NSLog(@"Max Wortabstand : %d",wortabstand);
	suchbegriff = [[suchbegriffTextField stringValue] copy];

	if ([suchbegriff length]>=1 && !sucheAktiv)
	{
		NSDictionary *sucheparameterdict;
		sucheparameterdict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:suchbegriff,[NSNumber numberWithInt:minPage],[NSNumber numberWithInt:maxPage],[NSNumber numberWithInt:wortabstand],[NSNumber numberWithInt:maxfundstellen],[NSNumber numberWithInt:[grosskleinschreibungButton intValue]],[NSNumber numberWithInt:[schreibweisentolerantButton intValue]],nil] forKeys:[NSArray arrayWithObjects:@"suchbegriff",@"startseite",@"endseite",@"maxwortabstand",@"maxfundstellen",@"grosskleinschreibung",@"schreibweisentolerant",nil]];

	////	sucheparameterdict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:suchbegriff,[NSNumber numberWithInt:minPage],[NSNumber numberWithInt:maxPage],[NSNumber numberWithInt:wortabstand],[NSNumber numberWithInt:maxfundstellen],[NSNumber numberWithInt:1],[NSNumber numberWithInt:0],nil] forKeys:[NSArray arrayWithObjects:@"suchbegriff",@"startseite",@"endseite",@"maxwortabstand",@"maxfundstellen",@"grosskleinschreibung",@"schreibweisentolerant",nil]];		//// GS test
//		sollen wir vorher die fundstellenliste loeschen
		
		if (![fundstellenvorherloeschenButton state])
		{
			[[[[self band] fundstellenDS] rows] removeAllObjects];
		}

		NSString* tmpstring = [NSString stringWithUTF8String:"Suche läuft!"];

		[self suchenButtonstateChangeTo:YES Message:tmpstring];
		//NSLog(@"kurz vor Thread!");

		[NSThread detachNewThreadSelector:@selector(sucheStarten:)  toTarget:[self band] withObject:sucheparameterdict];
	}
	else if (sucheAktiv) // suche anhalten
	{
		[[self band] sucheStoppen];	
	}	
}

- (IBAction) naechstesSuchergebniss:(id)sender
{
//	aktuellerTrefferNum++;
//	[self displayPageWithNumber:[[suchergebnisse objectAtIndex:aktuellerTrefferNum-1] intValue]];
//	[self updateAktuellerTrefferTextField];
}

- (IBAction) vorherigesSuchergebniss:(id)sender
{
//	aktuellerTrefferNum--;
//	[self displayPageWithNumber:[[suchergebnisse objectAtIndex:aktuellerTrefferNum-1] intValue]];
//	[self updateAktuellerTrefferTextField];
}
#pragma mark -

// Menu Actions
//	Menu	Fundstellen

-(NSString *)showSavePanel:(NSString *)_title withFile:(NSString *)_filename
{
	NSSavePanel* mySavePanel;
	
	mySavePanel = [NSSavePanel savePanel];
	if (_filename)
		[mySavePanel setDirectory:_filename];
	[mySavePanel setTitle:_title];
	
//	[mySavePanel beginSheetForDirectory:nil file:nil modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:_obj];

	if (NSOKButton == [mySavePanel runModal])
		return [mySavePanel filename];
	else
		return nil;
}

-(NSString *)showOpenPanel:(NSString *)_title
{
/* 
	Returns the filename or nil on failure
*/
	NSOpenPanel* mySavePanel;
	
	mySavePanel = [NSOpenPanel openPanel];
	[mySavePanel setTitle:_title];

	if (NSOKButton==[mySavePanel runModalForTypes:nil])
		return [[mySavePanel filenames] lastObject];
	else
		return nil;
}

-(void) savePanelDidEnd:(NSSavePanel*)_sheet returnCode:(int)_returnCode contextInfo:(void *)_contextInfo
{
	if (_returnCode == NSOKButton)
	{
		[NSArchiver archiveRootObject:(id)_contextInfo toFile:[_sheet filename]];
	}
}

#pragma mark -
#pragma mark Menu Methoden

- (IBAction) menuGeheZuSeite:(id)sender
{
	//NSLog(@"menuGeheZuSeite");
	int num = [geheZuSeiteTextField intValue];
	if (num > 0 && num <= [[self band] lastpagenumber])
		[self displayPageWithNumber:num];	
	else
		NSRunAlertPanel(@"Hinweis",@"Sie haben keine gueltige Seitenzahl eingegeben",nil,nil,nil);

	[geheZuSeiteWindow orderOut:nil];
}

- (IBAction) menuMarkierungenFundstellenUebernehmen:(id)sender
{
	// GS BUG : Sie werden nicht sofort im Tableview dargestellt
	[markierungenTableView reloadData];
	[[[self band] markierungenDS] addObjectsFromArray:[[[self band] fundstellenDS]rows]];
}

//	Menu Markierungen
// TODO : duerfen natuerlich nur aus dem selbem band stammen
- (IBAction) menuMarkierungenLadenAction:(id)sender
{
	int rc;
	BOOL ersetzen=NO;
	NSString *filename;

	NSString* tmpstring1 = [NSString stringWithUTF8String:"Es sind bereits Markierungen vorhanden,\nBitte wählen Sie!"];
	NSString* tmpstring2 = [NSString stringWithUTF8String:"Markierungnen hinzufügen"];

	if (([[[[self band] markierungenDS] rows] count]) > 0)
	{
		rc=NSRunAlertPanel(@"Hinweis",tmpstring1,tmpstring2, @"Markierungen ersetzten", @"Abbrechen",nil);
		ersetzen = rc == NSAlertAlternateReturn;

		if (rc == NSAlertOtherReturn)
			return;
	}

	filename = [self showOpenPanel:@"Markierungen laden"];

	if (filename)
	{
		if (ersetzen)
			[[[[self band] markierungenDS] rows] removeAllObjects];

		if ([[[self band]markierungenDS]loadFromFile:filename])
		{
			[markierungenTableView reloadData];
			[self displayPage:actualPageInView];
		}
		else 
			NSRunAlertPanel(@"Fehler",@"Beim laden der Markierungen ist ein Fehler aufgetreten!",@"OK",nil,nil);
	}
	else 
		return;
}

- (IBAction) menuMarkierungenSpeichernAction:(id)sender
{
	NSString *filename;
	NSString *preselectedfilename;
	
	preselectedfilename = [[[self band] markierungenDS]lastSavedFilename];
	filename = [self showSavePanel:@"Markierungen speichern" withFile:preselectedfilename];

	if (filename)
	{
		if (![[[self band]markierungenDS]saveToFile:filename])
		{
			NSRunAlertPanel(@"Fehler",@"Beim speichern der Markierungen ist ein Fehler aufgetreten!",@"OK",nil,nil);		}
	}
}

- (IBAction) menuMarkierungenLoeschenAction:(id)sender
{
	[[[self band] markierungenDS] removeAllObjects];
	[markierungenTableView reloadData];
	makierungChanged=YES;
	[self displayPage:actualPageInView];
}

- (IBAction) menuMarkierungenExportierenAction:(id)sender
{
	NSString *tabformat;
	NSString *filename;
	NSData *data;
	
	filename = [self showSavePanel:@"Markierungen exportieren" withFile:nil];
	if (filename)
	{
		tabformat = [[[self band] markierungenDS] tabFormat];
		data = [tabformat dataUsingEncoding:NSUnicodeStringEncoding];
		if (![data writeToFile:filename atomically:YES])
			NSRunAlertPanel(@"Fehler",@"Beim exportieren der Markierungen ist ein Fehler aufgetreten!",@"OK",nil,nil);	}
}

// algemeine Menu Methoden
-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	int tag;
	BOOL rv=YES;

	tag = [menuItem tag];
//	NSLog(@"menutag: %d",tag);
	switch (tag)
	{
		case 100:		// Markierungen Laden
			break;
		case 101:		// Markierungen Speichern
			rv = ([[[[self band] markierungenDS] rows] count]) > 0 ? YES : NO; 
			break;
		case 102:		// Markierungen exportieren
			rv = ([[[[self band] markierungenDS] rows] count]) > 0 ? YES : NO; 
			break;
		case 103:		// Fundstellen uebernehmen
			rv = ([[[[self band] fundstellenDS] rows] count])  > 0 ? YES : NO; 
			break;
		case 104:		// Markierungen Loeschen
			rv = ([[[[self band] markierungenDS] rows] count])  > 0 ? YES : NO; 
			break;
		default:
			break;
	}
	return rv;
}

#pragma mark -
#pragma mark Drucken Methoden

-(IBAction)print:(id)_sender
{
//	[self showResponderChain];
	[druckenStartTextField setIntValue:[actualPageInView textpagenumber]];
	[druckenEndeTextField setIntValue:[actualPageInView textpagenumber]];
	[druckenMengeTextField setIntValue:1];

	[printWindow makeKeyAndOrderFront:self];
}

-(void) druckenStartTextFieldAction:(id)_sender
{
	int value = [_sender intValue];

	if ([druckenEndeTextField intValue] < value)
	{
		[druckenEndeTextField setIntValue:value];
		[druckenMengeTextField setIntValue:1];
	}
}

-(void) druckenEndeTextFieldAction:(id)_sender
{
	int value = [_sender intValue];
	int startseite = [druckenStartTextField intValue];

	if (value < startseite)
		value = startseite;

	int neuemenge = (value-startseite)+1;

	if (neuemenge >= 256) neuemenge = 255;

	[druckenMengeTextField setIntValue:neuemenge];
	[druckenEndeTextField setIntValue:(startseite + neuemenge) - 1];
}

-(void) druckenMengeTextFieldAction:(id)_sender
{
	int value = [_sender intValue];

	if (value < 1)
	{
		value = 1;
	}

	if (value > 255)
	{
		value = 255;
		[druckenMengeTextField setIntValue:value];
	}
	[druckenEndeTextField setIntValue:([druckenStartTextField intValue] + value) - 1];
}

-(void) druckenStartenButtonAction:(id)_sender
{
//	NSLog(@"print");

	[printWindow orderOut:self];

	NSPrintOperation* printOp;
	NSPrintInfo* printInfo;

	printInfo = [NSPrintInfo sharedPrintInfo];

	NSMutableArray* pageArray = [[NSMutableArray alloc] init];

	Band* band = [actualPageInView band];

	int i;

	int druckstartseite = [druckenStartTextField intValue];
	int druckmenge = [druckenMengeTextField intValue];

	if (druckstartseite < 1) druckmenge = 1;
	if (druckstartseite > [[actualPageInView band] lastpagenumber]) druckstartseite = 1;

	if ((druckstartseite + druckmenge) > [[actualPageInView band] lastpagenumber])
		druckmenge = [[actualPageInView band] lastpagenumber] - druckstartseite + 1;

	if (druckmenge >= 257) druckmenge = 256;
	if (druckmenge < 1) druckmenge = 1;

//	NSLog(@"druck startet bei seite: %d",druckstartseite);
//	NSLog(@"druckmenge: %d",druckmenge);

	for (i=druckstartseite;i<(druckstartseite+druckmenge);i++)
	{
		[pageArray addObject:[band textPageData:i]];
	}

//	NSLog(@"Anzahl der pages im array: %d",[pageArray count]);
	
	DBPrintView* printView = [[DBPrintView alloc] initWithArray:pageArray printInfo:printInfo];

	if(printView != nil)
	{
		printOp = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
		[printOp setShowPanels:YES];
		[printOp runOperation];
	}
}

#pragma mark -

- (BOOL)respondsToSelector:(SEL)aSelector
{
//	NSLog(@"respondsToSelector : %@",NSStringFromSelector(aSelector));
	return [super respondsToSelector:aSelector];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
//	if ([@"bilder" compare:[tabViewItem identifier]] == NSOrderedSame)
//	{
//		[_button selectItemAtIndex:globalAbbildungenindexOfSelectedItem];
//		[self abbildungStichwortPopUpButtonAction:_button];
//	}
}

-(IBAction) textModusAction:(id)sender;
{
	[pageBoxView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];

	[mainTabView retain];
	[mainTabView removeFromSuperview];

	NSRect windowframe = [[mainWindow contentView] frame];
	NSRect rightframe = [pageBoxView frame];

	rightframe.origin.x = 14;
	rightframe.origin.y = 14;

	rightframe.size.width = windowframe.size.width - (rightframe.origin.x * 2);
	rightframe.size.height = windowframe.size.height - (rightframe.origin.y * 2);

	[pageBoxView setFrame:rightframe];
	[pageBoxView setNeedsDisplay:YES];

	[scrollView setHasVerticalScroller:YES];

	[pageView setBoundsSize:NSMakeSize(1000,1464)];
	[pageView setNeedsDisplay:YES];

	if (bildschirmmodus == 2)
	{
		[[mainWindow contentView] addSubview:pageBoxView];
	}

	bildschirmmodus = 1;

	[self contentViewFrameChangedNotifications:nil];
}

-(IBAction) tabellenModusAction:(id)sender;
{
	[mainTabView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];

	[pageBoxView retain];
	[pageBoxView removeFromSuperview];

	NSRect windowframe = [[mainWindow contentView] frame];
	NSRect leftframe = [mainTabView frame];

	leftframe.origin.x = 14;
	leftframe.origin.y = 14;

	leftframe.size.width = windowframe.size.width - (14 + 14);
	leftframe.size.height = windowframe.size.height - (14 + 4);

	[mainTabView setFrame:leftframe];
	[mainTabView setNeedsDisplay:YES];

	if (bildschirmmodus == 1)
	{
		[[mainWindow contentView] addSubview:mainTabView];
	}

	bildschirmmodus = 2;
}

-(IBAction) splitviewModusAction:(id)sender;
{
	[mainTabView setAutoresizingMask:NSViewHeightSizable];
	[pageBoxView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];

	NSRect windowframe = [[mainWindow contentView] frame];

	if (bildschirmmodus == 1)
	{
		[[mainWindow contentView] addSubview:mainTabView];
	}
	else if (bildschirmmodus == 2)
	{
		[[mainWindow contentView] addSubview:pageBoxView];
	}

	[scrollView setHasVerticalScroller:NO];
	bildschirmmodus = 3;

	NSRect rightframe = [pageBoxView frame];

	rightframe.origin.y = 14;
	rightframe.size.height = (windowframe.size.height - (rightframe.origin.y * 2));

	rightframe.size.width = 150;
	rightframe.origin.x = windowframe.size.width - rightframe.size.width - 14;

	NSRect pageframe = [pageView frame];
	pageframe.size.height = rightframe.size.height - pageViewHeightDiff;
	[pageView setFrame:pageframe];

	[self contentViewFrameChangedNotifications:nil];

	NSRect leftframe = [mainTabView frame];

	leftframe.origin.x = 14;
	leftframe.origin.y = 14;
	
	leftframe.size.width = windowframe.size.width - 14 - rightframe.size.width - 14;
	leftframe.size.height = windowframe.size.height - (14 + 4);

	[pageBoxView setFrame:rightframe];
	[pageBoxView setNeedsDisplay:YES];
	[mainTabView setFrame:leftframe];
	[mainTabView setNeedsDisplay:YES];

	[self contentViewFrameChangedNotifications:nil];

	[[mainWindow contentView] setNeedsDisplay:YES];
}

-(void)contentViewFrameChangedNotifications:(NSNotification *)_note
{
	//NSLog(@"object1: %@",[_note object]);

	//NSLog(@" START : Frame: %0.f x %0.f Bounds : %0.f x %0.f",[pageView frame].size.width,[pageView frame].size.height,[pageView bounds].size.width,[pageView bounds].size.height);
	if (bildschirmmodus == 3)
	{
		NSRect pageframe = [pageView frame];

		float pagehoehe = pageframe.size.height;
		float zielbreite = pagehoehe * 1000.0 / 1464.0;
		float diff = (int)(pageframe.size.width - zielbreite);  // das (int) entfernt den Fliegendreck!

		//NSLog(@"Bildschirmmodus 3");

		if (diff)
		{
			NSSize leftframesize = [mainTabView frame].size;
			NSRect rightframe = [pageBoxView frame];

			leftframesize.width += diff;
			rightframe.size.width -= diff;
			rightframe.origin.x += diff;

			[mainTabView setFrameSize:leftframesize];
			[mainTabView setNeedsDisplay:YES];
			[pageBoxView setFrame:rightframe];
			[pageBoxView setNeedsDisplay:YES];

//			[self updateInfoFields];		// groesse der infofields anpassen!
		}
	}
	else if (bildschirmmodus == 1)
	{
		NSSize pageframesize = [pageView frame].size;

		pageframesize.height = (pageframesize.width) * 1464.0 / 1000.0;

		[pageView setFrameSize:pageframesize];
		[pageView setNeedsDisplay:YES];

//		[self updateInfoFields];		// groesse der infofields anpassen!
	}
	// Seite neu anzeigen
	[actualPageInView enforceRedisplay:YES];
	[self displayPage:actualPageInView];
	//NSLog(@" end : Frame: %0.f x %0.f Bounds : %0.f x %0.f",[pageView frame].size.width,[pageView frame].size.height,[pageView bounds].size.width,[pageView bounds].size.height);
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if ([self band])
	{
		if ([[[self  band] markierungenDS] hasUnsavedChanges])
		{
			NSString* tmpString = [NSString stringWithUTF8String:"Möchten Sie Ihre Markierungen vorher Speichern?"];
			if (NSAlertDefaultReturn==NSRunAlertPanel(@"Warnung",tmpString,@"Ja",@"Nein",nil))
				[self menuMarkierungenSpeichernAction:self];
		}
	}
	return NSTerminateNow;
}

-(IBAction)searchAction:(id)_sender		// Apfel-F
{
	if (bildschirmmodus != 3)
	{
		[self splitviewModusAction:nil];
	}

	[mainTabView selectTabViewItemWithIdentifier:@"suche"];

	if ([suchbegriffTextField acceptsFirstResponder] == YES)
		[mainWindow makeFirstResponder:suchbegriffTextField];
}

-(IBAction)galeryClickedAction:(id)sender
{
	[self displayPageWithNumber:[sender intValue]];
}

-(void)showResponderChain
{
	id r;
	r = mainWindow;
	while (r != nil) {
		NSLog(@"Responder: %@",r);
		r = [r nextResponder];
	}
}
#pragma mark Wikipedia Methoden
-(void)zeigeSeiteAusRegisterNotification:(NSNotification*)_not
{
	
	[self performSelectorOnMainThread:@selector(zeigeSeiteAusRegisterNotificationinMainThread:) withObject:[_not object] waitUntilDone:NO];
	NSLog(@"zeigeSeiteAusRegisterNotification %@",[_not object]);
	
}

-(void)zeigeSeiteAusRegisterNotificationinMainThread:(NSString *)_registername
{
	[self displayPageWithNumber:[[[actualPageInView band]Register] pageNumberForTitle:_registername]];
}


-(void)zeigeBildMitNameNotification:(NSNotification*)_not
{	
	[self performSelectorOnMainThread:@selector(zeigeSeiteAusRegisterNotificationinMainThread:) withObject:[_not object] waitUntilDone:NO];

}

-(void)zeigeBildMitNameNotificationinMainThread:(NSString *)_bildname
{
	ImageController* imageController;
	imageController = [[ImageController alloc] initWithDBImageSet:[[[actualPageInView band] imageDict] objectForKey:_bildname]];
	NSLog(@"zeigeBildMitNameNotification %@",_bildname);
}

@end;
