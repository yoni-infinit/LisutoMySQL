DROP PROCEDURE IF EXISTS content.get_product_test_values;
CREATE PROCEDURE content.`get_product_test_values`(IN p_target_att_id int,IN p_attribute_id_list varchar(2000),INOUT p_pagination tinyint,IN p_language_id tinyint,IN p_last_product_id int)
BEGIN

   IF p_pagination=0 THEN
    SET @rand_product_id = '';
    SET @s = concat('select product_id into @rand_product_id from product_data pd ',
                     'LEFT JOIN catalog_value cv ON pd.value_id = cv.value_id AND cv.language_id = ',p_language_id,
                    ' WHERE pd.attribute_id IN (',p_attribute_id_list,') order by rand() limit 1');
                    
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

  SET @s = CONCAT(
   'SELECT attribute_name,attribute_value FROM (SELECT pd.product_id,ca.attribute_name,',
      'CASE WHEN pd.value IS NOT NULL THEN pd.value WHEN cv.language_id IS NOT NULL THEN cv.value END AS attribute_value ',
      'FROM product_data pd ',
      'LEFT JOIN catalog_value cv ON pd.value_id = cv.value_id AND cv.language_id = ',p_language_id,
      ' JOIN catalog_attribute ca ON ca.attribute_id = pd.attribute_id '
       'WHERE not exists (select 1 from product_data pd2 where pd.product_id = pd2.product_id and pd.attribute_id=pd2.attribute_id '
       'and pd.product_data_id!=pd2.product_data_id) '
       'and exists (select 1 from connection c1 '
       'JOIN connection c2 on c1.parent_id = c2.parent_id and c1.parent_type = c2.parent_type and c2.child_type=2 and c2.child_id=',p_target_att_id,
       ' where c1.child_id = pd.attribute_id and c1.child_type = 2) '
       'and ca.attribute_id in(',p_attribute_id_list,') and pd.product_id=',
       CASE WHEN p_pagination=1 THEN
        concat('(select ifnull(min(pd3.product_id),',
        '(select min(pd4.product_id) from product_data pd4 where pd4.attribute_id in(',p_attribute_id_list,'))',
        ') product_id FROM product_data pd3 ',
        'LEFT JOIN catalog_value cv3 ON pd3.value_id = cv3.value_id and cv3.language_id = ',p_language_id,
        ' WHERE pd3.attribute_id in(',p_attribute_id_list,') and pd3.product_id > ',p_last_product_id,')')
        WHEN p_pagination=-1 THEN
        concat('(select ifnull(max(pd3.product_id),',
        '(select max(pd4.product_id) from product_data pd4 where pd4.attribute_id in(',p_attribute_id_list,'))',
        ') product_id FROM product_data pd3 ',
        'LEFT JOIN catalog_value cv3 ON pd3.value_id = cv3.value_id and cv3.language_id = ',p_language_id,
        ' WHERE pd3.attribute_id in(',p_attribute_id_list,') and pd3.product_id < ',p_last_product_id,')')        
        WHEN p_pagination=0 THEN
        @rand_product_id
        ELSE
         'pd.product_id'
        END,
       ') AS r ORDER BY attribute_name');

    SELECT @s;
     PREPARE stmt FROM @s;
     EXECUTE stmt;
     DEALLOCATE PREPARE stmt;

END;
