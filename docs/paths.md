# Paths

kitchen-cinc derives several paths automatically. Override only when
your test environment deviates from the conventional layout.

## Sandbox paths (workstation side)

These options point at directories on the workstation that the
provisioner will look at when staging the sandbox. When one is not set,
Test Kitchen looks for the subpath below in three places, in order, and
uses the first that exists:

1. `<test_base_path>/<suite name>/<subpath>` (usually
   `test/integration/<suite>/...`)
2. `<test_base_path>/<subpath>`
3. `<current directory>/<subpath>`

If none of those exists the option stays unset and nothing is staged for
it -- the defaults are auto-detected, not invented.

| Option                              | Default subpath                    |
|-------------------------------------|------------------------------------|
| `data_path`                         | `data/`                            |
| `data_bags_path`                    | `data_bags/`                       |
| `environments_path`                 | `environments/`                    |
| `nodes_path`                        | `nodes/`                           |
| `roles_path`                        | `roles/`                           |
| `clients_path`                      | `clients/`                         |
| `encrypted_data_bag_secret_key_path`| `encrypted_data_bag_secret_key`    |
| `apply_path` (`cinc_apply` only)    | `apply/`                           |

If a path is set explicitly it is used as-is, expanded relative to
`kitchen_root`, and no auto-detection happens.

### `root_path`

- **Type:** `String`
- **Default:** `auto`
- **Description:** Directory on the test instance that the sandbox is copied
  into, and the root that every other on-instance path is joined against.
  Defaults to the driver's sandbox location. Under `cinc_target` this is
  redirected to the local sandbox path, because the converge runs from the
  workstation rather than on the instance.

## On-instance binary paths

These options point at executables on the test instance. The defaults
derive from `cinc_omnibus_root` (set by the installer at runtime). On
Windows the `.bat` extension is appended automatically.

### `cinc_client_path` (`cinc_infra` / `cinc_zero` / `cinc_target`)

- **Type:** String
- **Default:** `<cinc_omnibus_root>/bin/cinc-client`
- Path to the `cinc-client` binary used during converge.

### `cinc_solo_path` (`cinc_solo`)

- **Type:** String
- **Default:** `<cinc_omnibus_root>/bin/cinc-solo`
- Path to the `cinc-solo` binary used during converge.

### `cinc_apply_path` (`cinc_apply`)

- **Type:** String
- **Default:** `<cinc_omnibus_root>/bin/cinc-apply`
- Path to the `cinc-apply` binary used during converge.

### `ruby_bindir`

- **Type:** String
- **Default:** `<cinc_omnibus_root>/embedded/bin`
- Directory containing the embedded Ruby interpreter shipped with the
  Cinc package.

## Notes

- The `<cinc_omnibus_root>` value is populated at install time by
  `Mixlib::Install`. For typical Linux installs it's `/opt/cinc`; for
  Windows it's under `C:\opscode\cinc`.
- Override the binary paths if you install Cinc into a non-default
  prefix (for example, when packaging a custom omnibus build).
- `kitchen_root` is provided by Test Kitchen itself and points at the
  top of the project being tested. It is not a kitchen-cinc option.
