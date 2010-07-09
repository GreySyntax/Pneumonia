//
//  PneumoniaAppDelegate.m
//  Pneumonia
//
//  Created by GreySyntax on 08/07/2010.
//  Copyright 2010 NSPwn. All rights reserved.
//

#import "Utilities.h"
#import "PneumoniaAppDelegate.h"

#define DEST_PATH	[NSHomeDirectory() stringByAppendingString:@"/Documents/"]

@implementation PneumoniaAppDelegate

@synthesize window, fileManager, documents, resources, device, func_reset, deviceDict, bundles, boot3gs, restore3gs;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	NSLog(@"Pneumonia - Copyright NSPwn.com - Application by GreySyntax");
	fileManager = [[NSFileManager defaultManager] init];
	documents = [NSString stringWithFormat:@"%@", DEST_PATH]; //Thanks to DarkMalloc
	resources = [[NSBundle mainBundle] resourcePath];
	bundles = [[NSBundle mainBundle] pathForResource:@"Bundles" ofType:@"plist"];
	
	[fileManager retain];
	[documents retain];
	[resources retain];
	[bundles retain];
}

- (void) createAlert:(NSString *)message info:(NSString *)info setAlertStyle:(NSAlertStyle)style {
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	[alert addButtonWithTitle:@"OK"];
	[alert setInformativeText:info];
	[alert setMessageText:message];
	[alert setAlertStyle:style];
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(buttonDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void) buttonDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	if(returnCode == NSAlertFirstButtonReturn) {
		//[self resetButton];
	}
}

- (void)loadDeviceDictionary:(NSString*)model {
	
	deviceDict = [[NSDictionary dictionaryWithContentsOfFile:bundles] objectForKey:model];
	[deviceDict retain];
}

- (BOOL)processDict {
	
	NSDictionary *OS3 = [deviceDict objectForKey:@"7D11"];
	NSDictionary *OS4 = [deviceDict objectForKey:@"8A293"];
	
	BOOL sumValid = NO;
	BOOL extracted = NO;
	
	for (NSDictionary *bundleDict in deviceDict) {
		
		for (NSDictionary *tempDict in [bundleDict objectForKey:@"required"]) {
			
			BOOL exists = [fileManager isReadableFileAtPath:[resources stringByAppendingFormat:@"/%@", [tempDict objectForKey:@"target"]]];
			
			//Create
			if (! exists) {
				
				NSLog(@"Failed to locate required file, attempting to generate.");
				
				BOOL package = [fileManager isReadableFileAtPath:[documents stringByAppendingString:[OS3 objectForKey:@"file"]]];
				if (! package) {
					NSLog(@"Failed to locate firmware bundle");
					
					[self createAlert:@"Firmware not found"
								 info:[NSString stringWithFormat:@"Failed to locate \"%@\" please plave the file in your Documents folder and try again",
									   [tempDict objectForKey:@"file"]]
						setAlertStyle:NSWarningAlertStyle
					 ];
					
					return NO;
				}
				
				//md5sum bundle 
				if (! sumValid) {
					BOOL shouldMatch = [OS3 valueForKey:@"md5_validates"];
					NSString *expected = [OS3 objectForKey:@"md5_sum"];
					NSString *actual = [Utilities fileMD5:[documents stringByAppendingString:[OS3 objectForKey:@"file"]]];
					
					if ((expected == actual) == shouldMatch) {
						
						[self createAlert:@"Failed to validate ipsw"
									 info:[NSString stringWithFormat:@"Failed to validate \"%@\"", [tempDict objectForKey:@"file"]] 
							setAlertStyle:NSWarningAlertStyle
						 ];
						
						return NO;
					}
					sumValid = YES;
					
					[expected release];
					[actual release];
				}
				//extract to /tmp/nspwn_ipsw
				if (! extracted) {
					if (! [Utilities unzip:[documents stringByAppendingString:[OS3 objectForKey:@"file"]] toPath:@"/tmp/nspwn_ipsw"]) {
						
						[self createAlert:@"Failed to extract ipsw"
									 info:[NSString stringWithFormat:@"Failed to extract \"%@\"", [documents stringByAppendingString:[OS3 objectForKey:@"file"]]]
							setAlertStyle:NSWarningAlertStyle
						 ];
						
						return NO;
					}
					extracted = YES; 
				}
				
				//copy file, decrypt, save
				NSString *grab = [@"/tmp/nspwn_ipswn" stringByAppendingString:[tempDict objectForKey:@"file"]];
				BOOL decrypt = [tempDict objectForKey:@"decrypt"];
				BOOL patch = [tempDict objectForKey:@"patch"];
				
				if (decrypt) {
					//use xpwn-tool to decrypt using iv & key
				}
				
				if (patch) {
					//use bspatch on the ipsw
				}
			}
		}
		
		if ([fileManager isReadableFileAtPath:@"/tmp/nspwn_ipsw"]) {
			//remove file
			NSError *error;
			if (! [fileManager removeItemAtPath:@"/tmp/nspwn_ipsw" error:&error]) {
				NSLog(@"Failed to remove \"/tmp/nspwn_ipsw\" error: %@", error);
				[self createAlert:@"Failed to remove temp files"
							 info:@"Failed to remove the \"/tmp/nspwn_ipsw\""
					setAlertStyle:NSWarningAlertStyle
				 ];
				
				return NO;
			}
		}
	}
	
	return YES;
}

- (void)bootDevice {
	
	//Process dictionary
	if (! [self processDict]) {
		return;
	}
}

- (IBAction)boot3GS:(id)sender {
	
	[status setTitleWithMnemonic:@"Waitingaasdasdas."];
	[boot3gs setEnabled:NO];
	[restore3gs setEnabled:NO];
	
	func_reset = @selector(reset3GS);
	[self loadDeviceDictionary:@"iPhone2,1"];
	[self bootDevice];
	
}

- (IBAction)restore3GS:(id)sender {
	//stub
}

- (IBAction)boot2G:(id)sender {
	//stub
}

- (IBAction)boot3G:(id)sender {
	//stub
}

- (void)reset3GS {
	[boot3gs setEnabled:YES];
	[restore3gs setEnabled:YES];
	[status setTitleWithMnemonic:@"Waiting..."];
}

//- (void)
@end
