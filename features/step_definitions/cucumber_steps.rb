def support_file_path(file)
  File.join('features', 'support', file.gsub(/^file:/, '').gsub(/ +/, '_') + '.txt')
end

Given /^a record created with (create|update|destroy|any) approval$/ do |type|
  @record = case type
            when 'create'; CreatesApprovable.create
            when 'update'; UpdatesApprovable.create
            when 'destroy'; DestroysApprovable.create
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

When /^I (approve|reject|reset) the (record|changes?|destruction)( forcefully)?$/ do |state, type, force|
  begin
    params = ["#{state}!".to_sym]
    params << true if force

    record = type == 'record' ? @record : @approval
    record.send(*params)
  rescue => error
    @last_error = error if error.present?
  end

  @record.reload unless type == 'destruction'
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

When /^I destroy the record$/ do
  @record.destroy
  @approval = @record.destroy_approvals.last
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

Then /^it should (not )?be pending destruction$/ do |invert|
  if !!invert
    @record.should_not be_pending_destruction
  else
    @record.should be_pending_destruction
  end
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

Then /^it should (still|no longer) exist$/ do |state|
  begin
    persisted = @record.class.find_by_id(@record.id)
  rescue ActiveRecord::RecordNotFound
    persisted = false
  end

  if state == 'still'
    persisted.should be
  else
    persisted.should_not be
  end
end
