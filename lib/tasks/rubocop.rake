require 'octokit'
require 'rubocop'

def system!(*args)
  system(*args) || abort
end

namespace :rubocop do
  task :auto_correct_pull_request, :environment do
    todos = YAML.load_file '.rubocop_todo.yml'
    cops = todos.keys.map { |cop_name| RuboCop::Cop::Registry.all.find { |klass| klass.cop_name == cop_name } }.select(&:support_autocorrect?)
    cop = cops.sample

    title = "RuboCop auto-correct #{cop.cop_name}"
    branch = "rubocop/auto-correct/#{cop.cop_name}"
    system! "git switch -c #{branch}"

    system! 'cat /dev/null > .rubocop_todo.yml'
    system! "rubocop -a --only #{cop.cop_name}"
    system! 'rubocop --regenerate-todo'

    system! 'git add .'
    system! "git commit -m '#{title}'"
    system! "git push origin #{branch}"

    octokit_client = Octokit::Client.new
    octokit_client.create_pull_request(ENV['GITHUB_REPOSITORY'], 'main', branch, title)
  end
end
