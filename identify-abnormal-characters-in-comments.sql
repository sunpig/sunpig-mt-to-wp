/* 
The mt_comment table uses the latin1 character set; wp_comments uses utf8.
The copy process uses a latin1 -> utf8 conversion that will handle most
comments, but there are some that cause problems and end up truncated.
To identify which ones these are, and fix them in MT before the migration,
use the following steps:

- Create a temporary table with utf8 charset
- Perform a copy+convert from mt_comment to the temp table
- Join mt_comment with the temp table to find comments that have been truncated
- Note the problem comments, and fix them either in the MT admin or 
  identify the characters that are causing the problem, and run a search/replace
  on the mt_comment table directly.

*/


/*** Drop & create the temp table ***/

drop table if exists tmp_comment_sanitize;

create temporary table if not exists tmp_comment_sanitize (
  `comment_ID` bigint(20) unsigned NOT NULL,
  `comment_post_ID` bigint(20) unsigned NOT NULL,
  `comment_content` text NOT NULL,
  PRIMARY KEY (`comment_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/*** Copy + convert from mt_comment to temp table ***/

insert into tmp_comment_sanitize
(comment_id, comment_post_id, comment_content)
select 
	comment_id,
	comment_entry_id,
	convert(cast(convert(comment_text using latin1) as binary) using utf8)
from 
	mt_comment 
	where comment_junk_status <> -1
	and comment_visible = 1;


/*** Join mt_comment with the temp table to find comments that need fixing ***/

select 
	mtc.comment_blog_id,
	mtc.comment_entry_id,
	mtc.comment_id,
	mtc.comment_author,
	mtc.comment_text,
	length(mtc.comment_text),
	tcs.comment_content,
	length(tcs.comment_content)
from
	tmp_comment_sanitize tcs
	inner join mt_comment mtc on tcs.comment_id = mtc.comment_id
where
	tcs.comment_content <> mtc.comment_text
	and length(tcs.comment_content) <> length(mtc.comment_text)
order by
	mtc.comment_blog_id,
	mtc.comment_entry_id,
	mtc.comment_id;

