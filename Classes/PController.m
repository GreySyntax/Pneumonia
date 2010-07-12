//
//  PController.m
//  Pneumonia
//
//  Created by GreySyntax and GRMrGecko on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import "PController.h"
#import "PAddons.h"

NSString * const PTMP = @"/tmp/nspwn_ipsw";
NSString * const PApplicationSupport = @"~/Library/Application Support/Pneumonia/";

//Bundle Keys
NSString *PBName = @"name";
NSString *PBID = @"id";
NSString *PBFirmwares = @"firmwares";
NSString *PBStock = @"stock";
NSString *PBMD5 = @"md5";
NSString *PBFVersion = @"version";
NSString *PBFiles = @"files";
NSString *PBPatch = @"patch";
NSString *PBIV = @"iv";
NSString *PBKey = @"key";
NSString *PBTarget = @"target";
NSString *PBPath = @"path";

//Choose Info
NSString * const PCISender = @"sender";
NSString * const PCIFile = @"file";
NSString * const PCIDeviceMatchError = @"The devices does not match";
NSString * const PCIDeviceFoundError = @"This device is not supported";
NSString * const PCIDeviceFirmwareError = @"This firmware matches the other";
NSString * const PCIDeviceFirmwareFoundError = @"This firmware is not supported";
NSString * const PCIDeviceFirmwareValidationError = @"This firmware is not valid";

@implementation PController
- (void)awakeFromNib {
	printf("Pneumonia - Copyright NSPwn.com - Application by GreySyntax & GRMrGecko\n\n");
	devicesDic = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Devices" ofType:@"plist"]] retain];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:[PApplicationSupport stringByExpandingTildeInPath]]) {
		if ([manager respondsToSelector:@selector(createDirectoryAtPath:attributes:)]) {
			[manager createDirectoryAtPath:[PApplicationSupport stringByExpandingTildeInPath] attributes:nil];
		} else {
			[manager createDirectoryAtPath:[PApplicationSupport stringByExpandingTildeInPath] withIntermediateDirectories:YES attributes:nil error:nil];
		}
	}
	
	[S1Next setEnabled:NO];
	[stepsView selectTabViewItem:[stepsView tabViewItemAtIndex:0]];
}
- (void)dealloc {
	if (devicesDic!=nil)
		[devicesDic release];
	if (deviceDic!=nil)
		[deviceDic release];
	if (stockFirmware!=nil)
		[stockFirmware release];
	if (stockFirmwareMD5!=nil)
		[stockFirmwareMD5 release];
	if (stockFirmwareDic!=nil)
		[stockFirmwareDic release];
	if (customFirmware!=nil)
		[customFirmware release];
	if (customFirmwareMD5!=nil)
		[customFirmwareMD5 release];
	if (customFirmwareDic!=nil)
		[customFirmwareDic release];
	[super dealloc];
}

- (BOOL)isError:(NSString *)string {
	if ([string isEqual:PCIDeviceMatchError])
		return YES;
	if ([string isEqual:PCIDeviceFoundError])
		return YES;
	if ([string isEqual:PCIDeviceFirmwareError])
		return YES;
	if ([string isEqual:PCIDeviceFirmwareFoundError])
		return YES;
	if ([string isEqual:PCIDeviceFirmwareValidationError])
		return YES;
	return NO;
}

