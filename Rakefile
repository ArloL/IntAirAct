require 'rubygems'
require 'xcoder'

# The name of the project (also used for the Xcode project and loading the schemes)
$name='IntAirAct'

workspace = Xcode.workspace($name)
$ios = workspace.scheme($name + 'IOS').builder
$osx = workspace.scheme($name + 'OSX').builder

desc 'Clean, Build, Test and Archive for iOS and OS X'
task :default => [:ios, :osx]

desc 'Remove the build folder'
task :clean do
    rm_rf 'Build'
end

desc 'Builds for iOS and OS X'
task :build => ['clean', 'ios:build', 'osx:build']

desc 'Test for iOS and OS X'
task :test => ['ios:test', 'osx:test']

desc 'Archives for iOS and OS X'
task :archive => ['ios:archive', 'osx:archive']

desc 'Clean, Build, Test and Archive for iOS'
task :ios => ['ios:clean', 'ios:build', 'ios:test', 'ios:archive']

namespace :ios do

    desc 'Clean for iOS'
    task :clean do
        $ios.clean
    end

    desc 'Build for iOS'
    task :build do
        $ios.build
    end

    desc 'Test for iOS'
    task :test do
        report = $ios.test(:sdk => :iphonesimulator) do |report|
            report.add_formatter :stdout
        end
        if report.failed?
            fail('At least one test failed.')
        end
    end

    desc 'Archive for iOS'
    task :archive => ['ios:clean', 'ios:build', 'ios:test'] do
        cd 'Build/Products/Release-iphoneos' do
            run('tar cvzf "../' + $name + '-iOS.tar.gz" *.framework')
        end
    end

end

desc 'Clean, Build, Test and Archive for OS X'
task :osx => ['osx:clean', 'osx:build', 'osx:test', 'osx:archive']

namespace :osx do

    desc 'Clean for OS X'
    task :clean do
        $osx.clean
    end

    desc 'Build for OS X'
    task :build do
        $osx.build
    end

    desc 'Test for OS X'
    task :test do
        report = $osx.test do |report|
            report.add_formatter :stdout
        end
        if report.failed?
            fail('At least one test failed.')
        end
    end

    desc 'Archive for OS X'
    task :archive => ['osx:clean', 'osx:build', 'osx:test'] do
        cd 'Build/Products/Release' do
            run('tar cvzf "../' + $name + '-OSX.tar.gz" *.framework')
        end
    end

end

desc 'Increment version'
task :publish, :version do |t, args|
    if !args[:version]
        fail('Usage: rake publish[version]');
    end
    version = args[:version]
    # check that version is newer than current_version
    current_version = open('Version').gets.strip
    if Gem::Version.new(version) < Gem::Version.new(current_version)
        fail('New version (' + version + ') is smaller than current version (' + current_version + ')')
    end
    run('git flow release start ' + version)
    # write version into versionfile
    File.open('Version', 'w') {|f| f.write(version) }

    Rake::Task['archive'].invoke

    # build was successful, increment version and push changes
    run('git add Version')
    run('git commit -m "Update version to ' + version + '"')
    run('git checkout master')
    run('git merge --no-ff -m "Merge branch \'release/' + version + '\'" release/' + version)
    run('git tag -a -m "Release ' + version + '" v' + version)
    run('git checkout develop')
    run('git merge --no-ff -m "Merge branch \'release/' + version + '\'" release/' + version)
    run('git branch -d release/' + version)
    run('git push')
    run('git push --tags')
end

def run cmd
    result = system(cmd)
    if !result
        fail('System command failed: ' + cmd)
    end
    result
end
