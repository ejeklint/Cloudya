//
//  main.m
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import <signal.h>

void SIGTERM_handler(const int sigid)
{
	NSLog(@"SIGTERM received");
	exit(0);
	
/*	CFRunLoopRef rl = [[NSRunLoop currentRunLoop] getCFRunLoop];
	if (rl == NULL)
		exit(1); // Oops. Exit!
	else
		CFRunLoopStop(rl); */
}


int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    signal(SIGTERM, (sig_t)SIGTERM_handler);
	
	NSLog(@"Starting up version 7");
	AppDelegate *ad = [[AppDelegate alloc] init];

	[[NSRunLoop currentRunLoop] run];

	(void) ad;
	
    [pool drain];
    return 0;
}
