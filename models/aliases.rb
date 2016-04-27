require_relative 'domains'

class Alias < ActiveRecord::Base
  belongs_to :domain

  validates :local_part, uniqueness: { scope: :domain, case_sensitive: false }
  validates :destination, :length => { :minimum => 1 }

  def active?
    self[:active]
  end
end
