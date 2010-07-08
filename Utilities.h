//
//  Utilities.h
//  Pneumonia
//
//  Created by GreySyntax on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>

@interface Utilities : NSObject {
	
}

//generates md5 hash from a string
+ (NSString *) returnMD5Hash:(NSString*)concat;
+ (NSString *) fileMD5:(NSString *)path;
+ (BOOL) unzip:(NSString *)path toPath:(NSString *)topath;

@end