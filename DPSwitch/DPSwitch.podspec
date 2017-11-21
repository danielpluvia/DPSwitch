Pod::Spec.new do |s|
  s.name         = "DPSwitch"
  s.version      = "1.0.2"
  s.summary      = "A framework which implements some custom switches in iOS."
  s.description  = "This framework provides an option for people to create a custom switch."
  s.homepage     = "https://github.com/danielpluvia/DPSwitch"
  s.license      = "MIT"
  s.author       = "Daniel"
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/danielpluvia/DPSwitch.git", :tag => "#{s.version}" }
  s.source_files = "DPSwitch/**/*"
  s.dependency 'RxSwift'
end
