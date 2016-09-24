class Setup < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string     :username
      t.string     :password
      t.string     :email
      t.string     :salt
      t.boolean    :admin
      t.timestamps
    end

    add_index :users, :username, :unique => true
    add_index :users, :email, :unique => true


    create_table :domains do |t|
      t.references :user
      t.string     :fqdn
      t.integer    :gid
      t.boolean    :active

      t.timestamps
    end

    add_index :domains, :fqdn, :unique => true
    add_index :domains, :gid, :unique => true
    add_foreign_key :domains, :users


    create_table :transports do |t|
      t.string     :name
      t.string     :transport

      t.timestamps
    end


    create_table :mailboxes do |t|
      t.references :domain
      t.references :transport
      t.string     :local_part
      t.string     :password
      t.integer    :uid
      t.boolean    :active
      t.boolean    :auth_allowed
      t.column     :quota_limit_bytes, :bigint
      t.string     :mailbox_format # defaults to Maildir, can also do sdbox, mdbox

      t.timestamps
    end

    add_index :mailboxes, [:local_part, :domain_id], :unique => true
    add_index :mailboxes, :uid, :unique => true
    add_foreign_key :mailboxes, :domains, on_delete: :cascade
    add_foreign_key :mailboxes, :transports


    create_table :aliases do |t|
      t.references :domain
      t.string     :local_part
      t.text       :destination
      t.boolean    :active

      t.timestamps
    end

    add_index :aliases, [:local_part, :domain_id], :unique => true
    add_foreign_key :aliases, :domains, on_delete: :cascade
  end

  def self.down
    drop_table :domains
    drop_table :mailboxes
    drop_table :aliases
    drop_table :users
    drop_table :transports
  end
end
