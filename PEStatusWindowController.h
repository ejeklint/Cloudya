//
//  PEStatusWindowController.h
//  WLoggerApp
//
//  Created by Per Ejeklint on 2010-11-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PEStatusWindowController : NSObject {
	IBOutlet NSWindow * window;

	IBOutlet NSTextField *rainLabel;
	IBOutlet NSLevelIndicator *rainBatteryIndicator;
	IBOutlet NSTextField *windLabel;
	IBOutlet NSLevelIndicator *windBatteryIndicator;
	IBOutlet NSTextField *outdoorLabel;
	IBOutlet NSLevelIndicator *outdoorTempBatteryIndicator;
	IBOutlet NSTextField *indoorLabel;
	IBOutlet NSLevelIndicator *indoorTempBatteryIndicator;
	IBOutlet NSTextField *uvLabel;
	IBOutlet NSLevelIndicator *uvBatteryIndicator;
	IBOutlet NSProgressIndicator *spinner;
	IBOutlet NSTextField *clockSynkLabel;
	IBOutlet NSLevelIndicator *clockSynkIndicator;
	IBOutlet NSTextField *basePowerLabel;
	IBOutlet NSButton *basePowerIndicator;
	
	NSConnection *connection;
	id proxy;
	NSTimer *timer;
}

- (IBAction) debugClicked: (id) sender;

@end
