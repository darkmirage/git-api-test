#!/usr/bin/ruby

require 'json'
require 'octokit'
require 'logger'
require 'base64'

class GitTest
  attr_accessor :config

  def initialize
    @log = Logger.new(STDOUT)
    @log.level = Logger::WARN
    @repo = 'darkmirage/test'
    @config = {}
    config['default_branches'] = ['autopush', 'master']
    config['default_repo'] = 'darkmirage/test'
    config['test_file'] = 'files/test.xcf'

    login

    repo = config['default_repo']
    filename = config['test_file'] = 'files/test.xcf'
    
    sha = create_blob repo, filename

    repo = config['default_repo']

    branch = get_branch
    puts branch.name
    sha = branch.commit.sha
    commit = @client.commit(repo, sha)
    tree_sha = commit.commit.tree.sha

    elems = [
      {
        path: 'test.xcf',
        mode: '100644',
        type: 'blob',
        sha: sha,
        base_tree: tree_sha
      }
    ]
    tree = @client.create_tree(repo, elems)

    new_commit = @client.create_commit(repo, 'First test!', tree.sha, commit.sha)
    puts new_commit.sha

    @client.update_ref(repo, 'heads/' + branch.name, new_commit.sha)

  end

  def run
    @repos = []
    @client.repositories.each { |repo| parse_repo repo }
    @client.organizations.each do |org|
      @client.organization_repositories(org.login).each { |repo| parse_repo repo }
    end
  end

private

  def login
    token_file = File.read 'token.json'
    token_json = JSON.parse token_file
    token = token_json['token']
    @log.debug token
    @client = Octokit::Client.new(login: 'me', oauth_token: token)
  end

  def get_branch
    branches = @client.branches(config['default_repo'])
    branches.reject! { |branch| not config['default_branches'].include? branch.name }
    branches.sort_by { |branch| config['default_branches'].index branch.name }
    return branches[0]
  end

  def create_blob(repo, filename)
    input = File.read filename
    @client.create_blob(repo, Base64.encode64(input), 'base64')
  end

  def parse_repo(repo)
    @log.debug('%s (push=%s)' % [repo.full_name, repo.permissions.push])
    if (repo.permissions.push) then
      @repos.push repo.full_name
    end
  end

  # This will eventually do recursive tree traversal
  def navigate_to(path_list='')
    repo = config['default_repo']

    branch = get_branch
    sha = branch.commit.sha
    commit = @client.commit(repo, sha)
    commit.commit.tree.sha

    # tree = @client.tree(repo, tree_sha)
    # puts JSON.pretty_generate tree
  end
end


g = GitTest.new