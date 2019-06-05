//
//  AppDelegate.m
//  SDWebImageHEIFCoder_Example macOS
//
//  Created by lizhuoli on 2019/4/13.
//  Copyright © 2019 DreamPiggy. All rights reserved.
//

#import "AppDelegate.h"
#import <SDWebImageHEIFCoder/SDWebImageHEIFCoder.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    if (@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)) {
        // These version supports Image/IO built-in decoding (hardware accelerate for A9+ device)
    } else {
        // Don't support HEIF decoding, add coder
        SDImageHEIFCoder *HEIFCoder = [SDImageHEIFCoder sharedCoder];
        [[SDImageCodersManager sharedManager] addCoder:HEIFCoder];
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
