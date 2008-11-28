Gem::Specification.new do |s|
  s.name     = "dbstruct"
  s.version  = "0.1.0"
  s.date     = "2008-11-28"
  s.summary  = "Easy to use library for mapping rows between objects and database"
  s.email    = "mudnaes@gmail.com"
  s.homepage = "http://github.com/mudnaes/dbstruct/tree/master"
  s.description = "This is a very simple framework to be able to access database rows as objects without forcing you to inherit from a Model class. Instead you create the class-hierarchy you want and use mixin to add persistance functionality to the object."
  s.has_rdoc = true
  s.authors  = ["Morten Udnæs"]
  s.files    = ["README", 
		"dbstruct.gemspec", 
		"lib/dbstruct.rb"]
  s.test_files = ["spec/dbstruct_spec.rb"]
  s.rdoc_options = ["--main", "README.txt"]
  s.extra_rdoc_files = ["README"]
  s.add_dependency("diff-lcs", ["> 0.0.0"])
  s.add_dependency("mime-types", ["> 0.0.0"])
  s.add_dependency("open4", ["> 0.0.0"])
end

