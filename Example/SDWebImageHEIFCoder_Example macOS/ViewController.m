//
//  ViewController.m
//  SDWebImageHEIFCoder-Example macOS
//
//  Created by lizhuoli on 2019/4/13.
//  Copyright © 2019 DreamPiggy. All rights reserved.
//

#import "ViewController.h"
#import <SDWebImage/SDWebImage.h>
#import <SDWebImageHEIFCoder/SDWebImageHEIFCoder.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SDImageHEIFCoder *HEIFCoder = [SDImageHEIFCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:HEIFCoder];
    NSURL *staticHEIFURL = [NSURL URLWithString:@"http://nokiatech.github.io/heif/content/images/ski_jump_1440x960.heic"];
    NSURL *animatedHEIFURL = [NSURL URLWithString:@"http://nokiatech.github.io/heif/content/image_sequences/starfield_animation.heic"];
    
    CGSize screenSize = self.view.bounds.size;
    
    UIImageView *imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width / 2, screenSize.height)];
    imageView1.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(screenSize.width / 2, 0, screenSize.width / 2, screenSize.height)];
    imageView2.imageScaling = NSImageScaleProportionallyUpOrDown;
    
    [self.view addSubview:imageView1];
    [self.view addSubview:imageView2];
    
    [imageView1 sd_setImageWithURL:staticHEIFURL completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            NSLog(@"Static HEIF load success");
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *HEIFData = [SDImageHEIFCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatHEIF options:nil];
                if (HEIFData) {
                    NSLog(@"Static HEIF encode success");
                }
            });
        }
    }];
    [imageView2 sd_setImageWithURL:animatedHEIFURL completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image.sd_isAnimated) {
            NSLog(@"Animated HEIF load success");
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Animated HEIF encoding is really slow, specify the lowest quality with fast speed
                NSData *HEIFData = [SDImageHEIFCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatHEIF options:@{SDImageCoderEncodeCompressionQuality : @(0)}];
                if (HEIFData) {
                    NSLog(@"Animated HEIF encode success");
                }
            });
        }
    }];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}


@end
