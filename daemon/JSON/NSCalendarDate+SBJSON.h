#import <Foundation/Foundation.h>

#import "JSON.h"


@interface NSCalendarDate (NSCalendarDate_SBJSON)
- (id)JSONFragmentValue;

- (id)JSONValue;
- (id)JSONValueWithOptions:(NSDictionary *)opts;
@end
