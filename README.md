# kitchen-cinc

[![Gem Version](https://badge.fury.io/rb/kitchen-cinc.svg)](https://badge.fury.io/rb/kitchen-cinc)

A Test Kitchen provisioner for [Cinc Client](https://cinc.sh/) (the community distribution of Chef Infra Client) that downloads and installs omnibus packages via the [Cinc omnitruck API](https://omnitruck.cinc.sh/).

## Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration options](#configuration-options)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

This Test Kitchen plugin provides provisioners that automatically download and install the desired version of Cinc Client on your test instances. This allows you to test your cookbooks against different Cinc versions without pre-installing Cinc on your images.

## Requirements

- Ruby 3.1 or newer.
- Test Kitchen 4.0 or newer.
- A Test Kitchen driver for wherever you want to converge — for example
  [kitchen-vagrant][kitchen_vagrant], [kitchen-dokken][kitchen_dokken], or
  [kitchen-docker][kitchen_docker].
- Cookbook dependency resolution needs either
  [Cinc Workstation](https://cinc.sh/download/) on your `PATH` (for
  Policyfiles) or the `berkshelf` gem (for Berksfiles). Neither is needed if
  you stage cookbooks yourself.
- The `cinc_target` provisioner additionally needs Cinc Client 19.0.0 or newer
  installed on your workstation and a Train-based transport. See
  [docs/target-mode.md](docs/target-mode.md).

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

## Configuration options

Every option exposed by the provisioners is documented under
[`docs/`](docs/README.md), each with its type, its default, and what it
actually does:

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

## Troubleshooting

Start with `kitchen converge -l debug`. That prints the exact install script and
`cinc-client` command line the provisioner generated, which answers most
questions on its own. To turn up Cinc's own logging instead of Test Kitchen's,
set `log_level: debug` (or `trace`) on the provisioner.

### `Cinc Client will run, but do nothing. Is this intended?`

No `Policyfile.rb`, `Berksfile`, `cookbooks/` directory, or `metadata.rb` was
found under your kitchen root, so there was nothing to converge. kitchen-cinc
stages an empty placeholder cookbook and carries on. Run kitchen from your
cookbook's directory, or point `policyfile_path` / `berksfile_path` at the right
file.

### `policyfile detected, but provisioner ... doesn't support Policyfiles`

Only `cinc_infra`, `cinc_zero`, and `cinc_target` can use Policyfiles.
`cinc_solo` and `cinc_apply` cannot, and they fail rather than quietly
resolving cookbooks some other way. Switch to `cinc_infra`, or move the
Policyfile out of the kitchen root.

### `The 'cinc', 'cinc-cli', 'chef', or 'chef-cli' executables cannot be found`

Policyfile resolution shells out to Cinc Workstation. Install it from
<https://cinc.sh/download/> and make sure `cinc` is on your `PATH`, or remove
the Policyfile and use Berkshelf or a plain `cookbooks/` directory instead.

### The install step fails or downloads the wrong package

The install command comes from the [Cinc omnitruck API](https://omnitruck.cinc.sh/)
via `Mixlib::Install`. Pin what you want with `product_version` and `channel`,
or bypass omnitruck entirely with `download_url` (plus `checksum`). If your
image already has Cinc baked in, set `install_strategy: skip` and kitchen-cinc
will not try to install anything.

### `Need cinc-client installed locally` / `Need version 19.0.0 or higher`

These come from `cinc_target`, which runs `cinc-client` on your workstation
rather than on the instance. Install Cinc Client 19.0.0 or newer locally. If
you see a complaint that the version output could not be parsed, run
`cinc-client -v` yourself and check what it prints.

### `Cinc Target Mode provisioner requires a Train-based transport`

`cinc_target` needs a transport that can hand it a Train URI, such as
[kitchen-transport-train](https://github.com/tecracer-chef/kitchen-transport-train).
The stock `ssh` and `winrm` transports will not work with it.

### A `chef_*` option is being ignored

The `chef_*`-prefixed configuration keys are deprecated aliases and are
forwarded to their `cinc_*` equivalents, but the `cinc_*` key wins when both
are set. Run `kitchen doctor` to list every deprecated key in your
`kitchen.yml`.

## Contributing

Bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md)
for development setup, how to run the unit and integration tests, and the
release process.

## License

Apache-2.0 — see [LICENSE](LICENSE) for details.

[kitchen_docker]: https://github.com/test-kitchen/kitchen-docker
[kitchen_dokken]: https://github.com/test-kitchen/kitchen-dokken
[kitchen_vagrant]: https://github.com/test-kitchen/kitchen-vagrant
