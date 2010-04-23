spec = File.dirname(__FILE__)
$LOAD_PATH.unshift(spec) unless $LOAD_PATH.include?(spec)

lib = File.dirname(__FILE__) + '../lib/'
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'cinch'

