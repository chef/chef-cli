context = ChefCLI::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
input_dir = File.join(cookbook_dir, 'compliance', 'inputs')
input_path = File.join(input_dir, "#{context.new_file_basename}.yml")

directory input_dir do
  recursive true
end

template input_path do
  source 'input.yml.erb'
  helpers(ChefCLI::Generator::TemplateHelper)
end
