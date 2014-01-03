# Database Charsets

The mt_* tables in our database use the latin1 charset, but the wp_* tables use
the utf8 charset. To make things more fun, the data in the mt_* tables is not
consistently encoded: some rows use utf8 stored in the db as latin1, while
other rows genuinely are latin1 stored as latin1. This is visible if I do a
`select entry_text from mt_entry` on the database: sometimes a GBP character
will come back as '£', and sometimes as 'Â£'.

For *most* rows, this conversion will take the utf8 text in the latin1 mt_* tables,
and turn it into utf8 text for the wp_* tables:

```
select 
	convert(cast(convert(entry_text using latin1) as binary) using utf8)
from
	mt_entry;
```

But for some rows it goes horribly wrong, truncating the text at the point where
it encounters an invalid character.

Step 1: Identify problematic rows with badly encoded characters:

```
select
	entry_id, 
	entry_blog_id
from
	mt_entry
where
	convert(cast(convert(entry_text using latin1) as binary) using utf8) <> entry_text
	or convert(cast(convert(entry_text_more using latin1) as binary) using utf8) <> entry_text_more
order by
	entry_id;
```

Step 2: In the MT admin interface, visit each of the 110 problematic entries, and fix them
so that the conversion process will run OK.

It's only 110 entries.

Step 3: Carry on.
