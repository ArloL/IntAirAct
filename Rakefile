require 'rubygems'
require 'xcodebuild'

name = "Interact"
configuration = "Release"
build_dir = "build"
xcode_config = "BUILD_DIR=\"" + File.dirname(__FILE__) + "/" + build_dir + "\""

@ios = XcodeBuild::Tasks::BuildTask.new "ios" do |t|
	t.scheme = name + "IOS"
	t.configuration = configuration
end

@osx = XcodeBuild::Tasks::BuildTask.new "osx" do |t|
	t.scheme = name +  "OSX"
	t.configuration = configuration
end

desc "Calls :clean and :build"
task :default => [:clean, :build]

desc "Builds for iOS and OS X"
task :build => [:iosbuild, :osxbuild]

task :iosbuild do
	@ios.send(:xcodebuild, xcode_config + " build")
end

task :osxbuild do
	@osx.send(:xcodebuild, xcode_config + " build")
end

desc "Clean up build folders."
task :clean => [:iosclean, :osxclean] do
	rm_rf "build"
end

task :iosclean do
	@ios.send(:xcodebuild, xcode_config + " clean")
end

task :osxclean do
	@osx.send(:xcodebuild, xcode_config + " clean")
end

desc "Creates archives of the frameworks"
task :archive => [:clean, :build] do
    cd build_dir + "/Release-iphoneos" do
      sh "tar cvzf ../" + name + "IOS.tar.gz " + name + ".framework"
    end
    cd build_dir + "/Release" do
      sh "tar cvzf ../" + name + "OSX.tar.gz " + name + ".framework"
    end
end
