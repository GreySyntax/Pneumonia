//
//  Utilities.m
//  Pneumonia
//
//  Created by GreySyntax on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import "Utilities.h"


@implementation Utilities

//
/***
 * Taken from:
 * http://www.iphonedevsdk.com/forum/iphone-sdk-development/17659-calculating-md5-hash-large-file.html#post82394
 */
+ (NSString*)fileMD5:(NSString*)path
{
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
	if( handle== nil ) return @"ERROR GETTING FILE MD5"; // file didnt exist
	
	CC_MD5_CTX md5;
	
	CC_MD5_Init(&md5);
	
	NSData* fileData;
	
	BOOL done = NO;
	while(!done)
	{
		fileData = [handle readDataOfLength:256];
		CC_MD5_Update(&md5, [fileData bytes], [fileData length]);
		if( [fileData length] == 0 ) done = YES;
	}
	
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5_Final(digest, &md5);
	
	NSString *s = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		 digest[0], digest[1], 
		 digest[2], digest[3],
		 digest[4], digest[5],
		 digest[6], digest[7],
		 digest[8], digest[9],
		 digest[10], digest[11],
		 digest[12], digest[13],
		 digest[14], digest[15]];
	
	[fileData dealloc];
	
	return s;
}

//generate md5 hash from string
+ (NSString *) returnMD5Hash:(NSString*)concat {
    const char *concat_str = [concat UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(concat_str, strlen(concat_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash lowercaseString];
	
}

+ (BOOL) unzip:(NSString *)path toPath:(NSString *)topath {

	ZipArchive *unzip = [[ZipArchive alloc] init];
	
	if([unzip UnzipOpenFile:path]) {
		
		if ( ![unzip UnzipFileTo:topath overWrite:YES]) {
			
			NSLog(@"Error extracting.");
			
			[unzip UnzipCloseFile];
			[unzip release];
			
			NSLog(@"Failed to unzip: %@", path);
			NSLog(@"to:	%@", topath);
			return NO;
		}
	}
	
	[unzip  UnzipCloseFile];
	[unzip release];
	return YES;
}

@end
