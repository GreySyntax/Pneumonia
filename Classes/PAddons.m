//
//  PAddons.m
//  Pneumonia
//
//  Created by Mr. Gecko on 7/9/10.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import "PAddons.h"
#import <CommonCrypto/CommonDigest.h>
#import <openssl/md5.h>

@implementation NSString (PAddons)
- (NSString *)md5 {
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	
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
- (NSString *)pathMD5 {
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:self];
	if (handle==nil)
		return nil;
	
	CC_MD5_CTX md5;
	CC_MD5_Init(&md5);
	
	BOOL done = NO;
	while (!done) {
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		NSData *data = [handle readDataOfLength:1024];
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
@end