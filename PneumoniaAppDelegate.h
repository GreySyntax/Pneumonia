//
//  PneumoniaAppDelegate.h
//  Pneumonia
//
//  Created by GreySyntax on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <openssl/md5.h>
#import <Cocoa/Cocoa.h>

@interface PneumoniaAppDelegate : NSObject <NSApplicationDelegate> {
	
    NSWindow *window;
	NSFileManager *fileManager;
	NSString *documents;
	NSString *resources;
	NSInteger *device;
	NSButton *boot3gs;
	NSButton *restore3gs;
	SEL func_reset;
	NSDictionary *deviceDict;
	NSString *bundles;
	NSTextField *status;
}

- (void) createAlert:(NSString *)message info:(NSString *)info setAlertStyle:(NSAlertStyle)style;

- (IBAction)boot3GS:(id)sender;
- (IBAction)boot2G:(id)sender;
- (IBAction)boot3G:(id)sender;

- (IBAction)restore3GS:(id)sender;
- (IBAction)restore2G:(id)sender;
- (IBAction)restore3G:(id)sender;

- (void)reset3GS;

- (void)loadDeviceDictionary:(NSString*)model;
- (void)bootDevice;
- (BOOL)processDict;

- (BOOL)extractIPSW:(NSString*)path;
- (NSString*)fileMD5:(NSString*)path;

- (void) buttonDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) NSString *documents;
@property (nonatomic, retain) NSString *resources;
@property (assign) NSInteger *device;
@property (nonatomic, retain) IBOutlet NSButton *boot3gs;
@property (nonatomic, retain) IBOutlet NSButton *restore3gs;
@property (nonatomic) SEL func_reset;
@property (nonatomic, retain) NSDictionary *deviceDict;
@property (nonatomic, retain) NSString *bundles;
@property (nonatomic, retain) IBOutlet NSTextField *status;

@end
