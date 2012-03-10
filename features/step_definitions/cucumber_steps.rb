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

When /^I (approve|reject) the (record|changes?)$/ do |state, type|
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

Then /^it should be (pending|approved|rejected)$/ do |state|
  method = "#{state}?".to_sym
  @record.send(method).should be_true
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
