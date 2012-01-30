class Approval < ActiveRecord::Base
  belongs_to :item,  :polymorphic => true

  validates_presence_of  :item
  validates_inclusion_of :event, :in => %w(create update)
  validates_inclusion_of :state, :in => %w(pending approved rejected)

  serialize :object

  before_save :can_save?

  def self.owner_model=(model)
    send(:belongs_to, :owner, :class_name => model.to_s)
    @has_owner = true
  end

  def self.has_owner?
    @has_owner || false
  end

  def self.options_for_state
    [
      ['All', 'all'],
      ['Pending', 'pending'],
      ['Approved', 'approved'],
      ['Rejected', 'rejected']
    ]
  end

  def self.options_for_owner
    return [] unless has_owner?
    all(:select => 'DISTINCT(owner_id)', :conditions => 'owner_id IS NOT NULL').map { |row| [row.owner.to_s, row.owner_id] }
  end

  def self.options_for_type
    all(:select => 'DISTINCT(item_type)').map { |row| [row.item_type.classify, row.item_type] }
  end

  def pending?
    state == 'pending'
  end

  def approved?
    state == 'approved'
  end

  def rejected?
    state == 'rejected'
  end

  def locked?
    approved? or rejected?
  end

  def unlocked?
    not locked?
  end

  def can_save?
    unlocked? or state_was == 'pending'
  end

  def stale?
    unlocked? and item.has_attribute?(:updated_at) and created_at < item.updated_at
  end

  def fresh?
    not stale?
  end

  def update?
    event == 'update'
  end

  def create?
    event == 'create'
  end

  def approve!(options = {})
    raise "This approval is locked: #{state}" if locked?
    raise "This is a stale approval" if stale? and !options.delete(:force)

    if update?
      data = {}
      object.each do |attr, value|
        data[attr] = value if item.attribute_names.include?(attr)
      end

      item.without_approval { update_attributes!(data) }
    elsif create? && item.approval_state.present?
      item.without_approval { set_approval_state('approved'); save! }
    end

    update_attributes(:state => 'approved')
  end

  def reject!(reason = nil)
    raise "This approval is locked: #{state}" if locked?

    if create? && item.approval_state.present?
      item.without_approval { set_approval_state('rejected'); save! }
    end

    update_attributes(:state => 'rejected', :reason => reason)
  end
end
