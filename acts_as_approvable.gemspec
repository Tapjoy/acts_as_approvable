$:.push File.expand_path('../lib', __FILE__)
require "acts_as_approvable/version"

Gem::Specification.new do |s|
  s.name    = %q(acts_as_approvable)
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

  s.add_development_dependency %q<redcarpet>
  s.add_development_dependency %q<shoulda>
  s.add_development_dependency %q<rake>
  s.add_development_dependency %q<rcov>
  s.add_development_dependency %q<yard>
end
