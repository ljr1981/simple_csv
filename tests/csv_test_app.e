note
	description: "Test application for simple_csv"
	author: "Larry Rix"

class
	CSV_TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		local
			tests: SIMPLE_CSV_TEST_SET
		do
			create tests
			print ("simple_csv test runner%N")
			print ("========================%N%N")

			passed := 0
			failed := 0

			-- Basic Parsing
			run_test (agent tests.test_parse_simple, "test_parse_simple")
			run_test (agent tests.test_parse_single_row, "test_parse_single_row")
			run_test (agent tests.test_parse_empty, "test_parse_empty")
			run_test (agent tests.test_parse_with_empty_fields, "test_parse_with_empty_fields")

			-- Quoted Fields
			run_test (agent tests.test_parse_quoted_field, "test_parse_quoted_field")
			run_test (agent tests.test_parse_quoted_with_comma, "test_parse_quoted_with_comma")
			run_test (agent tests.test_parse_escaped_quote, "test_parse_escaped_quote")
			run_test (agent tests.test_parse_quoted_with_newline, "test_parse_quoted_with_newline")

			-- Headers
			run_test (agent tests.test_with_header, "test_with_header")
			run_test (agent tests.test_headers_list, "test_headers_list")
			run_test (agent tests.test_has_column, "test_has_column")
			run_test (agent tests.test_column_index, "test_column_index")
			run_test (agent tests.test_header_case_insensitive, "test_header_case_insensitive")

			-- Row and Column Access
			run_test (agent tests.test_get_row, "test_get_row")
			run_test (agent tests.test_get_column, "test_get_column")
			run_test (agent tests.test_get_column_by_name, "test_get_column_by_name")

			-- Custom Delimiter
			run_test (agent tests.test_tab_delimiter, "test_tab_delimiter")
			run_test (agent tests.test_semicolon_delimiter, "test_semicolon_delimiter")

			-- Generation
			run_test (agent tests.test_to_csv_simple, "test_to_csv_simple")
			run_test (agent tests.test_to_csv_with_quotes, "test_to_csv_with_quotes")
			run_test (agent tests.test_roundtrip, "test_roundtrip")

			-- Set Headers
			run_test (agent tests.test_set_headers, "test_set_headers")
			run_test (agent tests.test_set_headers_after_parse_without_header, "test_set_headers_after_parse_without_header")
			run_test (agent tests.test_set_headers_replace_existing, "test_set_headers_replace_existing")

			-- set_delimiter
			run_test (agent tests.test_set_delimiter, "test_set_delimiter")

			-- Edge Cases
			run_test (agent tests.test_crlf_line_endings, "test_crlf_line_endings")
			run_test (agent tests.test_is_empty, "test_is_empty")
			run_test (agent tests.test_clear, "test_clear")

			-- BOM Support
			run_test (agent tests.test_has_bom_true, "test_has_bom_true")
			run_test (agent tests.test_has_bom_false, "test_has_bom_false")
			run_test (agent tests.test_strip_bom, "test_strip_bom")
			run_test (agent tests.test_parse_with_bom, "test_parse_with_bom")
			run_test (agent tests.test_to_csv_with_bom, "test_to_csv_with_bom")

			-- Lenient Mode
			run_test (agent tests.test_lenient_mode_default_off, "test_lenient_mode_default_off")
			run_test (agent tests.test_set_lenient_mode, "test_set_lenient_mode")
			run_test (agent tests.test_lenient_mode_logs_errors, "test_lenient_mode_logs_errors")

			-- Row Iteration
			run_test (agent tests.test_row_iteration, "test_row_iteration")
			run_test (agent tests.test_row_iteration_with_header, "test_row_iteration_with_header")
			run_test (agent tests.test_current_field, "test_current_field")
			run_test (agent tests.test_current_field_by_name, "test_current_field_by_name")

			-- Null Handling
			run_test (agent tests.test_is_null_empty_string, "test_is_null_empty_string")
			run_test (agent tests.test_set_null_representation, "test_set_null_representation")
			run_test (agent tests.test_is_null_by_name, "test_is_null_by_name")

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
