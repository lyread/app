/*
 * Helper.m -- 
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
// Constants

unsigned long MAGIC = 1647820;

NSDictionary *unicodedict=nil;

@implementation Helper

+(void)loadunicodedict
{
/*
 INPUT _path_to_find wrong case
 OUTPUT pathname case sensitive
 
 dircontent von startpath holen
 erste pathcomponent von file nehmen
 vergleichen case insensitive
 wenn match
 _startpath um pathcomponent erweitern
 n. pathcomponent von file nehmen
 vergleichen ...
 wenn match und keine weitere pathcomponent uebrig dann
 */
	NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"unicode" ofType:@"plist"]];
	
	if (dict == nil)
	{
		NSRunAlertPanel(@"Fehler",@"Konnte unicode.plist nicht laden, Programm wird beendet!",@"OK",nil,nil);
		exit(0);
	}
	
	// trenner CharacterSet erstellen
	
	NSEnumerator *keyenu;
	NSString *key;
	NSMutableString *trennerZeichen;
	unichar c;
	int lettercode; 
	NSMutableDictionary *muunicodedict;
	
	muunicodedict = [[NSMutableDictionary alloc] init];
	
	trennerZeichen = [[NSMutableString alloc] init];
	keyenu = [dict keyEnumerator];
	
	while (key = [keyenu nextObject])
	{
		NSString *value;
		value = [dict objectForKey:key];
		sscanf([key cString],"%X",&lettercode);
		c=lettercode;
		[muunicodedict setObject:[dict objectForKey:key] forKey:[NSString stringWithFormat:@"%C",c]];
	}
	unicodedict = [[NSDictionary dictionaryWithDictionary:muunicodedict] retain];
	[muunicodedict release];
	
}

+(NSDictionary *)unicodeDictionary
{
	if (unicodedict == nil) {
		////[Helper loadunicodedict];
	}
	return unicodedict;
}

+(NSString *)findFile:(NSString *)_file startPath:(NSString *)_startpath
{
	NSEnumerator *compsenu,*pathenu;
	NSArray *components,*pathes;
	NSString *path,*file;
	int compnum = 0;

//	NSLog(@"Helper findfile(file %@, startpath %@)",_file,_startpath);
	components = [_file componentsSeparatedByString:@"/"];

	compsenu = [components objectEnumerator];

	while (file = [compsenu nextObject])		// file ist filename den wir suchen
	{
		pathes = [[NSFileManager defaultManager] directoryContentsAtPath:_startpath];
		pathenu = [pathes objectEnumerator];

		while (path = [pathenu nextObject])		// path ist filename aus dem pathes
		{
			if ([path caseInsensitiveCompare:file] == NSOrderedSame)
			{
				compnum++;
				_startpath = [NSString stringWithFormat:@"%@/%@",_startpath,path];
				break;
			}
		}
	}

	if ([[[_startpath lastPathComponent] lowercaseString] hasSuffix:[[_file lastPathComponent] lowercaseString]])
		return _startpath;
	else
		return nil;
}

+(BOOL)isMagic:(FILE *)_f
{
	unsigned long plxmagic;

	fseek(_f,0,SEEK_SET);
	if ( 4 != fread(&plxmagic,1,4,_f)) {
		NSLog(@"isMagic() : error reading magic marker");
		exit(1);
	}

	return (plxmagic == MAGIC);   // magic number
}

@end
