# SDWebImageHEIFCoder

[![CI Status](https://img.shields.io/travis/SDWebImage/SDWebImageHEIFCoder.svg?style=flat)](https://travis-ci.org/SDWebImage/SDWebImageHEIFCoder)
[![Version](https://img.shields.io/cocoapods/v/SDWebImageHEIFCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageHEIFCoder)
[![License](https://img.shields.io/cocoapods/l/SDWebImageHEIFCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageHEIFCoder)
[![Platform](https://img.shields.io/cocoapods/p/SDWebImageHEIFCoder.svg?style=flat)](https://cocoapods.org/pods/SDWebImageHEIFCoder)

## 4.x compatibility

SDWebImage 5.x change the custom image coder API. This `master` branch follow the `5.x` branch of SDWebImage. For 4.x compatibility HEIF coder support, checkout `4.x` branch.

## What's for

This is a [SDWebImage](https://github.com/rs/SDWebImage) coder plugin to add [High Efficiency Image File Format (HEIF)](http://nokiatech.github.io/heif/index.html) support. Which is built based on the open-sourced [libheif](https://github.com/strukturag/libheif) codec.

This HEIF coder plugin currently support HEIF single/still image **decoding** as well as HEIC image **encoding**.

It support iOS 8+/macOS 10.9+ device without the dependency of Apple's Image/IO framework.

However, for better performance and hardware accelerate for iOS 11+ device, it's really recommended to use Image/IO instead.

## Requirements

+ iOS 8
+ tvOS 9.0
+ macOS 10.9
+ watchOS 2.0

## Installation

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

## Usage

To use HEIF coder, you should firstly add the `SDWebImageHEIFCoder` to the coders manager. Then you can call the View Category method to start load HEIF images.

+ Objective-C

```objective-c
SDWebImageHEIFCoder *HEIFCoder = [SDWebImageHEIFCoder sharedCoder];
[[SDImageCodersManager sharedManager] addCoder:HEIFCoder];
UIImageView *imageView;
[imageView sd_setImageWithURL:url];
```

+ Swift

```swift
let HEIFCoder = SDWebImageHEIFCoder.shared
SDImageCodersManager.shared.addCoder(HEIFCoder)
let imageView: UIImageView
imageView.sd_setImage(with: url)
```

`SDWebImageHEIFCoder` also support HEIF encoding (need x265 subspec). You can encode `UIImage` to HEIF compressed image data.

+ Objective-C

```objectivec
UIImage *image;
NSData *imageData = [image sd_imageDataAsFormat:SDImageFormatHEIF];
```

+ Swift

```swift
let image;
let imageData = image.sd_imageData(asFormat: .HEIF)
```

## Screenshot

<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageHEIFCoder/master/Example/Screenshot/HEIFDemo.png" width="300" />

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


