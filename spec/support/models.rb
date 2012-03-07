class DefaultApprovable < ActiveRecord::Base
  set_table_name 'defaults'

  acts_as_approvable
end

class CreatesApprovable < ActiveRecord::Base
  set_table_name 'creates'

  acts_as_approvable :on => :create
end

class CreatesWithStateApprovable < ActiveRecord::Base
  set_table_name 'creates'

  acts_as_approvable :on => :create, :state_field => :state
end

class UpdatesApprovable < ActiveRecord::Base
  set_table_name 'updates'

  acts_as_approvable :on => :update
end

class UpdatesOnlyFieldsApprovable < ActiveRecord::Base
  set_table_name 'updates'

  acts_as_approvable :on => :update, :only => [:body]
end

class UpdatesIgnoreFieldsApprovable < ActiveRecord::Base
  set_table_name 'updates'

  acts_as_approvable :on => :update, :ignore => [:title]
end
