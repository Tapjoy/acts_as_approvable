ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
  end

  create_table :nots, :force => true do |t|
    t.string  :title
    t.text    :body, :limit => 16777216

    t.timestamps
  end

  create_table :defaults, :force => true do |t|
    t.string  :title
    t.text    :body, :limit => 16777216

    t.timestamps
  end

  create_table :creates, :force => true do |t|
    t.string  :title
    t.text    :body, :limit => 16777216
    t.string  :state

    t.timestamps
  end

  create_table :updates, :force => true do |t|
    t.string  :title
    t.text    :body, :limit => 16777216

    t.timestamps
  end

  create_table :approvals, :force => true do |t|
    t.string   :item_type, :null => false
    t.integer  :item_id,   :null => false
    t.string   :event,     :null => false
    t.integer  :state,     :null => false, :default => 0
    t.integer  :owner_id
    t.text     :object,    :limit => 16777216
    t.text     :original,  :limit => 16777216
    t.text     :reason

    t.timestamps
  end

  add_index :approvals, [:state, :event]
  add_index :approvals, [:item_type, :item_id]
  add_index :approvals, [:owner_id]
end
