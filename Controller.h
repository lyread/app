/*
 * Controller.h -- 
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
#import "History.h"
#import "Markierung.h"
#import "DBGaleryView.h"
#import "AdvancedTableView.h"
#import "DataSource.h"
#import "Band.h"
#import "DBSuche.h"
#import "DBImageSet.h"
#import "StartWindowController.h"
#import "TabellenDataSource.h"
#import "DBPrintView.h"
#import "DBKeyboardHandler.h"
#import "DBAutorenController.h"
#import "nanohttpd.h"

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

@interface Controller : NSObject
{
	DBAutorenController *myAutorenController;
	DBPage* actualPageInView;
	NSDictionary *colored_words;
	DataSource* datasource;
	Entry* masterRootEntry;

	NSWindowController* swController;

	id  mainWindow;
	id  mainMenu;
	id  printWindow;
	id  geheZuSeiteWindow;
	id  mainTabView;
	id  pageBoxView;
	id  outlineview;
	id  galeryview;
	id  pageView;
	id  scrollView;

	id  mainDrawer;
	id  infoImageView;

	id  Info1;
	id  Info2;
	id  Info3;
	id  Info4;
	id  Info5;
	id  Info6;
	id  Info7;

	id  Bandinfo;

	id  sigelField;
	id  seitenField;
	id  treetextField;

	id  registerView;
	id  registerTextField;
	id  geheZuSeiteTextField;

	id  nextpageButton;
	id  backpageButton;

	id  pageslider;

	id  historyBackButton;
	id  historyForwardButton;

//	IBOutlet NSMatrix *imageMatrix;
	id  abbildungstichwortTextField;
	id  abbildungentrefferTextField;
	id  abbildungenPopUpButton;

//  Tabellen
	id  tabellenPopUpButton;
	id  tabellenView;

//  Markierungen Outlets
	id  markierungenTableView;
	id  markierungenMenu;
	id  mark1Button;
	id  mark2Button;
	id  mark3Button;
	id  mark4Button;
	id lastMarker;
	int lastMarkerTag;
	BOOL makierungChanged;

//  Suchpanel Outlets
	id  suchbegriffTextField;
	id  suchbeergebnissTextField;
	id  suchenButton;
	id  maximalerWortabstandTextField;
	id  schreibweisentolerantButton;
	id  grosskleinschreibungButton;
	id  abaktuellerSeiteButton;
	id  fundstellenvorherloeschenButton;
	id  suchbereichseingrenzungPopUpButton;
	id  maximaleFundstellenPopUpButton;
	id  suchProgressIndicator;
	id  fundstellenTableView;

	// Suchen Variablen
	id  suchoptionenAktivBox;
	id  suchoptionenInAktivBox;
	id  suchoptionenBox;	
	NSString *suchbegriff;
	NSArray *suchergebnisse;
	BOOL sucheAktiv;
	int aktuellerTrefferWordNum,vorherigerTrefferWordNum;

//  Drucken
	id  druckenStartTextField;
	id  druckenEndeTextField;
	id  druckenMengeTextField;

	NSTimer *historyTimer;
	History *history;

	long histprevpage,histinpage,fromhistpage;
	double historyTimeInterval;
	unsigned notescount;

	int globalAbbildungenindexOfSelectedItem;

	int bildschirmmodus;
	float pageViewHeightDiff;
	float pageViewWidthDiff;
}

//Menuitems

-(IBAction) textModusAction:(id)sender;
-(IBAction) tabellenModusAction:(id)sender;
-(IBAction) splitviewModusAction:(id)sender;
-(IBAction) menuGeheZuSeite:(id)sender;

// Debug Actions
- (IBAction) printwordlistAction:(id)sender;

- (IBAction) konkordanzTextFieldAction:(id)sender;

//  Markierungen Actions
- (IBAction) markerClickedAction:(id)sender;

//  Suchpanel Actions
- (IBAction) showsuchoptionenAction:(id)sender;
- (IBAction) suchen:(id)sender;
-(NSColor *)getColorForMarker:(int)_markerNum;

// Drucken
- (IBAction) druckenStartTextFieldAction:(id)sender;
- (IBAction) druckenEndeTextFieldAction:(id)sender;
- (IBAction) druckenMengeTextFieldAction:(id)sender;
- (IBAction) druckenStartenButtonAction:(id)sender;

// Menu Actions

//		Markierungen
- (IBAction) menuMarkierungenLadenAction:(id)sender;
- (IBAction) menuMarkierungenSpeichernAction:(id)sender;
- (IBAction) menuMarkierungenLoeschenAction:(id)sender;
- (IBAction) menuMarkierungenExportierenAction:(id)sender;
- (IBAction) menuMarkierungenFundstellenUebernehmen:(id)sender;

// algemeine Menu Methoden
-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;

- (IBAction) openFileReq:(id)sender;
- (IBAction) nextpageButtonAction:(id)sender;
- (IBAction) backpageButtonAction:(id)sender;

- (IBAction) historyButtonAction:(id)sender;

- (IBAction)pagesliderAction:(id)sender;
- (IBAction)abbildungStichwortTextFieldAction:(id)sender;
- (IBAction)abbildungStichwortPopUpButtonAction:(id)sender;
- (IBAction)tabellenPopUpButtonAction:(id)sender;
- (IBAction)galeryClickedAction:(id)sender;

-(Band*)loadBand:(NSString*)_directorypath;

-(int)selectItemInTreeView:(Entry*)_myItem;
-(void)selectPageInTreeView:(DBPage*)_dbpage;
-(void)selectPageNumberInTreeView:(int)_pagenumber band:(Band*)_band;
-(int)selectItemNumberInTreeView:(int)_zeile band:(Band*)_band;
-(void)displayPage:(DBPage*)_dbpage;
-(void)setSliderFromDBPage:(DBPage*)_dbpage;
-(void)setPopUpMenu:(DBPage*)_dbpage popupbutton:(NSPopUpButton *)_button;
-(void)history;
-(void)updateHistoryButtons;
-(void)historyButtonAction:(id)_sender;
-(void)displayPageWithNumber:(int)num;
-(void)updatePopUpMenu:(DBPage*)_dbpage;
-(void)configureRegisterView;
-(Band *)band;

// Delegate Methods
-(void)textViewDidChangeSelection:(NSNotification *)not;
-(BOOL)textView:(NSTextView *)aTextView clickedOnLink:(id)_link atIndex:(unsigned)_index;

-(void)contentViewFrameChangedNotifications:(NSNotification *)_note;
-(void)updateInfoFields;
-(IBAction)print:(id)_sender;
-(IBAction)searchAction:(id)_sender;

@end
