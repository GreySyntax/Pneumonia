//
//  PneumoniaAppDelegate.h
//  Pneumonia
//
//  Created by GreySyntax on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PneumoniaAppDelegate : NSObject {
    IBOutlet NSWindow *mainWindow;
	IBOutlet NSTextField *status;
	int device;
	IBOutlet NSButton *boot3gs;
	IBOutlet NSButton *restore3gs;
	SEL func_reset;
	NSDictionary *devicesDict;
	NSDictionary *deviceDict;
}

- (void)buttonDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (IBAction)boot3GS:(id)sender;
- (IBAction)boot2G:(id)sender;
- (IBAction)boot3G:(id)sender;

- (IBAction)restore3GS:(id)sender;
- (IBAction)restore2G:(id)sender;
- (IBAction)restore3G:(id)sender;

- (void)reset3GS;

- (void)setDevice:(NSString*)model;
- (void)bootDevice;
- (BOOL)processDict;

- (BOOL)extractIPSW:(NSString*)path;
@end
