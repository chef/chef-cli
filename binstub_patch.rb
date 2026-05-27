unless ENV["APPBUNDLER_ALLOW_RVM"]
  ENV["APPBUNDLER_ALLOW_RVM"] = "true"
  bin_path = __dir__
  vendor_path = File.expand_path(File.join(bin_path, "..", "vendor"))
  ENV["GEM_HOME"] = vendor_path
  ENV["GEM_PATH"] = [vendor_path, ENV["GEM_PATH"]].compact.join(File::PATH_SEPARATOR)
  ENV["PATH"] = [bin_path, File.join(vendor_path, "bin"), RbConfig::CONFIG["bindir"], ENV["PATH"]].compact.join(File::PATH_SEPARATOR)
end
