class ApprovalsController < <%= options[:base] %>
  before_filter :setup_conditions, :only => [:index, :history]
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

  def find_approval
    @approval = Approval.find(params[:id])
  end
end
