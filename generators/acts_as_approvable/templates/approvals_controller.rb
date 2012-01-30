class ApprovalsController < <%= options[:base] %>
  before_filter :setup_conditions, :only => [:index, :history]
  before_filter :setup_partial, :only => [:index, :history]
  before_filter :find_approval, :only => [:approve, :reject]

  def index
    state = params[:state] || 'pending'
    @conditions[:state] = state if state != 'any'

    @approvals = Approval.all(:conditions => @conditions)
  end

  def history
    @conditions[:state] = ['approved', 'rejected']

    @approvals = Approval.all(:conditions => @conditions)
    render :index
  end

  def approve
    @approval.owner = current_user if respond_to?(:curret_user)
    @approval.approve!

    redirect_to :action => :index
  end

  def reject
    @approval.owner = current_user if respond_to?(:curret_user)
    @approval.reject!(params[:reason])

    redirect_to :action => :index
  end

  private
  def setup_conditions
    @conditions ||= {}

    if params[:owner_id]
      @conditions[:owner_id] = params[:owner_id]
      @conditions[:owner_id] = nil if params[:owner_id] == 0
    end
    if params[:item_type]
      @conditions[:item_type] = params[:item_type]
    end
  end

  # Check for the selected models partial, use the generic one if it doesn't exist
  def setup_partial
    @table_partial = @conditions.fetch(:item_type) { 'table' }

    if @table_partial != 'table'
      partial_path = Rails.root.join('app', 'views', 'approvals', "_#{@table_partial}.html.#{view_language}")
      @table_partial = 'table' unless File.exist?(partial_path)
    end
  end

  def find_approval
    @approval = Approval.find(params[:id])
  end

  def view_language
    ActsAsApprovable.view_language
  end
end
