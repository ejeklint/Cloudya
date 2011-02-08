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
#import <QuartzCore/QuartzCore.h>


@implementation PEWeatherWindowController


- (void) awakeFromNib {
	[window makeKeyAndOrderFront:nil];

	// Make wind image rotatable with CAAnimation
	[[windImageView superview] setWantsLayer:YES];

    // Must change anchor point to get centre rotation, it defaults to 0.0,0.0
    windImageView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    // Adjust position so image won't move when changing anchor point
	CGPoint position = windImageView.layer.position;
	CGRect bounds = windImageView.bounds;
	position.x += (0.5 * bounds.size.width);
	position.y += (0.5 * bounds.size.height);
    windImageView.layer.position = position;
    
    previousWindAngle = 0.0;
	
	
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
	NSDictionary *data = [dict objectForKey:KEY_READINGS];
	NSString *pressure = [data objectForKey:KEY_BAROMETER_ABSOLUTE];
	NSString *forecast = [data objectForKey:KEY_BAROMETER_ABSOLUTE_FORECAST_STRING];
	NSString *s = [NSString stringWithFormat:@"%@ mBar", pressure];
	[self setImageForCondition:forecast];
	[baroDataView setStringValue:s];
}

- (void) setOutdoorData: (NSDictionary*) dict
{
	NSDictionary *data = [dict objectForKey:KEY_READINGS];
	NSString *hum = [data objectForKey:KEY_HUMIDITY_OUTDOOR];
	NSString *temp = [data objectForKey:KEY_TEMP_OUTDOOR];
	NSString *chill = [data objectForKey:KEY_WIND_CHILL];
	if ([chill length] != 0)
		temp = [NSString stringWithFormat:@"%@°C\n%@°C (wind chill)", [data objectForKey:KEY_TEMP_OUTDOOR], chill];
	else
		temp = [NSString stringWithFormat:@"%@°C", temp];
	NSString *s = [NSString stringWithFormat:@"%@\n%@%%", temp, hum];
	[outdoorDataView setStringValue:s];
}


- (void) setIndoorData: (NSDictionary*) dict
{
	NSDictionary *data = [dict objectForKey:KEY_READINGS];
	NSString *temp = [data objectForKey:KEY_TEMP_INDOOR];
	NSString *hum = [data objectForKey:KEY_HUMIDITY_INDOOR];
	NSString *s = [NSString stringWithFormat:@"%@°C\n%@%%", temp, hum];
	[indoorDataView setStringValue:s];
}


CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};


- (CABasicAnimation*) makeRotateAnimationFrom: (float) fromValue to: (float) toValue
{
    float adjustedToValue = toValue;
    if (fromValue >= 180.0 && toValue == 0)
        adjustedToValue = 360.0;
    else if (fromValue == 0 && toValue > 180.0)
        adjustedToValue = toValue - 360;
	
    CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
	rotate.fromValue = [NSNumber numberWithFloat:DegreesToRadians(-1.0 * fromValue)];
	rotate.toValue = [NSNumber numberWithFloat:DegreesToRadians(-1.0 * adjustedToValue)];
	rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    rotate.removedOnCompletion = NO;
    rotate.fillMode = kCAFillModeForwards;
	rotate.duration = 0.5;
	return rotate;
}


- (void) setWindData: (NSDictionary*) dict
{
	NSDictionary *data = [dict objectForKey:KEY_READINGS];
	NSString *direction = [data objectForKey:KEY_WIND_DIRECTION];
	NSString *gust = [data objectForKey:KEY_WIND_GUST];
	NSString *average = [data objectForKey:KEY_WIND_AVERAGE];
	
	NSString *s = [NSString stringWithFormat:@"%@ m/s avg.\n%@ m/s gust", average, gust];
	[windDataView setStringValue:s];
    
	// Rotate wind image
    float toWindAngle = [direction floatValue];
    if (previousWindAngle == toWindAngle)
        return;
    
    NSLog(@"Rotating to: %f", toWindAngle);
    CABasicAnimation *rotate = [self makeRotateAnimationFrom: previousWindAngle to: toWindAngle];
    [[windImageView layer] addAnimation:rotate forKey:@"rotate"];
    
    previousWindAngle = toWindAngle;
}


- (void) updateValues: (NSTimer *) timer
{
	NSDictionary *conditions = [NSMutableDictionary dictionaryWithDictionary: [proxy getCurrentConditions]];
	
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
