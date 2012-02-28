require 'generators/acts_as_approvable/base'

module Erb
  module Generators
    class ActsAsApprovableGenerator < Rails::Generators::Base
      include ActsAsApprovable::Generators::Base

      source_root File.expand_path('../templates', __FILE__)

      class_option :owner, :type => :string, :optional => true, :desc => 'Model that can own approvals'
      class_option :scripts, :type => :boolean, :optional => true, :default => false

      def copy_view_files
        template 'index.html.erb',          'app/views/approvals/index.html.erb'
        template '_table.html.erb',         'app/views/approvals/_table.html.erb'
        template '_owner_select.html.erb',  'app/views/approvals/_owner_select.html.erb' if owner?
      end

      protected
      def format
        :html
      end

      def handler
        :erb
      end

      def filename_with_extensions(name)
        [name, format, handler].compact.join('.')
      end
    end
  end
end
