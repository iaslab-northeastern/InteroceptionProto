Pod::Spec.new do |s|
  s.name             = 'BreathingExerciseEngine'
  s.version          = '0.0.1'
  s.summary          = 'An engine to guide a deep breathing exercise.'

  s.homepage         = "https://github.com/biobeats/BundledBreathingExercise"
  
  s.license          = 'Code is BioBeats proprietary.'
  s.author           = { 'Matteo Puccinelli' => 'matteo.puccinelli@huma.com' }
  s.source           = { :git => 'git@github.com:biobeats/BundledBreathingExercise.git', :tag => s.version.to_s }
  

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'ios/BreathingExerciseEngine/Sources/**/*'
  s.dependency 'HeartDetectorEngine'
  
end
