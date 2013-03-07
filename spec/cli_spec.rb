require 'spec_helper'
require 'fileutils'

def clear_toggle_files_from path
  Dir.glob(File.join(path, '*'), File::FNM_DOTMATCH).each do |file|
    FileUtils.rm_f file if file =~ /((config|key)(\..*)?$|\.toggle\.local)/
  end
end

describe "CLI" do
  let(:test_dir) { File.join(File.expand_path('..', __FILE__), 'test', 'fixtures', 'cli') }

  describe "--ensure-key" do
    let(:default_key_file) { File.join(test_dir, 'key.yml.default') }
    let(:key_file)         { File.join(test_dir, 'key.yml') }
    let(:content)          { 'some_key' }

    before :all do
      clear_toggle_files_from test_dir
    end

    before :each do
      %x(echo "#{content}" > #{default_key_file})
    end

    after :each do
      clear_toggle_files_from test_dir
    end

    describe "when key does not exist" do
      it "copies the default key to the actual" do
        %x(./bin/toggle --ensure-key #{test_dir})
        FileUtils.identical?(key_file, default_key_file).should == true
      end
    end

    describe "when key already exists" do
      let(:key_content) { 'existing_key' }

      before do
        %x(echo "#{key_content}" > #{key_file})
      end

      it "leaves the current key alone" do
        %x(./bin/toggle --ensure-key #{test_dir})
        File.read(key_file).chomp.should == key_content
      end
    end
  end

  describe "--copy-config-defaults" do
    let(:default_config_file)    { File.join(test_dir, 'config.yml.default') }
    let(:actual_config_file)     { File.join(test_dir, 'config.yml') }
    let(:default_config_content) { 'DEFAULT CONFIG CONTENT' }

    before :all do
      clear_toggle_files_from test_dir
    end

    before :each do
      %x(echo "#{default_config_content}" > #{default_config_file})
    end

    after :each do
      clear_toggle_files_from test_dir
    end

    it "does not copy the key default" do
      default_key_file    = File.join(test_dir, 'key.yml.default')
      actual_key_file     = File.join(test_dir, 'key.yml')
      default_key_content = 'some_key'

      %x(echo "#{default_key_content}" > #{default_key_file})
      %x(./bin/toggle --copy-config-defaults #{test_dir})
      File.exists?(actual_key_file).should == false
    end

    describe "no config exists" do
      it "copies the default config to the actual" do
        %x(./bin/toggle --copy-config-defaults #{test_dir})
        FileUtils.identical?(actual_config_file, default_config_file).should == true
      end
    end

    describe "config is identical to default" do
      before do
        %x(cp #{default_config_file} #{actual_config_file})
      end

      it "leaves current config unchanged" do
        %x(./bin/toggle --copy-config-defaults #{test_dir})
        FileUtils.identical?(actual_config_file, default_config_file).should == true
      end
    end

    describe "actual is present and different from default" do
      let(:different_content) { "#{default_config_content} BUT DIFFERENT" }

      before do
        %x(echo "#{different_content}" > #{actual_config_file})
      end

      it "leaves current config unchanged when user responds with anything but 'y' words" do
        %x(echo 'n' | ./bin/toggle --copy-config-defaults #{test_dir})
        FileUtils.identical?(actual_config_file, default_config_file).should == false
      end

      it "replaces current config with default when user responds with 'y' words" do
        %x(echo 'y' | ./bin/toggle --copy-config-defaults #{test_dir})
        FileUtils.identical?(actual_config_file, default_config_file).should == true
        File.read(actual_config_file).chomp.should == default_config_content
      end
    end
  end

  describe "--copy-defaults" do
    let(:config_default_file)    { File.join(test_dir, 'config.yml.default') }
    let(:config_actual_file)     { File.join(test_dir, 'config.yml') }
    let(:config_default_content) { 'DEFAULT CONTENT' }
    let(:key_default_file)       { File.join(test_dir, 'key.yml.default') }
    let(:key_actual_file)        { File.join(test_dir, 'key.yml') }
    let(:key_default_content)    { 'DEFAULT CONTENT' }

    before :all do
      clear_toggle_files_from test_dir
    end

    before :each do
      %x(echo "#{config_default_content}" > #{config_default_file})
      %x(echo "#{key_default_content}"    > #{key_default_file})
    end

    after :each do
      clear_toggle_files_from test_dir
    end

    describe "copies default config and key file" do
      it "copies each default file over to its appropriate location" do
        %x(./bin/toggle --copy-defaults #{test_dir})
        FileUtils.identical?(config_default_file, config_actual_file).should == true
        FileUtils.identical?(key_default_file, key_actual_file).should == true
      end
    end

    describe "actual is identical to default" do
      before do
        %x(cp #{config_default_file} #{config_actual_file})
      end

      it "leaves current file unchanged" do
        %x(./bin/toggle --copy-defaults #{test_dir})
        FileUtils.identical?(config_default_file, config_actual_file).should == true
      end
    end

    describe "actual is present but has different content from default" do
      let(:different_content) { "#{config_default_content} BUT DIFFERENT" }

      before do
        %x(echo "#{different_content}" > #{config_actual_file})
      end

      it "leaves current file unchanged when user responds with anything but 'y' words" do
        %x(echo 'n' | ./bin/toggle --copy-defaults #{test_dir})
        FileUtils.identical?(config_default_file, config_actual_file).should == false
        File.read(config_actual_file).chomp.should == different_content
      end

      it "replaces current file with default when user responds with 'y' words" do
        %x(echo 'y' | ./bin/toggle --copy-defaults #{test_dir})
        FileUtils.identical?(config_default_file, config_actual_file).should == true
        File.read(config_actual_file).chomp.should == config_default_content
      end
    end
  end

  describe "--keys" do
    let(:config_file) { File.join(FIXTURES_PATH, 'config.yml') }

    it "alerts the user if the file is not found" do
      %x(./bin/toggle --keys /path/to/nothing).chomp.should == "toggle config file not found, please check specified path"
    end

    it "can be queried for the available keys from the commandline" do
      %x(./bin/toggle --keys #{config_file}).chomp.should == "- local\n- remote"
    end
  end

  describe "--values" do
    let(:config_file) { File.join(FIXTURES_PATH, 'config.yml') }

    it "alerts the user if the file is not found" do
      %x(./bin/toggle --values /path/to/nothing).chomp.should == "toggle config file not found, please check specified path"
    end

    it "can be queried for the available keys from the commandline" do
      %x(./bin/toggle --values #{config_file},local).should == <<-EOS.strip_heredoc
        ---
        :plain_attribute: local_plain_attribute_value
        :erb_attribute: local_erb_attribute_value
      EOS
    end
  end

  describe "--init-local" do
    let(:file) { File.join(test_dir, '.toggle.local') }

    before :all do
      clear_toggle_files_from test_dir
    end

    after :each do
      clear_toggle_files_from test_dir
    end

    describe "file does not exist" do
      it "adds .toggle.local with commons var placeholders" do
        %x(./bin/toggle --init-local #{test_dir})
        File.read(file).chomp.should == <<-EOS.strip_heredoc
          # Add any variables that you'd like below.
          #
          # We've included a few suggestions, but please feel free
          # to modify as needed.
          #
          # Make sure that you source this file in your ~/.bash_profile
          # or ~/.bashrc (or whereever you'd like) via:
          #
          # if [ -s ~/.toggle.local ] ; then source ~/.toggle.local ; fi
          export DATABASE_HOST=''
          export DATABASE_NAME=''
          export DATABASE_USERNAME=''
          export DATABASE_PASSWORD=''
          export USER_EMAIL=''
        EOS
      end
    end

    describe "file already exists" do
      before do
        %x(echo "SOME CONTENT" > #{file})
      end

      it "leaves .toggle.local unchanged when user responds with anything but 'y' words" do
        %x(echo 'n' | ./bin/toggle --init-local #{test_dir})
        File.read(file).chomp.should == 'SOME CONTENT'
      end

      it "replaces .toggle.local with default when user responds with 'y' words" do
        %x(echo 'y' | ./bin/toggle --init-local #{test_dir})
        File.read(file).chomp.should == <<-EOS.strip_heredoc
          # Add any variables that you'd like below.
          #
          # We've included a few suggestions, but please feel free
          # to modify as needed.
          #
          # Make sure that you source this file in your ~/.bash_profile
          # or ~/.bashrc (or whereever you'd like) via:
          #
          # if [ -s ~/.toggle.local ] ; then source ~/.toggle.local ; fi
          export DATABASE_HOST=''
          export DATABASE_NAME=''
          export DATABASE_USERNAME=''
          export DATABASE_PASSWORD=''
          export USER_EMAIL=''
        EOS
      end
    end
  end

  describe "--make-defaults" do
    let(:actual_key_file)     { File.join(test_dir, 'key.yml') }
    let(:default_key_file)    { File.join(test_dir, 'key.yml.default') }
    let(:actual_config_file)  { File.join(test_dir, 'config.yml') }
    let(:default_config_file) { File.join(test_dir, 'config.yml.default') }

    before :all do
      clear_toggle_files_from test_dir
    end

    after :each do
      clear_toggle_files_from test_dir
    end

    describe "when user has not created any actual or .default files" do
      it "creates a default key + config file in the passed path" do
        %x(./bin/toggle --make-defaults #{test_dir})
        File.read(default_key_file).should == <<-EOS.strip_heredoc
          # Copy this file to ./key{.exts} or run the following command:
          #
          #   $ toggle --copy-defaults [PATH]
          #
          # which will copy {config,key}{.exts}.default files in the given PATH to
          # {config,key}{exts} (removes .default extension)
          #
          # You can toggle this file to use a particular config block you have
          # set up. To view which top level blocks are available for a given key file,
          # run:
          #
          #   $ toggle --keys FILENAME
          #
          # where FILENAME is the name of a given toggle config file.
          development # <= change "development" to whatever you'd like
        EOS

        File.read(default_config_file).should == <<-EOS.strip_heredoc
          # Copy this file to ./config.yml or run the following command:
          #
          #   $ toggle --copy-defaults [PATH]
          #
          # which will copy {config,key}{,.*}.default files in the given PATH to
          # {config,key}{,.*} (removes .default extension)
          #
          # We're using the configuration conventions & setup:
          # https://git.squareup.com/iacono/toggle#configuration-conventions--setup
          #
          # If you've set up your local variables, you should be able to copy and go!
          #
          # Otherwise, run:
          #
          #   $ toggle --init-local
          #
          # And follow the instructions
          :development:
            :some: :development_setting

          :production:
            :some: :production_setting
          # define any other config blocks that you want!
        EOS
      end
    end

    describe "when user has created an actual key file but the corresponding .default file does not exist" do
      before do
        %x(echo "SOME CONTENT" > #{actual_key_file})
      end

      it "copies the actual user created key file to the corresponding .default" do
        %x(./bin/toggle --make-defaults #{test_dir})
        File.read(default_key_file).should == "SOME CONTENT\n"
      end
    end

    describe "when user has created an actual config file but the corresponding .default file does not exist" do
      before do
        %x(echo "SOME CONTENT" > #{actual_config_file})
      end

      it "copies the actual user created file to the corresponding .default" do
        %x(./bin/toggle --make-defaults #{test_dir})
        File.read(default_config_file).should == "SOME CONTENT\n"
      end
    end

    describe "when user has created .default key file" do
      before do
        %x(echo "SOME CONTENT" > #{default_key_file})
      end

      it "leaves the .default file unchanged when user responds with anything but 'y' words" do
        %x(echo 'n' | ./bin/toggle --make-defaults #{test_dir})
        File.read(default_key_file).should == "SOME CONTENT\n"
      end

      it "replaces the .default file with default when user responds with 'y' words" do
        %x(echo 'y' | ./bin/toggle --make-defaults #{test_dir})
        File.read(default_key_file).should == <<-EOS.strip_heredoc
          # Copy this file to ./key{.exts} or run the following command:
          #
          #   $ toggle --copy-defaults [PATH]
          #
          # which will copy {config,key}{.exts}.default files in the given PATH to
          # {config,key}{exts} (removes .default extension)
          #
          # You can toggle this file to use a particular config block you have
          # set up. To view which top level blocks are available for a given key file,
          # run:
          #
          #   $ toggle --keys FILENAME
          #
          # where FILENAME is the name of a given toggle config file.
          development # <= change "development" to whatever you'd like
        EOS
      end
    end

    describe "when user has created .default config file" do
      before do
        %x(echo "SOME CONTENT" > #{default_config_file})
      end

      it "leaves current config file unchanged when user responds with anything but 'y' words" do
        %x(echo 'n' | ./bin/toggle --make-defaults #{test_dir})
        File.read(default_config_file).should == "SOME CONTENT\n"
      end

      it "replaces current config file with default when user responds with 'y' words" do
        %x(echo 'y' | ./bin/toggle --make-defaults #{test_dir})
        File.read(default_config_file).should == <<-EOS.strip_heredoc
          # Copy this file to ./config.yml or run the following command:
          #
          #   $ toggle --copy-defaults [PATH]
          #
          # which will copy {config,key}{,.*}.default files in the given PATH to
          # {config,key}{,.*} (removes .default extension)
          #
          # We're using the configuration conventions & setup:
          # https://git.squareup.com/iacono/toggle#configuration-conventions--setup
          #
          # If you've set up your local variables, you should be able to copy and go!
          #
          # Otherwise, run:
          #
          #   $ toggle --init-local
          #
          # And follow the instructions
          :development:
            :some: :development_setting

          :production:
            :some: :production_setting
          # define any other config blocks that you want!
        EOS
      end
    end
  end
end
