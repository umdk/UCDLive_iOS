#
#  Be sure to run `pod spec lint UCDLive_iOS.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

 
  s.name         = "UCDLive_iOS"
  s.version      = "1.8.0"
  s.summary      = "A short description of UCDLive_iOS."

  s.description  = <<-DESC
  								UCDLive_iOS is used for live playing.
                   DESC

  s.homepage     = "https://github.com/umdk/UCDLive_iOS"

  s.license      = "MIT"
  s.author             = { "aplaycat" => "2398585702@qq.com.com" }
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/umdk/UCDLive_iOS.git", 
                     :tag => 'v'+ s.version.to_s
                   }

  s.requires_arc = true
  s.ios.library = 'z', 'iconv', 'stdc++.6','c++'
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC -all_load' }

  s.subspec 'Agora' do |sub|
    sub.vendored_frameworks = 'Agora/*.framework'
  end

  s.subspec 'libyuv' do |sub|
    sub.source_files = '*.h','libyuv/*.h'
    sub.vendored_library = 'libyuv.a'
  end
  
   s.subspec 'Player' do |sub|
    sub.source_files = 'Player/*.h'
    sub.vendored_library = 'Player/*.a'
  end

   s.subspec 'Recorder' do |sub|
   sub.resources = 'Recorder/res/*.png'
   sub.source_files = 'Recorder/*.{h,m}','Recorder/include/UCloudGPUImage/*.h','Recorder/include/UCloudGPUImage/**/*.h'
   sub.vendored_library = 'Recorder/*.a'
  end

end
