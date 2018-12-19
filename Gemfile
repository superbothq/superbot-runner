source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in superbot-runner.gemspec
gemspec

unless ENV['SUPERBOT_USE_RUBYGEMS'] == "yes"
  gem "superbot-runner-side", path: "../superbot-runner-side"
end
