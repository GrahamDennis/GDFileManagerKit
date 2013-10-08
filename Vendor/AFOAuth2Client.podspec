Pod::Spec.new do |s|
  s.name     = 'AFOAuth2Client'
  s.version  = '0.1.1'
  s.license  = 'MIT'
  s.summary  = 'AFNetworking Extension for OAuth 2 Authentication.'
  s.homepage = 'https://github.com/AFNetworking/AFOAuth2Client'
  s.author   = { 'Mattt Thompson' => 'm@mattt.me' }
  s.source   = { :git => 'https://github.com/AFNetworking/AFOAuth2Client.git',
                 :tag => '0.1.1' }
  s.source_files = 'AFOAuth2Client'
  s.requires_arc = true

  s.dependency 'AFNetworking', '~>1'

  s.ios.frameworks = 'Security', 'SystemConfiguration', 'MobileCoreServices'

  s.prefix_header_contents = <<-EOS
#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <MobileCoreServices/MobileCoreServices.h>
  #import <Security/Security.h>
#else
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <CoreServices/CoreServices.h>
  #import <Security/Security.h>
#endif
EOS
end