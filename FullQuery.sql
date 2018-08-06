- Function: get_question_option_json(integer, integer)

-- DROP FUNCTION get_question_option_json(integer, integer);

CREATE OR REPLACE FUNCTION get_question_option_json( sp_client_id integer, sp_questinnaire_id integer) RETURNS json AS $BODY$

DECLARE header_questions JSON; header_question_options JSON; question_options JSON; question_master JSON; option_count_json_data JSON; country_data JSON; state_data JSON; BEGIN --json object to get header_questions SELECT json_agg(header_questions.*) INTO header_questions FROM ( SELECT CAST(a.header_question_id AS CHARACTER VARYING), header_question_text1, CAST(question_type_id AS CHARACTER VARYING), CAST(sequence_id AS CHARACTER VARYING), CAST(no_of_options AS CHARACTER VARYING) FROM header_question_master_ut a, header_question_mapping_ut b WHERE a.header_question_id = b.header_question_id AND client_id = sp_client_id AND questionnaire_id = sp_questinnaire_id AND a.status = 1 AND b.status = 1 ORDER BY sequence_id ) AS header_questions;

--json object to get header_question_options
SELECT json_agg(header_question_options.*) INTO header_question_options FROM (
	SELECT
		CAST(a.header_question_id AS CHARACTER VARYING), CAST(header_option_id AS CHARACTER VARYING), header_option_text1
	FROM
		header_question_master_ut a, header_question_options_ut b, header_question_mapping_ut c
	WHERE
		a.header_question_id = b.header_question_id AND a.header_question_id = c.header_question_id AND
		client_id = sp_client_id AND questionnaire_id = sp_questinnaire_id AND a.status = 1 AND b.status = 1 AND c.status = 1
	ORDER BY
		a.header_question_id, header_option_id
) AS header_question_options;


--json object to get questions
SELECT json_agg(question_master.*) INTO question_master FROM (
	SELECT 
		CAST(a.question_id AS CHARACTER VARYING), question_text1, CAST(a.question_type_id AS CHARACTER VARYING),
		CAST(sequence_id AS CHARACTER VARYING), CAST(no_of_options AS CHARACTER VARYING)
	FROM 
		question_master_ut a, questionnaire_master_ut b, questionnaire_details_ut c, question_type_master_ut d
	where 
		b.questionnaire_id = c.questionnaire_id AND a.question_id = c.question_id AND 
		a.question_type_id = d.question_type_id AND
		a.status = 1 AND b.status = 1 AND c.status = 1 AND b.questionnaire_id = sp_questinnaire_id
	ORDER BY 
		question_id
) AS question_master;

--json object to get question_options
SELECT json_agg(question_options.*) INTO question_options FROM (
	SELECT 
		CAST(a.question_id AS CHARACTER VARYING), CAST(question_option_id AS CHARACTER VARYING), option_text1
	FROM 
		question_master_ut a, questionnaire_details_ut b, question_option_ut c, question_type_master_ut d
	WHERE
		a.question_id = b.question_id AND a.question_id = c.question_id AND a.question_type_id = d.question_type_id AND
		a.status = 1 AND b.status = 1 AND c.status = 1 AND questionnaire_id = sp_questinnaire_id
	ORDER BY
		question_option_id
) AS question_options;

--call procedure to get count of options
SELECT INTO option_count_json_data
option_count(sp_questinnaire_id);

-- json object to get country data
SELECT json_agg(country_data.*) INTO country_data FROM (
	SELECT 
		CAST(country_id AS CHARACTER VARYING), country_name
	FROM 
		country_master_ut 
	where 
		status = 1
	ORDER BY 
		country_name
) AS country_data;

--json object to get state data
SELECT json_agg(state_data.*) INTO state_data FROM (
	SELECT 
		CAST(state_id AS CHARACTER VARYING), state_name,
		CAST(b.country_id AS CHARACTER VARYING)
	FROM 
		country_master_ut a, state_master_ut b
	WHERE
		a.country_id = b.country_id AND
		a.status = 1 AND b.status = 1
	ORDER BY 
		state_name
) AS state_data;

RETURN (SELECT json_build_object( 'header_questions', header_questions, 'header_question_options', header_question_options, 'questions', question_master, 'question_options', question_options, 'option_count_json_data', option_count_json_data, 'country_data', country_data, 'state_data', state_data ) ); 
END; 
$BODY$ LANGUAGE plpgsql VOLATILE COST 100; 
ALTER FUNCTION get_question_option_json(integer, integer) OWNER TO postgres;
