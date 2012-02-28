ActsAsApprovable.view_language = '<%= view_language %>'
<% if owner? %>ActsAsApprovable::Ownership.configure<% if owner != 'User' %>(:owner => <%= owner.constantize %>)<% end %>
<% end %>
