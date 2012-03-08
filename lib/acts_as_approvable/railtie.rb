module ActsAsApprovable
  class Railtie < Rails::Railtie
    initializer 'acts_as_approvable.configure_rails_initialization' do |app|
      ActiveRecord::Base.send :extend, ActsAsApprovable::Model
    end
  end
end
