**Chef-CLI** is a command line interface which uses CodeChef’s official API. This application is for those who hate graphical application and love to do everything from terminal. With features like sample submit and problem recommendation, It is designed to improve the overall productivity of the user.

Now run ```chef-cli — help``` to know the available commands


## The chef-cli Command

**chef-cli generate**

The following generators are built-in:
1. ```chef-cli generate cookbook``` Creates a single cookbook.
2. ```chef-cli generate recipe``` Creates a new recipe file in an existing cookbook.
3. ```chef-cli generate attribute``` Creates a new attributes file in an existing cookbook.
4. ```chef-cli generate template``` Creates a new template file in an existing cookbook. Use the -s SOURCE option to copy a source file's content to populate the template.
5. ```chef-cli generate file``` Creates a new cookbook file in an existing cookbook. Supports the -s SOURCE option similar to template.
   
**chef-cli gem**

```chef-cli gem``` is a wrapper command that manages installation and updating of rubygems for the Ruby installation embedded in the Chef Workstation package. This allows you to install knife plugins, Test Kitchen drivers, and other Ruby applications that are not packaged with Chef Workstation.

**chef-cli exec**

```chef-cli exec <command>``` runs any arbitrary shell command with the PATH environment variable and the ruby environment variables (GEM_HOME, GEM_PATH, etc.) setup to point at the embedded Chef Workstation installation.

**chef-cli shell-init**

```chef-cli shell-init SHELL_NAME``` emits shell commands that modify your environment to make Chef Workstation your primary ruby. It supports bash, zsh, fish and PowerShell (posh). For more information to help you decide if this is desirable and instructions, see "Using Chef as Your Primary Development Environment" below.

**chef-cli install**

```chef-cli install``` reads a Policyfile.rb document, which contains a run_list and optional cookbook version constraints, finds a set of cookbooks that provide the desired recipes and meet dependency constraints, and emits a Policyfile.lock.json describing the expanded run list and locked cookbook set. The Policyfile.lock.json can be used to install the cookbooks on another machine. The policy lock can be uploaded to a Chef Infra Server (via the chef-cli push command) to apply the expanded run list and locked cookbook set to nodes in your infrastructure. See the POLICYFILE_README.md for further details.

**chef-cli push**

```chef-cli push POLICY_GROUP``` uploads a Policyfile.lock.json along with the cookbooks it references to a Chef Infra Server. The policy lock is applied to a POLICY_GROUP, which is a set of nodes that share the same run list and cookbook set. This command operates in compatibility mode and has the same caveats as chef-cli install. See the POLICYFILE_README.md for further details.

**chef-cli update**

```chef-cli update``` updates a Policyfile.lock.json with the latest cookbooks from upstream sources. It supports an --attributes flag which will cause only attributes from the Policyfile.rb to be updated.

**chef-cli diff**

```chef-cli diff``` shows an itemized diff between Policyfile locks. It can compare Policyfile locks from local disk, git, and/or the Chef Infra Server, based on the options given.

**```bundle exec``` is ruby command for running these above chef-cli commands from current project rather than the gems installed in chef-workstation tool.**

```e.g: bundle exec chef-cli generate cookbook```


## Development steps :

1. Fork this repo and clone it to your development system.
2. Create a feature branch for your change.
3. Write code and tests.
4. Commit changes to a git branch, making sure to sign-off those changes for the Developer Certificate of Origin.
5. Push your feature branch to GitHub and open a pull request against master.


**Setting Chef Workstation tool gems (like ruby etc ) as your Primary Development Environment**

*To try it temporarily, in a new terminal session, run:*

```eval "$(chef-cli shell-init SHELL_NAME)"```

*To add this permanently:*

```echo 'eval "$(chef-cli shell-init SHELL_NAME)"' >> ~/.YOUR_SHELL_PROFILE```

**Now your default ruby and associated tools will be the ones from Chef Workstation:**

```which ruby```

*=> /opt/chef-workstation/embedded/bin/ruby*

**Setting up system ruby as your default if using rbenv:**

```eval "$(rbenv init -)"```

**Now your default ruby will be system Ruby:**

```which ruby```

*/Users/<username>/.rbenv/shims/ruby*



*To debug, use ```pry``` or ```byebug``` gem*

*To run the test cases use rspec :*
```bundle exec rspec```

