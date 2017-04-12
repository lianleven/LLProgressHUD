Pod::Spec.new do |s|
  s.name         = 'LLProgressHUD'
  s.version      = '0.0.5'
  s.summary      = 'An iOS activity indicator view.'
  s.homepage     = 'https://github.com/lianleven/LLProgressHUD'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors       = { 'lianleven' => 'lianleven@163.com' }
  s.source       = { :git => 'https://github.com/lianleven/LLProgressHUD.git', :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'
  s.platform     = :ios, '7.0'
  s.source_files = 'LLProgressHUD/**/*.{h,m}'
  s.resource     = 'LLProgressHUD/LLProgressHUD.bundle'
  s.requires_arc = true
end


