/* 
The quickreviews blog (mt_blog_id=12, wp blog id = ?) used an entry-keywords plugin for storing
key-value data for an entry. In WP, this data is stored in the wp_postmeta table.
There are only three keys: imdb, amazon, and image
*/

insert into wp_?_postmeta (
	post_id,
	meta_key,
	meta_value
)
select 
	entry_id,
	'imdb',
	substring(
		entry_keywords
		FROM
		instr(lower(entry_keywords), 'imdb') + length('imdb') + 1
		FOR
		coalesce(
			nullif(locate(' ', lower(entry_keywords), instr(lower(entry_keywords), 'imdb')), 0),
			nullif(locate("\n", lower(entry_keywords), instr(lower(entry_keywords), 'imdb')), 0),
			length(entry_keywords) + 1
		) - (instr(lower(entry_keywords), 'imdb') + length('imdb') + 1)
	)
from
	mt_entry 
where
	entry_blog_id = 12
	and entry_keywords like '%imdb=%';


insert into wp_?_postmeta (
	post_id,
	meta_key,
	meta_value
)
select 
	entry_id,
	'amazon',
	substring(
		entry_keywords
		FROM
		instr(lower(entry_keywords), 'amazon') + length('amazon') + 1
		FOR
		coalesce(
			nullif(locate(' ', lower(entry_keywords), instr(lower(entry_keywords), 'amazon')), 0),
			nullif(locate("\n", lower(entry_keywords), instr(lower(entry_keywords), 'amazon')), 0),
			length(entry_keywords) + 1
		) - (instr(lower(entry_keywords), 'amazon') + length('amazon') + 1)
	)
from
	mt_entry 
where
	entry_blog_id = 12
	and entry_keywords like '%amazon=%';


insert into wp_?_postmeta (
	post_id,
	meta_key,
	meta_value
)
select 
	entry_id,
	'image',
	substring(
		entry_keywords
		FROM
		instr(lower(entry_keywords), 'image') + length('image') + 1
		FOR
		coalesce(
			nullif(locate(' ', lower(entry_keywords), instr(lower(entry_keywords), 'image')), 0),
			nullif(locate("\n", lower(entry_keywords), instr(lower(entry_keywords), 'image')), 0),
			length(entry_keywords) + 1
		) - (instr(lower(entry_keywords), 'image') + length('image') + 1)
	)
from
	mt_entry 
where
	entry_blog_id = 12
	and entry_keywords like '%image=%';
