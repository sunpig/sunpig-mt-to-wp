# The actual migration

## Clean up invalid characters in the original MT database

Manual effort. Can be done any time before the migration.

Use `identify-abnormal-characters-in-entries.sql` and `identify-abnormal-characters-in-comments.sql`
to find enties and comments with characters that will cause problems during migration.


## Clean up duplicate entry tags in the original MT database

Manual effort. Can be done any time before the migration.

The process of copying categories and tags is primitive, and will barf if it tries to copy two
tags that have the same basename (slug). For example, the tags "background image"
and "background-image" can be two separate tags in MT, but they end up with
the same *normalized* (n8d) tagname of "backgroundimage".

Also, it will drop tags that resolve to the same base name as an existing *category*.
(I can live with the loss.)


## Clean up entry_basename values in the mt_entry table in the original MT database

Make URLs consistent: /blogname/yyyy/mm/dd/entry-basename/

For this to happen, all entries should have an appropriate basename. Can be done
any time before the migration.


## Prepare .htaccess redirection rules in the original MT installation

Create relevant MT template to generate HTTP 301 redirect rules for use in .htaccess
for mapping old urls to new ones. Can be done any time before the migration.

Evilrooster:
<mt:Entries lastn="10000">
Redirect 301 <$mt:EntryPermalink$> http://sunpig.com/abi/<$mt:EntryDate format="%Y/%m/%d"$>/<$mt:EntryBasename$>/</mt:Entries>

Quick reviews:
<mt:Entries lastn="10000">
Redirect 301 <$mt:EntryPermalink$> http://sunpig.com/quickreviews/<$mt:EntryDate format="%Y/%m/%d"$>/<$mt:EntryBasename$>/</mt:Entries>

Bunny tails:
<mt:Entries lastn="10000">
Redirect 301 <$mt:EntryPermalink$> http://sunpig.com/bunnytails/<$mt:EntryDate format="%Y/%m/%d"$>/<$mt:EntryBasename$>/</mt:Entries>


## Take backup of MT database

The usual.


## Install Wordpress

Main instructions: [http://codex.wordpress.org/Installing_WordPress](http://codex.wordpress.org/Installing_WordPress)

Multisite install: [http://codex.wordpress.org/Create_A_Network](http://codex.wordpress.org/Create_A_Network)

Install wordpress in its own subdirectory, rather than in the root of the site.

Note that the blog database exists already - use the same db for both MT and WP, which
makes copying data between the two easy.

* Grab the latest version of wordpress and uncompress it to /wordpress under sunpig.com
* Copy wp-config-sample.php to wp-config.php, and edit the file to
	* add database connection details
	* add security keys, populated with details from https://api.wordpress.org/secret-key/1.1/salt/ 
* Run the wp installation script by going to http://sunpig.com/wordpress/wp-admin/install.php
* Create initial user and initial blog on /dummy url (initial blog will later be disabled)


## Prepare Wordpress multisite

Edit wp-config.php to add multisite configuration:

```
/* Multisite */
define( 'WP_ALLOW_MULTISITE', true );
```

This enables network configuration from within wp. In the wp-admin screens, find 
Tools -> Network Setup -> Create a Network of Wordpress Sites

Follow instructions on screen, which will create some code to be added to the wp-config.php
file, and a block to be added to .htaccess


## Add WP users

In the wp-admin interface, create users to match those in the mt installation. The copy scripts
rely on user email address to match up users between mt and wp.


## Add WP sites

In the following order:

1. Legends of the Sun Pig
2. Evilrooster Crows
3. Quick Reviews
4. Bunny Tails

For each blog, edit the settings to make sure that the "Day and name" option is selected

## Copy content

Run the script `procedures.sql` to install the copy procedures.


## Copy the content

In mysql console:

```
-- legends of the sun pig
call copy_mt_categories_and_entry_tags_to_wp_terms(2, 2);
call copy_mt_entries_to_wp_posts(2, 2);
call copy_mt_comments_to_wp_comments(2, 2);

-- evilrooster crows
call copy_mt_categories_and_entry_tags_to_wp_terms(4, 3);
call copy_mt_entries_to_wp_posts(4, 3);
call copy_mt_comments_to_wp_comments(4, 3);

-- quickreviews
call copy_mt_categories_and_entry_tags_to_wp_terms(12, 4);
call copy_mt_entries_to_wp_posts(12, 4);
call copy_mt_comments_to_wp_comments(12, 4);

-- bunny tails
call copy_mt_categories_and_entry_tags_to_wp_terms(3, 5);
call copy_mt_entries_to_wp_posts(3, 5);
call copy_mt_comments_to_wp_comments(3, 5);
```

After that, run the commands in `copy-entry-keywords.sql` to copy the key-value
metadata from the quick reviews blog from mt to wp.

## Create index.php files

For the top-level blog, create an index.php that loads wp:

```
<?php
/**
 * Front to the WordPress application. This file doesn't do anything, but loads
 * wp-blog-header.php which does and tells WordPress to load the theme.
 *
 * @package WordPress
 */

/**
 * Tells WordPress to load the WordPress theme and output it.
 *
 * @var bool
 */
define('WP_USE_THEMES', true);

/** Loads the WordPress Environment and Template */
require( dirname( __FILE__ ) . '/wordpress/wp-blog-header.php' );
```

For each other blog, create an index.php that loads wp (note the difference
in the path on the last line):

```
<?php
/**
 * Front to the WordPress application. This file doesn't do anything, but loads
 * wp-blog-header.php which does and tells WordPress to load the theme.
 *
 * @package WordPress
 */

/**
 * Tells WordPress to load the WordPress theme and output it.
 *
 * @var bool
 */
define('WP_USE_THEMES', true);

/** Loads the WordPress Environment and Template */
require( dirname( __FILE__ ) . '/../wordpress/wp-blog-header.php' );
```


## Modify htaccess for redirects

Go to the generated htaccess redirects files in MT, and add the redirect chunks to the 
main .htaccess file for sunpig so that old links are correctly redirected.


## Harden installation

See [http://codex.wordpress.org/Hardening_WordPress](http://codex.wordpress.org/Hardening_WordPress)