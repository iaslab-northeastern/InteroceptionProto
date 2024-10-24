# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'
source ‘https://github.com/CocoaPods/Specs.git’
# source 'git@github.com:biobeats/podrepo.git’

target 'InteroceptionProto' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for InteroceptionProto
 
  pod 'AppCenter'
  pod 'AppCenter/Distribute'
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'FirebaseUI/Storage'
  pod 'Firebase/Database'
  pod 'SwiftKeychainWrapper'
  pod 'SwiftDate'
  pod 'Firebase/Crashlytics'
  pod 'HeartDetectorEngine', :path => './podrepo-master/HDE'
  
  target 'InteroceptionProtoTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'InteroceptionProtoUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
