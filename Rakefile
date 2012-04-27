require 'rubygems'
require 'xcoder'

$name="Interact"
$configuration="Release"

def builder(os = "IOS")
  builder = Xcode.project($name).target($name+os).config($configuration).builder
  (os == "OSX") ? builder.sdk = :macosx : builder.sdk = :iphoneos
  builder
end

desc "Clean and Build"
task :default => [:clean, :build]

desc "Cleans everything"
task :clean => [:iosclean, :osxclean] do
	rm_rf "build"
end

desc "Clean for iOS"
task :iosclean => :init do
  builder().clean
end

desc "Clean for OS X"
task :osxclean => :init do
  builder("OSX").clean
end

desc "Builds for iOS and OS X"
task :build => [:iosbuild, :osxbuild]

desc "Build for iOS"
task :iosbuild => :init do
  builder().build
end

desc "Build for OS X"
task :osxbuild => :init do
  builder("OSX").build
end

desc "Test for iOS and OS X"
task :test => [:iostest, :osxtest]

desc "Test for iOS"
task :iostest do
  builder("IOSTests").test(:sdk => :iphonesimulator)
end

desc "Test for OS X"
task :osxtest do
  builder("OSXTests").test(:sdk => :macosx)
end

desc "Creates archives of the frameworks"
task :archive => [:clean, :build] do
  cd "build/" + $configuration + "-iphoneos" do
    sh "tar cvzf ../" + $name + "IOS.tar.gz " + $name + ".framework"
  end
  cd "build/" + $configuration do
    sh "tar cvzf ../" + $name + "OSX.tar.gz " + $name + ".framework"
  end
end

desc "Initialize and update all submodules"
task :init do
  system("git submodule update --init --recursive")
end

desc "Pull all submodules"
task :pull => :init do
  system("git submodule foreach --recursive git pull origin master")
end
