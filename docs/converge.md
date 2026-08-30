# Converge Options

These options control how Cinc Client is invoked during the converge
phase. Most apply to every provisioner; provisioner-specific notes are
called out where relevant.

## Run list and attributes

### `run_list`

- **Type:** Array
- **Default:** `[]`
- The Cinc run list to execute. Items can be recipe names
  (`recipe[my_cookbook::default]`) or role names.

### `attributes`

- **Type:** Hash
- **Default:** `{}`
- Node attributes to set during the converge. Always written to the
  `dna.json` file in the sandbox, for every provisioner -- attributes
  are never merged into `client.rb` or `solo.rb`. Use `client_rb` /
  `solo_rb` for config file entries.

### `named_run_list` (`cinc_infra` / `cinc_zero` / `cinc_target`)

- **Type:** String
- **Default:** `{}` (behaves as unset)
- Name of a run list defined in the Policyfile's `named_run_lists`
  block, written into the rendered `client.rb` as `named_run_list`. The
  default is an empty Hash for historical reasons; it renders as a no-op
  and Cinc uses the Policyfile's default run list.

### `policy_group`

- **Type:** String
- **Default:** none
- Policy group used when resolving a Policyfile. See
  [cookbook-resolution.md](cookbook-resolution.md).

### `json_attributes` (`cinc_infra` / `cinc_zero` / `cinc_target`)

- **Type:** Boolean
- **Default:** `true`
- When `true`, `--json-attributes <root_path>/dna.json` is passed to
  `cinc-client`. `dna.json` is written to the sandbox either way; this
  option only controls whether Cinc is told to read it. `cinc_solo`
  ignores this option and always passes `--json-attributes`.

## Logging

### `log_level`

- **Type:** String
- **Default:** `"auto"` (or `"debug"` if Test Kitchen debug is on)
- Cinc log level. Common values: `"auto"`, `"info"`, `"warn"`,
  `"debug"`, `"trace"`.

### `log_file`

- **Type:** String
- **Default:** none
- Path to write the Cinc log file on the test instance. When set, the
  provisioner passes `--logfile <path>` to `cinc-client`.

### `profile_ruby`

- **Type:** Boolean
- **Default:** `false`
- When `true`, passes `--profile-ruby` to `cinc-client`.

### `slow_resource_report` (advanced, `cinc_infra` / `cinc_zero` / `cinc_target`)

- **Type:** Boolean or Integer
- **Default:** none
- When set, passes `--slow-report` (or `--slow-report N` if an integer
  is given) to `cinc-client`.

## Multiple converges and idempotency

### `multiple_converge`

- **Type:** Integer
- **Default:** `1`
- Number of times to invoke Cinc per converge. Useful in combination
  with `enforce_idempotency` to assert that a second run is a no-op.

### `enforce_idempotency`

- **Type:** Boolean
- **Default:** `false`
- When `true`, the final converge uses an alternate `client.rb` that
  fails the run if any resource reports `:updated`. Pair with
  `multiple_converge: 2` (or higher).

### `retry_on_exit_code`

- **Type:** Array of Integer
- **Default:** `[35, 213]`
- Exit codes that Test Kitchen should treat as a successful retry
  signal (used by Cinc reboot handling).

### `deprecations_as_errors`

- **Type:** Boolean
- **Default:** `false`
- Sets `treat_deprecation_warnings_as_errors true` in the rendered
  `client.rb` / `solo.rb` so any deprecation warning fails the run.

## Custom config injection

### `client_rb` (`cinc_infra` / `cinc_zero` / `cinc_target`)

- **Type:** Hash
- **Default:** `{}`
- Extra entries merged into the rendered `client.rb`. Keys become
  config attribute names; values are formatted with Ruby `inspect`
  semantics. Example:

  ```yaml
  provisioner:
    name: cinc_infra
    client_rb:
      chef_server_url: https://my-chef-server.example.com/organizations/test
      ssl_verify_mode: :verify_peer
  ```

### `solo_rb` (`cinc_solo`)

- **Type:** Hash
- **Default:** `{}`
- Extra entries merged into the rendered `solo.rb`. Same semantics as
  `client_rb`.

### `config_path`

- **Type:** String
- **Default:** none
- Path to a `config.rb` that `ChefConfig::WorkstationConfigLoader`
  should load on startup, before any provisioner code runs. Lets you
  share workstation-level config (proxy settings, etc.) with
  kitchen-cinc.

## Chef Zero networking (`cinc_infra` / `cinc_zero` / `cinc_target`)

### `cinc_zero_host`

- **Type:** String
- **Default:** none
- Value passed to `--chef-zero-host`. Leave unset for the Cinc default
  bind address.

### `cinc_zero_port`

- **Type:** Integer
- **Default:** `8889`
- Value passed to `--chef-zero-port`.
