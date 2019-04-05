require_relative '../lib/casegen'

CLabs::CaseGen::CaseGen.new(DATA.read)

__END__

sets
----
role: admin, standard
authorization code: none, invalid, valid
submit enabled: true, false

rules(sets)
-----------
exclude role = admin AND submit enabled = false
  Admin role can always submit

exclude role = standard AND authorization code = none AND submit enabled = true
exclude role = standard AND authorization code = invalid AND submit enabled = true
exclude role = standard AND authorization code = valid AND submit enabled = false
  Standard role can only submit when authorization code is valid


ruby_array(rules)
-------------
DataSubmitCase