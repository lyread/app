/*
 * nanohttpd.h -- 
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
#import <Foundation/Foundation.h>
#import "Band.h"

@interface nanohttpd : NSObject
{
	Band* band;
	FILE *f;
	char *buffer;
	int port;
	int socket_desc;
}

-(void)waitForConnections:(id)_nothing;
-(id)initWithBand:(Band*)band;
-(void)start;
-(void)stop;
-(void)send_http_response:(char *)name;
-(void)send_ok_header:(char *)content_type;
-(void)send_204_header;
-(void)send_404_header;
-(void)send_501_header;
-(void)myerror:(const char *)s;


-(int)port;
@end

