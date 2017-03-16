Pod::Spec.new do |s|
  s.name         = 'WFDataSource'
  s.summary      = 'A block based tableview/collectionview datasource.'
  s.version      = '0.0.1'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      =  {'Jiang Wenfan' => 'jwfstars@163.com' }
  s.homepage     = 'https://github.com/jwfstars/WFDataSource'
  s.platform     = :ios, '8.0'
  s.ios.deployment_target = '8.0'
  s.source       = { :git => 'https://github.com/jwfstars/WFDataSource.git', :tag => s.version }
  
  s.source_files = 'WFDataSource/*.{h,m}'
  s.frameworks   =  'Foundation', 'UIKit'
  s.requires_arc = true

end
