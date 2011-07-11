test_fns = Dir[File.join('.', '**', '*.rb')]
test_fns.each do |fn| require fn end
