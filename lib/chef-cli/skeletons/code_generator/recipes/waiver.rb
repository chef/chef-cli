context = ChefCLI::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
waiver_dir = File.join(cookbook_dir, 'compliance', 'waivers')
waiver_path = File.join(waiver_dir, "#{context.new_file_basename}.yml")

directory waiver_dir do
  recursive true
end

template waiver_path do
  source 'waiver.yml.erb'
  helpers(ChefCLI::Generator::TemplateHelper)
end
