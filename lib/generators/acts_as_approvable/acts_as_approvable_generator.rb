require 'rails/generators/active_record'

class ActsAsApprovableGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  class_option :base, :type => :string, :default => 'ApplicationController', :desc => 'Base class for the ApprovalsController'
  class_option :owner, :type => :string, :optional => true, :desc => 'Model that can own approvals'

  desc 'Generates ApprovalsController, a migration the create the Approval table, and an initializer for the plugin.'

  def check_class_collisions
    class_collisions '', 'ApprovalsController'
  end

  def create_controller_file
    template 'approvals_controller.rb', File.join('app/controllers', 'approvals_controller.rb')
  end

  def create_migration_file
    number = ActiveRecord::Generators::Base.next_migration_number('db/migrate')
    template 'create_approvals.rb', "db/migrate/#{number}_create_approvals.rb"
  end

  def create_initializer_file
    initializer('acts_as_approvable.rb') do
      data = ''

      if owner?
        data << 'ActsAsApprovable::Ownership.configure'
        data << "(:owner => #{options[:owner]})" if options[:owner] != 'User'
      end

      data << "\n"
    end
  end

  hook_for :template_engine

  def add_routes
    resource = []
    resource << 'resources :approvals, :only => [:index] do'
    resource << '    collection do'
    resource << '      get \'index\''
    resource << '      get \'history\''
    resource << '      get \'mine\'' if owner?
    resource << '    end'
    resource << '    member do'
    resource << '      post \'approve\''
    resource << '      post \'reject\''
    resource << '      post \'assign\'' if owner?
    resource << '    end'
    resource << '  end'

    route(resource.join("\n"))
  end

  protected
  def owner?
    options[:owner].present?
  end

  def collection_actions
    actions = [:index, :history]
    actions << :mine if owner?
    actions.map { |a| ":#{a}" }
  end

  def member_actions
    actions = [:approve, :reject]
    actions << :assign if owner?
    actions.map { |a| ":#{a}" }
  end
end
