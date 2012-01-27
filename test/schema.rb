ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string  :login
    t.string  :state

    t.timestamps
  end

  create_table :projects, :force => true do |t|
    t.string  :title
    t.text    :description

    t.timestamps
  end

  create_table :games, :force => true do |t|
    t.string  :title
    t.text    :description

    t.timestamps
  end

  create_table :employees, :force => true do |t|
    t.string  :name

    t.timestamps
  end

  create_table :approvals, :force => true do |t|
    t.string   :item_type, :null => false
    t.integer  :item_id,   :null => false
    t.string   :event,     :null => false
    t.string   :state,     :null => false, :default => 'pending'
    t.string   :owner_type
    t.integer  :owner_id
    t.text     :object
    t.text     :reason

    t.timestamps
  end

  add_index :approvals, [:state, :event]
  add_index :approvals, [:item_type, :item_id]
  add_index :approvals, [:owner_id]
end
