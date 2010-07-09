//
//  PneumoniaAppDelegate.m
//  Pneumonia
//
//  Created by GreySyntax on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import "Utilities.h"
#import "PneumoniaAppDelegate.h"

NSString * const PDocuments = @"~/Documents/";

@implementation PneumoniaAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	printf("Pneumonia - Copyright NSPwn.com - Application by GreySyntax & GRMrGecko\n\n");
	devicesDict = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Bundles" ofType:@"plist"]] retain];
}
- (void)dealloc {
	if (devicesDict!=nil)
		[devicesDict release];
	if (deviceDict!=nil)
		[deviceDict release];
	[super dealloc];
}

- (void)setDevice:(NSString*)model {
	if (deviceDict!=nil) [deviceDict release];
	deviceDict = [[devicesDict objectForKey:model] retain];
}

- (BOOL)processDict {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	//NSDictionary *OS3 = [deviceDict objectForKey:@"7D11"];
	//NSDictionary *OS4 = [deviceDict objectForKey:@"8A293"];
	
	BOOL sumValid = NO;
	BOOL extracted = NO;
	
	NSArray *deviceKeys = [deviceDict allKeys];
	for (int i=0; i<[deviceKeys count]; i++) {
		NSDictionary *bundleDict = [deviceDict objectForKey:[deviceKeys objectAtIndex:i]];
		NSArray *required = [bundleDict objectForKey:@"required"];
		for (int r=0; r<[required count]; r++) {
			NSDictionary *tempDict = [required objectAtIndex:r];
			BOOL exists = [fileManager isReadableFileAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[tempDict objectForKey:@"target"]]];
			//Create
			if (! exists) {
				
				NSLog(@"Failed to locate required file, attempting to generate.");
				
				BOOL package = [fileManager isReadableFileAtPath:[[PDocuments stringByExpandingTildeInPath] stringByAppendingPathComponent:[bundleDict objectForKey:@"file"]]];
				if (!package) {
					NSLog(@"Failed to locate firmware bundle");
					
					[Utilities createAlert:@"Firmware not found" info:[NSString stringWithFormat:@"Failed to locate \"%@\" please plave the file in your Documents folder and try again", [tempDict objectForKey:@"file"]] window:mainWindow];
					
					return NO;
				}
				
				//md5sum bundle 
				if (! sumValid) {
					BOOL shouldMatch = [[bundleDict objectForKey:@"md5_validates"] boolValue];
					NSString *expected = [bundleDict objectForKey:@"md5_sum"];
					NSString *actual = [Utilities fileMD5:[[PDocuments stringByExpandingTildeInPath] stringByAppendingPathComponent:[bundleDict objectForKey:@"file"]]];
					
					if ((expected == actual) && shouldMatch) {
						
						[Utilities createAlert:@"Failed to validate ipsw" info:[NSString stringWithFormat:@"Failed to validate \"%@\"", [bundleDict objectForKey:@"file"]] window:mainWindow];
						
						return NO;
					}
					sumValid = YES;
					
					[expected release];
					[actual release];
				}
				//extract to /tmp/nspwn_ipsw
				if (! extracted) {
					if (! [Utilities unzip:[[PDocuments stringByExpandingTildeInPath] stringByAppendingPathComponent:[bundleDict objectForKey:@"file"]] toPath:@"/tmp/nspwn_ipsw"]) {
						
						[Utilities createAlert:@"Failed to extract ipsw" info:[NSString stringWithFormat:@"Failed to extract \"%@\"", [[PDocuments stringByExpandingTildeInPath] stringByAppendingPathComponent:[bundleDict objectForKey:@"file"]]] window:mainWindow];
						
						return NO;
					}
					extracted = YES; 
				}
				
				//copy file, decrypt, save
				NSString *grab = [@"/tmp/nspwn_ipswn" stringByAppendingPathComponent:[tempDict objectForKey:@"file"]];
				BOOL decrypt = [[tempDict objectForKey:@"decrypt"] boolValue];
				BOOL patch = [[tempDict objectForKey:@"patch"] boolValue];
				
				if (decrypt) {
					//use xpwn-tool to decrypt using iv & key
					BOOL state = [Utilities xpwnDecrypt:grab 
												 toPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:[tempDict objectForKey:@"file"]]
													key:[tempDict objectForKey:@"key"]
													 iv:[tempDict objectForKey:@"iv"]
								  ];
					
					if (! state) { //Failed to decrypt :(
						
						[Utilities createAlert:@"Failed to decrypt file"
									 info:[NSString stringWithFormat:@"Failed to decrypt \"%@\" using xpwntool", [tempDict objectForKey:@"file"]]
						 ];
						
						return NO;
					}
				}
				
				if (patch) {
					//use bspatch on the ipsw
				}
			}
		}
		
		if ([fileManager isReadableFileAtPath:@"/tmp/nspwn_ipsw"]) {
			//remove file
			NSError *error;
			if ([fileManager respondsToSelector:@selector(removeFileAtPath:handler:)]) {
				if (![fileManager removeFileAtPath:@"/tmp/nspwn_ipsw" handler:nil]) {
					[Utilities createAlert:@"Failed to remove temp files" info:@"Failed to remove the \"/tmp/nspwn_ipsw\"" window:mainWindow];
					return NO;
				}
			} else {
				if (![fileManager removeItemAtPath:@"/tmp/nspwn_ipsw" error:&error]) {
					NSLog(@"Failed to remove \"/tmp/nspwn_ipsw\" error: %@", error);
					[Utilities createAlert:@"Failed to remove temp files" info:@"Failed to remove the \"/tmp/nspwn_ipsw\"" window:mainWindow];
					return NO;
				}
			}
			
		}
	}
	
	return YES;
}

- (void)bootDevice {
	//Process dictionary
	if (![self processDict]) {
		return;
	}
}

- (IBAction)boot3GS:(id)sender {
	
	[status setTitleWithMnemonic:@"Waitingaasdasdas."];
	[boot3gs setEnabled:NO];
	[restore3gs setEnabled:NO];
	
	func_reset = @selector(reset3GS);
	[self setDevice:@"iPhone2,1"];
	[self bootDevice];
	
}

- (IBAction)restore3GS:(id)sender {
	//stub
}
- (IBAction)restore2G:(id)sender {
	
}
- (IBAction)restore3G:(id)sender {
	
}

- (IBAction)boot2G:(id)sender {
	//stub
}

- (IBAction)boot3G:(id)sender {
	//stub
}

- (BOOL)extractIPSW:(NSString*)path {
	return NO;
}

- (void)reset3GS {
	[boot3gs setEnabled:YES];
	[restore3gs setEnabled:YES];
	[status setTitleWithMnemonic:@"Waiting..."];
}
@end
