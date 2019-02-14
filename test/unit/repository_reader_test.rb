# frozen_string_literal: true

require 'test_plugin_helper'

class RepositoryReaderTest < ActiveSupport::TestCase
  test 'should return file content' do
    Dir.mktmpdir do |dir|
      repository_path = "#{dir}/repo.tar.gz"
      file_name = 'README.md'
      file_content = 'Hello'

      ForemanGitTemplates::Tar.tar(repository_path) do |tar|
        tar.add_file_simple(file_name, 644, file_content.length) { |io| io.write(file_content) }
      end

      result = ForemanGitTemplates::RepositoryReader.call(repository_path, file_name)
      assert_equal file_content, result
    end
  end

  test 'should find a file in the directory and return its contents' do
    Dir.mktmpdir do |dir|
      repository_path = "#{dir}/repo.tar.gz"
      dir_name = 'provision'
      file_name = 'my_template.erb'
      file_content = 'template'
      another_file_content = 'blah'

      ForemanGitTemplates::Tar.tar(repository_path) do |tar|
        tar.add_file_simple("#{dir_name}_copy/whatever.erb", 644, another_file_content.length) { |io| io.write(another_file_content) }
        tar.add_file_simple("#{dir_name}/#{file_name}", 644, file_content.length) { |io| io.write(file_content) }
      end

      result = ForemanGitTemplates::RepositoryReader.call(repository_path, dir_name)
      assert_equal file_content, result
    end
  end

  test 'should raise RepositoryUnreadableError when repository does not exist' do
    Dir.mktmpdir do |dir|
      repository_path = "#{dir}/repo.tar.gz"

      assert_raises(ForemanGitTemplates::RepositoryReader::RepositoryUnreadableError) do
        ForemanGitTemplates::RepositoryReader.call(repository_path, 'file')
      end
    end
  end

  test 'should raise MissingFileError when file does not exist' do
    Dir.mktmpdir do |dir|
      repository_path = "#{dir}/repo.tar.gz"
      filename = 'file.erb'
      ForemanGitTemplates::Tar.tar(repository_path)

      assert_raises(ForemanGitTemplates::RepositoryReader::MissingFileError) do
        ForemanGitTemplates::RepositoryReader.call(repository_path, filename)
      end
    end
  end

  test 'should raise EmptyFileError when file is empty' do
    Dir.mktmpdir do |dir|
      repository_path = "#{dir}/repo.tar.gz"
      dir_name = 'provision'
      file_content = ''

      ForemanGitTemplates::Tar.tar(repository_path) do |tar|
        tar.add_file_simple("#{dir_name}/whatever.erb", 644, file_content.length) { |io| io.write(file_content) }
      end

      assert_raises(ForemanGitTemplates::RepositoryReader::EmptyFileError) do
        ForemanGitTemplates::RepositoryReader.call(repository_path, dir_name)
      end
    end
  end
end
