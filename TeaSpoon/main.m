//
//  TeaSpoon.m
//  TeaSpoon
//
//  Created by user on 2021/07/19.
//

@import Cocoa;
#import "TeaSpoon-Swift.h"
#import "objc/runtime.h"

@implementation NSWindow(TeaSpoon_Swizzle)
-(NSButton*)swizzled_standardWindowButton:(NSWindowButton)b {
    NSLog(@"[TeaSpoon] standardWindowButton: called with %lu", (unsigned long)b);
    if ([TeaSpoon.shared checkWindowIsEmulatorMainWindow: self]) {
        // force enable full screen
        // buggy but better than nothing
        self.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
    }
//    return [self swizzled_standardWindowButton: b];
    return nil; // dirty hack to prevent Qt removes traffic lights
}
@end

__attribute__((constructor))
static void teaspoonConstructor(int argc, const char **argv)
{
    printf("[TeaSpoon] Welcome to TeaSpoon! argv[0] = %s\n", argv[0]);
    printf("[TeaSpoon] Injecting to NSWindow setStyleMask\n");
    {
        Method old = class_getInstanceMethod([NSWindow class], @selector(standardWindowButton:));
        Method new = class_getInstanceMethod([NSWindow class], @selector(swizzled_standardWindowButton:));
        method_exchangeImplementations(old, new);
    }
    printf("[TeaSpoon] Enjoy TeaSpoon!\n");
}
