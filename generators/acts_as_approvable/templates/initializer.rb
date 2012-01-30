ActsAsApprovable.view_language = <% view_language %>
<% if options[:owner] %>
ActsAsApprovable.owner_model = <%= options[:owner].constantize %>
<% end %>
