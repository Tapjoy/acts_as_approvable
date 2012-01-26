class ActsAsApprovableGenerator < Rails::Generator::Base
  default_options :base => 'ActionController::Base'

  def manifest
    record do |m|
      m.class_collisions 'Approval', 'ApprovalsController'
      m.migration_template 'create_approvals.rb', 'db/migrate', :migration_file_name => 'create_approvals'
    end
  end
end
