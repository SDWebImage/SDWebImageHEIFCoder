# SDWebImageHEIFCoder

[![CI Status](https://img.shields.io/travis/SDWebImage/SDWebImageHEIFCoder.svg?style=flat)](https://travis-ci.org/SDWebImage/SDWebImageHEIFCoder)
[![Version](https://img.shields.io/cocoapods/v/SDWebImageHEIFCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageHEIFCoder)
[![License](https://img.shields.io/cocoapods/l/SDWebImageHEIFCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageHEIFCoder)
[![Platform](https://img.shields.io/cocoapods/p/SDWebImageHEIFCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageHEIFCoder)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/SDWebImage/SDWebImageHEIFCoder)
[![codecov](https://codecov.io/gh/SDWebImage/SDWebImageHEIFCoder/branch/master/graph/badge.svg)](https://codecov.io/gh/SDWebImage/SDWebImageHEIFCoder)

## 4.x compatibility

SDWebImage 5.x change the custom image coder API. This `master` branch follow the `5.x` branch of SDWebImage. For 4.x compatibility HEIF coder support, checkout `4.x` branch.

## What's for

This is a [SDWebImage](https://github.com/rs/SDWebImage) coder plugin to add [High Efficiency Image File Format (HEIF)](http://nokiatech.github.io/heif/index.html) support. Which is built based on the open-sourced [libheif](https://github.com/strukturag/libheif) codec.

This HEIF coder plugin currently support HEIF single/still image **decoding** as well as HEIC image **encoding**.

The decoding supports [HDR](https://en.wikipedia.org/wiki/High-dynamic-range_imaging) HEIF image with 10/12 bit depth (larger than normal 8 bit) as well.

It support iOS 8+/macOS 10.10+ device without the dependency of Apple's Image/IO framework.

## Performance

Apple's Image/IO framework supports Hardware-Accelerated HEIF decoding (A9+ chip) and encoding on (A10+ chip). And provide a backup Software decoding and encoding on all iOS 11+/macOS 10.13+ devices.

This coder is used for backward-compatible solution. And the codec only do Software decoding / encoding, which is slower than Image/IO. So if possible, choose to use Image/IO (SDWebImage's built-in coder) firstly.

## Requirements

+ iOS 8
+ tvOS 9.0
+ macOS 10.10
+ watchOS 2.0

## Installation

#### CocoaPods
SDWebImageHEIFCoder is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SDWebImageHEIFCoder'
```

SDWebImageHEIFCoder contains subspecs `libde265` & `libx265`. Which integrate the codec plugin for libheif to support HEIF image decoding/encoding.

To enable HEIF decoding, you should add `libde265` subspec:

```ruby
pod 'SDWebImageHEIFCoder/libde265'
```

To enable HEIF encoding, you should add `libx265` subspec:

```ruby
pod 'SDWebImageHEIFCoder/libx265'
```

By default will contains only `libde265` subspec for most people's usage. Using `libx265` encoding subspec only if you want HEIF encoding.

#### Carthage

SDWebImageHEIFCoder is available through [Carthage](https://github.com/Carthage/Carthage).

Carthage does not support like CocoaPods' subspec, since most of user use HEIF decoding without x265 library. The framework through Carthage only supports libde265 for HEIF decoding.

```
github "SDWebImage/SDWebImageHEIFCoder"
```

#### Swift Package Manager (Xcode 11+)

SDWebImageHEIFCoder is available through [Swift Package Manager](https://swift.org/package-manager).

The framework through SwiftPM only supports libde265 for HEIF decoding.

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImageHEIFCoder.git", from: "0.6")
    ]
)
```

## Usage

### Add Coder

To use HEIF coder, you should firstly add the `SDImageHEIFCoder.sharedCoder` to the coders manager. You can also detect the target platform compatibility for HEIF and choose add coder.

+ Objective-C

```objective-c
if (@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)) {
    // These version supports Image/IO built-in decoding
} else {
    // Don't support HEIF decoding, add coder
    SDImageHEIFCoder *HEIFCoder = [SDImageHEIFCoder sharedCoder];
    [[SDImageCodersManager sharedManager] addCoder:HEIFCoder];
}
```

+ Swift

```swift
if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
    // These version supports Image/IO built-in decoding
} else {
    // Don't support HEIF decoding, add coder
    let HEIFCoder = SDImageHEIFCoder.shared
    SDImageCodersManager.shared.addCoder(HEIFCoder)
}
```

### Loading

Then you can call the View Category method to start load HEIF images.

+ Objective-C

```objective-c
UIImageView *imageView;
[imageView sd_setImageWithURL:url];
```

+ Swift

```swift
let imageView: UIImageView
imageView.sd_setImage(with: url)
```

### Decoding

`SDImageHEIFCoder` currently supports decode the static HEIF images.

Note HEIF sequence images(.heics) is not supported currently, only supported in built-in coder from SDWebImage for iOS 13+/macOS 10.15+, also supported by [Safari and WebKit](https://bugs.webkit.org/show_bug.cgi?id=197384).

+ Objective-C

```objective-c
// HEIF image decoding
NSData *heifData;
UIImage *image = [[SDImageHEIFCoder sharedCoder] decodedImageWithData:heifData options:nil];
```

+ Swift

```swift
// HEIF image decoding
let heifData: Data
let image = SDImageHEIFCoder.shared.decodedImage(with: data, options: nil)
```

### Thumbnail Decoding (0.7.0+)

HEIF image container supports embed thumbnail image. If we can found a suitable thumbnail image, we pick that instead for quickly display, else we will decode full pixel image and scale down.

+ Objective-C

```objective-c
// HEIF thumbnail image decoding
NSData *heifData;
CGSize thumbnailSize = CGSizeMake(300, 300);
UIImage *thumbnailImage = [[SDImageHEIFCoder sharedCoder] decodedImageWithData:heifData options:@{SDImageCoderDecodeThumbnailPixelSize : @(thumbnailSize}];
```

+ Swift

```swift
// HEIF thumbnail image decoding
let heifData: Data
let thumbnailSize = CGSize(width: 300, height: 300)
let image = SDImageHEIFCoder.shared.decodedImage(with: data, options: [.decodeThumbnailPixelSize: thumbnailSize])
```

### Encoding

`SDWebImageHEIFCoder` also support HEIF encoding (need x265 subspec). You can encode `UIImage` to HEIF compressed image data.

+ Objective-C

```objectivec
UIImage *image;
NSData *imageData = [image sd_imageDataAsFormat:SDImageFormatHEIF];
// Encode Quality
NSData *lossyData = [[SDImageHEIFCoder sharedCoder] encodedDataWithImage:image format:SDImageFormatHEIF options:@{SDImageCoderEncodeCompressionQuality : @(0.1)}]; // [0, 1] compression quality
NSData *limitedData = [[SDImageHEIFCoder sharedCoder] encodedDataWithImage:image format:SDImageFormatHEIF options:@{SDImageCoderEncodeMaxFileSize : @(1024 * 10)}]; // v0.8.0 feature, limit output file size <= 10KB
```

+ Swift

```swift
let image;
let imageData = image.sd_imageData(as: .HEIF)
// Encode Quality
let lossyData = SDImageHEIFCoder.shared.encodedData(with: image, format: .heif, options: [.encodeCompressionQuality: 0.1]) // [0, 1] compression quality
let limitedData = SDImageHEIFCoder.shared.encodedData(with: image, format: .heif, options: [.encodeMaxFileSize: 1024 * 10]) // v0.8.0 feature, limit output file size <= 10KB
```

### Thumbnail Encoding (0.8.0+)

+ Objective-C

```objective-c
// HEIF image thumbnail encoding
UIImage *image;
NSData *thumbnailData = [[SDImageHEIFCoder sharedCoder] encodedDataWithImage:image format:SDImageFormatHEIF options:@{SDImageCoderEncodeMaxPixelSize : @(CGSizeMake(200, 200)}]; // v0.8.0 feature, encoding max pixel size
```

+ Swift

```swift
// HEIF image thumbnail encoding
let image: UIImage
let thumbnailData = SDImageHEIFCoder.shared.encodedData(with: image, format: .heif, options: [.encodeMaxPixelSize: CGSize(width: 200, height: 200)]) // v0.8.0 feature, encoding max pixel size
```

See more documentation in [SDWebImage Wiki - Coders](https://github.com/SDWebImage/SDWebImage/wiki/Advanced-Usage#custom-coder-420)

## Screenshot

<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageHEIFCoder/master/Example/Screenshot/HEIFDemo.png" width="300" />
<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageHEIFCoder/master/Example/Screenshot/HEIFDemo-macOS.png" width="600" />

The images are from [HEIF official site example](http://nokiatech.github.io/heif/examples.html)

## Author

DreamPiggy, lizhuoli1126@126.com

## License

SDWebImageHEIFCoder itself is available under the MIT license. See the LICENSE file for more info.
However, when using `libx265`, the license will be subject to GPL licence (or commercial licence if you have one). Check [x265.org](http://x265.org/) for more information.

## Thanks

+ [libheif](https://github.com/strukturag/libheif)
+ [libde265](https://github.com/strukturag/libde265)
+ [libx265](https://bitbucket.org/multicoreware/x265)


