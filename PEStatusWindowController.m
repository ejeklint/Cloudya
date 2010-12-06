//
//  PEStatusWindowController.m
//  WLoggerApp
//
//  Created by Per Ejeklint on 2010-11-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PEStatusWindowController.h"
#import "RemoteProtocol.h"
#import "DataKeys.h"


@implementation PEStatusWindowController

- (void) awakeFromNib {
	[window makeKeyAndOrderFront:nil];
	
	// Set connection to daemon and get its settings
	connection = [NSConnection connectionWithRegisteredName:KEY_REMOTE_CONNECTION_NAME host:nil];
	[connection setRequestTimeout:5.0];
	proxy = [[connection rootProxy] retain];
	[proxy setProtocolForProxy:@protocol(RemoteProtocol)];
	
	// Get current status from daemon now
	[self updateValues:nil];
	
	// Set timer for regular updates as long as window is open
	timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateValues:) userInfo:NULL repeats:YES];
}

- (BOOL) windowShouldClose:(id)sender
{
	[timer invalidate];
	[connection invalidate];
	return YES;
}


- (IBAction)debugClicked:(id)sender {
	// Immediatey change log settings
    [proxy setDebug:[NSNumber numberWithBool:[sender state]]];
}


- (void) updateValues: (NSTimer *) timer
{
	NSDictionary *levels = [NSMutableDictionary dictionaryWithDictionary: [proxy getLevels]];
	
	if (!levels)
		return;
	
	NSString *l = [levels objectForKey:KEY_LEVEL_RAIN];
	if (l) {
		[rainBatteryIndicator setIntValue:([l isEqualToString:@"high"] == TRUE ) ? 2 : 1];
		[rainLabel setTextColor:[NSColor blackColor]];
	} else {
		[rainBatteryIndicator setIntValue:0];
		[rainLabel setTextColor:[NSColor grayColor]];
	}
	
	l = [levels objectForKey:KEY_LEVEL_WIND];
	if (l) {
		[windBatteryIndicator setIntValue:([l isEqualToString:@"high"] == TRUE ) ? 2 : 1];
		[windLabel setTextColor:[NSColor blackColor]];
	} else {
		[windBatteryIndicator setIntValue:0];
		[windLabel setTextColor:[NSColor grayColor]];
	}
	
	l = [levels objectForKey:[NSString stringWithFormat:@"%@1", KEY_LEVEL_SENSOR_]];
	if (l) {
		[outdoorTempBatteryIndicator setIntValue:([l isEqualToString:@"high"] == TRUE ) ? 2 : 1];
		[outdoorLabel setTextColor:[NSColor blackColor]];
	} else {
		[outdoorTempBatteryIndicator setIntValue:0];
		[outdoorLabel setTextColor:[NSColor grayColor]];
	}
	
	l = [levels objectForKey:[NSString stringWithFormat:@"%@0", KEY_LEVEL_SENSOR_]];
	if (l) {
		[indoorTempBatteryIndicator setIntValue:([l isEqualToString:@"high"] == TRUE ) ? 2 : 1];
		[indoorLabel setTextColor:[NSColor blackColor]];
	} else {
		[indoorTempBatteryIndicator setIntValue:0];
		[indoorLabel setTextColor:[NSColor grayColor]];
	}
	
	l = [levels objectForKey:KEY_LEVEL_UV];
	if (l) {
		[uvBatteryIndicator setIntValue:([l isEqualToString:@"high"] == TRUE ) ? 2 : 1];
		[uvLabel setTextColor:[NSColor blackColor]];
	} else {
		[uvBatteryIndicator setIntValue:0];
		[uvLabel setTextColor:[NSColor grayColor]];
	}
	
	NSNumber *n = [levels objectForKey:KEY_RADIO_CLOCK_SYNC];
	if (n) {
		[clockSynkIndicator setIntValue:[n integerValue]];
		[clockSynkLabel setTextColor:[NSColor blackColor]];
	} else {
		[clockSynkIndicator setIntValue:0];
		[clockSynkLabel setTextColor:[NSColor grayColor]];
	}
	l = [levels objectForKey:KEY_POWER_BASE];
	if (l) {
		[basePowerIndicator setState:([l boolValue] ? NSOnState : NSOffState)];
//		[basePowerLabel setTextColor:[NSColor blackColor]];
	} else {
		[basePowerIndicator setState:NSOffState];
		[basePowerIndicator setEnabled:NO];
//		[basePowerLabel setTextColor:[NSColor grayColor]];
	}

}

@end
