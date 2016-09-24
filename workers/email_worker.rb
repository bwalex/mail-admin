require 'bundler'
Bundler.require(:default)

require 'erb'

require_relative '../models/users'


class NewUserEmailJob
  include SuckerPunch::Job

  def perform(user_id, pass)
    template = ERB.new(File.open(File.join(File.expand_path(File.dirname(__FILE__)), '../views/emails/new_user.erb')).read)
    ActiveRecord::Base.connection_pool.with_connection do
      begin
        user = User.find(user_id)

        Pony.mail(
          :to => user.email,
          :subject => "Account created!",
          :body => template.result(binding)
        )
      rescue ActiveRecord::RecordNotFound
        puts "--> things went south..."
      end
    end
  end
end
