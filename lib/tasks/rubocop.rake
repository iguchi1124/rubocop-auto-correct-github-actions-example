require 'octokit'
require 'rubocop'

namespace :rubocop do
  task :auto_correct_pull_request, :environment do
    todos = YAML.load_file('.rubocop_todo.yml')
    cops = todos.keys.map { |cop_name| RuboCop::Cop::Registry.all.find { |klass| klass.cop_name == cop_name } }.select(&:support_autocorrect?)
    cop = cops.sample

    title = "RuboCop auto-correct #{cop.cop_name}"
    branch = "rubocop/auto-correct/#{cop.cop_name}"
    sh "git switch -c #{branch}"

    sh 'cat /dev/null > .rubocop_todo.yml'
    sh "rubocop -a --only #{cop.cop_name}"
    sh 'rubocop --regenerate-todo'

    sh 'git add .'
    sh "git commit -m '#{title}'"
    sh "git push origin #{branch}"

    octokit_client = Octokit::Client.new
    octokit_client.create_pull_request(ENV['GITHUB_REPOSITORY'], 'main', branch, title)
  end
end
