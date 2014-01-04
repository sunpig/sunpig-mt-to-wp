# The actual migration

## 1. Clean up invalid characters in the original MT database

Manual effort. Can be done any time before the migration.

Use `identify-abnormal-characters-in-entries.sql` and `identify-abnormal-characters-in-comments.sql`
to find enties and comments with characters that will cause problems during migration.

## 2. Clean up duplicate entry tags in the original MT database

Manual effort. Can be done any time before the migration.

The process of copying categories and tags is primitive, and will barf if it tries to copy two
tags that have the same basename (slug). For example, the tags "background image"
and "background-image" can be two separate tags in MT, but they end up with
the same *normalized* (n8d) tagname of "backgroundimage".

Also, it will drop tags that resolve to the same base name as an existing *category*.
I can live with the loss.

