require_relative '../../models/global_param'

class UidGidGen < ActiveRecord::Migration
  def self.up
    create_table :global_params do |t|
      t.string  :key
      t.string  :value
    end

    GlobalParam.create!(
      :key => :uid,
      :value => 70000.to_s
    )

    GlobalParam.create!(
      :key => :gid,
      :value => 70000.to_s
    )
  end

  def self.down
    drop_table :global_params
  end
end
