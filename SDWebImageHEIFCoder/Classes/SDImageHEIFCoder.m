//
//  SDImageHEIFCoder.m
//  SDWebImageHEIFCoder
//
//  Created by lizhuoli on 2018/5/8.
//

#import "SDImageHEIFCoder.h"
#if __has_include(<libheif/heif.h>)
#import <libheif/heif.h>
#else
#import "heif.h"
#endif
#import <Accelerate/Accelerate.h>

typedef struct heif_context heif_context;
typedef struct heif_image_handle heif_image_handle;
typedef struct heif_image heif_image;
typedef struct heif_encoder heif_encoder;
typedef struct heif_writer heif_writer;
typedef struct heif_error heif_error;
typedef enum heif_chroma heif_chroma;
typedef enum heif_channel heif_channel;
typedef enum heif_colorspace heif_colorspace;

static heif_error WriteImageData(heif_context * ctx, const void * data, size_t size, void * userdata) {
    NSMutableData *imageData = (__bridge NSMutableData *)userdata;
    NSCParameterAssert(imageData);
    NSCParameterAssert(data);
    
    [imageData appendBytes:data length:size];
    
    // OK
    heif_error error;
    error.code = heif_error_Ok;
    error.subcode = heif_suberror_Unspecified;
    error.message = "Success";
    return error;
}

static void FreeImageData(void *info, const void *data, size_t size) {
    heif_image *img = (heif_image *)info;
    heif_image_release(img); // `heif_image_release` will free the bitmap buffer. We do not call `free`
}

/// Calculate the actual thumnail pixel size
static CGSize SDCalculateThumbnailSize(CGSize fullSize, BOOL preserveAspectRatio, CGSize thumbnailSize) {
    CGFloat width = fullSize.width;
    CGFloat height = fullSize.height;
    CGFloat resultWidth;
    CGFloat resultHeight;
    
    if (width == 0 || height == 0 || thumbnailSize.width == 0 || thumbnailSize.height == 0 || (width <= thumbnailSize.width && height <= thumbnailSize.height)) {
        // Full Pixel
        resultWidth = width;
        resultHeight = height;
    } else {
        // Thumbnail
        if (preserveAspectRatio) {
            CGFloat pixelRatio = width / height;
            CGFloat thumbnailRatio = thumbnailSize.width / thumbnailSize.height;
            if (pixelRatio > thumbnailRatio) {
                resultWidth = thumbnailSize.width;
                resultHeight = ceil(thumbnailSize.width / pixelRatio);
            } else {
                resultHeight = thumbnailSize.height;
                resultWidth = ceil(thumbnailSize.height * pixelRatio);
            }
        } else {
            resultWidth = thumbnailSize.width;
            resultHeight = thumbnailSize.height;
        }
    }
    
    return CGSizeMake(resultWidth, resultHeight);
}

@implementation SDImageHEIFCoder

+ (instancetype)sharedCoder {
    static SDImageHEIFCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageHEIFCoder alloc] init];
    });
    return coder;
}

