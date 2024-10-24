# when you need to update the podspec:
# change the tag and s.version to reflect the tag you pushed on the project repo
# then run this command:
# pod repo push biobeats testpod.podspec --allow-warnings --verbose
Pod::Spec.new do |s|
  s.name             = "testpod"
  s.version          = "1.4"
  s.summary          = "just a dummy pod to test things"
  s.homepage         = "https://github.com/biobeats/testpod"
  s.license          = 'Code is BioBeats proprietary.'
  s.author           = { "Davide" => "davide@biobeats.com" }
  s.source           = { :git => "git@github.com:biobeats/testpod.git", :tag => '1.4' }
  s.social_media_url = 'http://www.biobeats.com'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.module_name = 'testpod'
  s.preserve_paths = ['audioengine/**', 'test/**']
  s.prepare_command = <<-CMD
[ -d ../../../audioengine ] && rm -r ../../../audioengine
cp -r ./audioengine ../../../
CMD
end
