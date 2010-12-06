//
//  PEWeatherWindowController.m
//  WLoggerApp
//
//  Created by Per Ejeklint on 2010-11-23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PEWeatherWindowController.h"
#import "RemoteProtocol.h"
#import "DataKeys.h"


@implementation PEWeatherWindowController


- (void) awakeFromNib {
	[window makeKeyAndOrderFront:nil];
	// Assert that TextViews are transparent
	[outdoorDataView setDrawsBackground:NO];
	[[outdoorDataView enclosingScrollView] setDrawsBackground:NO];
	[indoorDataView setDrawsBackground:NO];
	[[indoorDataView enclosingScrollView] setDrawsBackground:NO];
	[windDataView setDrawsBackground:NO];
	[[windDataView enclosingScrollView] setDrawsBackground:NO];
	[baroDataView setDrawsBackground:NO];
	[[baroDataView enclosingScrollView] setDrawsBackground:NO];
	
	// Make wind image rotatable (not sure if it's really needed)
	[[windImageView superview] setWantsLayer:YES];
	
	// Set connection to daemon and get its settings
	connection = [NSConnection connectionWithRegisteredName:KEY_REMOTE_CONNECTION_NAME host:nil];
	[connection setRequestTimeout:5.0];
	proxy = [[connection rootProxy] retain];
	[proxy setProtocolForProxy:@protocol(RemoteProtocol)];
	
	// Tick-tock
	timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateValues:) userInfo:NULL repeats:YES];
}


- (BOOL) windowShouldClose:(id)sender
{
	[timer invalidate];
	[connection invalidate];
	return YES;
}


- (void) setImageForCondition: (NSString*) condition
{
	if (!condition)
		return;
	
	NSString *conditionImage = [NSString stringWithFormat:@"%@.png", condition];
	[weatherImageView setImage:[NSImage imageNamed:conditionImage]];
}


- (void) setBarometerData: (NSDictionary*) dict
{
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								[NSFont fontWithName:@"Helvetica-Bold" size:18], NSFontAttributeName,
								[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	[baroDataView setTypingAttributes:attributes];
	NSDictionary *data = [dict objectForKey:KEY_READINGS];
	NSString *pressure = [data objectForKey:KEY_BAROMETER_ABSOLUTE];
	NSString *forecast = [data objectForKey:KEY_BAROMETER_ABSOLUTE_FORECAST_STRING];
	NSString *s = [NSString stringWithFormat:@"%@ mBar", pressure];
	[self setImageForCondition:forecast];
	[baroDataView setString:s];
}

- (void) setOutdoorData: (NSDictionary*) dict
{
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								[NSFont fontWithName:@"Helvetica-Bold" size:36], NSFontAttributeName,
								[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	[outdoorDataView setTypingAttributes:attributes];
	NSDictionary *data = [dict objectForKey:KEY_READINGS];
	NSString *temp = [data objectForKey:KEY_TEMP_OUTDOOR];
	NSString *hum = [data objectForKey:KEY_HUMIDITY_OUTDOOR];
	NSString *s = [NSString stringWithFormat:@"%@°C\n%@%%", temp, hum];
	[outdoorDataView setString:s];
}


- (void) setIndoorData: (NSDictionary*) dict
{
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								[NSFont fontWithName:@"Helvetica-Bold" size:36], NSFontAttributeName,
								[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	[indoorDataView setTypingAttributes:attributes];
	NSDictionary *data = [dict objectForKey:KEY_READINGS];
	NSString *temp = [data objectForKey:KEY_TEMP_INDOOR];
	NSString *hum = [data objectForKey:KEY_HUMIDITY_INDOOR];
	NSString *s = [NSString stringWithFormat:@"%@°C\n%@%%", temp, hum];
	[indoorDataView setString:s];
}

- (void) setWindData: (NSDictionary*) dict
{
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
								[NSFont fontWithName:@"Helvetica-Bold" size:18], NSFontAttributeName,
								[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	[windDataView setTypingAttributes:attributes];
	
	NSDictionary *data = [dict objectForKey:KEY_READINGS];
	NSString *direction = [data objectForKey:KEY_WIND_DIRECTION];
	NSString *gust = [data objectForKey:KEY_WIND_GUST];
	NSString *average = [data objectForKey:KEY_WIND_AVERAGE];
	
	NSString *s = [NSString stringWithFormat:@"%@ m/s avg.\n%@ m/s gust", average, gust];
	[windDataView setString:s];
	
	// Rotate wind
	[windImageView setFrameCenterRotation: -1.0 * [direction floatValue]];
}

- (void) updateValues: (NSTimer *) timer
{
	// TODO
	NSDictionary *conditions = [NSMutableDictionary dictionaryWithDictionary: [proxy getCurrentConditions]];
	NSLog(@"Current conditions from daemon: %@", conditions);
	
	if (!conditions)
		return;
	
	NSString *key = [NSString stringWithFormat:@"%@%d", KEY_TEMP_AND_HUM_READING_SENSOR_, 1];
	NSDictionary *outdoor = [conditions objectForKey:key];
	if (outdoor) {
		[self setOutdoorData:outdoor];
	}
	
	key = [NSString stringWithFormat:@"%@%d", KEY_TEMP_AND_HUM_READING_SENSOR_, 0];
	NSDictionary *indoor = [conditions objectForKey:key];
	if (indoor) {
		[self setIndoorData:indoor];
	}
	
	NSDictionary *baro = [conditions objectForKey:KEY_BAROMETER_READING];
	if (baro) {
		[self setBarometerData:baro];
	}	
	
	NSDictionary *wind = [conditions objectForKey:KEY_WIND_READING];
	if (wind) {
		[self setWindData:wind];
	}	
}



@end
