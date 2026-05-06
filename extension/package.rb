#!/usr/bin/env ruby
# Builds the .rbz (a renamed zip) for SketchUp's Extension Manager.
# Uses the system `zip` command — no Ruby gem dependencies.
require "fileutils"

VERSION  = "0.2.0"
OUT_NAME = "su_mcp_v#{VERSION}.rbz"
TMP_DIR  = "_build"

FileUtils.rm_rf(TMP_DIR)
FileUtils.mkdir_p(TMP_DIR)

FileUtils.cp("su_mcp.rb",     TMP_DIR)
FileUtils.cp("extension.json", TMP_DIR)
FileUtils.cp_r("su_mcp",      TMP_DIR)

FileUtils.rm(OUT_NAME) if File.exist?(OUT_NAME)
Dir.chdir(TMP_DIR) do
  system("zip", "-r", "../#{OUT_NAME}", ".", "-x", "*.DS_Store") || abort("zip failed")
end

FileUtils.rm_rf(TMP_DIR)
puts "Created #{OUT_NAME}"
