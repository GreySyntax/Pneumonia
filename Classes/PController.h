//
//  PController.h
//  Pneumonia
//
//  Created by GreySyntax and GRMrGecko on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "USBDevice.h"

@interface PController : NSObject {
	
	USBDevice usbDevice;
    IBOutlet NSWindow *mainWindow;
	NSDictionary *devicesDic;
	NSDictionary *deviceDic;
	
	IBOutlet NSTabView *stepsView;
	
	//Step 1: Firmware Select.
	NSString *stockFirmware;
	NSString *stockFirmwareMD5;
	NSDictionary *stockFirmwareDic;
	BOOL stockValid;
	NSString *customFirmware;
	NSString *customFirmwareMD5;
	NSDictionary *customFirmwareDic;
	BOOL customValid;
	IBOutlet NSTextField *S1Firmware1;
	IBOutlet NSButton *S1Choose1;
	IBOutlet NSProgressIndicator *S1Progress1;
	BOOL S1Firmware1Stock;
	IBOutlet NSTextField *S1Firmware2;
	IBOutlet NSButton *S1Choose2;
	IBOutlet NSProgressIndicator *S1Progress2;
	BOOL S1Firmware2Stock;
	IBOutlet NSTextField *S1Device;
	IBOutlet NSButton *S1Next;
	
	//Step 2: Extract and Patch Firmware.
	IBOutlet NSTextField *S2Status;
	IBOutlet NSProgressIndicator *S2Progress;
	
	//Step 3: Boot or Prepare Device
	IBOutlet NSButton *S3Boot;
	IBOutlet NSButton *S3Prep;
	BOOL bootDevice;
}

- (BOOL)isError:(NSString *)theString;

//Step 1: Firmware Select.
- (void)detectFirmware:(NSDictionary *)info;
- (IBAction)S1Choose:(id)sender;
- (IBAction)S1Next:(id)sender;

//Step 3: Boot or Prepare Device
- (void)runSet;
- (IBAction)S3BootDevice:(id)sender;
- (IBAction)S3PrepareDevice:(id)sender;

//Utilities
- (BOOL)unzip:(NSString *)path toPath:(NSString *)toPath;
- (BOOL)xpwnDecrypt:(NSString *)file newFile:(NSString *)newFile key:(NSString *)key iv:(NSString *)iv;
- (BOOL)bspatch:(NSString *)file newFile:(NSString *)newFile patch:(NSString *)patch;
@end