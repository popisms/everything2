name "e2dev"
description "Baseline squeeze development environment for everything2.com development"
run_list("recipe[edev]","recipe[e2app]")
default_attributes "edev" => {"gitrepo" => "git://github.com/everything2/everything2.git" }
