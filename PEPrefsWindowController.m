//
//  PEPrefsWindowController.m
//  WLoggerApp
//
//  Created by Per Ejeklint on 2010-11-17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PEPrefsWindowController.h"


@implementation PEPrefsWindowController

- (void)setupToolbar
{
	[self addView:generalPrefsView label:@"General"];
	[self addView:storagePrefsView label:@"Storage"];
}

@end
