#
# Be sure to run `pod lib lint SDWebImageHEIFCoder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SDWebImageHEIFCoder'
  s.version          = '0.2.4'
  s.summary          = 'A SDWebImage coder plugin to support HEIF image'

  s.description      = <<-DESC
This is a SDWebImage coder plugin to add High Efficiency Image File Format (HEIF) support.
Which is built based on the open-sourced libheif codec.
                       DESC

  s.homepage         = 'https://github.com/SDWebImage/SDWebImageHEIFCoder'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DreamPiggy' => 'lizhuoli1126@126.com' }
  s.source           = { :git => 'https://github.com/SDWebImage/SDWebImageHEIFCoder.git', :tag => s.version.to_s, :submodules => true }

  s.osx.deployment_target = '10.10'
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.module_map = 'SDWebImageHEIFCoder/Module/SDWebImageHEIFCoder.modulemap'
  s.default_subspecs = 'libheif', 'libde265'

  # HEIF core dependency
  s.subspec 'libheif' do |ss|
    ss.source_files = 'Vendors/libheif/libheif/*.{h,c,cc}', 'Vendors/include/libheif/*.h', 'SDWebImageHEIFCoder/Classes/**/*', 'SDWebImageHEIFCoder/Module/SDWebImageHEIFCoder.h'
    ss.exclude_files = 'Vendors/libheif/libheif/*fuzzer.{h,c,cc}', 'Vendors/libheif/libheif/heif.h', 'Vendors/libheif/libheif/heif_decoder_libde265.{h,c,cc}', 'Vendors/libheif/libheif/heif_encoder_x265.{h,c,cc}'
    ss.public_header_files = 'Vendors/include/libheif/*.h', 'SDWebImageHEIFCoder/Classes/**/*.h', 'SDWebImageHEIFCoder/Module/SDWebImageHEIFCoder.h'
    ss.preserve_path = 'Vendors/include'
    ss.xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_UNISTD_H=1',
      'HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_ROOT}/SDWebImageHEIFCoder/Vendors/include ${PODS_ROOT}/SDWebImageHEIFCoder/Vendors/include/libx265 ${PODS_TARGET_SRCROOT}/Vendors/include ${PODS_TARGET_SRCROOT}/Vendors/include/libx265'
    }
    ss.libraries = 'c++'
  end

  # HEIF Decoding need libde265
  s.subspec 'libde265' do |ss|
    ss.dependency 'SDWebImageHEIFCoder/libheif'
    ss.source_files = 'Vendors/include/libde265/*.{h}', 'Vendors/libheif/libheif/heif_decoder_libde265.{h,c,cc}'
    ss.public_header_files = 'Vendors/include/libde265/*.{h}'
    ss.osx.vendored_libraries = 'Vendors/libde265/macOS/libde265.a'
    ss.ios.vendored_libraries = 'Vendors/libde265/iOS/libde265.a'
    ss.tvos.vendored_libraries = 'Vendors/libde265/tvOS/libde265.a'
    ss.watchos.vendored_libraries = 'Vendors/libde265/watchOS/libde265.a'
    ss.preserve_path = 'Vendors/include'
    ss.xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_LIBDE265=1',
      'HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_ROOT}/SDWebImageHEIFCoder/Vendors/include'
    }
  end

  # HEIF Encoding need libx265
  s.subspec 'libx265' do |ss|
    ss.dependency 'SDWebImageHEIFCoder/libheif'
    ss.source_files = 'Vendors/include/libx265/*.{h}', 'Vendors/libheif/libheif/heif_encoder_x265.{h,c,cc}'
    ss.public_header_files = 'Vendors/include/libx265/*.{h}'
    ss.osx.vendored_libraries = 'Vendors/libx265/macOS/libx265.a'
    ss.ios.vendored_libraries = 'Vendors/libx265/iOS/libx265.a'
    ss.tvos.vendored_libraries = 'Vendors/libx265/tvOS/libx265.a'
    ss.watchos.vendored_libraries = 'Vendors/libx265/watchOS/libx265.a'
    ss.preserve_path = 'Vendors/include'
    ss.xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_X265=1',
      'HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_ROOT}/SDWebImageHEIFCoder/Vendors/include'
    }
  end
  
  s.dependency 'SDWebImage/Core', '>= 5.0.0-beta4'
end
