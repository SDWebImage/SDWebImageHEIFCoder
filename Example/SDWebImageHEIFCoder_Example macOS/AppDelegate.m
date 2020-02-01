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
    SDImageHEIFCoder *HEIFCoder = [SDImageHEIFCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:HEIFCoder];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
