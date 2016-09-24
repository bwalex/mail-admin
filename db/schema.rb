# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160924073325) do

  create_table "aliases", force: :cascade do |t|
    t.integer  "domain_id",   limit: 4
    t.string   "local_part",  limit: 255
    t.text     "destination", limit: 65535
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "aliases", ["domain_id"], name: "fk_rails_db4795fe20", using: :btree
  add_index "aliases", ["local_part", "domain_id"], name: "index_aliases_on_local_part_and_domain_id", unique: true, using: :btree

  create_table "domains", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "fqdn",       limit: 255
    t.integer  "gid",        limit: 4
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "domains", ["fqdn"], name: "index_domains_on_fqdn", unique: true, using: :btree
  add_index "domains", ["gid"], name: "index_domains_on_gid", unique: true, using: :btree
  add_index "domains", ["user_id"], name: "fk_rails_ed2a49436c", using: :btree

  create_table "global_params", force: :cascade do |t|
    t.string "key",   limit: 255
    t.string "value", limit: 255
  end

  create_table "mailboxes", force: :cascade do |t|
    t.integer  "domain_id",         limit: 4
    t.integer  "transport_id",      limit: 4
    t.string   "local_part",        limit: 255
    t.string   "password",          limit: 255
    t.integer  "uid",               limit: 4
    t.boolean  "active"
    t.boolean  "auth_allowed"
    t.integer  "quota_limit_bytes", limit: 8
    t.string   "mailbox_format",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mailboxes", ["domain_id"], name: "fk_rails_c2483914be", using: :btree
  add_index "mailboxes", ["local_part", "domain_id"], name: "index_mailboxes_on_local_part_and_domain_id", unique: true, using: :btree
  add_index "mailboxes", ["transport_id"], name: "fk_rails_2fcc6225f5", using: :btree
  add_index "mailboxes", ["uid"], name: "index_mailboxes_on_uid", unique: true, using: :btree

  create_table "transports", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "transport",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",   limit: 255
    t.string   "password",   limit: 255
    t.string   "email",      limit: 255
    t.string   "salt",       limit: 255
    t.boolean  "admin"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  add_foreign_key "aliases", "domains", on_delete: :cascade
  add_foreign_key "domains", "users"
  add_foreign_key "mailboxes", "domains", on_delete: :cascade
  add_foreign_key "mailboxes", "transports"
end
