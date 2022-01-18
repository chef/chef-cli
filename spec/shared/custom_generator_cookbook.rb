
# Required `let` bindings:
# * `generator_name` in lowercase, e.g., "cookbook", "app"
# * `generator_arg`: argument to the generator command
# * `expected_cookbook_files`: a list of files the generator should create
shared_examples_for "custom generator cookbook" do

  context "when given a generator-cookbook path" do

    let(:default_generator_cookbook_path) { File.expand_path("lib/chef-cli/skeletons/code_generator", project_root) }

    let(:generator_cookbook_path) { File.join(tempdir, "a_generator_cookbook") }
    let(:generator_copyright_holder) { "Chef" }
    let(:generator_email) { "mail@chef.io" }
    let(:generator_license) { "Free as in Beer" }

    let(:argv) { [generator_arg, "--generator-cookbook", generator_cookbook_path] }

    let(:stdout_io) { StringIO.new }

    subject(:code_generator) do
      described_class.new(argv).tap do |gen|
        allow(gen).to receive(:stdout).and_return(stdout_io)
      end
    end

    before do
      reset_tempdir
      code_generator.read_and_validate_params
      allow(code_generator.config_loader).to receive(:load)
    end

    it "configures the generator context" do
      code_generator.setup_context
      expect(generator_context.cookbook_name).to eq(generator_arg)
      expect(code_generator.chef_runner.cookbook_path).to eq(tempdir)
      expect(code_generator.chef_runner.run_list).to eq(["recipe[a_generator_cookbook::#{generator_name}]"])
    end

    context "when the generator cookbook is configured in a configuration file" do

      let(:argv) { [generator_arg] }

      let(:generator_config) do
        double("Generator Config Context",
          license: generator_license,
          copyright_holder: generator_copyright_holder,
          email: generator_email)
      end

      let(:chefcli_config) do
        double("Mixlib::Config context for ChefCLI",
          generator_cookbook: generator_cookbook_path,
          generator: generator_config)
      end

      before do
        allow(code_generator).to receive(:chefcli_config).and_return(chefcli_config)
      end

      it "configures the generator context" do
        code_generator.setup_context
        expect(generator_context.cookbook_name).to eq(generator_arg)
        expect(code_generator.chef_runner.cookbook_path).to eq(tempdir)
        expect(code_generator.chef_runner.run_list).to eq(["recipe[a_generator_cookbook::#{generator_name}]"])
      end
    end

    context "with a generator-cookbook path to a specific cookbook" do

      let(:metadata_file) { File.join(generator_cookbook_path, "metadata.rb") }

      before do
        FileUtils.cp_r(default_generator_cookbook_path, generator_cookbook_path)

        # have to update metadata with the correct name
        IO.binwrite(metadata_file, "name 'a_generator_cookbook'")
      end

      it "creates the new files" do
        expect(code_generator.chef_runner.cookbook_path).to eq(tempdir)
        expect(code_generator.chef_runner.run_list).to eq(["recipe[a_generator_cookbook::#{generator_name}]"])

        Dir.chdir(tempdir) do
          allow(code_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          code_generator.run
        end
      end

    end
  end
end
