# WP database

A multi-site Wordpress installation is considered a "network" of blogs. There is a set of
tables to describe the network as a whole, and features common to all blogs in the network
(e.g. users). Each blog in the network also gets its own set of tables for posts, comments,
links, and tags/categories.

Core/common tables:

* wp_blog_versions
* wp_blogs
* wp_registration_log
* wp_signups
* wp_site
* wp_sitemeta
* wp_usermeta
* wp_users

The first blog in the network gets tables starting just with the standard wp_* prefix.
Subsequent blogs are given a numeric infix that matches their ID in the wp_blogs table,
e.g. wp_2_posts.

Blog-specific tables:

* wp[_2]_commentmeta
* wp[_2]_comments
* wp[_2]_links
* wp[_2]_options
* wp[_2]_postmeta
* wp[_2]_posts
* wp[_2]_term_relationships
* wp[_2]_term_taxonomy
* wp[_2]_terms

This separation of tables is a big difference between a WP installation and a MT installation.
In MT, there is a single table for all blog entries (`mt_entry`), and each row in that table has
an `entry_blog_id` to show what blog it belongs to.

Another difference is that the `mt_entry` table contains many *columns* of data that in WP
are represented as *rows* of data in `wp_postmeta`. (Each row in `wp_postmeta` represents
a piece of data about a single post. Similarly for comments.)

So copying entry/post data from MT tables into the WP tables isn't simply a matter of
doing a single INSERT...SELECT query. Hello cursors.

