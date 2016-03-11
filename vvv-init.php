<?php
/**
 * Quick 'n' dirty vvv-activistnetwork installation helper.
 *
 * This file uses a non-standard format from Variable VV's blueprints
 * feature to create lists of plugins/themes to activate on ANP.
 *
 * @see https://github.com/bradp/vv/issues/184
 */

echo "Gathering Activist Network Platform configuration...".PHP_EOL;

$blueprint  = 'vvv-activistnetwork';
$blueprints = json_decode(file_get_contents(dirname(__FILE__).'/vv-anp-blueprint.json'));

printSlugs('network', 'themes');
printSlugs('mainsite', 'themes');
printSlugs('network', 'plugins');
printSlugs('site2.wordpress-anp.dev', 'plugins');

/**
 * @global $blueprints
 * @global $blueprint
 *
 * @param string $site
 * @param string $type
 */
function printSlugs ($site, $type) {
    global $blueprints, $blueprint;

    $sites = array_map('trim', array_filter(
        file(dirname(__FILE__).'/vvv-hosts'),
        function ($line) {
            return false === strpos($line, '#');
        }
    ));
    if ('network' !== $site && 'mainsite' !== $site && !in_array($site, $sites)) {
        return false;
    }
    switch ($type) {
        case 'themes':
        case 'plugins':
            continue;
        default:
            return false;
    }

    $file = dirname(__FILE__)."/$site-$type.txt";
    $fh = fopen($file, 'w+');
    $prop = 'activate';
    if (in_array($site, $sites)) {
        if (!empty($blueprints->$blueprint->sites)) {
            foreach ($blueprints->$blueprint->sites as $site_name => $the_site) {
                if (false !== stripos($site, $site_name)) {
                    foreach ($the_site->plugins as $obj) {
                        if (!empty($obj->$prop)) {
                            fputs($fh, getSlug($obj->location).PHP_EOL);
                        }
                    }
                }
            }
        }
    } else {
        if (!empty($blueprints->$blueprint->$type)) {
            foreach ($blueprints->$blueprint->$type as $obj) {
                if ('network' === $site) {
                    $prop = 'activate_network';
                }
                if (!empty($obj->$prop)) {
                    $slug = (empty($obj->slug)) ? getSlug($obj->location) : $obj->slug;
                    fputs($fh, $slug.PHP_EOL);
                }
            }
        }
    }
    fclose($fh);
}

/**
 * @param string
 */
function getSlug ($string) {
    $parsed = parse_url($string);
    if (!empty($parsed['host']) && false !== stripos($parsed['host'], 'github.com')) {
        if (!empty($parsed['path'])) {
            $p = explode('/', $parsed['path']);
            return $p[2]; // repository name
        }
    }
    return $string;
}
