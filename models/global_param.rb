class GlobalParam < ActiveRecord::Base
  def self.next_gid!
    prop = GlobalParam.find_by_key(:gid)
    val = nil
    prop.with_lock do
      val = prop[:value]
      prop[:value] += 1
      prop.save!
    end

    return val
  end

  def self.next_uid!
    prop = GlobalParam.find_by_key(:uid)
    val = nil
    prop.with_lock do
      val = prop[:value]
      prop[:value] += 1
      prop.save!
    end

    return val
  end
end
