class User < ActiveRecord::Base
  self.table_name = 'users'

  def to_str; id; end
end

class NotApprovable < ActiveRecord::Base
  self.table_name = 'nots'
end

class DefaultApprovable < ActiveRecord::Base
  self.table_name = 'defaults'

  acts_as_approvable
end

class CreatesApprovable < ActiveRecord::Base
  self.table_name = 'creates'

  acts_as_approvable :on => :create
end

class CreatesWithStateApprovable < ActiveRecord::Base
  self.table_name = 'creates'

  acts_as_approvable :on => :create, :state_field => :state
end

class UpdatesApprovable < ActiveRecord::Base
  self.table_name = 'updates'

  acts_as_approvable :on => :update
end

class UpdatesOnlyFieldsApprovable < ActiveRecord::Base
  self.table_name = 'updates'

  acts_as_approvable :on => :update, :only => [:body]
end

class UpdatesIgnoreFieldsApprovable < ActiveRecord::Base
  self.table_name = 'updates'

  acts_as_approvable :on => :update, :ignore => [:title]
end

class DestroysApprovable < ActiveRecord::Base
  self.table_name = 'destroys'

  acts_as_approvable :on => :destroy
end

class OwnedApproval < ActiveRecord::Base
  self.table_name = 'approvals'

  include ActsAsApprovable::Ownership
end
