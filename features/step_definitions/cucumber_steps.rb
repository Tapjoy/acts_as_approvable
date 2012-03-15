def support_file_path(file)
  File.join('features', 'support', file.gsub(/^file:/, '').gsub(/ +/, '_') + '.txt')
end

Given /^a record created with (create|update|any) approval$/ do |type|
  @record = case type
            when 'create'; CreatesApprovable.create
            when 'update'; UpdatesApprovable.create
            when 'any'; DefaultApprovable.create
            end
end

Given /^the record is (stale)$/ do |state|
  case state
  when 'stale'
    @record.title = 'changed'
    sleep(1) # Save will put updated_at in a stale place
  end

  @record.save_without_approval!
end

When /^I (approve|reject|reset) the (record|changes?)$/ do |state, type|
  begin
    method = "#{state}!".to_sym

    case type
    when 'record'; @record.send(method)
    when 'changes', 'change'; @approval.send(method)
    end
  rescue => @last_error
  end

  @record.reload
end

When /^the record is already (approved|rejected)$/ do |state|
  case state
  when 'approved'; @record.approve!
  when 'rejected'; @record.reject!
  end

  @record.reload
end

When /^I update the record with:$/ do |table|
  table.rows_hash.each_pair do |attr, value|
    value = File.read(support_file_path(value)) if value =~ /^file:/
    @record[attr] = value
  end
  @record.save!

  @approval = @record.update_approvals.last
  @update = table.rows_hash
end

Then /^it should (not )?be (pending|approved|rejected|stale)$/ do |invert, state|
  method = "#{state}?".to_sym
  record = state == 'stale' ? @record.approval : @record

  unless invert == 'not '
    record.send(method).should be_true
  else
    record.send(method).should be_false
  end

  @record.reload
end

Then /^it should have (no )?pending changes$/ do |empty|
  @record.pending_changes?.should_not == !!empty
end

Then /^it should raise (.+?)$/ do |exception|
  @last_error.class.should == eval(exception)
end

Then /^the (approval|record) should (not )?have (the changes|changed)$/ do |type, changed, tense|
  changed = !!changed
  changes = type == 'record' ? @record.attributes : @approval.object

  @update.each_pair do |attr, value|
    value = File.read(support_file_path(value)) if value =~ /^file:/
    if changed
      changes[attr].should_not == value
    else
      changes[attr].should == value
    end
  end
end

Then /^the (approval|record) should (not )?have changed to:$/ do |type, changed, table|
  changed = !!changed
  changes = type == 'record' ? @record.attributes : @approval.object

  table.rows_hash.each_pair do |attr, value|
    value = File.read(support_file_path(value)) if value =~ /^file:/
    if changed
      changes[attr].should_not == value
    else
      changes[attr].should == value
    end
  end
end
