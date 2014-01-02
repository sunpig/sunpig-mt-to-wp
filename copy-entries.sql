delimiter //

DROP PROCEDURE IF EXISTS copy_mt_entries_to_wp_posts //

CREATE PROCEDURE copy_mt_entries_to_wp_posts(mt_blog_id INT, wp_blog_id INT)
BEGIN
	SET @str_truncate_wp_table = CONCAT('TRUNCATE TABLE wp_', wp_blog_id, '_posts'); 
	PREPARE stmt_truncate_wp_table FROM @str_truncate_wp_table;
	EXECUTE stmt_truncate_wp_table;
	DEALLOCATE PREPARE stmt_truncate_wp_table;

	SET @str_copy_entries = CONCAT(
		'INSERT INTO wp_', wp_blog_id, '_posts (',
			'id, ',
			'post_author, ',
			'post_date, ',
			'post_date_gmt, ',
			'post_content, ',
			'post_title, ',
			'post_excerpt, ',
			'post_status, ',
			'comment_status, ',
			'ping_status, ',
			'post_name, ',
			'to_ping, ',
			'pinged, ',
			'post_modified, ',
			'post_modified_gmt, ',
			'post_parent, ',
			'guid, ',
			'menu_order, ',
			'post_type ',
		') ',
		' SELECT ',
			'entry_id, ',
			'entry_author_id, ',
			'entry_created_on, ',
			'CONVERT_TZ(entry_created_on,\'+00:00\',\'-06:00\'),',
			'IF (',
				'TRIM(IFNULL(entry_text_more,\'\'))=\'\', ',
				'IFNULL(entry_text,\'\'), ',
				'CONCAT(IFNULL(entry_text,\'\'), \'<!--more-->\', IFNULL(entry_text_more,\'\'))',
			'),',
			'entry_title, ',
			'entry_excerpt, ',
			'if(entry_status = 2, \'publish\', \'draft\'), ',
			'if(entry_allow_comments = 1, \'open\', \'closed\'), ',
			'if(entry_allow_pings = 1, \'open\', \'closed\'),',
			'entry_basename, ',
			'\'\', ',
			'\'\', ',
			'entry_modified_on, ',
			'CONVERT_TZ(entry_modified_on,\'+00:00\',\'-06:00\'), ',
			'0, ',
			'CONCAT(\'http://sunpig.com/mt-entry-\', entry_id, \'.html\'), ',
			'0, ',
			'\'post\' ',
		' FROM mt_entry WHERE entry_blog_id = ', mt_blog_id);
	PREPARE stmt_copy_entries FROM @str_copy_entries;
	EXECUTE stmt_copy_entries;
	DEALLOCATE PREPARE stmt_copy_entries;
END
//

delimiter ;
