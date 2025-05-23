Pod::Spec.new do |s|
  s.name             = 'WJXMdictParse'
  s.version          = '0.1.0'
  s.summary          = 'A Mdict dictionary parser for iOS'
  
  s.description      = <<-DESC
                      WJXMdictParse is an Objective-C library for parsing Mdict dictionary files (.mdx/.mdd) on iOS.
                      Supports various dictionary formats and provides easy-to-use APIs for dictionary parsing.
                      DESC
                      
  s.homepage         = 'https://github.com/YOURUSERNAME/WJXMdictParse'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :git => 'https://github.com/YOURUSERNAME/WJXMdictParse.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '9.0'
  
  s.source_files = 'WJXMdictParse/MdictParse/**/*'
  s.public_header_files = 'WJXMdictParse/MdictParse/*.h'
  
  s.frameworks = 'Foundation'
  s.libraries = 'z'
  s.requires_arc = true
end 