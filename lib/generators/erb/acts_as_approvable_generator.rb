require 'rails/generators/erb'

module Erb
  module Generators
    class ActsAsApprovableGenerator < Erb::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      class_option :owner, :type => :string, :optional => true, :desc => 'Model that can own approvals'

      def copy_view_files
        template 'index.html.erb',          'app/views/approvals/index.html.erb'
        template '_table.html.erb',         'app/views/approvals/_table.html.erb'
        template '_owner_select.html.erb',  'app/views/approvals/_owner_select.html.erb' if owner?
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
  end
end
