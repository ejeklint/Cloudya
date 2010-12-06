//
//  PEWeatherWindowController.h
//  WLoggerApp
//
//  Created by Per Ejeklint on 2010-11-23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PEWeatherWindowController : NSObject {
	IBOutlet NSWindow * window;
	IBOutlet NSImageView * weatherImageView;
	IBOutlet NSImageView * windImageView;
	
	IBOutlet NSTextView * outdoorDataView;
	IBOutlet NSTextView * indoorDataView;
	IBOutlet NSTextView * windDataView;
	IBOutlet NSTextView * baroDataView;

	NSConnection *connection;
	id proxy;
	NSTimer *timer;
}


@end
