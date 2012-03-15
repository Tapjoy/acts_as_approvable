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
  s.test_files    = `git ls-files -- spec/* features/*`.split("\n")
  s.require_paths = ['lib']

  s.add_development_dependency %q<activerecord>,  '~> 2.3.14'
  s.add_development_dependency %q<appraisal>,     '~> 0.4.1'
  s.add_development_dependency %q<redcarpet>,     '~> 2.1.0'
  s.add_development_dependency %q<shoulda>,       '~> 2.0'
  s.add_development_dependency %q<rspec>,         '~> 2.8.0'
  s.add_development_dependency %q<timecop>,       '~> 0.3.5'
  s.add_development_dependency %q<cucumber>,      '~> 1.1.0'
  s.add_development_dependency %q<rake>,          '~> 0.9.2'
  s.add_development_dependency %q<yard>
  s.add_development_dependency %q<pry>,           '~> 0.9.8.1'
  s.add_development_dependency %q<pry-syntax-hacks>

  if RUBY_VERSION =~ /^1\.9/
    s.add_development_dependency %q<simplecov>
    s.add_development_dependency %q<pry-stack_explorer>
    s.add_development_dependency %q<pry-nav>,           '~> 0.1.0'
    s.add_development_dependency %q<plymouth>
  elsif RUBY_VERSION =~ /^1\.8/
    s.add_development_dependency %q<rcov>
  end
end