- (BOOL)canDecodeFromData:(NSData *)data {
#if HAVE_LIBDE265
    return [[self class] isHEIFFormatForData:data];
#else
    return NO;
#endif
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(SDImageCoderOptions *)options {
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
    
    CGSize thumbnailSize = CGSizeZero;
    NSValue *thumbnailSizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
    if (thumbnailSizeValue != nil) {
#if SD_MAC
        thumbnailSize = thumbnailSizeValue.sizeValue;
#else
        thumbnailSize = thumbnailSizeValue.CGSizeValue;
#endif
    }
    
    BOOL preserveAspectRatio = YES;
    NSNumber *preserveAspectRatioValue = options[SDImageCoderDecodePreserveAspectRatio];
    if (preserveAspectRatioValue != nil) {
        preserveAspectRatio = preserveAspectRatioValue.boolValue;
    }
    
    // Currently only support primary image :)
    CGImageRef imageRef = [self sd_createHEIFImageWithData:data thumbnailSize:thumbnailSize preserveAspectRatio:preserveAspectRatio];
    if (!imageRef) {
        return nil;
    }
    
#if SD_MAC
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#endif
    CGImageRelease(imageRef);
    
    return image;
}

// Only decode the primary image (HEIF also support tied-image and animated image)
- (nullable CGImageRef)sd_createHEIFImageWithData:(nonnull NSData *)data thumbnailSize:(CGSize)thumbnailSize preserveAspectRatio:(BOOL)preserveAspectRatio CF_RETURNS_RETAINED {
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
    
    // check thumbnail firstly
    if (thumbnailSize.width > 0 && thumbnailSize.height > 0) {
        heif_item_id thumbnailID;
        int thumbnailCount = heif_image_handle_get_list_of_thumbnail_IDs(handle, &thumbnailID, 1);
        if (thumbnailCount > 0) {
            heif_image_handle *thumbnailHandle;
            error = heif_image_handle_get_thumbnail(handle, thumbnailID, &thumbnailHandle);
            if (error.code != heif_error_Ok) {
                heif_image_handle_release(handle);
                heif_context_free(ctx);
                return nil;
            }
            
            int handleWidth = heif_image_handle_get_width(thumbnailHandle);
            int handleHeight = heif_image_handle_get_height(thumbnailHandle);
            if (handleWidth < thumbnailSize.width && handleHeight < thumbnailSize.height) {
                // use full image to scale down if pixel size is smaller than thumbnail size
                heif_image_handle_release(thumbnailHandle);
            } else {
                // else, the thumbnail is large enough to directly use
                heif_image_handle_release(handle);
                handle = thumbnailHandle;
            }
        }
    }
    
    CGImageRef imageRef = [self sd_createFrameWithImageHandle:handle thumbnailSize:thumbnailSize preserveAspectRatio:preserveAspectRatio];
    
    // clean up
    heif_image_handle_release(handle);
    heif_context_free(ctx);
    
    return imageRef;
}

- (nullable CGImageRef)sd_createFrameWithImageHandle:(heif_image_handle *)handle thumbnailSize:(CGSize)thumbnailSize preserveAspectRatio:(BOOL)preserveAspectRatio CF_RETURNS_RETAINED {
    heif_error error;
    
    // check alpha channel
    BOOL hasAlpha = heif_image_handle_has_alpha_channel(handle);
    int depth = heif_image_handle_get_chroma_bits_per_pixel(handle);
    BOOL hasHighDepth = depth > 8;
    heif_chroma chroma;
    if (hasAlpha) {
        if (hasHighDepth) {
            chroma = heif_chroma_interleaved_RRGGBB_BE;
        } else {
            chroma = heif_chroma_interleaved_RGBA;
        }
    } else {
        if (hasHighDepth) {
            chroma = heif_chroma_interleaved_RRGGBBAA_BE;
        } else {
            chroma = heif_chroma_interleaved_RGB;
        }
    }
    
    // decode the image and convert colorspace to RGB/RGBA, saved as 24bit/32bit interleaved
    heif_image* img;
    error = heif_decode_image(handle, &img, heif_colorspace_RGB, chroma, NULL);
    if (error.code != heif_error_Ok) {
        return nil;
    }
    
    int handleWidth = heif_image_handle_get_width(handle);
    int handleHeight = heif_image_handle_get_height(handle);
    CGSize scaledSize = SDCalculateThumbnailSize(CGSizeMake(handleWidth, handleHeight), preserveAspectRatio, thumbnailSize);
    // use scaling for thumbnail
    if (scaledSize.width > 0 && scaledSize.height > 0 && scaledSize.width != handleWidth && scaledSize.height != handleHeight) {
        heif_image *scaled_img;
        error = heif_image_scale_image(img, &scaled_img, scaledSize.width, scaledSize.height, NULL);
        heif_image_release(img);
        if (error.code != heif_error_Ok) {
            return nil;
        }
        img = scaled_img;
    }
    
    int width, height, stride, bitsPerPixel, bitsPerComponent;
    width = heif_image_get_width(img, heif_channel_interleaved);
    height = heif_image_get_height(img, heif_channel_interleaved);
    bitsPerPixel = heif_image_get_bits_per_pixel(img, heif_channel_interleaved);
    bitsPerComponent = hasHighDepth ? 16 : 8;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone;
    
    const uint8_t *rgba = heif_image_get_plane_readonly(img, heif_channel_interleaved, &stride);
    if (!rgba) {
        heif_image_release(img);
        return nil;
    }
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(img, rgba, stride * height, FreeImageData);
    
    CGColorSpaceRef colorSpaceRef = [SDImageCoderHelper colorSpaceGetDeviceRGB];
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, stride, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // clean up
    CGDataProviderRelease(provider);
    
    return imageRef;
}

// libheif contains initilial encoding support using libx265, but currently is not fully support
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    if (format == SDImageFormatHEIC || format == SDImageFormatHEIF) {
#if HAVE_X265
        return YES;
#else
        return NO;
#endif
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
    CGSize maxPixelSize = CGSizeZero;
    NSValue *maxPixelSizeValue = options[SDImageCoderEncodeMaxPixelSize];
    if (maxPixelSizeValue != nil) {
#if SD_MAC
        maxPixelSize = maxPixelSizeValue.sizeValue;
#else
        maxPixelSize = maxPixelSizeValue.CGSizeValue;
#endif
    }
    NSUInteger maxFileSize = 0;
    if (options[SDImageCoderEncodeMaxFileSize]) {
        maxFileSize = [options[SDImageCoderEncodeMaxFileSize] unsignedIntegerValue];
    }
    
    data = [self sd_encodedHEIFDataWithImage:image quality:compressionQuality maxPixelSize:maxPixelSize maxFileSize:maxFileSize];
    
    return data;
}

- (nullable NSData *)sd_encodedHEIFDataWithImage:(nonnull UIImage *)image quality:(double)quality maxPixelSize:(CGSize)maxPixelSize maxFileSize:(NSUInteger)maxFileSize {
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    
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
    if (maxFileSize > 0) {
        // if we want to actually the limit bytes, use ABR to limit bitrate
        // I'm not professional in x265 video encoding, learn more: https://slhck.info/video/2017/03/01/rate-control.html
        unsigned long bitrate = maxFileSize * 8 / 1000; // kbps, 1 second
        size_t length = snprintf(NULL, 0, "%d", bitrate);
        char *bitrate_str = malloc(length + 1);
        snprintf(bitrate_str, length + 1, "%d", bitrate);
        heif_encoder_set_parameter(encoder, "x265:bitrate", bitrate_str);
        heif_encoder_set_parameter(encoder, "x265:vbv-maxrate", bitrate_str);
        heif_encoder_set_parameter(encoder, "x265:vbv-bufsize", bitrate_str);
        free(bitrate_str);
    } else {
        // else use the CRF quality (libheif's default quality params)
        heif_encoder_set_lossy_quality(encoder, quality * 100);
    }
    
    // libheif supports RGB888/RGBA8888 color mode, convert all to this
    vImageConverterRef convertor = NULL;
    vImage_Error v_error = kvImageNoError;
    
    size_t bitsPerPixel = hasAlpha ? 32 : 24;
    size_t bytesPerRow = (width * bitsPerPixel + 7) / 8;
    // use 16 byte alignment, see libheif's source code heif_image.cc :)
    int alignment = 16; // must be power of two
    bytesPerRow = (bytesPerRow+alignment-1) & ~(alignment-1);
    
    vImage_CGImageFormat srcFormat = {
        .bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(imageRef),
        .bitsPerPixel = (uint32_t)CGImageGetBitsPerPixel(imageRef),
        .colorSpace = CGImageGetColorSpace(imageRef),
        .bitmapInfo = bitmapInfo
    };
    vImage_CGImageFormat destFormat = {
        .bitsPerComponent = 8,
        .bitsPerPixel = bitsPerPixel,
        .colorSpace = [SDImageCoderHelper colorSpaceGetDeviceRGB],
        .bitmapInfo = hasAlpha ? kCGImageAlphaLast | kCGBitmapByteOrderDefault : kCGImageAlphaNone | kCGBitmapByteOrderDefault // RGB888/RGBA8888 (Non-premultiplied to works for libheif)
    };
    
    convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, &destFormat, NULL, kvImageNoFlags, &v_error);
    if (v_error != kvImageNoError) {
        heif_context_free(ctx);
        return nil;
    }
    
    vImage_Buffer src;
    v_error = vImageBuffer_InitWithCGImage(&src, &srcFormat, NULL, imageRef, kvImageNoFlags);
    if (v_error != kvImageNoError) {
        heif_context_free(ctx);
        return nil;
    }
    vImage_Buffer dest = {
        .width = width,
        .height = height,
        .rowBytes = bytesPerRow,
        .data = malloc(height * bytesPerRow) // It seems that libheif does not keep 32/64 byte alignment, however, vImage's `vImageBuffer_Init` does. So manually alloc buffer
    };
    if (!dest.data) {
        free(src.data);
        vImageConverter_Release(convertor);
        heif_context_free(ctx);
        return nil;
    }
    
    // Convert input color mode to RGB888/RGBA8888
    v_error = vImageConvert_AnyToAny(convertor, &src, &dest, NULL, kvImageNoFlags);
    vImageConverter_Release(convertor);
    if (v_error != kvImageNoError) {
        free(src.data);
        free(dest.data);
        heif_context_free(ctx);
        return nil;
    }
    
    free(src.data);
    void * rgba = dest.data; // Converted buffer
    
    // code to fill in the image
    heif_chroma chroma = hasAlpha ? heif_chroma_interleaved_RGBA : heif_chroma_interleaved_RGB;
    heif_colorspace colorspace = heif_colorspace_RGB;
    heif_image* img;
    error = heif_image_create((int)width, (int)height, colorspace, chroma, &img);
    if (error.code != heif_error_Ok) {
        free(rgba);
        heif_encoder_release(encoder);
        heif_context_free(ctx);
        return nil;
    }
    
    // add the plane
    heif_channel channel = heif_channel_interleaved;
    error = heif_image_add_plane(img, channel, (int)width, (int)height, (int)bitsPerPixel);
    if (error.code != heif_error_Ok) {
        free(rgba);
        heif_encoder_release(encoder);
        heif_context_free(ctx);
        return nil;
    }
    
    // fill the plane
    int stride;
    uint8_t *planar = heif_image_get_plane(img, channel, &stride);
    size_t bytes_per_pixel = (bitsPerPixel + 7) / 8;
    for (int y = 0 ; y < height ; y++) {
        memcpy(planar + y * stride, rgba + y * stride, width * bytes_per_pixel);
    }
    
    // free the rgba buffer
    free(rgba);
    
    // check thumbnail encoding
    int ctuSize = 64;
    // x265 cannot encode images smaller than one CTU size
    // https://bitbucket.org/multicoreware/x265/issues/475/x265-does-not-allow-image-sizes-smaller
    // -> use smaller CTU sizes for very small images
    if (maxPixelSize.width > 0 && maxPixelSize.height > 0 && width >= ctuSize && height >= ctuSize) {
        CGSize scaledSize = SDCalculateThumbnailSize(CGSizeMake(width, height), YES, maxPixelSize);
        heif_image *thumbnail_img;
        error = heif_image_scale_image(img, &thumbnail_img, (int)scaledSize.width, (int)scaledSize.height, NULL);
        if (error.code != heif_error_Ok) {
            heif_image_release(img);
            heif_encoder_release(encoder);
            heif_context_free(ctx);
            return nil;
        }
        heif_image_release(img);
        img = thumbnail_img;
    }
    
    // encode the image
    heif_image_handle *handle;
    error = heif_context_encode_image(ctx, img, encoder, NULL, &handle);
    if (error.code != heif_error_Ok) {
        heif_image_release(img);
        heif_encoder_release(encoder);
        heif_context_free(ctx);
        return nil;
    }

//    Support embed thumbnail image
//    error = heif_context_encode_thumbnail(ctx, img, handle, encoder, NULL, (int)finalPixelSize, NULL);
    
    NSMutableData *mutableData = [NSMutableData data];
    heif_writer writer;
    writer.writer_api_version = 1;
    writer.write = WriteImageData; // This is a function pointer
    
    error = heif_context_write(ctx, &writer, (__bridge void *)(mutableData));
    
    // clean up
    heif_image_release(img);
    heif_encoder_release(encoder);
    heif_image_handle_release(handle);
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

@end
