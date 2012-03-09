class User < ActiveRecord::Base
  def self.table_name; 'users'; end
  def self.primary_key; 'id'; end

  def to_str; id; end
end

class NotApprovable < ActiveRecord::Base
  def self.table_name; 'nots'; end
  def self.primary_key; 'id'; end
end

class DefaultApprovable < ActiveRecord::Base
  def self.table_name; 'defaults'; end
  def self.primary_key; 'id'; end

  acts_as_approvable
end

class CreatesApprovable < ActiveRecord::Base
  def self.table_name; 'creates'; end
  def self.primary_key; 'id'; end

  acts_as_approvable :on => :create
end

class CreatesWithStateApprovable < ActiveRecord::Base
  def self.table_name; 'creates'; end
  def self.primary_key; 'id'; end

  acts_as_approvable :on => :create, :state_field => :state
end

class UpdatesApprovable < ActiveRecord::Base
  def self.table_name; 'updates'; end
  def self.primary_key; 'id'; end

  acts_as_approvable :on => :update
end

class UpdatesOnlyFieldsApprovable < ActiveRecord::Base
  def self.table_name; 'updates'; end
  def self.primary_key; 'id'; end

  acts_as_approvable :on => :update, :only => [:body]
end

class UpdatesIgnoreFieldsApprovable < ActiveRecord::Base
  def self.table_name; 'updates'; end
  def self.primary_key; 'id'; end

  acts_as_approvable :on => :update, :ignore => [:title]
end

class OwnedApproval < ActiveRecord::Base
  def self.table_name; 'approvals'; end
  def self.primary_key; 'id'; end

  include ActsAsApprovable::Ownership
end
