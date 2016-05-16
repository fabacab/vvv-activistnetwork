# vvv-activistnetwork

Provision [Activist Network Platform](https://glocal.coop/activist-network-platform/) (a pre-configured WordPress Multi-Network installation) in your VVV development environment.

## Getting Started

1. Set up your environment with all the requirements for [VVV](https://github.com/Varying-Vagrant-Vagrants/VVV) - Follow points 1 through 6 of "[The First Vagrant Up](https://github.com/Varying-Vagrant-Vagrants/VVV#the-first-vagrant-up)."
1. Clone/download this repo into `/www/vvv-activistnetwork`.
1. Provision! `vagrant reload --provision`

## Provided Sites

1. `wordpress-anp.dev` (Main Network Site)
1. `site{2..5}.wordpress-anp.dev` (Main network's subsites 2 through 5)
1. `wpmn-anp.dev` (Sub-network root site)
1. `site{2..5}.wpmn-anp.dev` (Sub-network's subsites 2 through 5)

## Using [Variable VV](https://github.com/bradp/vv)

This alternate procedure makes use of the `vv` wizard, and assumes you already have VVV installed. Its results are almost the same as a vanilla VVV `--provision`, but without the multi-network configuration. That is, this method only results in a single WP Multisite.

1. Copy the `vv-anp-blueprint.json` file to `vv-blueprints.json` in your VVV directory.
1. Create the main site with `vv create --blueprint vvv-activistnetwork --multisite subdomain`

## Copyright / License

vvv-activistnetwork is copyleft (c) 2016, the contributors of the ANP project under the [TK-which license?](LICENSE).
