#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint common_lib.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'common_lib'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  s.swift_version = '5.0'



  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  

  # telling CocoaPods not to remove framework
  s.preserve_paths = 'opencv2.framework', 'TensorFlowLiteC.framework'
  # telling linker to include opencv2 framework
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework opencv2 -framework TensorFlowLiteC -all_load' }
  # including OpenCV framework
  s.vendored_frameworks = 'opencv2.framework', 'TensorFlowLiteC.framework'
  # including native framework
  s.frameworks = 'AVFoundation'

  s.ios.deployment_target = '9.0'
  # including C++ library
  s.library = 'c++'

end
