#
# Be sure to run `pod lib lint YamnetVad.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YamnetVad'
  s.version          = '0.1.0'
  s.summary          = 'A short description of YamnetVad.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/bberljw/YamnetVad'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '刘金伟' => 'bberljw@gmail.com' }
  s.source           = { :git => 'https://github.com/bberljw/YamnetVad.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.source_files = 'YamnetVad/Classes/**/*.{h,swift}'
  s.resource_bundles = {
    'YamnetVad' => ['YamnetVad/Assets/*']
  }
  s.dependency 'TensorFlowLiteTaskAudio', '~> 0.4.3'

end
