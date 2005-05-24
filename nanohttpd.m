/*
 * nanohttpd.m -- 
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

#import <nanohttpd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <string.h>
#include <netinet/in.h>

NSString *kzeigeSeiteAusRegister=@"zeigeSeiteAusRegisterNotification";
NSString *kzeigeBildMitName=@"zeigeBildMitNameNotification";


@implementation nanohttpd

// Todo den nanohttpd als thread starten o. als Task

-(void)start
{
	[NSThread detachNewThreadSelector:@selector(waitForConnections:) toTarget:self withObject:nil];
}

-(void)stop
{
}

-(int)port
{
	return port;
}

-(id)initWithBand:(Band *)_band
{
	struct sockaddr_in address;

	self = [super init];
	if (!self)
		return nil;
	band=_band;
	NSLog(@"Starting nano-httpd instance!");
	
	if ((socket_desc = socket(AF_INET,SOCK_STREAM,0)) == -1)
		[self myerror:"socket() failed"];

	/* type of socket created in socket() */
	address.sin_family = AF_INET;
	address.sin_addr.s_addr = INADDR_ANY;
	/* 7000 is the port to use for connections */
	port = 12000;
	do {
//		printf ("Binding to port %d\n",port);
		address.sin_port = htons(++port);
	/* bind the socket to the port specified above */
	}
	while (0 != bind(socket_desc,(struct sockaddr *)&address,sizeof(address)));

	NSLog(@"Accepting Connections on port %d...",port);
	
	if ( 0 != listen(socket_desc,128))
		[self myerror:"listen() failed"];
	return self;
}

-(void)waitForConnections:(id)_nothing
{
	char firstline[1024];
	struct sockaddr_in conn_address;
	int new_socket;
	int addrlen;

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	addrlen = sizeof(struct sockaddr_in);

	while (new_socket = accept(socket_desc, (struct sockaddr *)&conn_address, &addrlen)) {

		if (new_socket<0)
			[self myerror:"accept() failed"];

		NSLog(@"connection established!");
		f = fdopen(new_socket,"w+");
	
		if (fgets((char *)&firstline,sizeof(firstline),f)) {
			// 1. Zeile von browser gelesen
			NSLog(@"Firstline: %s",firstline);
			
			if (0 == strncmp("GET /",firstline,5)) {
				NSLog(@"GET reached");
				char *get_st,*name_st,*proto_st;
				get_st = strtok(firstline," ");
				name_st = strtok(NULL," ");
				name_st = strdup(name_st);
				proto_st = strtok(NULL," ");
				//NSLog(@"name : %s proto : %s",name_st,proto_st);
				// sieht nach http aus
				// suche nach ersten leerzeichen nach dem GET / das ist dann unser gesuchtest file
				// Rest vom Request einlesen
				while (fgets((char *)&firstline,sizeof(firstline),f)) {
					//NSLog(@"%s",firstline);
					if (strcmp("\r\n",firstline) == 0)
						break;
				}
				[self send_http_response:name_st];
			}
			else {	// alles andere koennen wir nicht!
				NSLog(@"unknown request:%s",firstline);
				[self send_501_header];
			}
		}
	} // END while
	
    [pool release];	
}

-(void)send_http_response:(char *)name {
	// name ist string von browser kann sein [("Register anzeigen", "bild anzeigen") Linux],"Bild ausgeben", ("HTML Seite ausgeben") muss nicht sein

	NSString *image_prefixstring = @"/wiki_de/images/";
	NSString *remote_prefixstring = @"/remote/";

	NSString *urlstring = [NSString stringWithCString:name];
	NSLog(@"urlstring : %@",urlstring);
	if([urlstring rangeOfString:remote_prefixstring].length > 1) // Digibux Steuerbefehl fuer Register oder Bild
	{
		NSString *remote_cmd = [urlstring substringFromIndex:[remote_prefixstring length]];
		if ([remote_cmd rangeOfString:@"Reg_"].length > 1) {	// Register Steuerbefehl
			NSString *rname = [remote_cmd substringFromIndex:4];
			rname = [rname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSLog (@"Show Register: %@",rname);
			
			[[NSNotificationCenter defaultCenter] postNotificationName:kzeigeSeiteAusRegister object:rname];
		}
		else if ([remote_cmd rangeOfString:@"Bild_"].length >1) {	// sollte sich um ein bild handeln
			NSString *bname = [remote_cmd substringFromIndex:5];
			bname = [bname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSLog(@"Show Bild: %@,bname");
			[[NSNotificationCenter defaultCenter] postNotificationName:kzeigeBildMitName object:[urlstring substringFromIndex:13]];
			
		}
		[self send_204_header];
	}
	else if([urlstring rangeOfString:image_prefixstring].length > 1) // inline Bild fuer HTML seite ausgeben
	{
		NSRange prefixrange = [urlstring rangeOfString:image_prefixstring];
		NSString *im_name = [urlstring substringToIndex:[urlstring length]-4];
		im_name =[im_name substringFromIndex:prefixrange.location+[image_prefixstring length]];
		im_name = [[urlstring substringFromIndex:prefixrange.location+[image_prefixstring length]] lowercaseString];
		im_name = [im_name stringByDeletingPathExtension];
		NSLog(@"inline image:%@",im_name);
		DBImageSet *im_dict = [[band imageDict] objectForKey:im_name];
		NSLog(@"imageset: %@",im_dict);

		NSData *data = [im_dict rawImage2];		// TODO immer eines finden nicht auf rawImage2 verlassen
		if (data) {	// wir haben die bilddaten
			NSLog(@"Transmitting image %@",im_name);
			[self send_ok_header:"image/png"];	// TODO richtiges Format ausgeben
			fwrite([data bytes],1,[data length],f);
			fclose(f);
		}
		else {
			NSLog(@"404 Error");
			[self send_404_header];
		}
	}
}

-(void)send_ok_header:(char *)content_type
{
	fprintf(f,"HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: %s\r\n\r\n",content_type);
}

-(void)send_204_header;
{
	fprintf(f,"HTTP/1.1 204 No Content\r\nConnection: close\r\n\r\n");
	fclose(f);
}
-(void)send_404_header;
{
	fprintf(f,"HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n");
	fclose(f);
}

-(void)send_501_header;
{
	fprintf(f,"HTTP/1.1 501 Not Implemented\r\nConnection: close\r\n\r\n");
	fclose(f);
}

-(void)myerror:(const char *)s
{
	perror(s);
}


@end
