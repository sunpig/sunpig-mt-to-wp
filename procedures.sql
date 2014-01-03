delimiter //

DROP PROCEDURE IF EXISTS copy_mt_categories_to_wp_terms //

CREATE PROCEDURE copy_mt_categories_to_wp_terms(mt_blog_id INT, wp_blog_id INT)
BEGIN
	SET @wp_table_infix = if(wp_blog_id = 1, '', CONCAT(wp_blog_id, '_'));

	SET @str_truncate_wp_table = CONCAT('TRUNCATE TABLE wp_', @wp_table_infix, 'term_relationships');
	PREPARE stmt_truncate_wp_table FROM @str_truncate_wp_table;
	EXECUTE stmt_truncate_wp_table;
	DEALLOCATE PREPARE stmt_truncate_wp_table;

	SET @str_truncate_wp_table = CONCAT('TRUNCATE TABLE wp_', @wp_table_infix, 'term_taxonomy');
	PREPARE stmt_truncate_wp_table FROM @str_truncate_wp_table;
	EXECUTE stmt_truncate_wp_table;
	DEALLOCATE PREPARE stmt_truncate_wp_table;

	SET @str_truncate_wp_table = CONCAT('TRUNCATE TABLE wp_', @wp_table_infix, 'terms');
	PREPARE stmt_truncate_wp_table FROM @str_truncate_wp_table;
	EXECUTE stmt_truncate_wp_table;
	DEALLOCATE PREPARE stmt_truncate_wp_table;

	SET @str_copy_categories = CONCAT(
		'INSERT INTO wp_', @wp_table_infix, 'terms (',
			'term_id, ',
			'name, ',
			'slug, ',
			'term_group ',
		') ',
		' SELECT ',
			'category_id, ',
			'category_label, ',
			'category_basename, ',
			'0 '
		' FROM mt_category ',
		' WHERE category_blog_id = ', mt_blog_id, ' ORDER BY category_id ASC');
	PREPARE stmt_copy_categories FROM @str_copy_categories;
	EXECUTE stmt_copy_categories;
	DEALLOCATE PREPARE stmt_copy_categories;

	SET @str_create_term_taxonomy = CONCAT(
		'INSERT INTO wp_', @wp_table_infix, 'term_taxonomy (',
			'term_id, ',
			'taxonomy, ',
			'description, ',
			'parent, ',
			'count',
		') ',
		' SELECT ',
			'category_id, ',
			'\'category\', ',
			'\'\', ',
			'0, '
			'0 '
		' FROM mt_category ',
		' WHERE category_blog_id = ', mt_blog_id, ' ORDER BY category_id ASC');
	PREPARE stmt_create_term_taxonomy FROM @str_create_term_taxonomy;
	EXECUTE stmt_create_term_taxonomy;
	DEALLOCATE PREPARE stmt_create_term_taxonomy;

	SET @str_create_term_relationships = CONCAT(
		'INSERT INTO wp_', @wp_table_infix, 'term_relationships (',
			'object_id, ',
			'term_taxonomy_id, ',
			'term_order ',
		') ',

		' select ',
			' mt_placement.placement_entry_id, ',
			' wp_', @wp_table_infix, 'term_taxonomy.term_taxonomy_id, ',
			' 1 ',
		' from ',
			' mt_placement ',
			' inner join wp_', @wp_table_infix, 'term_taxonomy on mt_placement.placement_category_id = wp_', @wp_table_infix, 'term_taxonomy.term_id ',
		' where  ',
			' mt_placement.placement_blog_id = ', mt_blog_id, ' ',
			' and wp_', @wp_table_infix, 'term_taxonomy.taxonomy = \'category\' ',
		' order by mt_placement.placement_entry_id; ');
	PREPARE stmt_create_term_relationships FROM @str_create_term_relationships;
	EXECUTE stmt_create_term_relationships;
	DEALLOCATE PREPARE stmt_create_term_relationships;

	SET SQL_SAFE_UPDATES=0;

	SET @str_update_counts = CONCAT(
		'INSERT INTO wp_', @wp_table_infix, 'term_relationships (',
		' update wp_', @wp_table_infix, 'term_taxonomy tt ',
			' inner join ( ',
				' select term_taxonomy_id, count(*) as c ',
				' from wp_', @wp_table_infix, 'term_relationships ',
				' group by term_taxonomy_id ',
			' ) c on tt.term_taxonomy_id = c.term_taxonomy_id ',
		' set tt.count = c.c; ');
	PREPARE stmt_update_counts FROM @str_update_counts;
	EXECUTE stmt_update_counts;
	DEALLOCATE PREPARE stmt_update_counts;

END
//


DROP PROCEDURE IF EXISTS copy_mt_entries_to_wp_posts //

CREATE PROCEDURE copy_mt_entries_to_wp_posts(mt_blog_id INT, wp_blog_id INT)
BEGIN
	SET @wp_table_infix = if(wp_blog_id = 1, '', CONCAT(wp_blog_id, '_'));

	SET @str_truncate_wp_table = CONCAT('TRUNCATE TABLE wp_', @wp_table_infix, 'posts'); 
	PREPARE stmt_truncate_wp_table FROM @str_truncate_wp_table;
	EXECUTE stmt_truncate_wp_table;
	DEALLOCATE PREPARE stmt_truncate_wp_table;

	SET @str_copy_entries = CONCAT(
		'INSERT INTO wp_', @wp_table_infix, 'posts (',
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
			'post_content_filtered, ',
			'post_parent, ',
			'guid, ',
			'menu_order, ',
			'post_type ',
		') ',
		' SELECT ',
			'entry_id, ',
			'wp_users.id, ',
			'entry_created_on, ',
			'CONVERT_TZ(entry_created_on,\'+00:00\',\'-06:00\'),',
			'CAST( ',
				'CAST( ',
					'IF (',
						'TRIM(IFNULL(entry_text_more,\'\'))=\'\', ',
						'IFNULL(entry_text,\'\'), ',
						'CONCAT(IFNULL(entry_text,\'\'), \'<!--more-->\', IFNULL(entry_text_more,\'\'))',
					') AS CHAR CHARACTER SET latin1 ',
				') AS BINARY ',
			'), ',
			'entry_title, ',
			'IFNULL(entry_excerpt, \'\'), ',
			'if(entry_status = 2, \'publish\', \'draft\'), ',
			'if(entry_allow_comments = 1, \'open\', \'closed\'), ',
			'if(entry_allow_pings = 1, \'open\', \'closed\'),',
			'replace(entry_basename, \'_\', \'-\'), ',
			'\'\', ',
			'\'\', ',
			'entry_modified_on, ',
			'CONVERT_TZ(entry_modified_on,\'+00:00\',\'-06:00\'), ',
			'\'\', ',
			'0, ',
			'CONCAT(\'http://sunpig.com/mt-entry-\', entry_id, \'.html\'), ',
			'0, ',
			'\'post\' ',
		' FROM mt_entry ',
		' INNER JOIN mt_author ON mt_entry.entry_author_id = mt_author.author_id ',
		' INNER JOIN wp_users ON mt_author.author_email = wp_users.user_email ',
		' WHERE entry_blog_id = ', mt_blog_id, ' ORDER BY entry_id ASC');
	PREPARE stmt_copy_entries FROM @str_copy_entries;
	EXECUTE stmt_copy_entries;
	DEALLOCATE PREPARE stmt_copy_entries;
END
//

delimiter ;
