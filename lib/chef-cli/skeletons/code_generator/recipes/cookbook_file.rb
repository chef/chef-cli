context = ChefCLI::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
new_file_basename = File.basename(context.new_file_basename)
relative_path = File.dirname(context.new_file_basename)
relative_path.slice! "."
files_dir = File.join(cookbook_dir, 'files', relative_path)
cookbook_file_path = File.join(files_dir, new_file_basename)

directory files_dir do
  recursive true
end

if context.content_source

  file cookbook_file_path do
    content(IO.read(context.content_source))
  end

else

  template cookbook_file_path do
    source 'cookbook_file.erb'
    helpers(ChefCLI::Generator::TemplateHelper)
  end
end
