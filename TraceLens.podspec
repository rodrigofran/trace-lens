Pod::Spec.new do |s|
  s.name = 'TraceLens'
  s.version = '0.1.0'
  s.summary = 'Network observability toolkit for iOS.'
  s.homepage = 'https://github.com/rodrigofran/trace-lens'
  s.author = { 'Rodrigo' => 'rodrigofrancms@gmail.com' }
  s.source = { :git => 'https://github.com/rodrigofran/trace-lens.git', :tag => s.version.to_s }

  s.platform = :ios, '15.0'
  s.swift_version = '6.0'
  s.source_files = 'Sources/TraceLens/**/*.swift'
  s.dependency 'TraceLensCore', s.version.to_s
  s.dependency 'TraceLensStorage', s.version.to_s
  s.dependency 'TraceLensMetrics', s.version.to_s
  s.dependency 'TraceLensCapture', s.version.to_s
  s.dependency 'TraceLensUI', s.version.to_s
end
