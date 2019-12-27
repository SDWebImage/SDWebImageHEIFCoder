//
//  SDImageHEIFCoder.h
//  SDWebImageHEIFCoder
//
//  Created by lizhuoli on 2018/5/8.
//

#if __has_include(<SDWebImage/SDWebImage.h>)
#import <SDWebImage/SDWebImage.h>
#else
@import SDWebImage;
#endif

@interface SDImageHEIFCoder : NSObject <SDImageCoder>

@property (nonatomic, class, readonly, nonnull) SDImageHEIFCoder *sharedCoder;

@end
