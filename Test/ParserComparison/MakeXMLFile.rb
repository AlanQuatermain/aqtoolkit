#!/usr/bin/ruby

require "rexml/document"
require "rexml/formatters/transitive"
require "rdoc/usage"

# == Usage
    #
    # Create an XML file containing a whole bunch of deeply-nested tags containing sequential integers.
    #
    # The idea is that the parser can pull out the integers into an NSIndexSet, so the parsed
    #  data consumes the smallest amount of memory possible, so the memory usage will refer mostly
    #  to the actual data allocated/used by the parser itself.
    #
    # set_channel_names [OPTIONS]
    #
    # -h, --help:
    #    Show this message
    # -c, --count:
    #    Number of consecutive values to embed (1 to X)
    #    Default is 20'000
    # -f, --file:
    #    Name of output file (required)
opts = GetoptLong.new(
  ['--help', '-h', GetoptLong::NO_ARGUMENT],
  ['--count', '-c', GetoptLong::REQUIRED_ARGUMENT],
  ['--file', '-f', GetoptLong::REQUIRED_ARGUMENT]
)

count = 20000
path = nil

opts.each do |opt, arg|
  case opt
  when '--help'
    RDoc::usage
    return
  when '--count'
    count = arg.to_i
  when '--file'
    path = File.expand_path(arg)
  end
end

if path == nil
  RDoc::usage
  return
end

doc = REXML::Document.new
doc << REXML::XMLDecl.new

root = doc.add_element 'root'

count.times do |i|
  lev1 = root.add_element 'level1', {'id' => 'levelOne'}
  lev2 = lev1.add_element 'level2', {'id' => 'levelTwo'}
  number = lev2.add_element 'number'
  number.text = i
  if (i % 1000) == 0
    puts i
  end
end

file = File.new(path, "w+")

formatter = REXML::Formatters::Transitive.new
formatter.write(doc, file)