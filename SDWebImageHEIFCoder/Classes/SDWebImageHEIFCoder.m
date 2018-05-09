//
//  SDWebImageHEIFCoder.m
//  SDWebImageHEIFCoder
//
//  Created by lizhuoli on 2018/5/8.
//

#import "SDWebImageHEIFCoder.h"
#import "heif.h"

typedef struct heif_context heif_context;
typedef struct heif_image_handle heif_image_handle;
typedef struct heif_image heif_image;
typedef struct heif_encoder heif_encoder;
typedef struct heif_writer heif_writer;
typedef struct heif_error heif_error;
typedef enum heif_chroma heif_chroma;

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

static struct heif_error WriteImageData(struct heif_context* ctx,
                                                const void* data, size_t size, void* userdata) {
    NSMutableData *imageData = (__bridge NSMutableData *)userdata;
    NSCParameterAssert(imageData);
    
    heif_error error;
    if (!data) {
        error.code = heif_error_Encoder_plugin_error;
        return error;
    }
    [imageData appendBytes:data length:size];
    
    // this API seems wrong. Public APIs does not have information to provide error
    error.code = heif_error_Ok;
    return error;
}

@implementation SDWebImageHEIFCoder

+ (instancetype)sharedCoder {
    static SDWebImageHEIFCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDWebImageHEIFCoder alloc] init];
    });
    return coder;
}

- (BOOL)canDecodeFromData:(NSData *)data {
    return [[self class] isHEIFFormatForData:data];
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    UIImage *image = nil;
    if (!data) {
        return nil;
    }
    
    CGFloat scale = 1;
    if ([options valueForKey:SDImageCoderDecodeScaleFactor]) {
        scale = [[options valueForKey:SDImageCoderDecodeScaleFactor] doubleValue];
        if (scale < 1) {
            scale = 1;
        }
    }
    
    // Currently only support primary image :)
    CGImageRef imageRef = [self sd_createHEIFImageWithData:data];
    if (!imageRef) {
        return nil;
    }
    
#if SD_UIKIT
    image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#else
    image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
    
    return image;
}

// Only decode the primary image (HEIF also support tied-image and still image)
- (nullable CGImageRef)sd_createHEIFImageWithData:(nonnull NSData *)data CF_RETURNS_RETAINED {
    heif_context* ctx = heif_context_alloc();
    if (!ctx) {
        return nil;
    }
    
    const void *bytes = data.bytes;
    const size_t size = data.length;
    heif_error error = heif_context_read_from_memory(ctx, bytes, size, NULL);
    if (error.code != heif_error_Ok) {
        heif_context_free(ctx);
        return nil;
    }
    
    // get a handle to the primary image
    heif_image_handle* handle;
    error = heif_context_get_primary_image_handle(ctx, &handle);
    if (error.code != heif_error_Ok) {
        heif_context_free(ctx);
        return nil;
    }
    
    // check alpha channel
    bool hasAlpha = heif_image_handle_has_alpha_channel(handle);
    heif_chroma chroma = hasAlpha ? heif_chroma_interleaved_32bit : heif_chroma_interleaved_24bit;
    
    // decode the image and convert colorspace to RGB/RGBA, saved as 24bit/32bit interleaved
    heif_image* img;
    error = heif_decode_image(handle, &img, heif_colorspace_RGB, chroma, NULL);
    if (error.code != heif_error_Ok) {
        heif_image_handle_release(handle);
        heif_context_free(ctx);
        return nil;
    }
    
    int width, height, stride, bitsPerPixel, bitsPerComponent;
    width =  heif_image_get_width(img, heif_channel_interleaved);
    height = heif_image_get_height(img, heif_channel_interleaved);
    bitsPerPixel = heif_image_get_bits_per_pixel(img, heif_channel_interleaved);
    bitsPerComponent = 8;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone;
    
    const uint8_t *rgba = heif_image_get_plane_readonly(img, heif_channel_interleaved, &stride);
    if (!rgba) {
        heif_image_release(img);
        heif_image_handle_release(handle);
        heif_context_free(ctx);
        return nil;
    }
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, rgba, stride * height, FreeImageData);
    
    CGColorSpaceRef colorSpaceRef = [SDImageCoderHelper colorSpaceGetDeviceRGB];
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, stride, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // clean up
    CGDataProviderRelease(provider);
    heif_image_release(img);
    heif_image_handle_release(handle);
    heif_context_free(ctx);
    
    return imageRef;
}

