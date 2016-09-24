require_relative 'models/users'
require_relative 'models/global_param'
require_relative 'models/domains'
require_relative 'models/aliases'
require_relative 'models/mailboxes'
require_relative 'models/transports'
#require_relative 'workers/email_worker'
require_relative 'helpers/account_creator'

class Web < Sinatra::Base
  use Rack::Flash

  get '/' do
    redirect '/admin'
  end


  get '/logout' do
    session[:user] = nil
    redirect '/'
  end


  get '/login' do
    haml :login, :format => :html5
  end


  post '/login' do
    u = User.authenticate(params[:email], params[:password])

    if u == nil
      flash[:error] = "Invalid email or password"
      redirect '/login'
    else
      session[:user] = u.id
      redirect '/'
    end
  end


  before '/admin*' do
    begin
      @user = User.find(session[:user])
    rescue ActiveRecord::RecordNotFound
      redirect '/login'
    end
  end


  get '/admin' do
    redirect '/admin/domains'
  end


  get '/admin/domains' do
    @domains = @user.is_admin? ? Domain.all : @user.domains

    haml :admin_domains, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "domains",
    }
  end


  post '/admin/domains' do
    begin
      ActiveRecord::Base.transaction do
        gid = GlobalParam.next_gid!
        Domain.create!(:fqdn => params[:fqdn], :gid => gid, :active => true, :user => @user)
        flash[:success] = "Successfully created new domain"
      end
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Failed to create domain because: " + invalid.message
    end

    redirect '/admin/domains'
  end


  get '/admin/account' do
    haml :admin_account, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "account"
    }
  end


  post '/admin/account' do
    if params[:new_password].blank?
      flash[:error] = "Failed to change password because: new password is blank"
    else
      begin
        @user.new_password = params[:new_password]
        @user.new_password_confirmation = params[:new_password_confirmation]
        @user.save!
        flash[:success] = "Password changed successfully"
      rescue ActiveRecord::RecordInvalid => invalid
        flash[:error] = "Failed to change password because: " + invalid.message
      end
    end

    redirect '/admin/account'
  end


  before '/admin/global/*' do
    unless @user.is_admin?
      flash[:error] = "You are not an admin"
      redirect "/admin"
    end
  end

  get '/admin/global' do
    redirect '/admin/global/users'
  end

  get '/admin/global/users' do
    @users = User.all

    haml :admin_global_users, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "global"
    }
  end

  post '/admin/global/users/modify' do
    begin
      user_ids = (params[:user_delete] || []).map { |i| i.to_i }
      if user_ids.include?(@user.id)
        flash[:error] = "You cannot delete your own user"
        redirect "/admin/global/users"
      end

      puts "admin params: #{params[:admin]}"
      if params[:admin] and
         params[:admin].has_key?(@user.id.to_s) and
        (params[:admin][@user.id.to_s] != "admin")
        flash[:error] = "You cannot strip yourself of admin privileges"
        redirect "/admin/global/users"
      end

      params[:admin].each do |u_id, new_admin|
        u = User.find(u_id.to_i)
        u.admin = (new_admin == "admin")
        u.save!
      end

      User.where(:id => user_ids).destroy_all

      flash[:success] = "Changes saved successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error updating user: #{invalid.message}"
    end
    redirect "/admin/global/users"
  end

  post '/admin/global/users/add' do
    begin
      _user = User.create!(:username => params[:username],
                          :email => params[:email],
                          :new_password => "r00t!",
                          :admin => false)

      # NewUserEmailJob.new.async.perform(user.id)
      flash[:success] = "New user added successfully"
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error adding new user: #{invalid.message}"
    end
    redirect "/admin/global/users"
  end

  get '/admin/global/transports' do
    @transports = Transport.all

    haml :admin_global_transports, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "global"
    }
  end

  post '/admin/global/transports/delete' do
    begin
      transport_ids = (params[:transport_delete] || []).map { |i| i.to_i }
      Transport.where(:id => transport_ids).destroy_all

      flash[:success] = "Changes saved successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error deleting transport: #{invalid.message}"
    end
    redirect "/admin/global/transports"
  end

  post '/admin/global/transports/modify' do
    begin
      transport = Transport.find(params[:transport_id].to_i)
      transport.name = params[:transport_name]
      transport.transport = params[:transport_transport]
      transport.save!

      flash[:success] = "Changes saved successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error modifying transport: #{invalid.message}"
    end
    redirect "/admin/global/transports"
  end

  post '/admin/global/transports/add' do
    begin
      _user = Transport.create!(:name => params[:name],
                                :transport => params[:transport])

      flash[:success] = "New transport added successfully"
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error adding new transport: #{invalid.message}"
    end
    redirect "/admin/global/transports"
  end

  get '/admin/global/params' do
    @gid = GlobalParam.find_by_key(:gid)
    @uid = GlobalParam.find_by_key(:uid)
    @mailbox_format = GlobalParam.find_by_key(:mailbox_format)

    haml :admin_global_params, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "global"
    }
  end

  post '/admin/global/params/modify' do
    begin
      @gid = GlobalParam.find_by_key(:gid)
      @uid = GlobalParam.find_by_key(:uid)
      @mailbox_format = GlobalParam.find_by_key(:mailbox_format)

      @gid.value = params[:next_gid]
      @uid.value = params[:next_uid]
      @mailbox_format.value = params[:mailbox_format]

      @gid.save!
      @uid.save!
      @mailbox_format.save!

      flash[:success] = "Changes saved successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error modifying uid/gid: #{invalid.message}"
    end
    redirect "/admin/global"
  end


  before '/admin/domains/:domain*' do
    begin
      @domain = Domain.find_by_fqdn!(params[:domain])
      raise ActiveRecord::RecordNotFound unless @user.can? :access, @domain
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Domain #{params[:domain]} doesn't exist or you don't have access to it."
      redirect '/admin/domains'
    end
  end


  get '/admin/domains/:domain' do
    @mailboxes = @domain.mailboxes.order(:local_part => :asc)
    @aliases = @domain.aliases.order(:local_part => :asc)
    haml :admin_domain, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "domains"
    }
  end

  post '/admin/domains/:domain/edit' do
    if @domain.gid != params[:gid].to_i and not @user.is_admin?
      flash[:error] = "Error updating domain: you are not authorized to change the GID"
      redirect "/admin/domains/#{params[:domain]}"
    end
    begin
      @domain.gid = params[:gid].to_i if @user.is_admin?
      @domain.active = (params[:domain_status].downcase == "active")
      @domain.save!
      flash[:success] = "Domain updated successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error updating domain: #{invalid.message}"
    end
    redirect "/admin/domains/#{params[:domain]}"
  end

  post '/admin/domains/:domain/delete' do
    begin
      @domain.destroy
      flash[:success] = "Domain deleted successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error updating domain: #{invalid.message}"
    end
    redirect "/admin/domains"
  end

  get '/admin/domains/:domain/aliases' do
    unless @user.can? :manage, @domain
      flash[:error] = "You can't manage #{params[:domain]}"
      redirect "/admin/domains"
    end
    @aliases = @domain.aliases
    haml :admin_domain_aliases, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "domains"
    }
  end

  post '/admin/domains/:domain/aliases' do
    unless @user.can? :manage, @domain
      flash[:error] = "You can't manage #{params[:domain]}"
      redirect "/admin/domains"
    end
    begin
      _alias = @domain.aliases.create!(:local_part => params[:local_part],
                                       :destination => params[:destination],
                                       :active => (params[:mailbox_status].downcase == "active"))
      flash[:success] = "New alias created successfully"
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error creating alias: #{invalid.message}"
    end
    redirect "/admin/domains/#{params[:domain]}/aliases"
  end

  get '/admin/domains/:domain/mailboxes' do
    unless @user.can? :manage, @domain
      flash[:error] = "You can't manage #{params[:domain]}"
      redirect "/admin/domains"
    end
    @mailboxes = @domain.mailboxes
    @transports = Transport.all
    haml :admin_domain_mailboxes, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "domains"
    }
  end

  post '/admin/domains/:domain/mailboxes' do
    unless @user.can? :manage, @domain
      flash[:error] = "You can't manage #{params[:domain]}"
      redirect "/admin/domains"
    end
    begin
      quota_limit_bytes = (params[:quota] || 0).to_f
      case params[:quota_suffix].downcase
      when 'k'
        quota_limit_bytes *= 1024
      when 'm'
        quota_limit_bytes *= 1024 * 1024
      when 'g'
        quota_limit_bytes *= 1024 * 1024 * 1024
      else
        flash[:error] = "Invalid quota suffix: #{params[:quota_suffix]}"
        redirect "/admin/domains/#{params[:domain]}/mailboxes"
      end
      mailbox = nil
      uid = nil
      if params[:uid] and params[:uid] != ''
        unless @user.is_admin?
          flash[:error] = "Error creating mailbox: you are not authorized to change the UID"
          redirect "/admin/domains/#{params[:domain]}/mailboxes"
        end
        uid = params[:uid]
      end
      ActiveRecord::Base.transaction do
        uid = GlobalParam.next_uid! if uid.nil?
        mailbox_format = GlobalParam.default_mailbox_format
        transport = Transport.find(params[:transport])
        mailbox = @domain.mailboxes.create!(:local_part => params[:local_part],
                                            :transport => transport,
                                            :new_password => params[:password],
                                            :new_password_confirmation => params[:repeat_password],
                                            :uid => uid,
                                            :active => (params[:mailbox_status].downcase == "active"),
                                            :auth_allowed => (params[:login_status].downcase == "allowed"),
                                            :quota_limit_bytes => quota_limit_bytes,
                                            :mailbox_format => mailbox_format)


      end

      AccountCreator.create_account!(uid, @domain.gid) unless @user.is_admin? and params[:skip_directory] == "skip"

      flash[:success] = "New mailbox created successfully"
    rescue AccountCreator::Error => e
      mailbox.destroy if mailbox
      flash[:error] = "Failed to create account: #{e.message}"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error creating mailbox: #{invalid.message}"
    end
    redirect "/admin/domains/#{params[:domain]}/mailboxes"
  end



  before '/admin/domains/:domain/mailboxes/:mailbox*' do
    unless @user.can? :manage, @domain
      flash[:error] = "You can't manage #{params[:domain]}"
      redirect "/admin/domains"
    end

    begin
      @mailbox = Mailbox.find_by_domain_id_and_local_part!(@domain.id, params[:mailbox])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "No such mailbox: #{params[:mailbox]}"
      redirect "/admin/domains/#{params[:domain]}/mailboxes"
    end
  end

  get '/admin/domains/:domain/mailboxes/:mailbox' do
    @transports = Transport.all
    if @mailbox.quota_limit_bytes > 1024*1024*1024
      @quota = @mailbox.quota_limit_bytes*1.0 / (1024*1024*1024)
      @quota_suffix = 'G'
    elsif @mailbox.quota_limit_bytes > 1024*1024
      @quota = @mailbox.quota_limit_bytes*1.0 / (1024*1024)
      @quota_suffix = 'M'
    else
      @quota = @mailbox.quota_limit_bytes / 1024.0
      @quota_suffix = 'k'
    end

    haml :admin_domain_mailbox, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "domains"
    }
  end

  post '/admin/domains/:domain/mailboxes/:mailbox/edit' do
    begin
      quota_limit_bytes = params[:quota].to_f
      case params[:quota_suffix].downcase
      when 'k'
        quota_limit_bytes *= 1024
      when 'm'
        quota_limit_bytes *= 1024 * 1024
      when 'g'
        quota_limit_bytes *= 1024 * 1024 * 1024
      else
        flash[:error] = "Invalid quota suffix: #{params[:quota_suffix]}"
        redirect "/admin/domains/#{params[:domain]}/mailboxes/#{params[:mailbox]}"
      end

      transport = Transport.find(params[:transport])

      @mailbox.transport = transport
      @mailbox.new_password = params[:new_password]
      @mailbox.new_password_confirmation = params[:new_password_confirmation]
      @mailbox.active = (params[:mailbox_status].downcase == "active")
      @mailbox.auth_allowed = (params[:login_status].downcase == "allowed")
      @mailbox.quota_limit_bytes = quota_limit_bytes
      @mailbox.save!
      flash[:success] = "Mailbox updated successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error updating mailbox: #{invalid.message}"
    end
    redirect "/admin/domains/#{params[:domain]}/mailboxes/#{params[:mailbox]}"
  end

  post '/admin/domains/:domain/mailboxes/:mailbox/delete' do
    begin
      @mailbox.destroy
      flash[:success] = "Mailbox deleted successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error updating mailbox: #{invalid.message}"
    end
    redirect "/admin/domains/#{params[:domain]}/mailboxes"
  end


  before '/admin/domains/:domain/aliases/:alias*' do
    unless @user.can? :manage, @domain
      flash[:error] = "You can't manage #{params[:domain]}"
      redirect "/admin/domains"
    end

    begin
      @alias = Alias.find_by_domain_id_and_local_part!(@domain.id, params[:alias])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "No such alias: #{params[:alias]}"
      redirect "/admin/domains/#{params[:domain]}/aliases"
    end
  end

  get '/admin/domains/:domain/aliases/:alias' do
    haml :admin_domain_alias, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "domains"
    }
  end

  post '/admin/domains/:domain/aliases/:alias/edit' do
    begin
      @alias.destination = params[:destination]
      @alias.active = (params[:mailbox_status].downcase == "active")
      @alias.save!
      flash[:success] = "Alias updated successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error updating alias: #{invalid.message}"
    end
    redirect "/admin/domains/#{params[:domain]}/aliases/#{params[:alias]}"
  end

  post '/admin/domains/:domain/aliases/:alias/delete' do
    begin
      @alias.destroy
      flash[:success] = "Alias deleted successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error updating alias: #{invalid.message}"
    end
    redirect "/admin/domains/#{params[:domain]}/aliases"
  end
end
