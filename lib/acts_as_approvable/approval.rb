class Approval < ActiveRecord::Base
  STATES = %w(pending approved rejected)

  belongs_to :item,  :polymorphic => true

  validates_presence_of  :item
  validates_inclusion_of :event, :in => %w(create update)
  validates_numericality_of :state, :greater_than_or_equal_to => 0, :less_than => STATES.length

  serialize :object

  before_save :can_save?

  def self.options_for_state
    [
      ['All', 'all'],
      ['Pending', 'pending'],
      ['Approved', 'approved'],
      ['Rejected', 'rejected']
    ]
  end

  def self.options_for_type(with_prompt = false)
    types = all(:select => 'DISTINCT(item_type)').map { |row| row.item_type }
    types.unshift(['All Types', nil]) if with_prompt
    types
  end

  def state
    STATES[(read_attribute(:state) || 0)]
  end

  def state_was
    STATES[(changed_attributes[:state] || 0)]
  end

  def state=(state)
    state = STATES.index(state) if state.is_a?(String)
    write_attribute(:state, state)
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
    raise ActsAsApprovable::Error::Locked if locked?
    raise ActsAsApprovable::Error::Stale if stale? and !options.delete(:force)
    return unless run_item_callback(:before_approve)

    if update?
      data = {}
      object.each do |attr, value|
        data[attr] = value if item.attribute_names.include?(attr)
      end

      item.without_approval { update_attributes!(data) }
    elsif create? && item.approval_state.present?
      item.without_approval { set_approval_state('approved'); save! }
    end

    update_attributes!(:state => 'approved')
    run_item_callback(:after_approve)
  end

  def reject!(reason = nil)
    raise ActsAsApprovable::Error::Locked if locked?
    return unless run_item_callback(:before_reject)

    if create? && item.approval_state.present?
      item.without_approval { set_approval_state('rejected'); save! }
    end

    update_attributes!(:state => 'rejected', :reason => reason)
    run_item_callback(:after_reject)
  end

  private
  def run_item_callback(callback)
    item.send(callback, self) != false
  end
end
