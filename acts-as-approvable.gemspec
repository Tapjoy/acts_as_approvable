$:.push File.expand_path('../lib', __FILE__)
require "acts-as-approvable/version"

Gem::Specification.new do |s|
  s.name    = %q(acts-as-approvable)
  s.version = ActsAsApprovable::VERSION

  s.summary     = %q(Generic approval queues for record creation and updates)
  s.description = %q(Generic approval queues for record creation and updates)

  s.authors   = ['James Logsdon', 'Hwan-Joon Choi', 'Neal Wiggins']
  s.email     = %q(dwarf@girsbrain.org)
  s.homepage  = %q(http://github.com/jlogsdon/acts_as_approvable)
  s.date      = %q(2012-02-14)

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ['lib']

  s.add_development_dependency %q<activerecord>, '~> 2.3'
  s.add_development_dependency %q<appraisal>
  s.add_development_dependency %q<redcarpet>
  s.add_development_dependency %q<shoulda>
  s.add_development_dependency %q<sqlite3>
  s.add_development_dependency %q<mocha>
  s.add_development_dependency %q<rake>
  s.add_development_dependency %q<rcov> if RUBY_VERSION =~ /^1\.8/
  s.add_development_dependency %q<simplecov> if RUBY_VERSION =~ /^1\.9/
  s.add_development_dependency %q<yard>
  s.add_development_dependency %q<pry>
end
