class MailboxFormat < ActiveRecord::Migration
  def self.up
    GlobalParam.create!(
      :key => :mailbox_format,
      :value => 'maildir'
    )
  end

  def self.down
    GlobalParam.find_by_key(:mailbox_format).destroy
  end
end
