Pod::Spec.new do |s|
  s.name         = 'CwlPreconditionTesting'
  s.version      = '2.1.2'
  s.summary      = 'A Mach exception handler, written in Swift and Objective-C, that allows `EXC_BAD_INSTRUCTION` to be caught and tested.'
  s.homepage     = 'https://github.com/mattgallagher/CwlPreconditionTesting'
  s.license      = { :file => 'LICENSE.txt', :type => 'ISC' }
  s.author       = 'Matt Gallagher'
  s.source       = {
                    :git => 'https://github.com/mattgallagher/CwlPreconditionTesting.git',
                    :tag => s.version.to_s
                   }
  
  s.source_files = 'Sources/CwlPreconditionTesting/**/*.swift'

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'
  s.visionos.deployment_target = '1.0'

  s.swift_version = '5.5'
  
  s.dependency 'CwlCatchException', '~> 2.1.2'
  s.dependency 'CwlMachBadInstructionHandler', '~> 2.1.2'
  s.dependency 'CwlPosixPreconditionTesting', '~> 2.1.2'

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/**/*.swift'
  end
end
