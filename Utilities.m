//
//  Utilities.m
//  Pneumonia
//
//  Created by GreySyntax on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import "Utilities.h"
#import <CommonCrypto/CommonDigest.h>
#import <openssl/md5.h>

@implementation Utilities

+ (void)createAlert:(NSString *)message info:(NSString *)info window:(NSWindow *)window {
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setInformativeText:info];
	[alert setMessageText:message];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(buttonDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

+ (void)buttonDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode==NSAlertFirstButtonReturn) {
		//[self resetButton];
	}
}

/***
 * Taken from:
 * http://www.iphonedevsdk.com/forum/iphone-sdk-development/17659-calculating-md5-hash-large-file.html#post82394
 */
+ (NSString*)fileMD5:(NSString*)path {
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
	if (handle==nil)
		return @"ERROR GETTING FILE MD5"; // file didnt exist
	
	CC_MD5_CTX md5;
	CC_MD5_Init(&md5);
	
	BOOL done = NO;
	while (!done) {
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		NSData *data = [handle readDataOfLength:256];
		CC_MD5_Update(&md5, [data bytes], [data length]);
		if ([data length]==0) done = YES;
		[pool release];
	}
	
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5_Final(digest, &md5);
	
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02x", digest[i]];
    return hash;
}

//generate md5 hash from string
+ (NSString *)returnMD5Hash:(NSString*)concat {
	NSData *data = [concat dataUsingEncoding:NSUTF8StringEncoding];
	
	CC_MD5_CTX md5;
	CC_MD5_Init(&md5);
	
	CC_MD5_Update(&md5, [data bytes], [data length]);
	
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5_Final(digest, &md5);
	
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02x", digest[i]];
	return hash;
}

+ (BOOL)unzip:(NSString *)path toPath:(NSString *)toPath {
	BOOL result = YES;
	
	if ([[NSFileManager defaultManager] isReadableFileAtPath:@"/tmp/nspwn_ipsw"]) {
		//remove file
		NSError *error;
		if ([[NSFileManager defaultManager] respondsToSelector:@selector(removeFileAtPath:handler:)]) {
			if (![[NSFileManager defaultManager] removeFileAtPath:@"/tmp/nspwn_ipsw" handler:nil]) {
				[self createAlert:@"Failed to remove temp files" info:@"Failed to remove the \"/tmp/nspwn_ipsw\""];
				return NO;
			}
		} else {
			if (![[NSFileManager defaultManager] removeItemAtPath:@"/tmp/nspwn_ipsw" error:&error]) {
				NSLog(@"Failed to remove \"/tmp/nspwn_ipsw\" error: %@", error);
				[Utilities createAlert:@"Failed to remove temp files" info:@"Failed to remove the \"/tmp/nspwn_ipsw\""];
				return NO;
			}
		}
	}
	
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:@"/usr/bin/ditto"];
	[theTask setCurrentDirectoryPath:[@"~/" stringByExpandingTildeInPath]];
	[theTask setArguments:[NSArray arrayWithObjects:@"-xk", path, toPath, nil]];
	[theTask launch];
	[theTask waitUntilExit];
	result = ([theTask terminationStatus]==0);
	[theTask release];
	
	return result;
}

+ (BOOL)xpwnDecrypt:(NSString *)file toPath:(NSString *)toPath key:(NSString *)key iv:(NSString *)iv {
	BOOL result = YES;
	
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"xpwntool" ofType:nil]];
	[theTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	[theTask setArguments:[NSArray arrayWithObjects:file, toPath, @"-k", key, @"-iv", iv]];
	[theTask launch];
	[theTask waitUntilExit];
	result = ([theTask terminationStatus] == 0);
	[theTask release];
	
	return result;
}
@end