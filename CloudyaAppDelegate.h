//
//  CloudyaAppDelegate.h
//  Cloudya
//
//  Created by Per Ejeklint on 2010-11-14.
//  Copyright 2010. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CloudyaAppDelegate : NSObject <NSApplicationDelegate> {
	NSMutableDictionary *settings;
	NSConnection *connection;
	id proxy;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction) openPreferencesWindow:(id)sender;
- (IBAction) showHelp:(id) sender;
- (IBAction) toggleWeatherWindow:(id) sender;
- (IBAction) toggleStatusWindow:(id) sender;

@end
