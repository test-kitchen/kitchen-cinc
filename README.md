# kitchen-cinc

[![Gem Version](https://badge.fury.io/rb/kitchen-cinc.svg)](https://badge.fury.io/rb/kitchen-cinc)

A Test Kitchen provisioner for [Cinc Client](https://cinc.sh/) (the community distribution of Chef Infra Client) that downloads and installs omnibus packages via the [Cinc omnitruck API](https://omnitruck.cinc.sh/).

## Overview

This Test Kitchen plugin provides provisioners that automatically download and install the desired version of Cinc Client on your test instances. This allows you to test your cookbooks against different Cinc versions without pre-installing Cinc on your images.

## Installation

**Note:** This gem will ship as part of Cinc Workstation. If you're using Cinc Workstation, no additional installation is necessary.

For standalone installation, add this line to your Gemfile:

```ruby
gem "kitchen-cinc"
```

Then execute:

```shell
bundle install
```

Or install it directly:

```shell
gem install kitchen-cinc
```

## Usage

### Available Provisioners

This gem provides five provisioners:

- **`cinc_infra`** — Modern Cinc Client provisioner using local mode (recommended)
- **`cinc_zero`** — Deprecated alias for `cinc_infra` (maintained for backward compatibility)
- **`cinc_solo`** — Cinc Solo provisioner (note: does not support parallel converge)
- **`cinc_apply`** — Cinc Apply provisioner for running individual recipes
- **`cinc_target`** — Cinc Target Mode provisioner (requires Cinc 19.0.0+, Train-based transport)

### kitchen-omnibus-chef compatibility

To ease migration from `kitchen-omnibus-chef`, every provisioner above is also
registered under its `chef_*` name: `chef_infra`, `chef_solo`, `chef_apply`,
`chef_target`, and `chef_zero`. An existing `kitchen.yml` using
`provisioner: name: chef_infra` will work without modification — it transparently
runs the Cinc Client equivalent.

The `chef_*` names follow this priority order across kitchen-* gems:
**kitchen-chef-enterprise > kitchen-cinc > kitchen-omnibus-chef**. When a
higher-priority gem is installed, kitchen-cinc yields to it. Users who
explicitly want the Cinc Client implementation should use the `cinc_*`
names in `kitchen.yml`.

So with `chef_infra` in your `kitchen.yml`:

- only kitchen-cinc installed → Cinc Client
- kitchen-cinc + kitchen-omnibus-chef (>= 1.1.0) → Cinc Client
- kitchen-cinc + kitchen-chef-enterprise → Chef Enterprise
- all three installed → Chef Enterprise

(Cinc Client is the community distribution of Chef Infra Client — same
upstream source, different build.)

The deprecated `chef_*`-prefixed configuration keys (`chef_client_path`,
`chef_omnibus_root`, `chef_zero_host`, etc.) are still accepted and forwarded
to their `cinc_*` equivalents. Run `kitchen doctor` to see which deprecated
keys are in use.

### Basic Configuration

To use the Cinc Infra provisioner in your `kitchen.yml`:

```yaml
provisioner:
  name: cinc_infra
```

### Complete Example

```yaml
---
driver:
  name: vagrant

provisioner:
  name: cinc_infra
  product_name: cinc
  install_strategy: always
  channel: stable

platforms:
  - name: ubuntu-24.04
  - name: almalinux-9

suites:
  - name: default
    run_list:
      - recipe[my_cookbook::default]
```

### Docker (Dokken) Example

```yaml
---
driver:
  name: dokken
  privileged: true
  chef_image: cincproject/cinc
  chef_version: latest

provisioner:
  name: cinc_infra
  product_name: cinc

transport:
  name: dokken

platforms:
  - name: ubuntu-24.04
    driver:
      image: dokken/ubuntu-24.04
      pid_one_command: /bin/systemd

  - name: almalinux-9
    driver:
      image: dokken/almalinux-9
      pid_one_command: /usr/lib/systemd/systemd
```

### Configuration Options

Every option exposed by the provisioners is documented under
[`docs/`](docs/README.md):

- [Provisioners](docs/provisioners.md) — overview of `cinc_infra`,
  `cinc_zero`, `cinc_solo`, `cinc_apply`, and `cinc_target`.
- [Installation options](docs/installation.md) — `product_name`,
  `product_version`, `channel`, `install_strategy`, `download_url`,
  `checksum`, proxies, and the legacy omnibus options.
- [Converge options](docs/converge.md) — `run_list`, `attributes`,
  logging, `multiple_converge`, `enforce_idempotency`, `client_rb` /
  `solo_rb`, Chef Zero host/port, and more.
- [Cookbook resolution](docs/cookbook-resolution.md) — Policyfile and
  Berkshelf integration.
- [Paths](docs/paths.md) — sandbox, on-instance, and binary paths.
- [Target mode](docs/target-mode.md) — extra requirements and option
  overrides for `cinc_target`.

## Contributing

Bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md)
for development setup, how to run the unit and integration tests, and the
release process.

## License

Apache-2.0 — see [LICENSE](LICENSE) for details.
