ActsAsApprovable.view_language = '<%= view_language %>'
<% if owner? %>ActsAsApprovable::Ownership.configure(Approval, <%= options[:owner].constantize %>)
<% end %>
