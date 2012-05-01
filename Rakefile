require 'rubygems'
require 'xcoder'

$name="Interact"
$configuration="Release"

def builder(os = "IOS")
  builder = Xcode.project($name).target($name+os).config($configuration).builder
  (os == "OSX") ? builder.sdk = :macosx : builder.sdk = :iphoneos
  builder
end

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
    builder().clean
    b = builder()
    b.sdk = :iphonesimulator
    b.clean
  end
  
  desc "Build for iOS"
  task :build => :init do
    builder().build
  end
  
  desc "Test for iOS"
  task :test => :init do
    puts("Tests for iOS are not implemented - hopefully (!) - yet.")
    #builder("IOSTests").test(:sdk => :iphonesimulator)
  end
  
  desc "Archive for iOS"
  task :archive => ["ios:clean", "ios:build", "ios:test"] do
    cd "build/" + $configuration + "-iphoneos" do
      sh "tar cvzf ../" + $name + "IOS.tar.gz " + $name + ".framework"
    end
  end

end

desc "Clean, Build, Test and Archive for iOS"
task :osx => ["osx:clean", "osx:build", "osx:test", "osx:archive"]

namespace :osx do

  desc "Clean for OS X"
  task :clean => [:init, :removebuild] do
    builder("OSX").clean
  end

  desc "Build for OS X"
  task :build => :init do
    builder("OSX").build
  end
  
  desc "Test for OS X"
  task :test => :init do
    puts("Tests for OS X are not implemented - hopefully (!) - yet.")
    #builder("OSXTests").test(:sdk => :macosx)
  end

  desc "Archive for OS X"
  task :archive => ["osx:clean", "osx:build", "osx:test"] do
    cd "build/" + $configuration do
      sh "tar cvzf ../" + $name + "OSX.tar.gz " + $name + ".framework"
    end
  end

end

desc "Initialize and update all submodules recursively"
task :init do
  system("git submodule update --init --recursive")
end

desc "Pull all submodules recursively"
task :pull => :init do
  system("git submodule foreach --recursive git pull origin master")
end

desc "Create docs"
task :docs do
  system('appledoc --project-name ' + $name + ' --project-company "ASE" --company-id org.agilesoftwareengineering --output ./build/docs --no-install-docset --keep-intermediate-files ' + $name + '/*.h')
end

desc "Publish docs"
task :publishdocs => :docs do
  cd "build" do
    if !File.exists?("docs-repo")
      system("git clone -b gh-pages git@github.com:ArloL/Interact.git docs-repo")
    end
    cd "docs-repo" do
      system("git pull")
      system("cp -R ../docs/html docs")
      system("git add docs")
      system('git commit -m "Updated docs"')
      system("git push")
    end
  end
end
