# Created by Nick Gerakines, open source and publically available under the
# MIT license. Use this module at your own risk.
# I'm an Erlang/Perl/C++ guy so please forgive my dirty ruby.

require 'rubygems'
require 'sequel'
require 'fileutils'
require 'yaml'

# NOTE: This converter requires Sequel and the MySQL gems.
# The MySQL gem can be difficult to install on OS X. Once you have MySQL
# installed, running the following commands should work:
# $ sudo gem install sequel
# $ sudo gem install mysql -- --with-mysql-config=/usr/local/mysql/bin/mysql_config

module Jekyll
  module MT
    # This query will pull blog posts from all entries across all blogs. If
    # you've got unpublished, deleted or otherwise hidden posts please sift
    # through the created posts to make sure nothing is accidently published.
    QUERY = "SELECT entry_id, entry_basename, entry_text, entry_text_more, entry_created_on, entry_title, entry_convert_breaks FROM mt_entry WHERE entry_blog_id = 1"

    def self.process(dbname, user, pass, host = 'localhost')
      db = Sequel.postgres(dbname, :user => user, :password => pass, :host => host)

      FileUtils.mkdir_p "_posts"

      db[QUERY].each do |post|
        title = post[:entry_title]
        slug = post[:entry_basename].gsub!('_','-')
        date = post[:entry_created_on]
        content = post[:entry_text]
        more_content = post[:entry_text_more]

        # Be sure to include the body and extended body.
        if more_content != nil
          content = content + " \n" + more_content
        end

        markup = "html"
        if post[:entry_convert_breaks] == "markdown"
          markup = "markdown"
        end

        slug
        name = [date.year, "%02d" % date.month, "%02d" % date.day, slug].join('-') + "." + markup

        data = {
           'layout' => 'post',
           'title' => title.to_s,
           'mt_id' => post[:entry_id],
         }.delete_if { |k,v| v.nil? || v == ''}.to_yaml

        File.open("_posts/#{name}", "w") do |f|
          f.puts data
          f.puts "---"
          f.puts content
        end
      end

    end
  end
end
