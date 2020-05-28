#!/bin/sh
jruby -r java \
  -r "./target/cdk-jruby-0.1-jar-with-dependencies.jar" \
  -r ./app/stack.rb
