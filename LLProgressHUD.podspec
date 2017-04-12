Pod::Spec.new do |s|
  s.name         = "LLProgressHUD"
  s.version      = "0.0.3"
  s.summary      = "An iOS activity indicator view."
  s.description  = <<-DESC
                    LLProgressHUD is an iOS drop-in class that displays a translucent HUD 
                    with an indicator and/or labels while work is being done in a background thread. 
                   DESC
  s.homepage     = "https://github.com/lianleven/LLProgressHUD"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'lianleven' => 'lianleven@163.com' }
  s.source       = { :git => "https://github.com/lianleven/LLProgressHUD.git", :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'
  s.platform     = :ios, '7.0'
  s.tvos.deployment_target = '7.0'
  s.source_files = 'LLProgressHUD/**/*.{h,m}'
  s.resource     = 'LLProgressHUD/LLProgressHUD.bundle'
  s.frameworks   = "CoreGraphics", "QuartzCore"
  s.requires_arc = true
end


