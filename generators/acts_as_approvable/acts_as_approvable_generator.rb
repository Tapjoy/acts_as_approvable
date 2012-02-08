class ActsAsApprovableGenerator < Rails::Generator::Base
  default_options :base => 'ApplicationController'

  def manifest
    record do |m|
      m.migration_template 'create_approvals.rb', 'db/migrate', :migration_file_name => 'create_approvals'

      m.directory 'app/controllers'
      m.template 'approvals_controller.rb', 'app/controllers/approvals_controller.rb'

      m.directory 'app/views/approvals'
      m.template "views/#{view_language}/index.html.#{view_language}", "app/views/approvals/index.html.#{view_language}"
      m.template "views/#{view_language}/_table.html.#{view_language}", "app/views/approvals/_table.html.#{view_language}"

      m.directory 'config/initializers'
      m.template 'initializer.rb', 'config/initializers/acts_as_approvable.rb'

      m.route route
    end
  end

  protected
  def view_language
    options[:haml] ? 'haml' : 'erb'
  end

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

  def route
    route = 'map.resources :approvals, :only => [:index], :collection => ['
    route << collection_actions.reject { |a| a == ':index' }.join(', ')
    route << '], :member => ['
    route << member_actions.join(', ')
    route << ']'
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on('--base BASE', 'Base class for ApprovableController.') { |v| options[:base] = v }
    opt.on('--haml', 'Generate HAML views instead of ERB.') { |v| options[:haml] = v }
    opt.on('--owner [User]', 'Enable and, optionally, set the model for approval ownerships.') { |v| options[:owner] = v || 'User' }
  end
end

# Gross! But Rails 2 only allows us to define resources with no options.
module Rails
  module Generator
    module Commands
      class Create
        def route(route)
          sentinel = 'ActionController::Routing::Routes.draw do |map|'

          logger.route route
          unless options[:pretend]
            gsub_file 'config/routes.rb', /#{Regexp.escape(sentinel)}/mi do |match|
              "#{match}\n  #{route}\n"
            end
          end
        end
      end

      class Destroy
        def route(route)
          look_for = "\n  #{Regexp.escape(route)}\n"
          logger.route route
          gsub_file 'config/routes.rb', /#{look_for}/mi, ''
        end
      end
    end
  end
end
