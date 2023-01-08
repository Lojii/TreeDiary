 #
 # To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
 # Run `pod lib lint libgit2dart.podspec` to validate before publishing.
 #
 Pod::Spec.new do |s|
   s.name             = 'libgit2dart'
   s.version          = '1.5.0'
   s.summary          = 'libgit2dart.'
   s.description      = <<-DESC
                        libgit2dart.
                        DESC
   s.homepage         = 'https://www.king.com'
   s.license          = { :file => '../LICENSE' }
   s.author           = { 'lojii' => 'lojii@plant.com' }
   s.source           = { :path => '.' }
   s.source_files = 'Classes/**/*'
   s.dependency 'Flutter'
   s.platform = :ios, '11.0'

   s.vendored_frameworks = 'xcframework/*.xcframework'
   s.xcconfig = { 'OTHER_LDFLAGS' => '-all_load' }
   s.libraries = 'z', 'iconv'

   s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
   s.swift_version = '5.0'
 end
