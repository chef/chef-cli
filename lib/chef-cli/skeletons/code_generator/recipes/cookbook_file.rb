context = ChefCLI::Generator.context
cookbook_dir = File.join(context.cookbook_root, context.cookbook_name)
files_dir = File.join(cookbook_dir, 'files')
file_basename = context.new_file_basename
path_arr = file_basename.split('/')
if path_arr.size > 1
   new_file_basename = path_arr.last
   path_arr.pop
   path_arr.each do |ele|
     files_dir = File.join(files_dir, ele)
   end
   cookbook_file_path = File.join(files_dir, new_file_basename)
else
  cookbook_file_path = File.join(files_dir, context.new_file_basename)  # handlers/email_handler.rb # alert some change might be required here
end

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
