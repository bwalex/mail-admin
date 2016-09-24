require_relative 'users'
require_relative 'aliases'

class Domain < ActiveRecord::Base
  has_many :aliases
  has_many :mailboxes

  belongs_to :user

  validates :fqdn, :length => { :minimum => 4 }
  validates_uniqueness_of :fqdn
  validates_uniqueness_of :gid
  validates :gid, :numericality => { :greater_than_or_equal_to => 0 }
end
