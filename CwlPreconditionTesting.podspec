Pod::Spec.new do |s|
  s.name         = 'CwlPreconditionTesting'
  s.version      = '2.0.1'
  s.summary      = "A Mach exception handler, written in Swift and Objective-C, that allows `EXC_BAD_INSTRUCTION` (as raised by Swift's `assertionFailure`/`preconditionFailure`/`fatalError`) to be caught and tested."
  s.homepage     = 'https://github.com/mattgallagher/CwlPreconditionTesting'
  s.license      = { :file => 'LICENSE.txt', :type => 'ISC' }
  s.author       = 'Matt Gallagher'
  s.source       = { :git => 'https://github.com/mattgallagher/CwlPreconditionTesting.git', :tag => s.version.to_s }
  
  s.source_files = 'Sources/CwlPreconditionTesting/**/*.swift'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  s.swift_version = '5.0'
  
  s.dependency 'CwlCatchException', '~> 2.0'
  s.dependency 'CwlMachBadInstructionHandler', '~> 2.0'

  # s.dependency 'CwlPreconditionTesting/CwlPosixPreconditionTesting'

  # s.subspec 'CwlMachBadInstructionHandler' do |ss|
  #   ss.source_files = 'Sources/CwlMachBadInstructionHandler/**/*.{h,m,c}'    
  # end

  # s.subspec 'CwlPosixPreconditionTesting' do |ss|
  #   ss.source_files = 'Sources/CwlPosixPreconditionTesting/**/*.swift'    
  # end

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/**/*.swift'
  end
end