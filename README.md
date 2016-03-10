# vvv-activistnetwork

Provision [Activist Network Platform](http://glocal.coop/activist-network-platform/) (a pre-configured WordPress multisite installation) on your VVV

## Getting Started
1. Set up your environment with all the requirements for [VVV](https://github.com/Varying-Vagrant-Vagrants/VVV) - Follow points 1. - 6. of [The First Vagrant Up](https://github.com/Varying-Vagrant-Vagrants/VVV#the-first-vagrant-up)
2. Clone/DL this repo into `/www/vvv-activistnetwork`
3. Provision! `vagrant reload --provision`

## Provided Sites
1. `wordpress-anp.dev` (Main Network Site)
1. `site{2..5}.wordpress-anp.dev` (Subsites 2 through 5)

## Using [Variable VV](https://github.com/bradp/vv)
1. Copy the `vv-anp-blueprint.json` file to `vv-blueprints.json` in your VVV directory.
1. Create the main site with `vv create --blueprint vvv-activistnetwork --multisite subdomain`

Note this only provisions the Multisite network and its main site, not subsites. See bradp/vv#184 for updates.

## Copyright / License
vvv-activistnetwork is copyleft (c) 2016, the contributors of the ANP project under the [TK-which license?](LICENSE).
