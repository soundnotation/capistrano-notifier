class Capistrano::Notifier::Base
  def initialize()
  end

  private

  def application
    fetch :application
  end

  def branch
    fetch :branch
  end

  def git_current_revision
    fetch(:current_revision).try(:[], 0,7)
  end

  def git_log
    return unless git_range
    cmd = "git log #{git_range} "
    cmd << '--no-merges ' unless fetch(:notifier_mail_options)[:show_merges]
    delimiter = '/'
    cmd << "--format=format:\"%h#{delimiter}%s#{delimiter}%an#{delimiter}%ar\""
    result = `#{cmd}`
    return result if fetch(:notifier_mail_options)[:format] == :text
    result = result.split("\n")
    result.map do |commit_str|
      hash_result = {}
      %i(hash date user).each do |attr|
        if attr == :hash
          commit_str = commit_str.split(delimiter, 2)
          hash_result[attr] = commit_str.first
          commit_str = commit_str.last
        else
          commit_str = commit_str.rpartition(delimiter)
          hash_result[attr] = commit_str.last
          commit_str = commit_str.first
        end
      end
      urls = URI.extract(commit_str)
      previous_end_index = 0
      final_message = urls.each_with_object('') do |v, f_str|
        begin_index = commit_str.index v
        f_str << commit_str[previous_end_index..begin_index - 1]
        f_str << "<a href=\"#{v}\">#{v}</a>"
        previous_end_index = begin_index + v.size
      end
      final_message << commit_str[previous_end_index..-1]
      hash_result[:message] = final_message
      hash_result
    end
  end

  def git_previous_revision
    fetch(:previous_revision).try(:[], 0,7)
  end

  def git_range
    return unless git_previous_revision && git_current_revision

    "#{git_previous_revision}..#{git_current_revision}"
  end

  def now
    @now ||= Time.now
  end

  def stage
    fetch :stage
  end

  def user_name
    user = ENV['DEPLOYER']
    user = `git config --get user.name`.strip if user.nil?
  end
end
