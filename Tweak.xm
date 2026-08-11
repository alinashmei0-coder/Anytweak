#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import "DumpMaster.h"

%ctor {
    NSLog(@"🔥 DumpMaster: Tweak loaded!");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DumpMaster sharedInstance] startDump];
    });
}
