require 'yaml'
require_relative '../helpers/account_creator'

# Setup account_creator
cfg_file = 'config/helper.yml'

Kernel.abort "#{cfg_file} doesn't exist. Please create it and try again." unless File.exist? cfg_file

cfg = YAML::load(File.open(cfg_file))

Kernel.abort "#{cfg_file} doesn't contain any settings for the current environment (#{ENV['RACK_ENV']})" unless cfg.has_key? ENV['RACK_ENV']

AccountCreator.config = cfg[ENV['RACK_ENV']]
