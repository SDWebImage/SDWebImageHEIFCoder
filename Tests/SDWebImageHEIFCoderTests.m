/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

@import Foundation;
@import XCTest;
#import <SDWebImage/SDWebImage.h>
#import <SDWebImageHEIFCoder/SDWebImageHEIFCoder.h>
#import <libheif/heif.h>
#import <Expecta/Expecta.h>

const int64_t kAsyncTestTimeout = 5;

typedef struct heif_context heif_context;
typedef struct heif_image_handle heif_image_handle;
typedef struct heif_image heif_image;
typedef struct heif_encoder heif_encoder;
typedef struct heif_writer heif_writer;
typedef struct heif_error heif_error;
typedef enum heif_chroma heif_chroma;
typedef enum heif_channel heif_channel;
typedef enum heif_colorspace heif_colorspace;

@interface SDWebImageHEIFCoderTests : XCTestCase
@end

@interface SDHEIFCoderFrame : NSObject
@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSUInteger blendFromIndex; // The nearest previous frame index which blend mode is HEIF_MUX_BLEND
@end

@implementation SDWebImageHEIFCoderTests

+ (void)setUp {
    [SDImageCache.sharedImageCache clearMemory];
    [SDImageCache.sharedImageCache clearDiskOnCompletion:nil];
    [[SDImageCodersManager sharedManager] addCoder:[SDImageHEIFCoder sharedCoder]];
}

+ (void)tearDown {
    [[SDImageCodersManager sharedManager] removeCoder:[SDImageHEIFCoder sharedCoder]];
}

- (void)test01ThatHEIFWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"HEIF download"];
    NSURL *imageURL = [NSURL URLWithString:@"http://nokiatech.github.io/heif/content/images/ski_jump_1440x960.heic"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong");
        }
    }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)test02ThatProgressiveHEIFWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progressive HEIF download"];
    NSURL *imageURL = [NSURL URLWithString:@"http://nokiatech.github.io/heif/content/image_sequences/starfield_animation.heic"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:SDWebImageDownloaderProgressiveLoad progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else if (finished) {
            XCTFail(@"Something went wrong");
        } else {
            // progressive updates
        }
    }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)test11ThatStaticHEIFCoderWorks {
    NSURL *staticHEIFURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageStatic" withExtension:@"heic"];
    [self verifyCoder:[SDImageHEIFCoder sharedCoder]
    withLocalImageURL:staticHEIFURL
     supportsEncoding:YES
      isAnimatedImage:NO];
}

- (void)test12ThatAnimatedHEIFCoderWorks {
    NSURL *animatedHEIFURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"heic"];
    // libheif does not support Animated Image currently
    [self verifyCoder:[SDImageHEIFCoder sharedCoder]
    withLocalImageURL:animatedHEIFURL
     supportsEncoding:NO
      isAnimatedImage:NO];
}

- (void)test45HEIFEncodingMaxFileSize {
    NSURL *staticHEIFURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageStatic" withExtension:@"heic"];
    NSData *data = [NSData dataWithContentsOfURL:staticHEIFURL];
    UIImage *image = [UIImage sd_imageWithData:data];
    NSData *dataWithNoLimit = [SDImageHEIFCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatHEIC options:nil];
    XCTAssertNotNil(dataWithNoLimit);
    NSUInteger maxFileSize = 1024 * 50;
    NSData *dataWithLimit = [SDImageHEIFCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatHEIC options:@{SDImageCoderEncodeMaxFileSize : @(maxFileSize)}];
    XCTAssertNotNil(dataWithLimit);
    XCTAssertGreaterThan(dataWithNoLimit.length, dataWithLimit.length);
    XCTAssertGreaterThan(dataWithNoLimit.length, maxFileSize);
    XCTAssertLessThanOrEqual(dataWithLimit.length, maxFileSize);
}

