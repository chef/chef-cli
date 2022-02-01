# compliance

This directory contains profile, waiver and input objects which are used with the Chef Infra Compliance Phase.

Detailed information on Compliance Phase can be found on the documentation site [https://docs.chef.io/chef_compliance_phase/].

```plain
./compliance
├── inputs
├── profiles
└── waivers
```

Use the `chef generate` command from Chef Workstation to create content for these directories:

```sh
# Generate an InSpec profile
chef generate profile PROFILE_NAME

# Generate an InSpec waiver file
chef generate waiver WAIVER_NAME

# Generate an InSpec input file
chef generate input INPUT_NAME
```
