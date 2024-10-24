# when you need to update the podspec:
# change the tag and s.version to reflect the tag you pushed on the project repo
# then run this command:
# pod repo push biobeats HeartDetectorEngine.podspec --allow-warnings
Pod::Spec.new do |s|
  s.name             = "HeartDetectorEngine"
  s.version          = "1.30"
  s.summary          = "The BioBeats heart and breath detector engine."
  s.homepage         = "http://gitlab.biobeats.com/biobeats/HeartRateDetector"
  s.license          = 'Code is BioBeats proprietary.'
  s.author           = { "Davide" => "davide@biobeats.com" }
  s.source           = { :git => "git@40.74.62.125:biobeats/HeartRateDetector.git", :tag => 'v1.30' }
  s.social_media_url = 'http://www.biobeats.com'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = ['HeartDetectorEngine/HeartDetectorEngine/*.{h,m}','HeartDetectorEngine/Helpers/*.{h,m}','HeartDetectorEngine/Pipeline/*.{h,m}','HeartDetectorEngine/Stream/*.{h,m}']

  s.frameworks = 'AVFoundation', 'Accelerate', 'CoreMotion', 'Foundation'
  s.module_name = 'HeartDetectorEngine'
end
