import Config

# General configuration for HushOpenbao

# Only import environment specific config if it exists
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
