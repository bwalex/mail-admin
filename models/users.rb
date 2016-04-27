require_relative "../helpers/email_validator"
require_relative "domains"

class User < ActiveRecord::Base
  attr_accessor :new_password, :new_password_confirmation

  has_many :domains

  validates :username, :presence => true, :uniqueness => true, :length => { :in => 2..60 }
  validates :email, :presence => true, :uniqueness => { case_sensitive: false }, :email => true
  validates_confirmation_of :new_password, :if => :password_changed?

  before_save :hash_new_password, :if => :password_changed?

  def to_s
    self[:email]
  end

  def email=(mail)
    self[:email] = mail.strip.downcase
  end

  def password_changed?
    !@new_password.blank?
  end

  def as_json(options={})
    only = [
      :id,
      :username,
      :email
    ]

    methods = [
    ]

    super(
      :only => only,
      :methods => methods
    )
  end

  def self.authenticate(email, password)
    if user = find_by_email(email)
      if BCrypt::Password.new(user.password).is_password? password
        return user
      end
    elsif user = find_by_username(email)
      if BCrypt::Password.new(user.password).is_password? password
        return user
      end
    end
    return nil
  end

  def is_admin?
    return self[:admin]
  end

  private

  def hash_new_password
    self[:password] = BCrypt::Password.create(@new_password)
  end
end
