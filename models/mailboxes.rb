require 'securerandom'
require_relative 'domains'

class Mailbox < ActiveRecord::Base
  attr_accessor :new_password

  belongs_to :domain
  belongs_to :transport

  before_save :hash_new_password, :if => :password_changed?
  before_validation :populate_defaults, :on => [:create, :update]

  validates :local_part, uniqueness: { scope: :domain, case_sensitive: false }
  validates :uid, :numericality => { :greater_than_or_equal_to => 0 }
  validates :quota_limit_bytes, :numericality => { :greater_than_or_equal_to => 0 }
  validates :mailbox_format, :inclusion => { :in => Domain::MAILBOX_FORMATS }

  def active?
    self[:active]
  end

  def can_auth?
    self[:auth_allowed]
  end

  def password_changed?
    !@new_password.blank?
  end

  private

  def hash_new_password
    salt = "$5$rounds=100000$#{SecureRandom.base64(15).tr("+", ".")}"
    self[:password] = @new_password.crypt(salt)
  end

  def populate_defaults
    self[:mailbox_format] = domain.def_mailbox_format if self[:mailbox_format].blank?
  end

end
