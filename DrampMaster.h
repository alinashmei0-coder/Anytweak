#import <Foundation/Foundation.h>

@interface DumpMaster : NSObject

+ (instancetype)sharedInstance;
- (void)startDump;
- (void)saveDumpToFile:(NSDictionary *)dumpData;

@end
