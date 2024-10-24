# when you need to update the podspec:
# change the tag and s.version to reflect the tag you pushed on the project repo
# then run this command:
# pod repo push biobeats HANAudioEngine.podspec --allow-warnings --verbose
Pod::Spec.new do |s|
  s.name             = "HANAudioEngine"
  s.version          = "2.0.4"
  s.summary          = "The HearAndNow audio engine."
  s.homepage         = "https://github.com/biobeats/HANAudioEngine"
  s.license          = 'Code is BioBeats proprietary.'
  s.author           = { "Davide" => "davide@biobeats.com" }
  s.source           = { :git => "git@github.com:biobeats/HANAudioEngine.git", :tag => '2.0.4' }
  s.social_media_url = 'http://www.biobeats.com'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = ['*.pd','engineabs/*.pd','roblib/*.{pd,wav}','appsounds/*/*.{wav,m4a}', 'rjbsd/*.{pd,txt}','fluid/*.{pd,txt}','HAN_engineabs/*.{pd}', 'packs/*/*.{wav,m4a,txt}','packs/*/*/*.{wav,m4a,txt}']
  s.module_name = 'HANAudioEngine'
end
