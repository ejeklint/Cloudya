//
//  main.m
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import <signal.h>

void SIGTERM_handler(const int sigid)
{
	CFRunLoopRef rl = [[NSRunLoop currentRunLoop] getCFRunLoop];
	if (rl == NULL) {
		exit(1); // Oops. Exit!
	} else {
		CFRunLoopStop(rl);
		exit(0);
	}
}


int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    signal(SIGTERM, (sig_t)SIGTERM_handler);
	
	NSString *name = [NSString stringWithCString:argv[0]];
	NSString *installedToolPath = [[NSString alloc] initWithFormat:@"file://%@", name];
	NSURL *installedURL = [NSURL URLWithString:installedToolPath];
	
	NSDictionary *installedToolDict = (NSDictionary*) CFBundleCopyInfoDictionaryForURL((CFURLRef) installedURL);
	NSString *version = (installedToolDict) ? (NSString*) [installedToolDict objectForKey:@"CFBundleVersion"] : @"?";
	NSLog(@"Starting wldaemon version %@", version);
	AppDelegate *ad = [[AppDelegate alloc] init];

	[[NSRunLoop currentRunLoop] run];

	(void) ad;
	
    [pool drain];
    return 0;
}
