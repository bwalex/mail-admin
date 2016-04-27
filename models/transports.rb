class Transport < ActiveRecord::Base
  validates_uniqueness_of :name
  validates :name, :length => { :minimum => 3 }
  validates :transport, :length => { :minimum => 1 }
end
