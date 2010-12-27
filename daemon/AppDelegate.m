

#import "AppDelegate.h"
#import "DataKeys.h"
#import "RemoteProtocol.h"
#import	"EMKeychainItem.h"

//#import <Growl/GrowlApplicationBridge.h>


@implementation AppDelegate


static BOOL gDebugPrint;


+ (BOOL) debugPrint {
	return gDebugPrint;
}


- (id) init {
	if ((self = [super init]))
	{
		gDebugPrint = NO;
		
		// Postpone the setup a few seconds to make sure other stuff is up and running
		[self performSelector:@selector(setup:) withObject:self afterDelay:1.0];
		
		return self;
	}
	return nil;
}


- (void) setup: (id) anObject {
	(void) anObject;

	ra = [[ReadingAssembler alloc] init];
	wmr100n = [[WMR100NDeviceController alloc] init];	
	
	// Set up remote objects connection
	serverConnection=[[NSConnection new] autorelease];
    [serverConnection setRootObject:self];
    [serverConnection registerName:KEY_REMOTE_CONNECTION_NAME];

	// Set up notifications
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];	
	[nc addObserver:self selector:@selector(readingListener:) name:@"Reading" object:nil];
	[nc addObserver:self selector:@selector(minuteReportListener:) name:@"MinuteReport" object:nil];
	[nc addObserver:self selector:@selector(statusReportListener:) name:@"StatusReport" object:nil];
	[nc addObserver:self selector:@selector(deviceAddedListener:) name:@"DeviceAdded" object:nil];
	[nc addObserver:self selector:@selector(deviceRemovedListener:) name:@"DeviceRemoved" object:nil];	
	
	// Hour chime timer. Shoot every hour, start at next whole hour
	NSTimeInterval since2001 = [[NSDate date] timeIntervalSinceReferenceDate];
	NSDate *nextHour = [NSDate dateWithTimeIntervalSinceReferenceDate: (int)(since2001 / 3600) * 3600 + 3600]; 
	
	myTickTimer = [[NSTimer alloc] initWithFireDate:nextHour interval:3600 target:self selector:@selector(hourChime:) userInfo:NULL repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:myTickTimer forMode:NSDefaultRunLoopMode];
	
	[self setupCouchDB:[self getSettings]];
	
	// Set up self as Growl delegate.
	//		[GrowlApplicationBridge setGrowlDelegate:self];
}


- (void) dealloc
{
	[myTickTimer invalidate];
	[myTickTimer release];
	[serverConnection release];
	[ra release];
	[wmr100n release];
	[db release];
	[couch release];
	[super release];
}


- (BOOL) setupCouchDB: (NSDictionary*) settings {	
	NSString *couchDBHost = [settings valueForKey:@"couchDBHost"];
	NSNumber *couchDBPort = [settings valueForKey:@"couchDBPort"];
	NSString *couchDBName = [settings valueForKey:@"couchDBName"];
	NSString *username = [settings valueForKey:@"couchDBUsername"];
	NSString *password = [settings valueForKey:@"couchDBPassword"];
	NSNumber *updateInterval = [settings valueForKey:@"couchDBUpdateInterval"];
	
	if ([couchDBHost length] == 0 || !couchDBPort)
		return NO;
	
	if ([password length] == 0) {
		password = [[EMGenericKeychainItem genericKeychainItemForService:@"CouchDB" withUsername:(NSString*)APP_ID] password];
	} else {
		[EMGenericKeychainItem addGenericKeychainItemForService:@"CouchDB" withUsername:(NSString*)APP_ID password:password];
	}
	
	NSString *hoststring;
	if ([username length] == 0 || [password length] == 0) {
		hoststring = couchDBHost;
	} else {
		hoststring = [NSString stringWithFormat:@"%@:%@@%@", username, password, couchDBHost];
	}
	
	SBCouchServer *tmpCouch = [[SBCouchServer alloc] initWithHost:hoststring port:[couchDBPort integerValue]];
	
	// Test if connection is ok
	if ([tmpCouch version] == nil) {
		NSLog(@"No CouchDB available at %@", [couch serverURLAsString]);
		return NO;
	}
	
	[self saveSettings:settings];
	
	int interval = [updateInterval intValue];
	if (interval < 1 || interval > 3600) {
		NSLog(@"No reasonable DB update interval found. Set it to 2 min");
		interval = 2; // Default value
	}
	
	// Sync globals
	[ra setInterval: interval];
	
	couch = tmpCouch;
	[couch createDatabase:couchDBName];
	db = [[couch database:couchDBName] retain];
	return YES;
}


