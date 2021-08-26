# Chef-CLI

[![Build status](https://badge.buildkite.com/c0b83a31c5491c6321949a96f20c628c803409387e9d7e770a.svg?branch=main)](https://buildkite.com/chef-oss/chef-chef-cli-master-verify)
[![Gem Version](https://badge.fury.io/rb/chef-cli.svg)](https://badge.fury.io/rb/chef-cli)

**Umbrella Project**: [Chef Workstation](https://github.com/chef/chef-oss-practices/blob/main/projects/chef-workstation.md)

**[Project State](https://github.com/chef/chef-oss-practices/blob/main/repo-management/repo-states.md):** Active

**Issues [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/main/repo-management/repo-states.md):** 14 days

**Pull Request [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/main/repo-management/repo-states.md):** 14 days

The Chef-CLI is the command line interface for Chef Infra practitioners. This tool aims to include everything you need to be successful using Chef Infra and soon Chef InSpec and Chef Habitat.

### The `chef-cli` Command

The `chef-cli` command is a workflow tool that builds Chef Infra Policyfiles to provide an awesome experience that encourages quick iteration and testing (and makes those things easy) and provides a way to easily, reliably, and repeatably roll out new automation code to your infrastructure.

#### `chef-cli generate`

The generate subcommand generates skeleton Chef Infra code layouts so you can skip repetitive boilerplate and get down to automating your infrastructure quickly. Unlike other generators, it only generates the minimum required files when creating a cookbook so you can focus on the task at hand without getting overwhelmed by stuff you don't need.

The following generators are built-in:

* `chef-cli generate cookbook` Creates a single cookbook.
* `chef-cli generate recipe` Creates a new recipe file in an existing cookbook.
* `chef-cli generate attribute` Creates a new attributes file in an existing cookbook.
* `chef-cli generate template` Creates a new template file in an existing cookbook. Use the `-s SOURCE` option to copy a source file's content to populate the template.
* `chef-cli generate file` Creates a new cookbook file in an existing cookbook. Supports the `-s SOURCE` option similar to template.

The `chef-cli generate` command also accepts additional `--generator-arg key=value` pairs that can be used to supply ad-hoc data to a generator cookbook. For example, you might specify `--generator-arg database=mysql` and then only write a template for `recipes/mysql.rb` if `context.database == 'mysql'`.

#### `chef-cli gem`

`chef-cli gem` is a wrapper command that manages installation and updating of rubygems for the Ruby installation embedded in the Chef Workstation package. This allows you to install knife plugins, Test Kitchen drivers, and other Ruby applications that are not packaged with Chef Workstation.

Gems are installed to a `.chef-workstation` directory in your home directory; any
executables included with a gem you install will be created in
`~/.chef-workstation/gem/ruby/2.1.0/bin`. You can run these executables with
`chef-cli exec`, or use `chef-cli shell-init` to add Chef Workstation's paths to
your environment. Those commands are documented below.

#### `chef-cli exec`
`chef-cli exec <command>` runs any arbitrary shell command with the PATH
environment variable and the ruby environment variables (`GEM_HOME`,
`GEM_PATH`, etc.) setup to point at the embedded Chef Workstation installation.

#### `chef-cli shell-init`
`chef-cli shell-init SHELL_NAME` emits shell commands that modify your
environment to make Chef Workstation your primary ruby. It supports bash, zsh,
fish and PowerShell (posh). For more information to help you decide if
this is desirable and instructions, see "Using Chef as Your Primary
Development Environment" below.

#### `chef-cli install`
`chef-cli install` reads a `Policyfile.rb` document, which contains a
`run_list` and optional cookbook version constraints, finds a set of
cookbooks that provide the desired recipes and meet dependency
constraints, and emits a `Policyfile.lock.json` describing the expanded
run list and locked cookbook set. The `Policyfile.lock.json` can be used
to install the cookbooks on another machine. The policy lock can be
uploaded to a Chef Infra Server (via the `chef-cli push` command) to apply
the expanded run list and locked cookbook set to nodes in your
infrastructure. See the POLICYFILE_README.md for further details.

#### `chef-cli push`
`chef-cli push POLICY_GROUP` uploads a Policyfile.lock.json along with the
cookbooks it references to a Chef Infra Server. The policy lock is applied
to a `POLICY_GROUP`, which is a set of nodes that share the same run list
and cookbook set. This command operates in compatibility mode and has the
same caveats as `chef-cli install`. See the POLICYFILE_README.md for
further details.

#### `chef-cli update`
`chef-cli update` updates a Policyfile.lock.json with the latest cookbooks
from upstream sources. It supports an `--attributes` flag which will
cause only attributes from the Policyfile.rb to be updated.

#### `chef-cli diff`
`chef-cli diff` shows an itemized diff between Policyfile locks. It can
compare Policyfile locks from local disk, git, and/or the Chef Infra Server,
based on the options given.

### Using Chef as Your Primary Development Environment

By default, Chef Workstation only adds a few select applications to your `PATH`
and packages them in such a way that they are isolated from any other
Ruby development tools you have on your system. If you're happily using
your system ruby, rvm, rbenv, chruby or any other development
environment, you can continue to do so. Just ensure that the Workstation-
provided applications appear first in your `PATH` before any
gem-installed versions and you're good to go.

If you'd like for Chef to provide your primary Ruby/Chef Infra development
environment, however, you can do so by initializing your shell with
Chef Workstation's environment.

To try it temporarily, in a new terminal session, run:

```sh
eval "$(chef-cli shell-init SHELL_NAME)"
```

where `SHELL_NAME` is the name of your shell (usually bash, but zsh is
also common). This modifies your `PATH` and `GEM_*` environment
variables to include Chef Workstation's paths (run without the `eval` to see the
generated code). Now your default `ruby` and associated tools will be
the ones from Chef Workstation:

```sh
which ruby
# => /opt/chef-workstation/embedded/bin/ruby
```

To add Chef Workstation to your shell's environment permanently, add the
initialization step to your shell's profile:

```sh
echo 'eval "$(chef-cli shell-init SHELL_NAME)"' >> ~/.YOUR_SHELL_PROFILE
```

Where `YOUR_SHELL_PROFILE` is `~/.bash_profile` for most bash users,
`~/.zshrc` for zsh, and `~/.bashrc` on Ubuntu.

#### Powershell

You can use `chef-cli shell-init` with PowerShell on Windows.

To try it in your current session:

```posh
chef-cli shell-init powershell | Invoke-Expression
```

To enable it permanently:

```posh
"chef-cli shell-init powershell | Invoke-Expression" >> $PROFILE
```

#### Fish

`chef-cli shell-init` also supports fish.

To try it:

```fish
eval (chef-cli shell-init fish)
```

To permanently enable:

```fish
echo 'eval (chef-cli shell-init SHELL_NAME)' >> ~/.config/fish/config.fish
```

## Contributing

For information on contributing to this project see <https://github.com/chef/chef/blob/main/CONTRIBUTING.md>

# For Chef-CLI Developers

See the [Development Guide](CONTRIBUTING.md) for how to get started with
development on Chef Workstation itself, as well as details on how dependencies,
packaging, and building works.
