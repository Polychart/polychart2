#!/usr/bin/env python
import argparse
import subprocess
import json
import os

def uglify_js(source, dest):
  # multiple (possible) implementations.
  # 1. uglify.js - fast, but fails hard without good error message on js syntax error.
  # 2. closure compiler (api) - easy to use via HTTP API.
  # 3. closure compiler (jar) - same thing as #2, - it's not just implemented yet.
  # we're using #2 right now.

  #source = open(path).read()

  options = [ 
    '-d', 'output_info=compiled_code',
    '-d', 'output_info=warnings',
    '-d', 'output_info=errors',
    '-d', 'output_info=statistics',
    '-d', 'output_format=json',
    '-d', 'compilation_level=SIMPLE_OPTIMIZATIONS',
  ]
  cmd = ['curl'] + options + [ 
    '--data-urlencode', ('js_code@%s' % source),
    "http://closure-compiler.appspot.com/compile"
  ]
  result = check_output(*cmd)
  obj = json.loads(result)
  with open(dest, 'wb') as f:
    f.write(obj['compiledCode'])

def check_output(*args):
  return subprocess.Popen(args, stdout=subprocess.PIPE).communicate()[0]

def main():
  """
  Abstract main method.
  """
  parser = argparse.ArgumentParser(description='Uses clojure compiler to minify JS')
  parser.add_argument('--source', dest='source', help="Path to source file.")
  parser.add_argument('--dest',  dest='dest', help="Path to destination.")
  parsed = parser.parse_args()
  root_dir = os.getcwd()
  source =  os.path.join(root_dir, parsed.source)
  dest   =  os.path.join(root_dir, parsed.dest)
  uglify_js(source, dest)

main()
