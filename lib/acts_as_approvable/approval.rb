class Approval < ActiveRecord::Base
  ##
  # Enumeration of available states.
  STATES = %w(pending approved rejected)

  attr_accessible :event, :state, :object, :original, :reason

  belongs_to :item,  :polymorphic => true

  validates_presence_of  :item
  validates_inclusion_of :event, :in => %w(create update destroy)
  validates_numericality_of :state, :greater_than_or_equal_to => 0, :less_than => STATES.length

  serialize :object
  serialize :original

  before_save :able_to_save?

  ##
  # Find the enumerated value for a given state.
  #
  # @return [Integer]
  def self.enumerate_state(state)
    enumerate_states(state).first
  end

  ##
  # Find the enumerated values for a list of states.
  #
  # @return [Array]
  def self.enumerate_states(*states)
    states.map { |name| STATES.index(name) }.compact
  end

  ##
  # Build an array of states usable by Rails' `#options_for_select`.
  def self.options_for_state
    options = [['All', -1]]
    STATES.each_index { |x| options << [STATES[x].capitalize, x] }
    options
  end

  ##
  # Build an array of types usable by Rails' `#options_for_select`.
  def self.options_for_type(with_prompt = false)
    types = all(:select => 'DISTINCT(item_type)').map { |row| row.item_type }
    types.unshift(['All Types', nil]) if with_prompt
    types
  end

  ##
  # Get the current state of the approval. Converts from integer via {STATES} constant.
  def state
    STATES[(read_attribute(:state) || 0)]
  end

  ##
  # Get the previous state of the approval. Converts from integer via {STATES} constant.
  def state_was
    STATES[(changed_attributes[:state] || 0)]
  end

  ##
  # Set the state of the approval. Converts from string to integer via {STATES} constant.
  def state=(state)
    state = self.class.enumerate_state(state) if state.is_a?(String)
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
  # Returns true if the approval has not been approved or rejected.
  def unlocked?
    not locked?
  end

  ##
  # Returns true if the approval able to be saved. This requires an unlocked
  # approval, or an approval just leaving the 'pending' state.
  def able_to_save?
    unlocked? or state_was == 'pending'
  end

  ##
  # Returns true if the affected item has been updated since this approval was
  # last updated.
  def stale?
    unlocked? and item.has_attribute?(:updated_at) and updated_at < item.updated_at
  end

  ##
  # Returns true if the affected item has not been updated since this approval
  # was created.
  def fresh?
    not stale?
  end

  ##
  # Returns true if the approval is stale and the stale check is enabled.
  def stale_approval?
    ActsAsApprovable.stale_check? and update? and stale?
  end

  ##
  # Returns true if this is an `:update` approval event.
  def update?
    event == 'update'
  end

  ##
  # Returns true if this is a `:create` approval event.
  def create?
    event == 'create'
  end

  ##
  # Returns true if this is a `:destroy` approval event.
  def destroy?
    event == 'destroy'
  end

  ##
  # Attempt to approve the record change.
  #
  # @param [Boolean] force if the approval record is stale force the acceptance.
  # @raise [ActsAsApprovable::Error::Locked] raised if the record is {#locked? locked}.
  # @raise [ActsAsApprovable::Error::Stale] raised if the record is {#stale? stale} and `force` is false.
  def approve!(force = false)
    raise ActsAsApprovable::Error::Locked if locked?
    raise ActsAsApprovable::Error::Stale if !force and stale_approval?
    return unless run_item_callback(:before_approve)

    if update?
      data = {}
      object.each do |attr, value|
        data[attr] = value if item.attribute_names.include?(attr)
      end

      item.attributes = data
    elsif create?
      item.set_approval_state('approved')
    elsif destroy?
      item.destroy_without_approval
    end

    item.save_without_approval! unless destroy?
    update_attributes!(:state => 'approved')
    run_item_callback(:after_approve)
  end

  ##
  # Attempt to reject the record change.
  #
  # @param [String] reason a reason for rejecting the change.
  # @raise [ActsAsApprovable::Error::Locked] raised if the record is {#locked? locked}.
  def reject!(reason = nil)
    raise ActsAsApprovable::Error::Locked if locked?
    return unless run_item_callback(:before_reject)

    item.set_approval_state('rejected') if create?

    item.save_without_approval!
    update_attributes!(:state => 'rejected', :reason => reason)
    run_item_callback(:after_reject)
  end

  ##
  # Force the approval back into a 'pending' state. Only valid for :create events.
  #
  # @raise [ActsAsApprovable::Error::InvalidTransition] raised if the event is not {#create? :create}.
  def reset!
    raise ActsAsApprovable::Error::InvalidTransition.new(state, 'pending', self) unless create?

    item.set_approval_state('pending')
    item.save_without_approval!

    state_will_change! # Force an update to the record
    update_attributes!(:state => 'rejected')
  end

  private
  def run_item_callback(callback)
    item.send(callback, self) != false
  end
end
