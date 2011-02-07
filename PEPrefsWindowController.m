//
//  PEPrefsWindowController.m
//  WLoggerApp
//
//  Created by Per Ejeklint on 2010-11-17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PEPrefsWindowController.h"
#import "EMKeychainItem.h"
#import "DataKeys.h"
#import "RemoteProtocol.h"


@implementation PEPrefsWindowController

// Override to initialize
- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:nil];
	if (self != nil) {
		// Get connection to daemon and get its settings
		connection = [NSConnection connectionWithRegisteredName:KEY_REMOTE_CONNECTION_NAME host:nil];
		[connection setRequestTimeout:5.0];
		proxy = [[connection rootProxy] retain];
		[proxy setProtocolForProxy:@protocol(RemoteProtocol)];	
		
		settings = [proxy getSettings];
	}
	return self;
	
	(void)window;
}


- (void) dealloc
{
	[proxy release];
	[connection release];
	[super dealloc];
}


- (void)setupToolbar
{
	[self addView:generalPrefsView label:@"General"];
	[self addView:storagePrefsView label:@"Storage"];
	[self addView:twitterPrefsView label:@"Twitter"];
	[self addView:alarmsPrefsView label:@"Alarms"];
}


- (IBAction) validateCouchDB: (id) sender
{
	// Smart hack to make last edited text field save its value in case user didn't tab out from it
	[[sender window] makeFirstResponder:nil];
	[self performSelector:@selector(doValidate:) withObject:self afterDelay:0.1];
}


- (void) doValidate: (NSTimer*) timer
{
	if ([proxy setupCouchDB:settings] == NO) {
		// Bad values
		NSLog(@"Failed to set CouchDB settings");
	} else {
		NSLog(@"CouchDB settings saved");
	}
}
 

@end