// libheif contains initilial encoding support using libx265, but currently is not fully support
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    if (format == SDImageFormatHEIC) {
        return [[self class] canEncodeToHEICFormat];
    }
    return NO;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    
    NSData *data;
    
    double compressionQuality = 1;
    if ([options valueForKey:SDImageCoderEncodeCompressionQuality]) {
        compressionQuality = [[options valueForKey:SDImageCoderEncodeCompressionQuality] doubleValue];
    }
    
    data = [self sd_encodedHEIFDataWithImage:image quality:compressionQuality];
    
    return data;
}

- (nullable NSData *)sd_encodedHEIFDataWithImage:(nonnull UIImage *)image quality:(double)quality {
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    
    heif_context* ctx = heif_context_alloc();
    if (!ctx) {
        return nil;
    }
    heif_error error;
    
    // get the default encoder
    heif_encoder* encoder;
    error = heif_context_get_encoder_for_format(ctx, heif_compression_HEVC, &encoder);
    if (error.code != heif_error_Ok) {
        heif_context_free(ctx);
        return nil;
    }
    
    // set the encoder parameters
    heif_encoder_set_lossy_quality(encoder, quality * 100);
    
    // code to fill in the image
    heif_chroma chroma = hasAlpha ? heif_chroma_interleaved_RGBA : heif_chroma_interleaved_RGB;
    heif_image* img;
    error = heif_image_create(width, height, heif_colorspace_RGB, chroma, &img);
    if (error.code != heif_error_Ok) {
        heif_context_free(ctx);
        heif_encoder_release(encoder);
        return nil;
    }
    
    // Fix-me: support RGB/ARGB only, using vImage's `vImageConvert_AnyToAny` later
    error = heif_image_add_plane(img, heif_channel_interleaved, width, height, 24);
    if (error.code != heif_error_Ok) {
        heif_context_free(ctx);
        heif_encoder_release(encoder);
        return nil;
    }
    
    // if we can not get bitmap buffer, early return
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    if (!dataProvider) {
        return nil;
    }
    CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
    if (!dataRef) {
        return nil;
    }
    size_t stride;
    uint8_t *rgba = (uint8_t *)CFDataGetBytePtr(dataRef);
    uint8_t *output_rgba = heif_image_get_plane(img, heif_channel_interleaved, &stride);
    NSAssert(bytesPerRow == stride, @"stride equal");
    // Fix-me: assume input stride == output stride, override with input
    memcpy(output_rgba, rgba, stride * height);
    
    // encode the image
    error = heif_context_encode_image(ctx, img, encoder, NULL, NULL);
    if (error.code != heif_error_Ok) {
        CFRelease(dataRef);
        heif_encoder_release(encoder);
        heif_context_free(ctx);
        return nil;
    }
    
    NSMutableData *mutableData = [NSMutableData data];
    heif_writer writer;
    writer.writer_api_version = 1;
    writer.write = WriteImageData; // This is a function pointer
    
    error = heif_context_write(ctx, &writer, (__bridge void *)(mutableData));
    
    // clean up
    CFRelease(dataRef);
    heif_image_release(img);
    heif_encoder_release(encoder);
    heif_context_free(ctx);
    
    return [mutableData copy];
}

#pragma mark - Helper
+ (BOOL)isHEIFFormatForData:(NSData *)data
{
    if (!data) {
        return NO;
    }
    if (data.length >= 12) {
        //....ftypmif1 ....ftypmsf1 ....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
        NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(4, 8)] encoding:NSASCIIStringEncoding];
        if ([testString isEqualToString:@"ftypmif1"]
            || [testString isEqualToString:@"ftypmsf1"]
            || [testString isEqualToString:@"ftypheic"]
            || [testString isEqualToString:@"ftypheix"]
            || [testString isEqualToString:@"ftyphevc"]
            || [testString isEqualToString:@"ftyphevx"]) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)canEncodeToHEICFormat
{
    static BOOL canEncode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Check whether libheif has HEVC plugin support
        heif_context* ctx = heif_context_alloc();
        if (!ctx) {
            return;
        }
        heif_error error;
        
        // get the default encoder
        heif_encoder* encoder;
        error = heif_context_get_encoder_for_format(ctx, heif_compression_HEVC, &encoder);
        if (error.code != heif_error_Ok) {
            heif_context_free(ctx);
            return;
        }
        // Can encode to HEIC
        canEncode = YES;
        heif_context_free(ctx);
        heif_encoder_release(encoder);
    });
    
    return canEncode;
}

@end
