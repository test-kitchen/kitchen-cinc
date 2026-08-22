# Provisioners

kitchen-cinc ships five provisioners. All of them inherit from a common
`CincBase` class, so the options documented in
[installation.md](installation.md), [converge.md](converge.md),
[cookbook-resolution.md](cookbook-resolution.md), and [paths.md](paths.md)
apply to every provisioner unless noted otherwise.

## `cinc_infra` (recommended)

Modern Cinc Client provisioner that runs `cinc-client --local-mode` on
the test instance. This is the preferred provisioner for new projects.

```yaml
provisioner:
  name: cinc_infra
```

Adds the following provisioner-specific options on top of the base set:

- `client_rb` — extra `client.rb` config merged into the rendered file.
  Hash, default `{}`.
- `named_run_list` — selects a named run list from a Policyfile. Hash,
  default `{}`.
- `json_attributes` — when `true`, writes node attributes to a `dna.json`
  file and passes `--json-attributes`. Boolean, default `true`.
- `cinc_zero_host` — value passed to `--chef-zero-host`. String,
  default `nil`.
- `cinc_zero_port` — value passed to `--chef-zero-port`. Integer,
  default `8889`.
- `cinc_client_path` — absolute path to the `cinc-client` binary on the
  test instance. String, defaults to
  `<cinc_omnibus_root>/bin/cinc-client` (with `.bat` on Windows).
- `ruby_bindir` — directory containing the embedded Ruby. String,
  defaults to `<cinc_omnibus_root>/embedded/bin`.

## `cinc_zero` (deprecated)

Backward-compatible alias for `cinc_infra`. Use `cinc_infra` in new
configurations.

```yaml
provisioner:
  name: cinc_zero
```

Accepts exactly the same options as `cinc_infra`.

## `cinc_solo`

Runs `cinc-solo` on the test instance. Does not run in parallel with
other provisioner instances (`no_parallel_for :converge`) because
Berkshelf is not thread-safe.

```yaml
provisioner:
  name: cinc_solo
```

Adds the following provisioner-specific options:

- `solo_rb` — extra `solo.rb` config merged into the rendered file.
  Hash, default `{}`.
- `cinc_solo_path` — absolute path to the `cinc-solo` binary on the
  test instance. String, defaults to
  `<cinc_omnibus_root>/bin/cinc-solo` (with `.bat` on Windows).
- `ruby_bindir` — directory containing the embedded Ruby. String,
  defaults to `<cinc_omnibus_root>/embedded/bin`.

`cinc_solo` does **not** support Policyfiles. Use Berkshelf or a
pre-resolved cookbook directory.

### `legacy_mode`

- **Type:** `Boolean`
- **Default:** `false`
- **Description:** Passes `--legacy-mode` to `cinc-solo`, running it as a true
  Cinc Solo run rather than the local-mode shim. Only applies to `cinc_solo`.

## `cinc_apply`

Runs each recipe in the suite's `run_list` through `cinc-apply` against
files staged under an `apply/` directory in the sandbox.

```yaml
provisioner:
  name: cinc_apply
```

Adds the following provisioner-specific options:

- `cinc_apply_path` — absolute path to the `cinc-apply` binary on the
  test instance. String, defaults to
  `<cinc_omnibus_root>/bin/cinc-apply` (with `.bat` on Windows).
- `ruby_bindir` — directory containing the embedded Ruby. String,
  defaults to `<cinc_omnibus_root>/embedded/bin`.
- `apply_path` — sandbox path under which `<recipe>.rb` files are
  staged. String, auto-calculated from `kitchen_root` if unset.

## `cinc_target`

Runs Cinc Client in target mode (Cinc Client 19.0.0+) against a remote
node, using a Train-based transport. The provisioner runs `cinc-client`
locally on the workstation, not on the test instance, so it does **not**
install Cinc on the target.

```yaml
provisioner:
  name: cinc_target
```

Inherits everything from `cinc_infra`. See
[target-mode.md](target-mode.md) for the additional requirements and
the option overrides specific to this provisioner.
