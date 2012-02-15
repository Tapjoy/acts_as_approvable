require 'rails/generators/erb/controller/controller_generator'

module Haml
  module Generators
    class ActsAsApprovableGenerator < Erb::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      class_option :owner, :type => :string, :optional => true, :desc => 'Model that can own approvals'

      def copy_view_files
        template 'index.html.haml',          'app/views/approvals/index.html.haml'
        template '_table.html.haml',         'app/views/approvals/_table.html.haml'
        template '_owner_select.html.haml',  'app/views/approvals/_owner_select.html.haml' if owner?
      end

      protected
      def handler
        :haml
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
    end
  end
end
