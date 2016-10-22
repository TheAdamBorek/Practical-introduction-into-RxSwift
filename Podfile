# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'RxSwiftBasicUsage+API' do
  use_frameworks!
  pod 'RxSwift', '3.0.0-rc.1'
  pod 'RxCocoa', '3.0.0-rc.1'
  pod 'RxOptional'
  pod 'Alamofire'
  pod 'RxSwiftExt', :git => "https://github.com/RxSwiftCommunity/RxSwiftExt", :branch => "swift3"
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
