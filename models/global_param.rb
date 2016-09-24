require_relative 'domains'
require_relative 'mailboxes'

class GlobalParam < ActiveRecord::Base
  validates :key, inclusion: { in: %w(gid uid mailbox_format) }
  validates_each :value do |record,attr,value|
    case record.key.to_sym
    when :gid
      record.errors.add(attr, "must be a valid gid") unless value.to_s =~ /\A[0-9]+\Z/
    when :uid
      record.errors.add(attr, "must be a valid uid") unless value.to_s =~ /\A[0-9]+\Z/
    when :mailbox_format
      record.errors.add(attr, "must be a valid mailbox format") unless %w(maildir mdbox sdbox).include? value
    end
  end

  def self.next_gid!
    prop = GlobalParam.find_by_key(:gid)
    val = nil
    prop.with_lock do
      loop do
        val = prop[:value].to_i
        prop[:value] = (val + 1).to_s
        break unless Domain.exists?(:gid => val)
      end
      prop.save!
    end

    return val
  end

  def self.next_uid!
    prop = GlobalParam.find_by_key(:uid)
    val = nil
    prop.with_lock do
      loop do
        val = prop[:value].to_i
        prop[:value] = (val + 1).to_s
        break unless Mailbox.exists?(:uid => val)
      end
      prop.save!
    end

    return val
  end

  def self.default_mailbox_format
    GlobalParam.find_by_key(:mailbox_format).value
  end
end
