#ifdef __OBJC__
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import <SDWebImageHEIFCoder/SDImageHEIFCoder.h>
// libheif
#if __has_include(<SDWebImageHEIFCoder/heif.h>)
#import <SDWebImageHEIFCoder/heif.h>
#import <SDWebImageHEIFCoder/heif_version.h>
#endif
// libde265
#if __has_include(<SDWebImageHEIFCoder/de265.h>)
#import <SDWebImageHEIFCoder/de265.h>
#import <SDWebImageHEIFCoder/de265-version.h>
#endif

FOUNDATION_EXPORT double SDWebImageHEIFCoderVersionNumber;
FOUNDATION_EXPORT const unsigned char SDWebImageHEIFCoderVersionString[];

