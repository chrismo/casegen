# frozen_string_literal: true

require_relative '../lib/case_gen'

raise "This doesn't currently work. Do I even want to keep it?"

# CLabs::CaseGen::CaseGen.new(DATA.read)

# Outputs
#
# DataSubmitCase = Struct.new(:role, :authorization_code, :submit_enabled)
#
# cases = [DataSubmitCase.new("admin", "none", "true"),
#          DataSubmitCase.new("admin", "invalid", "true"),
#          DataSubmitCase.new("admin", "valid", "true"),
#          DataSubmitCase.new("standard", "none", "false"),
#          DataSubmitCase.new("standard", "invalid", "false"),
#          DataSubmitCase.new("standard", "valid", "true")]

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