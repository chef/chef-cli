# This is vitally important for cookbooks that ship with context-dependent
# metadata.rb (to do things like auto incrementing semantic versioning) where
# the metadata.json means the cookbook is 'finalized' and must be authoritative.
# We need to never try to parse metadata.rb if the metadata.json exists.  It isn't
# sufficient to simply not use the metadata.rb file, but we must allow the
# metadata.rb to have an invalid parse due to LoadErrors in the environment where
# the cookbook is being loaded.

raise "we never want to read the metadata.rb if metadata.json exists"
