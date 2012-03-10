appraise 'rails2' do
  gem 'activerecord', '~> 2.3'
  gem 'sqlite3'
end

if RUBY_VERSION =~ /^1\.9/
  appraise 'rails30' do
    gem 'activerecord', '~> 3.0.0'
    gem 'railties',     '~> 3.0.0'
    gem 'sqlite3'
  end

  appraise 'rails31' do
    gem 'activerecord', '~> 3.1.0'
    gem 'railties',     '~> 3.1.0'
    gem 'sqlite3'
  end
end

appraise 'mysql2' do
  gem 'mysql2',       '~> 0.2.18'
end
