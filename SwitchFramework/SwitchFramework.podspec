Pod::Spec.new do |s|
  s.name         = "SwitchFramework"
  s.version      = "1.0.0"
  s.summary      = "This is a framework of switch."
  s.description  = "This framework helps you build a switch with spring animation."
  s.homepage     = "https://github.com/danielpluvia/iOSSwitch"
  s.license      = "MIT"
  s.author    = "Daniel"
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/danielpluvia/iOSSwitch.git", :tag => "#{s.version}" }
  s.source_files  = "SwitchFramework/**/*"
end
