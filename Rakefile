require 'rubygems'
require 'xcoder'
require 'github_api'

if File.exist?('Rakefile.config')
  load 'Rakefile.config'
end

$name="IntAirAct"

$github_user='ase-lab'
$github_repo='IntAirAct'

$configuration="Release"

project=Xcode.project($name)
$iphone=project.target($name+"IOS").config($configuration).builder
$iphone.sdk = :iphoneos
$iphonesimulator=project.target($name+"IOS").config($configuration).builder
$iphonesimulator.sdk = :iphonesimulator
$iostest=project.target($name+"IOSTests").config($configuration).builder
$osx=project.target($name+"OSX").config($configuration).builder
$osx.sdk = :macosx
$osxtest=project.target($name+"OSXTests").config($configuration).builder
$osxtest.sdk = :macosx

desc "Clean, Build, Test and Archive for iOS and OS X"
task :default => [:ios, :osx]

desc "Cleans for iOS and OS X"
task :clean => [:removebuild, "ios:clean", "osx:clean"]

desc "Builds for iOS and OS X"
task :build => ["ios:build", "osx:build"]

desc "Test for iOS and OS X"
task :test => ["ios:test", "osx:test"]

desc "Archives for iOS and OS X"
task :archive => ["ios:archive", "osx:archive"]

desc "Remove build folder"
task :removebuild do
  rm_rf "build"
end

desc "Clean, Build, Test and Archive for iOS"
task :ios => ["ios:clean", "ios:build", "ios:test", "ios:archive"]

namespace :ios do  

  desc "Clean for iOS"
  task :clean => [:init, :removebuild] do
    $iphone.clean
    $iphonesimulator.clean
  end
  
  desc "Build for iOS"
  task :build => :init do
    $iphone.build
  end
  
  desc "Test for iOS"
  task :test => :init do
    $iostest.test do |report|
	  report.add_formatter :junit, 'build/'+$configuration+'-iphonesimulator/test-reports'
      report.add_formatter :stdout
    end
  end
  
  desc "Archive for iOS"
  task :archive => ["ios:clean", "ios:build", "ios:test"] do
    cd "build/" + $configuration + "-iphoneos" do
      sh "tar cvzf ../" + $name + "IOS.tar.gz *.framework"
    end
  end

end

desc "Clean, Build, Test and Archive for OS X"
task :osx => ["osx:clean", "osx:build", "osx:test", "osx:archive"]

namespace :osx do

  desc "Clean for OS X"
  task :clean => [:init, :removebuild] do
    $osx.clean
  end

  desc "Build for OS X"
  task :build => :init do
    $osx.build
  end
  
  desc "Test for OS X"
  task :test => :init do
    $osxtest.test(:sdk => :macosx) do |report|
	  report.add_formatter :junit, 'build/'+$configuration+'/test-reports'
      report.add_formatter :stdout
    end
  end

  desc "Archive for OS X"
  task :archive => ["osx:clean", "osx:build", "osx:test"] do
    cd "build/" + $configuration do
      sh "tar cvzf ../" + $name + "OSX.tar.gz *.framework"
    end
  end

end

desc "Initialize and update all submodules recursively"
task :init do
  system("git submodule update --init --recursive")
  system("git submodule foreach --recursive git checkout master")
end

desc "Pull all submodules recursively"
task :pull => :init do
  system("git submodule foreach --recursive git pull")
end

def publish(version, os = "IOS")
  github = Github.new :user => $github_user, :repo => $github_repo, :login => $github_login, :password => $github_password
  file = 'build/' + $name + os + ".tar.gz"
  name = $name + os + '-' + version + '.tar.gz'
  size = File.size(file)
  description = os + " Framework version " + version
  res = github.repos.downloads.create $github_user, $github_repo,
    "name" => name,
    "size" => size,
    "description" => description,
    "content_type" => "application/x-gzip"
  github.repos.downloads.upload res, file
end

desc "Publish a new version of the framework to github"
task :publish, :version do |t, args|
  if !args[:version]
    puts("Usage: rake publish[version]");
    exit(1)
  end
  if !defined? $github_login
    puts("$github_login is not set");
    exit(1)
  end
  if !defined? $github_password
    puts("$github_password is not set");
    exit(1)
  end
  version = args[:version]
  #check that version is newer than current_version
  current_version = open("Version").gets.strip
  if Gem::Version.new(version) < Gem::Version.new(current_version)
    puts("New version (" + version + ") is smaller than current version ("+current_version+")")
    exit(1)
  end
  #write version into versionfile
  File.open("Version", 'w') {|f| f.write(version) }
  Rake::Task["archive"].invoke
  system("git add Version")
  system('git commit -m "Bump version to ' + version + '"')
  system('git tag -a v' + version + ' -m "Framework version ' + version + '."')
  system('git push')
  system('git push --tags')
  publish(version)
  publish(version, "OSX")
end