- (void) hourChime: (NSTimer*) timer {
	CFBooleanRef temp = (CFBooleanRef) CFPreferencesCopyValue(CFSTR("enableCouchDB"), APP_ID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
	BOOL useCouchDB = (temp) ? CFBooleanGetValue(temp) : NO;
	if (useCouchDB == YES) {
		// Store status in db
		SBCouchDocument *storedReport = [db getDocument:KEY_DOC_STATUS withRevisionCount:NO andInfo:NO revision:nil];
		if (!storedReport) {
			storedReport = [[SBCouchDocument alloc] initWithNSDictionary:devicesStatus couchDatabase:db];
			[storedReport setObject:KEY_DOC_STATUS forKey:KEY_COUCH_ID];
		} else {
			[storedReport addEntriesFromDictionary:devicesStatus];
		}
		[storedReport setObject:KEY_DOC_STATUS forKey:KEY_DOC_DOCTYPE];
		SBCouchResponse *response =[db putDocument:storedReport named:KEY_DOC_STATUS];
		(void) response;
	}
	
	
	
	// Update twitter
//	CFBooleanRef temp = (CFBooleanRef) CFPreferencesCopyValue(CFSTR("useTwitter"), APP_ID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
//	BOOL twit = (temp) ? CFBooleanGetValue(temp) : NO;
//	if (twit)
//		[self updateTwitter];
}

// TODO: Make this GROWLY instead
//
// Update twitter with current readings
//
/*
- (void) updateTwitter {	
	NSMutableString *s = [NSMutableString stringWithCapacity:140];
	NSString *key = [NSString stringWithFormat:@"%@%d", KEY_TEMP_AND_HUM_READING_SENSOR_, 1];
	NSDictionary *tempOut = [weatherReport objectForKey:key];
	if (tempOut) {
		NSDictionary *d = [tempOut objectForKey:KEY_READINGS];
		[s appendFormat:@"Out: %.1f¡C/%d%% ",
		 [[d objectForKey:KEY_TEMP_OUTDOOR] doubleValue],
		 [[d objectForKey:KEY_HUMIDITY_OUTDOOR] intValue]
		];
	}
	
	tempOut = [weatherReport objectForKey:KEY_WIND_READING];
	if (tempOut) {
		NSDictionary *d = [tempOut objectForKey:KEY_READINGS];
		[s appendFormat:@"Wind: %d¡, gust %.1f m/s, avg %.1f\n",
		 [[d objectForKey:KEY_WIND_DIRECTION] intValue],
		 [[d objectForKey:KEY_WIND_AVERAGE] doubleValue],
		 [[d objectForKey:KEY_WIND_GUST] doubleValue]
		];
	}
	
	tempOut = [weatherReport objectForKey:KEY_UV_READING];
	if (tempOut) {
		NSDictionary *d = [tempOut objectForKey:KEY_READINGS];
		[s appendFormat:@"UV Index: %d ",
		 [[d objectForKey:KEY_UV_INDEX] intValue]
		];
	}
	
	tempOut = [weatherReport objectForKey:KEY_RAIN_READING];
	if (tempOut) {
		NSDictionary *d = [tempOut objectForKey:KEY_READINGS];
		[s appendFormat:@"Rain 24h: %d ",
		 [[d objectForKey:KEY_RAIN_24H] intValue]
		];
	}
	
	tempOut = [weatherReport objectForKey:KEY_BAROMETER_READING];
	if (tempOut) {
		NSDictionary *d = [tempOut objectForKey:KEY_READINGS];
		[s appendFormat:@"Baro: %d mbar Forecast: %@\n",
		 [[d objectForKey:KEY_BAROMETER_RELATIVE] intValue],
		 [d objectForKey:KEY_BAROMETER_ABSOLUTE_FORECAST_STRING]
		];
	}
	
	key = [NSString stringWithFormat:@"%@%d", KEY_TEMP_AND_HUM_READING_SENSOR_, 0];
	tempOut = [weatherReport objectForKey:key];
	if (tempOut) {
		NSDictionary *d = [tempOut objectForKey:KEY_READINGS];
		[s appendFormat:@"In: %.1f¡C/%d%% ",
		 [[d objectForKey:KEY_TEMP_INDOOR] doubleValue],
		 [[d objectForKey:KEY_HUMIDITY_INDOOR] intValue]
		];
	}
	

	if (DEBUGALOT)
		NSLog(@"Twitter string with %d chars:\n%@", [s length], s);

	[twitterEngine sendUpdate:s];
}
*/


//
// Notification listeners
//

- (void) readingListener:(NSNotification *)notification {	
	NSDictionary *userInfo = [notification userInfo];
	
	// Add a timestamp so we can sort out too old readings
	NSDate *now = [NSDate date];
	NSMutableDictionary *readingWithTimeStamp = [NSMutableDictionary dictionaryWithCapacity:2];
	[readingWithTimeStamp setObject:now forKey:KEY_TIMESTAMP];
	[readingWithTimeStamp setObject:[userInfo objectForKey:KEY_READINGS] forKey:KEY_READINGS];
	
	if (!currentConditions) {
		currentConditions = [NSMutableDictionary dictionaryWithCapacity:5];
	}
	[currentConditions setObject:readingWithTimeStamp forKey:[userInfo objectForKey:KEY_READING_TYPE]];
}

	
- (void) minuteReportListener:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	
	// Store report
	SBCouchDocument *storedReport = [[SBCouchDocument alloc] initWithNSDictionary:userInfo couchDatabase:db];
	[storedReport setObject:KEY_DOC_READINGS forKey:KEY_DOC_DOCTYPE];
	
	// Store all nested values in weatherReport
	for (id key in currentConditions) {
		// Check if not too old (should be younger than 120 seconds)
		NSDictionary *dict = [currentConditions objectForKey:key];
		NSDate *timestamp = (NSDate*) [dict objectForKey:KEY_TIMESTAMP];
		if ([timestamp timeIntervalSinceNow] < -120.0) {
			if (DEBUGALOT)
				NSLog(@"Discarding old report: %@", dict);
			continue;
		}
		[storedReport addEntriesFromDictionary:[dict objectForKey:KEY_READINGS]];
	}
	
	CFBooleanRef temp = (CFBooleanRef) CFPreferencesCopyValue(CFSTR("enableCouchDB"), APP_ID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
	BOOL useCouchDB = (temp) ? CFBooleanGetValue(temp) : NO;
	if (useCouchDB == YES) {
		[storedReport put];
	}
}


- (void) statusReportListener:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	
	[devicesStatus addEntriesFromDictionary:userInfo];
}


