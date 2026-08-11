unless ENV["APPBUNDLER_ALLOW_RVM"]
  ENV["APPBUNDLER_ALLOW_RVM"] = "true"
  user_gem_home = File.expand_path(File.join("~", ".chef", "ruby", RbConfig::CONFIG["ruby_version"], "gems"))
  ENV["GEM_PATH"] = [user_gem_home, File.expand_path(File.join(__dir__, "..", "vendor")), ENV["GEM_PATH"]].compact.join(File::PATH_SEPARATOR)
end
