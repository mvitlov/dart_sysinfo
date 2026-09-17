#
# Run `pod lib lint dart_sysinfo.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dart_sysinfo'
  s.version          = '0.1.0'
  s.summary          = 'Cross-platform system information for Dart and Flutter.'
  s.description      = <<-DESC
Cross-platform system information for Dart and Flutter.
                       DESC
  s.homepage         = 'https://github.com/example/dart_sysinfo'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'dart_sysinfo contributors' => 'email@example.com' }
  s.module_name      = 'dart_sysinfo'

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../../native dart_sysinfo_native',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    :output_files => ["${PODS_CONFIGURATION_BUILD_DIR}/dart_sysinfo/libdart_sysinfo_native.a"],
  }
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${PODS_CONFIGURATION_BUILD_DIR}/dart_sysinfo/libdart_sysinfo_native.a',
  }
  s.swift_version = '5.0'
end
