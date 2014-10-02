Pod::Spec.new do |s|
  s.name = 'AQToolkit'
  s.version = '0.0.1'
  s.license = { :type => 'BSD' }
  s.homepage = 'https://github.com/AlanQuatermain/aqtoolkit'
  s.authors = {
    'Jim Dovey (aka Alan Quatermain)' => 'jimdovey@mac.com',
    'Mark Aufflick' => 'mark@htb.io'
  }
  s.summary = 'A toolkit consisting of a bunch of generally useful routines and extensions I wrote when putting together other projects.'
  
  s.subspec 'ASLogger' do |ss|
    ss.source_files = 'ASLogger'
    ss.framework = 'Foundation'
    ss.requires_arc = false
    ss.dependency 'AQToolkit/NSObject+Properties'
    ss.dependency 'AQToolkit/NSData+Base64'
  end

  s.subspec 'AQXMLParser' do |ss|
    ss.source_files = 'StreamingXMLParser'
    ss.framework = 'Foundation'
    ss.requires_arc = false
    ss.libraries = 'xml2'
  end

  s.subspec 'NSObject+Properties' do |ss|
    ss.source_files = 'Extensions/NSObject+Properties.{h,m}'
    ss.requires_arc = false
    ss.framework = 'Foundation'
  end

  s.subspec 'NSData+Base64' do |ss|
    ss.source_files = 'Extensions/NSData+Base64.{h,m}', 'Extensions/b64.{h,m}'
    ss.requires_arc = false
    ss.framework = 'Foundation'
  end

end
