class Approval < ActiveRecord::Base
  STATES = %w(pending approved rejected)

  belongs_to :item,  :polymorphic => true

  validates_presence_of  :item
  validates_inclusion_of :event, :in => %w(create update)
  validates_numericality_of :state, :greater_than_or_equal_to => 0, :less_than => STATES.length

  serialize :object

  before_save :can_save?

  ##
  # Build an array of states usable by #options_for_select.
  def self.options_for_state
    [
      ['All', 'all'],
      ['Pending', 'pending'],
      ['Approved', 'approved'],
      ['Rejected', 'rejected']
    ]
  end

  ##
  # Build an array of types usable by #options_for_select.
  def self.options_for_type(with_prompt = false)
    types = all(:select => 'DISTINCT(item_type)').map { |row| row.item_type }
    types.unshift(['All Types', nil]) if with_prompt
    types
  end

  ##
  # Get the current state of the approval. Converts from integer via STATES constant.
  def state
    STATES[(read_attribute(:state) || 0)]
  end

  ##
  # Get the previous state of the approval. Converts from integer via STATES constant.
  def state_was
    STATES[(changed_attributes[:state] || 0)]
  end

  ##
  # Set the state of the approval. Converts from string to integer via STATES constant.
  def state=(state)
    state = STATES.index(state) if state.is_a?(String)
    write_attribute(:state, state)
  end

  ##
  # Returns true if the approval is still pending.
  def pending?
    state == 'pending'
  end

  ##
  # Returns true if the approval has been approved.
  def approved?
    state == 'approved'
  end

  ##
  # Returns true if the approval has been rejected.
  def rejected?
    state == 'rejected'
  end

  ##
  # Returns true if the approval has been approved or rejected.
  def locked?
    approved? or rejected?
  end

  ##
  # Returns the inverse of #locked?
  def unlocked?
    not locked?
  end

  ##
  # Returns true if the approval able to be saved. This requires an unlocked
  # approval, or an approval just leaving the 'pending' state.
  def can_save?
    unlocked? or state_was == 'pending'
  end

  ##
  # Returns true if the affected item has been updated since this approval was
  # created.
  def stale?
    unlocked? and item.has_attribute?(:updated_at) and created_at < item.updated_at
  end

  ##
  # Returns true if the affected item has not been updated since this approval
  # was created.
  def fresh?
    not stale?
  end

  ##
  # Returns true if this is an :update approval event.
  def update?
    event == 'update'
  end

  ##
  # Returns true if this is a :create approval event.
  def create?
    event == 'create'
  end

  ##
  # Attempt to approve the record change.
  #
  # Options:
  # :force        do not block approval if the record is stale
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

  ##
  # Attempt to reject the record change.
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
