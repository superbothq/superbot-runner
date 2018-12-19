module Superbot
  module Runner
    module CLI
      class RootCommand < Clamp::Command
        include Superbot::Validations
        include Superbot::Cloud::Validations

        parameter "RECORDING", "recording"

        option ['--browser'], 'BROWSER', "Browser type to use. Can be either local or cloud", default: 'local' do |browser|
          validates_browser_type browser
          require_login unless browser == 'cloud'
          browser
        end
        option ['--region'], 'REGION', 'Region for remote webdriver'

        def execute
          open_teleport

          file_extension = File.extname(recording)
          case file_extension
          when '.side' then Superbot::Runner::Side.run(recording)
          else abort "#{file_extension} scripts are not supported yet"
          end
        ensure
          close_teleport
        end

        private

        def open_teleport
          @teleport = Thread.new do
            Superbot::Web.run!(webdriver_type: browser, region: region)
          end

          if browser == 'local'
            chromedriver_path = Chromedriver::Helper.new.binary_path
            @chromedriver = Kommando.new "#{chromedriver_path} --silent --port=9515 --url-base=wd/hub"
            @chromedriver.run_async
          end
        end

        def close_teleport
          sleep 1
          @chromedriver&.kill
          @teleport&.kill
        end
      end
    end
  end
end
