# -*- encoding: utf-8 -*-
# stub: rb-pygments 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rb-pygments"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Nathan Weizenbaum"]
  s.date = "2010-01-24"
  s.description = "A Ruby wrapper for the Pygments syntax highlighter."
  s.email = "nex342@gmail.com"
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md"]
  s.homepage = "http://github.com/nex3/rb-pygments"
  s.rdoc_options = ["--charset=UTF-8"]
  s.requirements = ["pygments, 1.2.2 or greater"]
  s.rubygems_version = "2.5.1"
  s.summary = "A Ruby wrapper for the Pygments syntax highlighter."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<yard>, ["~> 0.5.3"])
    else
      s.add_dependency(%q<yard>, ["~> 0.5.3"])
    end
  else
    s.add_dependency(%q<yard>, ["~> 0.5.3"])
  end
end
