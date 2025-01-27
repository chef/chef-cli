# compliance

This directory contains Chef InSpec profile, waiver and input objects which are used with the Chef Infra Compliance Phase.

Detailed information on the Chef Infra Compliance Phase can be found in the [Chef Documentation](https://docs.chef.io/chef_compliance_phase/).

```plain
./compliance
├── inputs
├── profiles
└── waivers
```

Use the `chef generate` command from Chef Workstation to create content for these directories:

```sh
# Generate a Chef InSpec profile
chef generate profile PROFILE_NAME

# Generate a Chef InSpec waiver file
chef generate waiver WAIVER_NAME

# Generate a Chef InSpec input file
chef generate input INPUT_NAME
```