- (void)test19ThatEmbedThumbnailHEICWorks {
    // The input HEIC does not contains any embed thumbnail
    NSURL *heicURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"heic"];
    NSData *heicData = [NSData dataWithContentsOfURL:heicURL];
    NSArray *thumbnailImages = [self thumbnailImagesFromData:heicData];
    expect(thumbnailImages.count).equal(0);
    
    UIImage *image = [SDImageHEIFCoder.sharedCoder decodedImageWithData:heicData options:nil];
    // Encode with embed thumbnail
    NSData *encodedData = [SDImageHEIFCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatHEIC options:@{SDImageCoderEncodeEmbedThumbnail : @(YES)}];
    
    [encodedData writeToFile:@"/tmp/1.heic" atomically:YES];
    
    // The new HEIC contains one embed thumbnail
    NSArray *thumbnailImages2 = [self thumbnailImagesFromData:encodedData];
    expect(thumbnailImages2.count).equal(1);
    
    // Cuurent we use 320x320 for thubmnail (keep aspect ratio), check the behavior :)
    NSDictionary *thumbnailImageInfo = thumbnailImages2.firstObject;
    NSUInteger thumbnailWidth = [thumbnailImageInfo[@"width"] unsignedIntegerValue];
    NSUInteger thumbnailHeight = [thumbnailImageInfo[@"height"] unsignedIntegerValue];
    expect(thumbnailWidth).equal(320);
    expect(thumbnailHeight).equal(212);
}

- (void)verifyCoder:(id<SDImageCoder>)coder
  withLocalImageURL:(NSURL *)imageUrl
   supportsEncoding:(BOOL)supportsEncoding
    isAnimatedImage:(BOOL)isAnimated {
    SDImageFormat encodingFormat = SDImageFormatHEIC;
    
    NSData *inputImageData = [NSData dataWithContentsOfURL:imageUrl];
    expect(inputImageData).toNot.beNil();
    SDImageFormat inputImageFormat = [NSData sd_imageFormatForImageData:inputImageData];
    expect(inputImageFormat).toNot.equal(SDImageFormatUndefined);
    
    // 1 - check if we can decode - should be true
    expect([coder canDecodeFromData:inputImageData]).to.beTruthy();
    
    // 2 - decode from NSData to UIImage and check it
    UIImage *inputImage = [coder decodedImageWithData:inputImageData options:nil];
    expect(inputImage).toNot.beNil();
    
    if (isAnimated) {
        // 2a - check images count > 0 (only for animated images)
        expect(inputImage.sd_isAnimated).to.beTruthy();
        
        // 2b - check image size and scale for each frameImage (only for animated images)
#if SD_UIKIT
        CGSize imageSize = inputImage.size;
        CGFloat imageScale = inputImage.scale;
        [inputImage.images enumerateObjectsUsingBlock:^(UIImage * frameImage, NSUInteger idx, BOOL * stop) {
            expect(imageSize).to.equal(frameImage.size);
            expect(imageScale).to.equal(frameImage.scale);
        }];
#endif
    }
    
    // 3 - check thumbnail decoding
    CGFloat pixelWidth = inputImage.size.width;
    CGFloat pixelHeight = inputImage.size.height;
    expect(pixelWidth).beGreaterThan(0);
    expect(pixelHeight).beGreaterThan(0);
    // check thumnail with scratch
    CGFloat thumbnailWidth = 50;
    CGFloat thumbnailHeight = 50;
    UIImage *thumbImage = [coder decodedImageWithData:inputImageData options:@{
        SDImageCoderDecodeThumbnailPixelSize : @(CGSizeMake(thumbnailWidth, thumbnailHeight)),
        SDImageCoderDecodePreserveAspectRatio : @(NO)
    }];
    expect(thumbImage).toNot.beNil();
    expect(thumbImage.size).equal(CGSizeMake(thumbnailWidth, thumbnailHeight));
    // check thumnail with aspect ratio limit
    thumbImage = [coder decodedImageWithData:inputImageData options:@{
        SDImageCoderDecodeThumbnailPixelSize : @(CGSizeMake(thumbnailWidth, thumbnailHeight)),
        SDImageCoderDecodePreserveAspectRatio : @(YES)
    }];
    expect(thumbImage).toNot.beNil();
    CGFloat ratio = pixelWidth / pixelHeight;
    CGFloat thumbnailRatio = thumbnailWidth / thumbnailHeight;
    CGSize thumbnailPixelSize;
    if (ratio > thumbnailRatio) {
        thumbnailPixelSize = CGSizeMake(thumbnailWidth, round(thumbnailWidth / ratio));
    } else {
        thumbnailPixelSize = CGSizeMake(round(thumbnailHeight * ratio), thumbnailHeight);
    }
    // Image/IO's thumbnail API does not always use round to preserve precision, we check ABS <= 1
    expect(ABS(thumbImage.size.width - thumbnailPixelSize.width)).beLessThanOrEqualTo(1);
    expect(ABS(thumbImage.size.height - thumbnailPixelSize.height)).beLessThanOrEqualTo(1);
    
    
    if (supportsEncoding) {
        // 4 - check if we can encode to the original format
        if (encodingFormat == SDImageFormatUndefined) {
            encodingFormat = inputImageFormat;
        }
        expect([coder canEncodeToFormat:encodingFormat]).to.beTruthy();
        
        // 5 - encode from UIImage to NSData using the inputImageFormat and check it
        NSData *outputImageData = [coder encodedDataWithImage:inputImage format:encodingFormat options:nil];
        expect(outputImageData).toNot.beNil();
        UIImage *outputImage = [coder decodedImageWithData:outputImageData options:nil];
        expect(outputImage.size).to.equal(inputImage.size);
        expect(outputImage.scale).to.equal(inputImage.scale);
#if SD_UIKIT
        expect(outputImage.images.count).to.equal(inputImage.images.count);
#endif
        
        // check max pixel size encoding with scratch
        CGFloat maxWidth = 100;
        CGFloat maxHeight = 100;
        CGFloat maxRatio = maxWidth / maxHeight;
        CGSize maxPixelSize;
        if (ratio > maxRatio) {
            maxPixelSize = CGSizeMake(maxWidth, round(maxWidth / ratio));
        } else {
            maxPixelSize = CGSizeMake(round(maxHeight * ratio), maxHeight);
        }
        NSData *outputMaxImageData = [coder encodedDataWithImage:inputImage format:encodingFormat options:@{SDImageCoderEncodeMaxPixelSize : @(CGSizeMake(maxWidth, maxHeight))}];
        expect(outputMaxImageData).toNot.beNil();
        UIImage *outputMaxImage = [coder decodedImageWithData:outputMaxImageData options:nil];
        // Image/IO's thumbnail API does not always use round to preserve precision, we check ABS <= 1
        expect(ABS(outputMaxImage.size.width - maxPixelSize.width)).beLessThanOrEqualTo(1);
        expect(ABS(outputMaxImage.size.height - maxPixelSize.height)).beLessThanOrEqualTo(1);
#if SD_UIKIT
        expect(outputMaxImage.images.count).to.equal(inputImage.images.count);
#endif
    }
}

