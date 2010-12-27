//
//  PEPrefsWindowController.h
//  WLoggerApp
//
//  Created by Per Ejeklint on 2010-11-17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"

@interface PEPrefsWindowController : DBPrefsWindowController {
	IBOutlet NSView *generalPrefsView;
	IBOutlet NSView *storagePrefsView;
	
	NSDictionary *settings;
	NSConnection *connection;
	id proxy;
}

- (IBAction) validateCouchDB: (id) sender;

@end
