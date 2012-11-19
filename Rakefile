require 'rubygems'
require 'xcoder'
require 'github_api'

# This file stores $github_login and $github_password which are
# used for publishing a download
if File.exist?('Rakefile.config')
  load 'Rakefile.config'
end

# The name of the project (also used for the Xcode project and loading the schemes)
$name='IntAirAct'

# The user and repository name on GitHub. Used when publishing a download.
$github_user='ase-lab'
$github_repo='IntAirAct'

# The configuration to build: 'Debug' or 'Release'
$configuration='Release'

desc 'Clean, Build, Test and Archive for iOS and OS X'
task :default => [:ios, :osx]

desc 'Cleans for iOS and OS X'
task :clean => [:remove_build_dir, 'ios:clean', 'osx:clean']

desc 'Builds for iOS and OS X'
task :build => ['ios:build', 'osx:build']

desc 'Test for iOS and OS X'
task :test => ['ios:test', 'osx:test']

desc 'Archives for iOS and OS X'
task :archive => ['ios:archive', 'osx:archive']

desc 'Remove build folder'
task :remove_build_dir do
  rm_rf 'build'
end

$project
$ios
$iostests
$osx
$osxtests

task :load_project do
  $project = Xcode.project($name)
  $ios = $project.target($name+'IOS').config($configuration).builder
  $iostests = $project.target($name+'IOSTests').config($configuration).builder
  $osx = $project.target($name+'OSX').config($configuration).builder
  $osx.sdk = :macosx
  $osxtests = $project.target($name+'OSXTests').config($configuration).builder
  $osxtests.sdk = :macosx
end

desc 'Clean, Build, Test and Archive for iOS'
task :ios => ['ios:clean', 'ios:build', 'ios:test', 'ios:archive']

namespace :ios do

  desc 'Clean for iOS'
  task :clean => [:init, :remove_build_dir, :load_project] do
    $ios.clean
  end
  
  desc 'Build for iOS'
  task :build => [:init, :load_project] do
    $ios.build
  end
  
  desc 'Test for iOS'
  task :test => [:init, :load_project] do
    $iostests.build
    report = $iostests.test do |report|
	  report.add_formatter :junit, 'build/'+$configuration+'-iphonesimulator/test-reports'
      report.add_formatter :stdout
    end
    if report.failed? || report.suites.count == 0  || report.suites[0].tests.count == 0
      fail('At least one test failed.')
    end
  end
  
  desc 'Archive for iOS'
  task :archive => ['ios:clean', 'ios:build', 'ios:test'] do
    cd 'build/' + $configuration + '-iphoneos' do
      system('tar cvzf "../' + $name + '-iOS.tar.gz" *.framework')
    end
  end

end

desc 'Clean, Build, Test and Archive for OS X'
task :osx => ['osx:clean', 'osx:build', 'osx:test', 'osx:archive']

namespace :osx do

  desc 'Clean for OS X'
  task :clean => [:init, :remove_build_dir, :load_project] do
    $osx.clean
  end

  desc 'Build for OS X'
  task :build => [:init, :load_project] do
    $osx.build
  end
  
  desc 'Test for OS X'
  task :test => [:init, :load_project] do
    $osxtests.build
    report = $osxtests.test(:sdk => :macosx) do |report|
	  report.add_formatter :junit, 'build/'+$configuration+'/test-reports'
      report.add_formatter :stdout
    end
    if report.failed? || report.suites.count == 0  || report.suites[0].tests.count == 0
      fail('At least one test failed.')
    end
  end

  desc 'Archive for OS X'
  task :archive => ['osx:clean', 'osx:build', 'osx:test'] do
    cd 'build/' + $configuration do
      system('tar cvzf "../' + $name + '-OSX.tar.gz" *.framework')
    end
  end
  
  desc 'Code coverage for OS X'
  task :coverage => ['osx:clean'] do
    config = $project.target($name+'OSX').config($configuration)
    # set build settings
    config.append "GCC_GENERATE_TEST_COVERAGE_FILES", "YES"
    config.append "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS", "YES"
    $project.save!
    $osxtests.build
    report = $osxtests.test(:sdk => :macosx) do |report|
      report.add_formatter :stdout
    end
    if report.failed? || report.suites.count == 0  || report.suites[0].tests.count == 0
      fail('At least one test failed.')
    end
    # analyze the coverage data
    system('lcov --directory "build/' + $name + '.build/Release/' + $name + 'OSX.build/Objects-normal/x86_64" --capture --output-file build/lcov.info')
    system('lcov --extract build/lcov.info /*IntAirAct/* --output build/lcov.info')
    system('lcov --remove build/lcov.info /*IntAirAct/Frameworks* --output build/lcov.info')
    # create the html pages
    system('genhtml --branch-coverage --output-directory build/lcov build/lcov.info')
    # revert project.pbxproj
    system('git checkout "' + $name + '.xcodeproj/project.pbxproj"')
  end

end

desc 'Initialize and update all submodules recursively'
task :init do
  system('git submodule update --init --recursive')
  system('git submodule foreach --recursive "git checkout master"')
end

desc 'Pull all submodules recursively'
task :pull => :init do
  system('git submodule foreach --recursive git pull')
end

def publish(version, os)
  file = 'build/' + $name + '-' + os + '.tar.gz'
  name = $name + '-' + os + '-' + version + '.tar.gz'
  description = os + ' Framework version ' + version

  size = File.size(file)

  github = Github.new(:user => $github_user,
                      :repo => $github_repo,
                      :login => $github_login,
                      :password => $github_password)
  res = github.repos.downloads.create $github_user, $github_repo,
    'name' => name,
    'size' => size,
    'description' => description,
    'content_type' => 'application/x-gzip'
  github.repos.downloads.upload res, file
end

desc 'Publish a new version to GitHub'
task :publish, :version do |t, args|
  if !args[:version]
    puts('Usage: rake publish[version]');
    exit(1)
  end
  if !defined? $github_login
    puts('$github_login is not set');
    exit(1)
  end
  if !defined? $github_password
    puts('$github_password is not set');
    exit(1)
  end
  version = args[:version]
  # check that version is newer than current_version
  current_version = open('Version').gets.strip
  if Gem::Version.new(version) < Gem::Version.new(current_version)
    puts('New version (' + version + ') is smaller than current version (' + current_version + ')')
    exit(1)
  end
  # write version into versionfile
  File.open('Version', 'w') {|f| f.write(version) }

  Rake::Task['archive'].invoke
  
  # build was successful, increment version and push changes
  system('git add Version')
  system('git commit -m "Bump version to ' + version + '"')
  system('git tag -a v' + version + ' -m "Framework version ' + version + '."')
  system('git push')
  system('git push --tags')

  publish(version, 'iOS')
  publish(version, 'OSX')
end
