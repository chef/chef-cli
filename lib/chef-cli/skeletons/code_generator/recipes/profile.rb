context = ChefCLI::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
profile_dir = File.join(cookbook_dir, 'compliance', 'profiles', "#{context.new_file_basename}")
control_dir = File.join(profile_dir, 'controls')

directory control_dir do
  recursive true
end

template "#{profile_dir}/inspec.yml" do
  source 'compliance_profile_inspec.yml.erb'
  helpers(ChefCLI::Generator::TemplateHelper)
  variables(
    spdx_license: ChefCLI::Generator::TemplateHelper.license_long(context.license),
    profile_name: context.new_file_basename
  )
end

template "#{control_dir}/example.rb" do
  source 'compliance_profile_control.rb.erb'
  helpers(ChefCLI::Generator::TemplateHelper)
end
