require_relative '../lib/casegen'

CLabs::CaseGen::CaseGen.new(File.read(File.join(__dir__, 'cart.sample.txt')))