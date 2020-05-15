#
# Be sure to run `pod lib lint SDWebImageHEIFCoder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SDWebImageHEIFCoder'
  s.version          = '0.8.0'
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
  s.default_subspec = 'libde265'

  # HEIF core dependency
  s.subspec 'libheif' do |ss|
    ss.dependency 'libheif/libheif', '>= 1.6.0'
    ss.source_files = 'SDWebImageHEIFCoder/Classes/**/*', 'SDWebImageHEIFCoder/Module/SDWebImageHEIFCoder.h'
  end

  # HEIF Decoding need libde265
  s.subspec 'libde265' do |ss|
    ss.dependency 'libheif/libde265'
    ss.dependency 'SDWebImageHEIFCoder/libheif'
    ss.xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_LIBDE265=1'
    }
  end

  # HEIF Encoding need libx265
  s.subspec 'libx265' do |ss|
    ss.dependency 'libheif/libx265'
    ss.dependency 'SDWebImageHEIFCoder/libheif'
    ss.xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_X265=1'
    }
  end
  
  s.dependency 'SDWebImage/Core', '~> 5.8'
end
