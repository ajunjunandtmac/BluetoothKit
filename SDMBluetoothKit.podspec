#
# Be sure to run `pod lib lint BluetoothKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name                  = 'SDMBluetoothKit'
  s.version               = '0.0.2'
  s.summary               = 'Bluetooth SDK'
  s.description           = <<-DESC
    BluetoothKit is a SDK that allows you easily and quickly develop an application with CoreBluetooth.
                       DESC
  s.homepage              = 'http://git.woodare.com'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'Stationdm' => "120489458@qq.com" }

  s.source                = {
      :git => 'https://github.com/ajunjunandtmac/BluetoothKit.git', :tag => "#{s.version}"
  }

  s.ios.deployment_target = '11.0'
  s.ios.vendored_frameworks = 'BluetoothSDK.xcframework'
  s.requires_arc          = true  
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
