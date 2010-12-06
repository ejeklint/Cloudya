//
//  CloudyaAppDelegate.m
//  WLoggerApp
//
//  Created by Per Ejeklint on 2010-11-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CloudyaAppDelegate.h"
#import "RemoteProtocol.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import "PEPrefsWindowController.h"

@implementation CloudyaAppDelegate

//@synthesize window;

+ (void)initialize
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:@"YES"
															forKey:@"MsgAtStartup"];
	[userDefaults registerDefaults:appDefaults];
}

- (BOOL) toolNeedsUpgrade: (NSString *) label {
	NSString *embeddedToolPath = [[NSString alloc] initWithFormat:@"file://%@/Contents/Library/LaunchServices/%@",
								  [[NSBundle mainBundle] bundlePath],
								  label];
	
	NSString *installedToolPath = [[NSString alloc] initWithFormat:@"file:///Library/PrivilegedHelperTools/%@", label];
	NSURL *installedURL = [NSURL URLWithString:installedToolPath];
	
	NSDictionary *installedToolDict = (NSDictionary*) CFBundleCopyInfoDictionaryForURL((CFURLRef) installedURL);
	if (!installedToolDict)
		return YES; // There is no installed tool...
	
	NSURL *embeddedURL = [NSURL URLWithString:embeddedToolPath];
	NSDictionary *embeddedToolDict = (NSDictionary*) CFBundleCopyInfoDictionaryForURL((CFURLRef) embeddedURL);
	
	NSString *installedVersion = (NSString*) [installedToolDict objectForKey:@"CFBundleVersion"];
	NSString *embeddedVersion = (NSString*) [embeddedToolDict objectForKey:@"CFBundleVersion"];
	
	if ([installedVersion isEqualToString:embeddedVersion] == NO)
		return YES;

	return NO;
}

- (void) installDaemon {
	NSString *jobLabel = @"se.ejeklint.wldaemon";

	NSDictionary *jobDict = (NSDictionary*) SMJobCopyDictionary(kSMDomainSystemLaunchd,
																(CFStringRef) jobLabel);

	BOOL removeOldJob = NO;
	
	if (jobDict) {
		// Installed. TODO: Check version and see if it needs upgrade
		NSLog(@"Daemon already installed");
		[jobDict release];
		if ([self toolNeedsUpgrade: jobLabel] == NO)
			return;
		
		removeOldJob = YES;
	}

	AuthorizationRef auth;
	OSStatus authResult = AuthorizationCreate(NULL,
											  NULL,
											  kAuthorizationFlagDefaults,
											  &auth);
	if (noErr != authResult) {
		NSLog(@"Error creating auth ref");
		return;
	}
	AuthorizationItem item = { 0 };
	item.name = kSMRightBlessPrivilegedHelper;
	item.valueLength = 0;
	item.value = NULL;
	item.flags = 0;
	AuthorizationRights requestedRights;
	requestedRights.count = 1;
	requestedRights.items = &item;
	// Gain the right to install the helper
	authResult = AuthorizationCopyRights(auth,
										 &requestedRights,
										 kAuthorizationEmptyEnvironment,
										 kAuthorizationFlagDefaults |
										 kAuthorizationFlagExtendRights |
										 kAuthorizationFlagInteractionAllowed,
										 NULL);
	if (noErr != authResult) {
		NSLog(@"Unable to acquire right to bless wldaemon");
		AuthorizationFree(auth, kAuthorizationFlagDefaults);
		return;
	}
	
	if (removeOldJob == YES) {
		NSLog(@"stopping and removing old daemon");
		// Remove wldaemon
		NSError *error = nil;
		BOOL removed = SMJobRemove(kSMDomainSystemLaunchd,
								   (CFStringRef) jobLabel,
								   auth,
								   true,
								   (CFErrorRef*) &error);
		if (!removed) {
			NSLog(@"Failed to remove the wldaemon");
			[NSApp presentError: error];
		}
	}
	
	NSLog(@"Will attempt to install or upgrade wldaemon");
	
	// Blessed be the daemon
	NSError *error = nil;
	BOOL blessed = SMJobBless(kSMDomainSystemLaunchd,
							  (CFStringRef) jobLabel,
							  auth,
							  (CFErrorRef*) &error);
	if (!blessed) {
		NSLog(@"Failed to bless wldaemon");
		[NSApp presentError: error];
		return;
	}
	NSLog(@"successfully blessed wldaemon");

	AuthorizationFree(auth, kAuthorizationFlagDefaults);
	
	// Give daemon time to initialise
	[NSThread sleepForTimeInterval:10.0]; 
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {

	// Ensure daemon is installed
	[self installDaemon];
	
	// Anything to show now?
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MsgAtStartup"]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Hello, world!"];
		[alert runModal];
		[alert release];
	}

	// Open connection to daemon
	connection = [NSConnection connectionWithRegisteredName:KEY_REMOTE_CONNECTION_NAME host:nil];
	[connection setRequestTimeout:5.0];
	proxy = [[connection rootProxy] retain];
	[proxy setProtocolForProxy:@protocol(RemoteProtocol)];
//	settings = [NSMutableDictionary dictionaryWithDictionary: [proxy getSettings]];

	// Open Weather Window as default
	[NSBundle loadNibNamed:@"WeatherWindow" owner:self];
}

- (IBAction)openPreferencesWindow:(id)sender
{
	[[PEPrefsWindowController sharedPrefsWindowController] showWindow:nil];
}

- (IBAction) showHelp:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.ejeklint.se"]];
}

- (IBAction) toggleWeatherWindow:(id) sender
{
	[NSBundle loadNibNamed:@"WeatherWindow" owner:self];
}

- (IBAction) toggleStatusWindow:(id) sender
{
	[NSBundle loadNibNamed:@"StatusWindow" owner:self];
}


@end
