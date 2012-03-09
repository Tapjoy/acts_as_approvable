Given /^a record created with (create|update|any) approval$/ do |type|
  @record = case type
            when 'create'; CreatesApprovable.create
            when 'update'; UpdatesApprovable.create
            when 'any'; DefaultApprovable.create
            end
end

When /^I (approve|reject) the record$/ do |state|
  begin
    method = "#{state}!".to_sym
    @record.send(method)
  rescue => @last_error
  end
end

When /^the record is already (approved|rejected)$/ do |state|
  case state
  when 'approved'; @record.approve!
  when 'rejected'; @record.reject!
  end
end

Then /^it should be (pending|approved|rejected)$/ do |state|
  method = "#{state}?".to_sym
  @record.send(method).should be_true
end

Then /^it should raise (.+?)$/ do |exception|
  @last_error.class.should == eval(exception)
end
