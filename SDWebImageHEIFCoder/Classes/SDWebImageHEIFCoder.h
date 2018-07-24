//
//  SDWebImageHEIFCoder.h
//  SDWebImageHEIFCoder
//
//  Created by lizhuoli on 2018/5/8.
//

#import <SDWebImage/SDWebImage.h>

static const SDImageFormat SDImageFormatHEIF = 10;

@interface SDWebImageHEIFCoder : NSObject <SDImageCoder>

@property (nonatomic, class, readonly, nonnull) SDWebImageHEIFCoder *sharedCoder;

@end
