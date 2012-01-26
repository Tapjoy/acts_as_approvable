Acts as Approvable
==================

This plugin provides a workflow for approving new records and changes to existing
records.

Installation
============

Install the plugin as you would any other Rails plugin:

    script/plugin install git://github.com/jlogsdon/acts_as_approvable.git

Usage
=====

Configuring a model to use the approval workflow, just put `acts_as_approvable`
somewhere in the model. By default both creation and update events must be
approved.

Once included, you can temporarily disable the approval hooks by calling
`Model.approvals_off`. To enable call `Model.approvals_on`. It is also possible
to use `@model.without_approvals { #do things }` to process several elements
while disabling approvals and then ensuring the approval workflow is enabled
afterwards.

Approval hooks may also be globaly disabled and enabled using
`ActsAsApprovable.enable` and `ActsAsApprovable.disable`.

Options
=======

The following options may be used to configure the workflow on a per-model
basis:

 :on            The type of events (:create or :update) to require approval on.
 :ignore        A list of fields to ignore for :update approvals.
 :only          A list of fields that should be approved. All other fields are
                ignored. If set, the :ignore option is... ignored.
 :state_field   A local model field to save the :create approvals state. Useful
                for selecting approved models without joining the approvals table.

The fields :created_at, :updated_at and whatever is set for the :state_field are
automatically ignored.

Examples
========

    class User < ActiveRecord::Base
      acts_as_approvable :state_field => :state, :only => :login
    end

    class Project < ActiveRecord::Base
      acts_as_approvable :on => :update, :ignore => [:views, :installs]
    end