//Step 1: Firmware Select.
- (void)detectFirmware:(NSDictionary *)info {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	BOOL sender1 = ([info objectForKey:PCISender]==S1Choose1);
	NSArray *devices = [devicesDic allKeys];
	BOOL foundDevice = NO;
	BOOL foundFirmware = NO;
	for (int i=0; i<[devices count]; i++) {
		if ([[info objectForKey:PCIFile] rangeOfString:[devices objectAtIndex:i]].location!=NSNotFound) {
			foundDevice = YES;
			if (deviceDic!=nil) {
				if (![deviceDic isEqual:[devicesDic objectForKey:[devices objectAtIndex:i]]]) {
					if (sender1) {
						if (![[S1Firmware2 stringValue] isEqual:@""] && ![self isError:[S1Firmware2 stringValue]]) {
							[S1Firmware1 setStringValue:PCIDeviceMatchError];
							break;
						}
					} else {
						if (![[S1Firmware1 stringValue] isEqual:@""] && ![self isError:[S1Firmware1 stringValue]]) {
							[S1Firmware2 setStringValue:PCIDeviceMatchError];
							break;
						}
					}
				}
			}
			deviceDic = [devicesDic objectForKey:[devices objectAtIndex:i]];
			[S1Device setStringValue:[deviceDic objectForKey:PBName]];
			NSArray *firmwares = [[deviceDic objectForKey:PBFirmwares] allKeys];
			for (int f=0; f<[firmwares count]; f++) {
				if ([[info objectForKey:PCIFile] rangeOfString:[firmwares objectAtIndex:f]].location!=NSNotFound) {
					foundFirmware = YES;
					NSDictionary *firmware = [[deviceDic objectForKey:PBFirmwares] objectForKey:[firmwares objectAtIndex:f]];
					if ([[firmware objectForKey:PBStock] boolValue]) {
						if (sender1 && S1Firmware2Stock && ![[S1Firmware2 stringValue] isEqual:@""] && ![self isError:[S1Firmware2 stringValue]]) {
							[S1Firmware1 setStringValue:PCIDeviceFirmwareError];
							break;
						} else if (S1Firmware1Stock && ![[S1Firmware1 stringValue] isEqual:@""] && ![self isError:[S1Firmware1 stringValue]]) {
							[S1Firmware2 setStringValue:PCIDeviceFirmwareError];
							break;
						}
					} else {
						if (sender1 && !S1Firmware2Stock && ![[S1Firmware2 stringValue] isEqual:@""] && ![self isError:[S1Firmware2 stringValue]]) {
							[S1Firmware1 setStringValue:PCIDeviceFirmwareError];
							break;
						} else if (!S1Firmware1Stock && ![[S1Firmware1 stringValue] isEqual:@""] && ![self isError:[S1Firmware1 stringValue]]) {
							[S1Firmware2 setStringValue:PCIDeviceFirmwareError];
							break;
						}
					}
					if (sender1) {
						if ([[firmware objectForKey:PBStock] boolValue]) {
							S1Firmware1Stock = YES;
							if (stockFirmware!=nil) [stockFirmware release];
							stockFirmware = [[info objectForKey:PCIFile] retain];
							stockValid = NO;
						} else {
							S1Firmware1Stock = NO;
							if (customFirmware!=nil) [customFirmware release];
							customFirmware = [[info objectForKey:PCIFile] retain];
							customValid = NO;
						}
						[S1Firmware1 setStringValue:[[info objectForKey:PCIFile] lastPathComponent]];
						[S1Progress1 setHidden:NO];
						[S1Progress1 startAnimation:self];
						[S1Choose1 setEnabled:NO];
					} else {
						if ([[firmware objectForKey:PBStock] boolValue]) {
							S1Firmware2Stock = YES;
							if (stockFirmware!=nil) [stockFirmware release];
							stockFirmware = [[info objectForKey:PCIFile] retain];
							stockValid = NO;
						} else {
							S1Firmware2Stock = NO;
							if (customFirmware!=nil) [customFirmware release];
							customFirmware = [[info objectForKey:PCIFile] retain];
							customValid = NO;
						}
						[S1Firmware2 setStringValue:[[info objectForKey:PCIFile] lastPathComponent]];
						[S1Progress2 setHidden:NO];
						[S1Progress2 startAnimation:self];
						[S1Choose2 setEnabled:NO];
					}
					
					NSString *md5 = [[info objectForKey:PCIFile] pathMD5];
					if ([[firmware objectForKey:PBStock] boolValue]) {
						if (![md5 isEqual:[firmware objectForKey:PBMD5]]) {
							if (sender1)
								[S1Firmware1 setStringValue:PCIDeviceFirmwareValidationError];
							else
								[S1Firmware2 setStringValue:PCIDeviceFirmwareValidationError];
						} else {
							stockValid = YES;
							if (stockFirmwareMD5!=nil) [stockFirmwareMD5 release];
							stockFirmwareMD5 = [md5 retain];
							if (stockFirmwareDic!=nil) [stockFirmwareDic release];
							stockFirmwareDic = [firmware retain];
						}
					} else {
						if ([md5 isEqual:[firmware objectForKey:PBMD5]]) {
							if (sender1)
								[S1Firmware1 setStringValue:PCIDeviceFirmwareValidationError];
							else
								[S1Firmware2 setStringValue:PCIDeviceFirmwareValidationError];
						} else {
							customValid = YES;
							if (customFirmwareMD5!=nil) [customFirmwareMD5 release];
							customFirmwareMD5 = [md5 retain];
							if (customFirmwareDic!=nil) [customFirmwareDic release];
							customFirmwareDic = [firmware retain];
						}
					}
					
					if (sender1) {
						[S1Progress1 stopAnimation:self];
						[S1Progress1 setHidden:YES];
						[S1Choose1 setEnabled:YES];
					} else {
						[S1Progress2 stopAnimation:self];
						[S1Progress2 setHidden:YES];
						[S1Choose2 setEnabled:YES];
					}
				}
			}
			if (!foundFirmware) {
				if (sender1)
					[S1Firmware1 setStringValue:PCIDeviceFirmwareFoundError];
				else
					[S1Firmware2 setStringValue:PCIDeviceFirmwareFoundError];
			}
		}
	}
	if (!foundDevice) {
		if (sender1)
			[S1Firmware1 setStringValue:PCIDeviceFoundError];
		else
			[S1Firmware2 setStringValue:PCIDeviceFoundError];
	} else if (foundFirmware) {
		if (customValid && stockValid) {
			[S1Next setEnabled:YES];
		}
	}
	[pool release];
}
- (IBAction)S1Choose:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setTitle:@"Choose Firmware"];
	[panel setPrompt:@"Choose"];
	[panel setAllowedFileTypes:[NSArray arrayWithObject:@"ipsw"]];
	int returnCode = [panel runModal];
	if (returnCode==NSOKButton) {
		[S1Next setEnabled:NO];
		NSString *file = [[[panel URLs] objectAtIndex:0] path];
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:sender, PCISender, file, PCIFile, nil];
		[NSThread detachNewThreadSelector:@selector(detectFirmware:) toTarget:self withObject:info];
	}
}
- (IBAction)S1Next:(id)sender {
	[stepsView selectTabViewItem:[stepsView tabViewItemAtIndex:1]];
	[S2Progress setDoubleValue:0.0];
	[S2Progress startAnimation:self];
	[NSThread detachNewThreadSelector:@selector(extractAndPatch) toTarget:self withObject:nil];
}