- (void)deviceAddedListener:(NSNotification *)notification {
	(void) notification;
	
	NSLog(@"Weather station plugged in");
	
	devicesStatus = [NSMutableDictionary dictionaryWithCapacity:5];
	currentConditions = [NSMutableDictionary dictionaryWithCapacity:5];

	NSDictionary *settings = [self getSettings];
	
	[self setupCouchDB:settings];
	
/*	
	[GrowlApplicationBridge
	 notifyWithTitle:@"Base unit connected"
	 description:@"The weather station has been connected. Weather reporting will start."
	 notificationName:@"Base unit connected"
	 iconData:nil
	 priority:0
	 isSticky:NO
	 clickContext:nil]; */
}


- (void) deviceRemovedListener: (NSNotification *)notification {
	(void) notification;
	
	NSLog(@"Weather station removed");

	// Stop twittering if it's on
	if (myTickTimer) {
		[myTickTimer invalidate];
		[myTickTimer release];
		myTickTimer = NULL;
	}
	
	// Remove ongoing report and reset minute cycle count
	if (currentConditions) {
		[currentConditions release];
		currentConditions = nil;
	}
	if (devicesStatus) {
		[devicesStatus release];
		devicesStatus= nil;
	}
	
/*	[GrowlApplicationBridge
	 notifyWithTitle:@"Base unit disconnected"
	 description:@"The weather station has been disconnected. Weather reporting will suspend until it is connected again."
	 notificationName:@"Base unit disconnected"
	 iconData:nil
	 priority:2
	 isSticky:NO
	 clickContext:nil]; */
}


// Growl delegate methods
/*
- (NSDictionary*) registrationDictionaryForGrowl {
	NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
	NSArray *a = [[NSArray alloc] initWithObjects: @"Battery warning", @"Base unit disconnected", @"Base unit connected", @"Power loss", @"Notification", @"Internal error", nil];
	[d setObject:a forKey:GROWL_NOTIFICATIONS_ALL];
	[d setObject:a forKey:GROWL_NOTIFICATIONS_DEFAULT];
	[d setObject:@"WLogger" forKey:GROWL_APP_ID];
	return d;
}

- (NSString *) applicationNameForGrowl {
	return @"Cloudya";
}
*/


#pragma mark Remote Objects methods BEGIN

- (BOOL) setDebug: (NSNumber*) debug {
	gDebugPrint = [debug boolValue];
	NSLog(@"Debug log set to %@", (gDebugPrint) ? @"YES" : @"NO");
	return gDebugPrint;
}


- (NSDictionary *) getSettings {
	CFArrayRef aref = CFPreferencesCopyKeyList(APP_ID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
	CFDictionaryRef dref = CFPreferencesCopyMultiple(aref, APP_ID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
	return (NSDictionary*) dref;
}

- (NSDictionary *) getLevels {
	return [NSDictionary dictionaryWithDictionary:devicesStatus];
}

- (NSDictionary *) getCurrentConditions
{
	return [NSDictionary dictionaryWithDictionary:currentConditions];
}


- (BOOL) saveSettings: (NSDictionary *) settings {
	for (id key in settings) {
		CFPreferencesSetValue((CFStringRef)key, [settings objectForKey:key], APP_ID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
	}
	// Save to disk
	CFPreferencesSynchronize(APP_ID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
	
	return YES;
}

#pragma mark Remote Objects methods END

@end
