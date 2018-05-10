//
//  SDWebImageHEIFCoder.h
//  SDWebImageHEIFCoder
//
//  Created by lizhuoli on 2018/5/8.
//

#import <SDWebImage/SDWebImageCoder.h>

@interface SDWebImageHEIFCoder : NSObject <SDWebImageCoder>

@property (nonatomic, class, readonly, nonnull) SDWebImageHEIFCoder *sharedCoder;

@end
