ActsAsApprovable.view_language = '<%= view_language %>'
<% if owner? %>ActsAsApprovable::Ownership.configure<% if options[:owner] != 'User' %>(:owner => <%= options[:owner].constantize %>)<% end %>
<% end %>
