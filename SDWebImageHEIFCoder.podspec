#
# Be sure to run `pod lib lint SDWebImageHEIFCoder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SDWebImageHEIFCoder'
  s.version          = '0.1.0'
  s.summary          = 'A short description of SDWebImageHEIFCoder.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/DreamPiggy/SDWebImageHEIFCoder'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DreamPiggy' => 'lizhuoli1126@126.com' }
  s.source           = { :git => 'https://github.com/DreamPiggy/SDWebImageHEIFCoder.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.osx.deployment_target = '10.10'
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'SDWebImageHEIFCoder/Classes/**/*', 'Vendors/libheif/src/*.{h,cc}'
  s.exclude_files = 'Vendors/libheif/src/*-fuzzer.{h,cc}', 'Vendors/libheif/src/heif.h'
  s.public_header_files = 'SDWebImageHEIFCoder/Classes/**/*.h'
  s.xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_UNISTD_H=1',
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}/../../Vendors/include" "${PODS_ROOT}/../../Vendors/include/libheif"'
  }
  s.libraries = 'c++'

  # HEIF Decoding need libde265
  s.subspec 'libde265' do |ss|
    ss.source_files = 'Vendors/include/libde265/*.{h}'
    ss.osx.vendored_libraries = 'Vendors/libde265/macOS/libde265.a'
    ss.ios.vendored_libraries = 'Vendors/libde265/iOS/libde265.a'
    ss.tvos.vendored_libraries = 'Vendors/libde265/iOS/libde265.a'
    ss.xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_LIBDE265=1',
    }
  end

  # HEIF Encoding need libx265
  s.subspec 'libx265' do |ss|
    ss.source_files = 'Vendors/include/libx265/*.{h}'
    ss.osx.vendored_libraries = 'Vendors/libx265/macOS/libx265.a'
    ss.ios.vendored_libraries = 'Vendors/libx265/iOS/libx265.a'
    ss.tvos.vendored_libraries = 'Vendors/libx265/iOS/libx265.a'
    ss.xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_X265=1',
    }
  end
  
  s.dependency 'SDWebImage/Core', '~> 4.2'
end
