class CreateApprovals < ActiveRecord::Migration
  def self.up
    create_table :approvals do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :state,     :null => false, :default => 'pending'
      <% if options[:owner] %>
      t.integer  :owner_id
      <% end %>
      t.text     :object
      t.text     :reason

      t.timestamps
    end

    add_index :approvals, [:state, :event]
    add_index :approvals, [:item_type, :item_id]
    <% if options[:owner] %>
    add_index :approvals, [:owner_id]
    <% end %>
  end

  def self.down
    remove_index :approvals, [:state, :event]
    remove_index :approvals, [:item_type, :item_id]
    <% if options[:owner] %>
    remove_index :approvals, [:owner_id]
    <% end %>
    drop_table :approvals
  end
end
