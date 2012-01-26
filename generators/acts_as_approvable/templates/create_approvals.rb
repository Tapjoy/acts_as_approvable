class CreateApprovals < ActiveRecord::Migration
  def self.up
    create_table :approvals do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :state,     :null => false, :default => :pending
      t.string   :owner_type
      t.integer  :owner_id
      t.text     :object
      t.text     :reason

      t.timestamps
    end

    add_index :approvals, [:status, :event, :item_type, :item_id, :owner_id]
  end

  def self.down
    remove_index :approvals, [:status, :event, :item_type, :item_id, :owner_id]
    drop_table :approvals
  end
end
