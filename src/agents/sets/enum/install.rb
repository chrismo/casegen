#!/usr/bin/env ruby

require 'rbconfig'
require 'getoptlong'
require 'ftools'

destdir = Config::CONFIG['sitedir']
noharm = false

Usage = <<END
  Usage: ruby install.rb [options]
  
      option      argument  action
      ------      --------  ------
      --destdir   dir       Destination dir
      -d                    (default is #{destdir})
      
      --help                Print this help
      -h
      
      --noharm              Do not install, just print commands
      -n

  Installs all .rb files from current dir and below, preserving
  directory structure, into a subdir of the destination dir. The name
  of this subdir is formed by stripping the version number off the end
  of the current dir. The version number is the largest suffix that
  contains no dashes.

END

opts = GetoptLong.new(
  [ "--destdir",    "-d",            GetoptLong::REQUIRED_ARGUMENT ],
  [ "--help",       "-h",            GetoptLong::NO_ARGUMENT       ],
  [ "--noharm",     "-n",            GetoptLong::NO_ARGUMENT       ]
)

opts.each do |opt, arg|
  case opt
  when '--destdir', '-d'
    destdir = arg
  when '--help', '-h'
    print Usage, "\n"
    exit
  when '--noharm', '-n'
    noharm = true
  else
    raise "unrecognized option: ", opt
  end
end

raise ArgumentError,
  "unrecognized arguments #{ARGV.join(' ')}" unless ARGV == []

basedir = (File.split(Dir.getwd))[1].sub(/-[^-]*\z/, "")
files = Dir.glob("**/*.rb").map { |file| file.sub(/\A\.\//, "") }
files = files.reject {|file| file == __FILE__ }
files.map! { |file|
  [file,
    File.join(destdir, basedir, file)]
}

dirs = {}
for src, dest in files
  d = File.dirname dest
  unless dirs[d]
    puts "File.makedir #{d}"
    File.makedirs d unless noharm
    dirs[d] = true
  end
  puts "File.install #{src}, #{dest}, 0644, true"
  File.install(src, dest, 0644, true) unless noharm
end