- (void)extractAndPatch {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSFileManager *manager = [NSFileManager defaultManager];
	//Stock
	NSString *stockPath = [[PApplicationSupport stringByExpandingTildeInPath] stringByAppendingPathComponent:stockFirmwareMD5];
	if (![manager fileExistsAtPath:stockPath]) {
		if ([manager respondsToSelector:@selector(createDirectoryAtPath:attributes:)]) {
			[manager createDirectoryAtPath:stockPath attributes:nil];
		} else {
			[manager createDirectoryAtPath:stockPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
		
		[S2Status setStringValue:[NSString stringWithFormat:@"Extracting %@ Firmware", [stockFirmwareDic objectForKey:PBFVersion]]];
		if (![self unzip:stockFirmware toPath:PTMP]) {
			NSAlert *theAlert = [[NSAlert new] autorelease];
			[theAlert addButtonWithTitle:@"Quit"];
			[theAlert setMessageText:@"Error"];
			[theAlert setInformativeText:[NSString stringWithFormat:@"Firmware %@ was unable to be extracted", [stockFirmwareDic objectForKey:PBFVersion]]];
			[theAlert setAlertStyle:2];
			[theAlert runModal];
			if ([manager fileExistsAtPath:PTMP]) {
				if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
					[manager removeFileAtPath:PTMP handler:nil];
				} else {
					[manager removeItemAtPath:PTMP error:nil];
				}
			}
			[[NSApplication sharedApplication] terminate:self];
			return;
		}
		
		[S2Progress setDoubleValue:1.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Patching %@ Firmware", [stockFirmwareDic objectForKey:PBFVersion]]];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		double increasement = 1.0/(double)[[stockFirmwareDic objectForKey:PBFiles] count];
		for (int i=0; i<[[stockFirmwareDic objectForKey:PBFiles] count]; i++) {
			NSDictionary *file = [[stockFirmwareDic objectForKey:PBFiles] objectAtIndex:i];
			
			if (![[file objectForKey:PBPatch] isEqual:@""]) {
				[self xpwnDecrypt:[PTMP stringByAppendingPathComponent:[file objectForKey:PBPath]]
						  newFile:[stockPath stringByAppendingPathComponent:[file objectForKey:PBTarget]]
							  key:[file objectForKey:PBKey]
							   iv:[file objectForKey:PBIV]];
			}
			
			[S2Progress setDoubleValue:[S2Progress doubleValue]+increasement];
		}
		
		[S2Progress setDoubleValue:2.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Cleaning %@ Firmware", [stockFirmwareDic objectForKey:PBFVersion]]];
		if ([manager fileExistsAtPath:PTMP]) {
			if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
				[manager removeFileAtPath:PTMP handler:nil];
			} else {
				[manager removeItemAtPath:PTMP error:nil];
			}
		}
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	}
	
	//Custom
	NSString *customPath = [[PApplicationSupport stringByExpandingTildeInPath] stringByAppendingPathComponent:customFirmwareMD5];
	if (![manager fileExistsAtPath:customPath]) {
		if ([manager respondsToSelector:@selector(createDirectoryAtPath:attributes:)]) {
			[manager createDirectoryAtPath:customPath attributes:nil];
		} else {
			[manager createDirectoryAtPath:customPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
		
		[S2Progress setDoubleValue:3.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Extracting %@ Firmware", [customFirmwareDic objectForKey:PBFVersion]]];
		if (![self unzip:customFirmware toPath:PTMP]) {
			NSAlert *theAlert = [[NSAlert new] autorelease];
			[theAlert addButtonWithTitle:@"Quit"];
			[theAlert setMessageText:@"Error"];
			[theAlert setInformativeText:[NSString stringWithFormat:@"Firmware %@ was unable to be extracted", [customFirmwareDic objectForKey:PBFVersion]]];
			[theAlert setAlertStyle:2];
			[theAlert runModal];
			if ([manager fileExistsAtPath:PTMP]) {
				if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
					[manager removeFileAtPath:PTMP handler:nil];
				} else {
					[manager removeItemAtPath:PTMP error:nil];
				}
			}
			[[NSApplication sharedApplication] terminate:self];
			return;
		}
		
		[S2Progress setDoubleValue:4.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Patching %@ Firmware", [customFirmwareDic objectForKey:PBFVersion]]];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		double increasement = 1.0/(double)[[customFirmwareDic objectForKey:PBFiles] count];
		for (int i=0; i<[[customFirmwareDic objectForKey:PBFiles] count]; i++) {
			
			
			[S2Progress setDoubleValue:[S2Progress doubleValue]+increasement];
		}
		
		[S2Progress setDoubleValue:5.0];
		[S2Status setStringValue:[NSString stringWithFormat:@"Cleaning %@ Firmware", [customFirmwareDic objectForKey:PBFVersion]]];
		if ([manager fileExistsAtPath:PTMP]) {
			if ([manager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
				[manager removeFileAtPath:PTMP handler:nil];
			} else {
				[manager removeItemAtPath:PTMP error:nil];
			}
		}
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	}
	
	[S2Progress setDoubleValue:6.0];
	[S2Status setStringValue:@"Done"];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	[stepsView selectTabViewItem:[stepsView tabViewItemAtIndex:2]];
	
	[pool release];
}

//Utilities
- (BOOL)unzip:(NSString *)path toPath:(NSString *)toPath {
	BOOL result = YES;
	
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:@"/usr/bin/ditto"];
	[theTask setCurrentDirectoryPath:[@"~/" stringByExpandingTildeInPath]];
	[theTask setArguments:[NSArray arrayWithObjects:@"-xk", path, toPath, nil]];
	[theTask launch];
	[theTask waitUntilExit];
	result = ([theTask terminationStatus]==0);
	[theTask release];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	
	return result;
}

- (BOOL)xpwnDecrypt:(NSString *)file newFile:(NSString *)newFile key:(NSString *)key iv:(NSString *)iv {
	BOOL result = YES;
	
	NSTask* theTask = [[NSTask alloc] init];
	[theTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"xpwntool" ofType:nil]];
	[theTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	[theTask setArguments:[NSArray arrayWithObjects:file, newFile, @"-k", key, @"-iv", iv, nil]];
	[theTask launch];
	[theTask waitUntilExit];
	result = ([theTask terminationStatus] == 0);
	[theTask release];
	
	return result;
}
@end