- (NSArray *)thumbnailImagesFromData:(NSData *)data {
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
    
    // check thumbnail count
    int thumbnailCount = heif_image_handle_get_number_of_thumbnails(handle);
    
    // check thumbnail size
    heif_item_id *thumbnailIDs = calloc(thumbnailCount, sizeof(heif_item_id));
    thumbnailCount = heif_image_handle_get_list_of_thumbnail_IDs(handle, thumbnailIDs, thumbnailCount);
    
    NSMutableArray *thumbnailImages = [NSMutableArray arrayWithCapacity:thumbnailCount];
    for (int i = 0; i < thumbnailCount; i++) {
        heif_image_handle *thumbnailHandle;
        error = heif_image_handle_get_thumbnail(handle, thumbnailIDs[i], &thumbnailHandle);
        if (error.code != heif_error_Ok) {
            heif_image_handle_release(handle);
            heif_context_free(ctx);
            free(thumbnailIDs);
            return nil;
        }
        
        int handleWidth = heif_image_handle_get_width(thumbnailHandle);
        int handleHeight = heif_image_handle_get_height(thumbnailHandle);
        heif_image_handle_release(thumbnailHandle);
        
        NSDictionary *thumbnailImage = @{@"width": @(handleWidth), @"height": @(handleHeight)};
        [thumbnailImages addObject:thumbnailImage];
    }
    
    free(thumbnailIDs);
    heif_image_handle_release(handle);
    heif_context_free(ctx);
    
    return [thumbnailImages copy];
}

@end
