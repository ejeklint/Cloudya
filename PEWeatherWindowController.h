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
	
	IBOutlet NSTextField * outdoorDataView;
	IBOutlet NSTextField * indoorDataView;
	IBOutlet NSTextField * windDataView;
	IBOutlet NSTextField * baroDataView;
	
	IBOutlet NSSlider * rotate;
	float previousValue;

	NSConnection *connection;
	id proxy;
	NSTimer *timer;
}


@end
