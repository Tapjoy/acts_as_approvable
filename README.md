Acts as Approvable
==================

This plugin provides a workflow for approving new records and changes to existing
records.

Installation
============

Rails 3
-------

Add the gem to your Gemfile:

    gem 'acts-as-approvable'

Then run the generator:

    rails g acts_as_approvable

Rails 2
-------

Add the gem to `config/environment.rb`

    config.gem 'acts-as-approvable'

Then run `rake gems:install`. After the gem is installed, run the generator:

    $ script/generate acts_as_approvable

Generator Options
=================

These options are also available by passing `--help` as an option to the generator.

    --base BASE     Base class for ApprovableController.
    --haml*         Generate HAML views instead of ERB.
    --owner [User]  Enable and, optionally, set the model for approval ownerships.

\* This option is not available in Rails 3. You should configure your template engine in `config/application.rb`

API Documentation
=================

API Documentation is [available online](http://rubydoc.info/gems/acts-as-approvable/frames).

Configuration
=============

The generator creates an initializor at `config/initializers/acts_as_approvable.rb`. A sample
initializer might look like this:

    ActsAsApprovable.view_language = 'haml'
    ActsAsApprovable::Ownership.configure

The `Ownership` functionality expects a `User` model in your project by default, but by providing
an `:owner` option you can change the expected model to whatever you wish. `.configure` also
accepts a block which it applies to the `Approval` model, allowing you to override methods as
you see fit.

For example, to only allow Users with the "admin" role to 'own' an Approval, change your initializer
to something like this:

    ActsAsApprovable.view_language = 'haml'
    ActsAsApprovable::Ownership.configure do
      def self.available_owners
        owner_class.all(:conditions => ['role', 'admin'])
      end
    end

Examples
========

Require approval for new Users, but not modifications...

    class User < ActiveRecord::Base
      acts_as_approvable :on => :create, :state_field => :state

      # Let the user know they've been approved
      def after_approve(approval)
        ApprovalMailer.deliver_user_approved(self.email)
      end

      # Let the user know they were rejected
      def after_reject(approval)
        ApprovalMailer.deliver_user_approved(self.email, approval.reason)
      end
    end

Require approval when a Game's title or description is changed, but not when view or installation count is changed...

    class Game < ActiveRecord::Base
        acts_as_approvable :on => :update, :ignore => [:views, :installs]
    end

Require approval for all changes, except the standard ignored fields (`created_at`, `updated_at` and `:state_field`)...

    class Advertisement < ActiveRecord::Base
        acts_as_approvable :state_field => :state
    end

Options
=======

The following options may be used to configure the workflow on a per-model
basis:

 * `:on`            The type of events (`:create` or `:update`) to require approval on.
 * `:ignore`        A list of fields to ignore for `:update` approvals.
 * `:only`          A list of fields that should be approved. All other fields are
                    ignored. If set, the `:ignore` option is... ignored.
 * `:state_field`   A local model field to save the `:create` approvals state. Useful
                    for selecting approved models without joining the approvals table.

The fields `:created_at`, `:updated_at` and whatever is set for the `:state_field`
are automatically ignored.

Contributors
============

 * [James Logsdon](http://github.com/jlogsdon) (Lead developer)
 * [Hwan-Joon Choi](http://github.com/hc5duke) (Performance enhancements, bug fixes)
 * [Neal Wiggins](http://github.com/nwigginsTJ) (Enumeration of states)
