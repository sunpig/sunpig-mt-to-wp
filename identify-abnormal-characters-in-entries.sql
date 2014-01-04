/* 
The mt_entry table uses the latin1 character set; wp_posts uses utf8.
The copy process uses a latin1 -> utf8 conversion that will handle most
entries, but there are some that cause problems and end up truncated.
To identify which ones these are, and fix them in MT before the migration,
use the following steps:

- Create a temporary table with utf8 charset
- Perform a copy+convert from mt_entry to the temp table
- Join mt_entry with the temp table to find entries that have been truncated
- Note the problem entries, and fix them either in the MT admin or 
  identify the characters that are causing the problem, and run a search/replace
  on the mt_entry table directly.

*/


/*** Drop & create the temp table ***/

drop table if exists tmp_entry_sanitize;

create temporary table if not exists tmp_entry_sanitize (
  `entry_ID` bigint(20) unsigned NOT NULL,
  `entry_title` text,
  `entry_excerpt` text,
  `entry_text` text,
  `entry_text_more` text,
  `entry_keywords` text,
  `entry_basename` text,
  PRIMARY KEY (`entry_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/*** Copy + convert from mt_entry to temp table ***/

insert into tmp_entry_sanitize (
	entry_id,
	entry_title,
	entry_excerpt,
	entry_text,
	entry_text_more,
	entry_keywords,
	entry_basename
)
select 
	entry_id,
	convert(cast(convert(entry_title using latin1) as binary) using utf8),
	convert(cast(convert(entry_excerpt using latin1) as binary) using utf8),
	convert(cast(convert(entry_text using latin1) as binary) using utf8),
	convert(cast(convert(entry_text_more using latin1) as binary) using utf8),
	convert(cast(convert(entry_keywords using latin1) as binary) using utf8),
	convert(cast(convert(entry_basename using latin1) as binary) using utf8)
from 
	mt_entry;


/*** Join mt_entry with the temp table to find entries that need fixing ***/

select 
	mte.entry_blog_id,
	mte.entry_id,
	mte.entry_title,
	tes.entry_title,
	length(mte.entry_title),
	length(tes.entry_title),
	mte.entry_excerpt,
	tes.entry_excerpt,
	length(mte.entry_excerpt),
	length(tes.entry_excerpt),
	mte.entry_text,
	tes.entry_text,
	length(mte.entry_text),
	length(tes.entry_text),
	mte.entry_text_more,
	tes.entry_text_more,
	length(mte.entry_text_more),
	length(tes.entry_text_more),
	mte.entry_keywords,
	tes.entry_keywords,
	length(mte.entry_keywords),
	length(tes.entry_keywords),
	mte.entry_basename,
	tes.entry_basename,
	length(mte.entry_basename),
	length(tes.entry_basename)
from
	tmp_entry_sanitize tes
	inner join mt_entry mte on tes.entry_id = mte.entry_id
where
	(tes.entry_title <> mte.entry_title and length(tes.entry_title) <> length(mte.entry_title) )
	or (tes.entry_excerpt <> mte.entry_excerpt and length(tes.entry_excerpt) <> length(mte.entry_excerpt) )
	or (tes.entry_text <> mte.entry_text and length(tes.entry_text) <> length(mte.entry_text) )
	or (tes.entry_text_more <> mte.entry_text_more and length(tes.entry_text_more) <> length(mte.entry_text_more) )
	or (tes.entry_keywords <> mte.entry_keywords and length(tes.entry_keywords) <> length(mte.entry_keywords) )
	or (tes.entry_basename <> mte.entry_basename and length(tes.entry_basename) <> length(mte.entry_basename) )
order by
	mte.entry_blog_id,
	mte.entry_id;
