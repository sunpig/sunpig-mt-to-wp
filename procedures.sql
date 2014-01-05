delimiter //

DROP PROCEDURE IF EXISTS copy_mt_categories_and_entry_tags_to_wp_terms //

CREATE PROCEDURE copy_mt_categories_and_entry_tags_to_wp_terms(mt_blog_id INT, wp_blog_id INT)
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
			'term_id, ',
			'\'category\', ',
			'\'\', ',
			'0, '
			'0 '
		' FROM wp_', @wp_table_infix, 'terms');
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
			' 0 ',
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




	SELECT @max_category_id := `max_category_id` FROM (select max(category_id) as max_category_id from mt_category) mtc;

	SET @str_copy_entry_tags = CONCAT(
		'INSERT INTO wp_', @wp_table_infix, 'terms (',
			'term_id, ',
			'name, ',
			'slug, ',
			'term_group ',
		') ',
		' select distinct ',
			' mtt.tag_id + 1000 + ', @max_category_id, ', ',
			' mtt.tag_name, ',
			' if(mtt.tag_n8d_id = 0, mtt.tag_name, mtt2.tag_name), ',
			' 0 ',
		' from  ',
			' mt_objecttag mto ',
			' inner join mt_tag mtt on mto.objecttag_tag_id = mtt.tag_id ',
			' left outer join mt_tag mtt2 on mtt.tag_n8d_id = mtt2.tag_id ',
		' where ',
			' mto.objecttag_blog_id = ', mt_blog_id,
			' and mto.objecttag_object_datasource = \'entry\'',
			' and if(mtt.tag_n8d_id = 0, mtt.tag_name, mtt2.tag_name) not in (select distinct slug from wp_', @wp_table_infix, 'terms)',
		' order by mtt.tag_id ');
	PREPARE stmt_copy_entry_tags FROM @str_copy_entry_tags;
	EXECUTE stmt_copy_entry_tags;
	DEALLOCATE PREPARE stmt_copy_entry_tags;

	SET @str_create_entry_tags_term_taxonomy = CONCAT(
		'INSERT INTO wp_', @wp_table_infix, 'term_taxonomy (',
			'term_id, ',
			'taxonomy, ',
			'description, ',
			'parent, ',
			'count',
		') ',
		' SELECT ',
			'term_id, ',
			'\'post_tag\', ',
			'\'\', ',
			'0, '
			'0 '
		' FROM wp_', @wp_table_infix, 'terms',
		' WHERE term_id > ', @max_category_id);
	PREPARE stmt_create_entry_tags_term_taxonomy FROM @str_create_entry_tags_term_taxonomy;
	EXECUTE stmt_create_entry_tags_term_taxonomy;
	DEALLOCATE PREPARE stmt_create_entry_tags_term_taxonomy;

	SET @str_create_entry_tags_term_relationships = CONCAT(
		'INSERT INTO wp_', @wp_table_infix, 'term_relationships (',
			'object_id, ',
			'term_taxonomy_id, ',
			'term_order ',
		') ',

		' select ',
			' mt_objecttag.objecttag_object_id, ',
			' wp_', @wp_table_infix, 'term_taxonomy.term_taxonomy_id, ',
			' 1 ',
		' from ',
			' mt_objecttag ',
			' inner join wp_', @wp_table_infix, 'term_taxonomy on mt_objecttag.objecttag_tag_id = wp_', @wp_table_infix, 'term_taxonomy.term_id - 1000 - ', @max_category_id, 
		' where  ',
			' mt_objecttag.objecttag_blog_id = ', mt_blog_id, ' and mt_objecttag.objecttag_object_datasource = \'entry\' ',
			' and wp_', @wp_table_infix, 'term_taxonomy.taxonomy = \'post_tag\' ');
	PREPARE stmt_create_entry_tags_term_relationships FROM @str_create_entry_tags_term_relationships;
	EXECUTE stmt_create_entry_tags_term_relationships;
	DEALLOCATE PREPARE stmt_create_entry_tags_term_relationships;


	SET SQL_SAFE_UPDATES=0;

	SET @str_update_counts = CONCAT(
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
			'CONVERT_TZ(entry_created_on,\'+00:00\',\'+00:00\'),',
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
			'CONVERT_TZ(entry_modified_on,\'+00:00\',\'+00:00\'), ',
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


DROP PROCEDURE IF EXISTS copy_mt_comments_to_wp_comments //

CREATE PROCEDURE copy_mt_comments_to_wp_comments(mt_blog_id INT, wp_blog_id INT)
BEGIN
	SET @wp_table_infix = if(wp_blog_id = 1, '', CONCAT(wp_blog_id, '_'));

	SET @str_truncate_wp_table = CONCAT('TRUNCATE TABLE wp_', @wp_table_infix, 'comments'); 
	PREPARE stmt_truncate_wp_table FROM @str_truncate_wp_table;
	EXECUTE stmt_truncate_wp_table;
	DEALLOCATE PREPARE stmt_truncate_wp_table;

	SET @str_copy_comments = CONCAT(
		'INSERT INTO wp_', @wp_table_infix, 'comments (',
			' comment_id, ',
			' comment_post_id, ',
			' comment_author, ',
			' comment_author_email, ',
			' comment_author_url, ',
			' comment_author_IP, ',
			' comment_date, ',
			' comment_date_gmt, ',
			' comment_content, ',
			' comment_karma,  ',
			' comment_approved, ',
			' comment_parent, ',
			' user_id ',
		' ) ',
		' SELECT ',
			' comment_id, ',
			' comment_entry_id, ',
			' comment_author, ',
			' comment_email, ',
			' comment_url, ',
			' comment_ip, ',
			' comment_created_on, ',
			' CONVERT_TZ(comment_created_on,\'+00:00\',\'+00:00\'), ',
			' convert(cast(convert(comment_text using latin1) as binary) using utf8), ',
			' 0, ',
			' comment_visible, ',
			' 0, ',
			' 0 ',
		' FROM ',
			' mt_comment ',
		' WHERE ',
			' comment_blog_id = ', mt_blog_id, 
			' and comment_junk_status <> -1 ',
			' and comment_visible = 1 ',
			' ORDER BY comment_id ASC');
	PREPARE stmt_copy_comments FROM @str_copy_comments;
	EXECUTE stmt_copy_comments;
	DEALLOCATE PREPARE stmt_copy_comments;

	SET @str_update_comment_counts = CONCAT(
		' update wp_', @wp_table_infix, 'posts p ',
		' inner join ( ',
			' select comment_post_id, count(*) as comment_count from wp_', @wp_table_infix, 'comments ',
			' where comment_approved = 1 ',
			' group by comment_post_id ',
		' ) cc on p.id = cc.comment_post_id ',
		' set p.comment_count = cc.comment_count;');
	PREPARE stmt_update_comment_counts FROM @str_update_comment_counts;
	EXECUTE stmt_update_comment_counts;
	DEALLOCATE PREPARE stmt_update_comment_counts;

END
//


delimiter ;
