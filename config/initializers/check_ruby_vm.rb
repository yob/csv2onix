# coding: utf-8

# FAIL EARLY, FAIL OFTEN
#
# Fail to start the app if we're running on anything less that ruby 1.9.2.
# It may actually run on lower than that, but I only test against 1.9.2

if RUBY_VERSION < "1.9.2"
  abort "This app requires ruby 1.9.2 or higher."
end
