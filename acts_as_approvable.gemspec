$:.push File.expand_path('../lib', __FILE__)
require "acts_as_approvable/version"

Gem::Specification.new do |s|
  s.name    = %q(acts_as_approvable)
  s.version = ActsAsApprovable::VERSION

  s.summary     = %q(Generic approval queues for record creation, updates and deletion)
  s.description = %q(Generic approval queues for record creation, updates and deletion)

  s.authors   = ['James Logsdon', 'Hwan-Joon Choi', 'Neal Wiggins']
  s.email     = %q(dwarf@girsbrain.org)
  s.homepage  = %q(http://github.com/Tapjoy/acts_as_approvable)
  s.date      = %q(2012-02-14)

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/* features/*`.split("\n")
  s.require_paths = ['lib']

  s.add_development_dependency 'activerecord',     '>= 2.3', '< 4.0'
  s.add_development_dependency 'shoulda-matchers', '~> 2.8'
  s.add_development_dependency 'rspec',            '~> 3.0'
  s.add_development_dependency 'timecop',          '~> 0.3.5'
  s.add_development_dependency 'cucumber',         '~> 2.0'
  s.add_development_dependency 'rake',             '~> 0.9.2'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'test-unit', '~> 3.0'
end
