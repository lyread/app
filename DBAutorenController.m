/*
 * DBAutorenController.m -- 
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

/* TODO : Wenn die Infoseite dazu schon existiert nur in Vordergrund bringen, aber keine neue aufbauen!
*/

/* TODO : Das Ding muss HTMLController heissen denn es soll auch HTML Seiten aufmachen koennen 
*/
#import "DBAutorenController.h"
#import "Band.h"
#include <unistd.h>

@implementation DBAutorenController

- (id)initWithParentObject:(id)_controller Autoren:(NSString *)_autoren Infotext:(NSString *)_infotext
{
	NSLog(@"Autoren: %@",_autoren);
	self = [super initWithWindowNibName:@"AutorenNIB"];
	browser = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultBrowser"];

	controller = _controller;
	if ([_autoren hasPrefix:@"http://"]) {	// externe URL mit browser oeffnen
		[self openInBrowser:_autoren];
	}
	else {	// hier die internen seiten und autoreninfos abhandeln
		autoren = [[_autoren substringFromIndex:5] componentsSeparatedByString:@"@"];
		if ([_autoren hasSuffix:@".html"]) {	// ist eine interne html seite also in browser anzeigen
			NSString *htmlpage = [[_controller band] getHTMLPage:_autoren];
			if (htmlpage) {
				// Alle Links umschreiben
				htmlpage = [self rewriteLinks:htmlpage port:[[_controller band] httpdport]];	
				// Seite speichern und dann browser mit tmpfile fuettern
				if ([htmlpage writeToFile:[NSString stringWithFormat:@"/tmp/%@",_autoren] atomically:YES]) {
					[self openInBrowser:[NSString stringWithFormat:@"file:///tmp/%@",_autoren]];
				}
				else {
					NSRunAlertPanel(@"Hinweis",@"Beim oeffnen der HTML-Seite ist ein Fehler aufgetreten",nil,nil,nil,nil);
				}
			}
		}
	/* TODO: diese bedingung ist nur hier weil es in der wikipedia, defekte eintraege gibt z.b. c&l liegt warscheinlich am & zeichen */
		else if ([autoren count] <2) {
			NSRunAlertPanel(@"Hinweis",@"Bei diesem Artikel gibt es keine Quellenangabe",nil,nil,nil,nil);
			return nil;
		}
		else {
			title = [autoren objectAtIndex:0];
			anonym = [autoren lastObject];
			autoren = [autoren subarrayWithRange:NSMakeRange(1,[autoren count]-2)];	
			[autoren retain];
			[title retain];
			[anonym retain];
			infotext = [_infotext retain];
			[self showWindow:self];
		}
	}
	return self;
} 
-(NSString *)rewriteLinks:(NSString *)_in port:(int)_port
{
	NSMutableString *work = [NSMutableString stringWithString:_in];

	// /wiki_de/images/ =>  http://localhost:PORT/wiki_de/images/
	[work  replaceOccurrencesOfString:@"/wiki_de/images/" withString:[NSString stringWithFormat:@"http://localhost:%d/wiki_de/images/",_port] options:0 range:NSMakeRange(0, [work length])];

	// file:///Reg_Ch... => http://localhost:PORT/remote/Reg_...
	[work  replaceOccurrencesOfString:@"file:///Reg_" withString:[NSString stringWithFormat:@"http://localhost:%d/remote/Reg_",_port] options:0 range:NSMakeRange(0, [work length])];

	// noch header und footer drum bauen
	[work insertString:@"<html><head><meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\"></head><body>" atIndex:0];
	[work appendString:@"</body></html>\n"];
	return [NSString stringWithString:work];
}

-(id)clickedAction:(id)_sender
{
	NSString *autor;
	int res;
	autor = [NSString stringWithFormat:@"http://de.wikipedia.org/wiki/Benutzer:%@",[autoren objectAtIndex:[tableView clickedRow]]];
	[self openInBrowser:autor];

	return self;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return [autoren objectAtIndex:rowIndex];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [autoren count];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	[aCell setDrawsBackground:YES];
	if (rowIndex %2)
		[aCell setBackgroundColor:[NSColor colorWithCalibratedRed:0.929 green:0.953 blue:0.996 alpha:1]];
	else
		[aCell setBackgroundColor:[NSColor whiteColor]];
}

-(void)dealloc
{
	[infotext release];
	[autoren release];
	[super dealloc];
}

-(void) awakeFromNib
{
	[oberesTextField setStringValue:[NSString stringWithFormat:@"Autoren des Artikels : %@",title]];
	[anonymTextField setStringValue:[NSString stringWithFormat:@"Anonyme Autoren : %@",anonym]];
	[tableView setAction:@selector(clickedAction:)];
	[tableView setTarget:self];
	[unteresTextField setStringValue:infotext];
	[unteresTextField setNeedsDisplay:YES];
}
-(void)openInBrowser:(NSString *)_url
{
	if (!browser)
		[self Browserauswahl:self];
	if (browser) {
		NSLog(@"%@ %@",browser,_url);
		if (fork() == 0) {
			system([[NSString stringWithFormat:@"%@ \"%@\"",browser,_url] cString]);
			exit(0);
		}
		else {
			NSLog(@"parent process");
		}
	}
}

-(void)Browserauswahl:(id)_sender
{
	int res;
	if (!browser)
		NSRunAlertPanel(@"Hinweis",@"Sie haben noch keinen Webbrowser angegeben, bitte waehlen sie jetzt ihren Webbrowser aus!",nil,nil,nil);
	do {
		NSOpenPanel *op;
		op = [NSOpenPanel openPanel];
		[op setTitle:@"Bitte waehlen Sie ihren Webbrowser aus."];

		if (NSOKButton == [op runModalForTypes:nil]) {
			browser = [[op filenames] lastObject];

			if ([[NSFileManager defaultManager] isExecutableFileAtPath:browser])
				[[NSUserDefaults standardUserDefaults] setObject:browser forKey:@"defaultBrowser"];
			else {
				res = NSRunAlertPanel(@"Hinweis",@"Die ausgewaehlte Datei ist kein startbares Programm.",@"neue Auswahl",@"Abrechen",nil);

				if (res == NSOKButton) 	
					continue;
				else
					break;
			}
		}
		else {
		// Broswer nicht gewaehlt also kann man keine htmls anzeigen
			break;
		}
	} while(!browser);
	if (!browser) {
		NSRunAlertPanel(@"Hinweis",@"Sie haben keinen Browser gewaehlt, solange kein Browser ausgewaehlt wurde koennen keine links im Internet angewaehlt werden!",@"OK",nil,nil);
	}
}
-(void)ArtikelImWeb:(id)_sender
{
	NSLog(@"ArtikelImWeb");
	[self openInBrowser:[NSString stringWithFormat:@"http://de.wikipedia.org/wiki/%@",title]];

}
-(void)DisskusionImWeb:(id)_sender
{
	NSLog(@"DisskusionImWeb");
	[self openInBrowser:[NSString stringWithFormat:@"http://de.wikipedia.org/wiki/Diskussion:%@",title]];
}

@end
