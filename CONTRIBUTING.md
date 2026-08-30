# Contributing to kitchen-cinc

Thanks for your interest in improving kitchen-cinc. Bug reports, feature requests, and pull requests are all welcome.

## Reporting issues

For bugs, please include:

- the version of kitchen-cinc and Test Kitchen you are using
- which provisioner you are using (`cinc_infra`, `cinc_solo`, `cinc_apply`,
  `cinc_target`, or one of the `chef_*` aliases)
- your `kitchen.yml`
- the output of the failing command, ideally with `-l debug`

## Development setup

```shell
bundle install
```

## Running tests

```shell
bundle exec rake          # Unit tests and linting
bundle exec rake test     # Unit tests only
bundle exec rake style    # Cookstyle linting only
```

Cookstyle must be run with `--chefstyle`; a bare `cookstyle` run applies
the cookbook cops to library code and reports a flood of offenses that do
not apply here.

```shell
bundle exec cookstyle --chefstyle       # what CI runs
bundle exec cookstyle --chefstyle -a    # autocorrect what can be autocorrected
```

Documentation coverage is also checked with YARD:

```shell
bundle exec rake doc            # Generate HTML docs into doc/
bundle exec rake doc_coverage   # List anything in lib/ still undocumented
```

## Integration tests

There are two integration configurations:

- `kitchen.yml` converges real Vagrant boxes (`ubuntu-24.04` and
  `almalinux-9`) and needs Vagrant plus a hypervisor locally.
- `kitchen.exec.yml` converges the machine you are sitting at, using the
  `exec` driver and transport. This is what CI runs, on Ubuntu, macOS,
  and Windows. It installs Cinc Client on that machine, so run it
  somewhere disposable.

```shell
# Vagrant
bundle exec kitchen test

# exec, against the local machine — this really does install Cinc
KITCHEN_LOCAL_YAML=kitchen.exec.yml bundle exec kitchen test default-localhost
```

Use `kitchen test` rather than `kitchen verify`: only `test` runs the
full create/converge/verify/destroy cycle, and teardown is easy to break
without noticing.

Changes that affect more than one provisioner are worth running against
both configurations, since `cinc_target` in particular takes a very
different path — it converges from the workstation rather than on the
instance.

## Documentation

Every configuration option is documented under [`docs/`](docs/README.md), split
by topic: provisioners, installation, converge, cookbook resolution, paths, and
target mode.

When you add or change an option, update the matching page and follow the
conventions in [`docs/README.md`](docs/README.md): each option is documented with
its **Type**, its **Default** (`auto` for values derived at runtime, `none` for
`nil`), and a **Description**. Options that are rarely needed are marked
**(advanced)**.

## Submitting changes

1. Fork the repository.
2. Create a feature branch off `main`.
3. Make your change, adding or updating tests to cover it.
4. Make sure `bundle exec rake` passes.
5. Push the branch to your fork and open a pull request.

Please keep pull requests focused on a single change — it makes review much
faster.

## Commit messages

This project releases through
[release-please](https://github.com/googleapis/release-please), which
derives the changelog and the next version number from commit subjects.
Commits merged to `main` must follow
[Conventional Commits](https://www.conventionalcommits.org/):

| Prefix                                     | Effect                                 |
|--------------------------------------------|----------------------------------------|
| `fix:`                                     | Patch release, listed in the changelog |
| `feat:`                                    | Minor release, listed in the changelog |
| `feat!:` / `BREAKING CHANGE:`              | Major release                          |
| `docs:` `test:` `ci:` `chore:` `refactor:` | No release on their own                |

Getting the prefix wrong means the release is versioned wrong, so it is
worth a moment's thought.

## Release process

Releases are automated. Nothing here needs to be done by hand:

1. Merging a `fix:` or `feat:` commit to `main` makes release-please open
   or update a release pull request that bumps
   `lib/kitchen/provisioner/cinc_version.rb` and writes `CHANGELOG.md`.
2. Review that pull request — mainly the changelog wording and the
   version it chose — and merge it when the release is wanted.
3. Merging it tags the release and publishes the gem to RubyGems and to
   GitHub Packages via `.github/workflows/publish.yaml`.

Never push to a `release-please--*` branch; release-please owns it and
will overwrite anything added there.
