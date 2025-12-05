note
	description: "Tests for SIMPLE_CSV"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	SIMPLE_CSV_TEST_SET

inherit
	TEST_SET_BASE

feature -- Test: Basic Parsing

	test_parse_simple
			-- Test parsing simple CSV.
		note
			testing: "covers/{SIMPLE_CSV}.parse"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("a,b,c%N1,2,3")
			assert_integers_equal ("2 rows", 2, csv.row_count)
			assert_integers_equal ("3 columns", 3, csv.column_count)
		end

	test_parse_single_row
			-- Test parsing single row.
		note
			testing: "covers/{SIMPLE_CSV}.parse"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("hello,world")
			assert_integers_equal ("1 row", 1, csv.row_count)
			assert_strings_equal ("field 1", "hello", csv.field (1, 1))
			assert_strings_equal ("field 2", "world", csv.field (1, 2))
		end

	test_parse_empty
			-- Test parsing empty string.
		note
			testing: "covers/{SIMPLE_CSV}.parse"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("")
			assert_integers_equal ("0 rows", 0, csv.row_count)
		end

	test_parse_with_empty_fields
			-- Test parsing with empty fields.
		note
			testing: "covers/{SIMPLE_CSV}.parse"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("a,,c%N,2,")
			assert_integers_equal ("2 rows", 2, csv.row_count)
			assert_strings_equal ("empty field", "", csv.field (1, 2))
		end

feature -- Test: Quoted Fields

	test_parse_quoted_field
			-- Test parsing quoted fields.
		note
			testing: "covers/{SIMPLE_CSV}.parse"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("%"hello world%",test")
			assert_strings_equal ("quoted", "hello world", csv.field (1, 1))
		end

	test_parse_quoted_with_comma
			-- Test quoted field containing comma.
		note
			testing: "covers/{SIMPLE_CSV}.parse"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("%"a,b%",c")
			assert_strings_equal ("comma in quotes", "a,b", csv.field (1, 1))
			assert_strings_equal ("after quoted", "c", csv.field (1, 2))
		end

	test_parse_escaped_quote
			-- Test escaped quote inside quoted field.
		note
			testing: "covers/{SIMPLE_CSV}.parse"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("%"say %"%"hello%"%"%",test")
			assert_strings_equal ("escaped quotes", "say %"hello%"", csv.field (1, 1))
		end

	test_parse_quoted_with_newline
			-- Test quoted field containing newline.
		note
			testing: "covers/{SIMPLE_CSV}.parse"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("%"line1%Nline2%",next")
			assert_integers_equal ("1 row", 1, csv.row_count)
			assert ("has newline", csv.field (1, 1).has ('%N'))
		end

feature -- Test: Headers

	test_with_header
			-- Test parsing with header row.
		note
			testing: "covers/{SIMPLE_CSV}.make_with_header", "covers/{SIMPLE_CSV}.field_by_name"
		local
			csv: SIMPLE_CSV
		do
			create csv.make_with_header
			csv.parse ("name,age,city%NJohn,30,NYC%NJane,25,LA")
			assert_integers_equal ("2 data rows", 2, csv.row_count)
			assert_strings_equal ("by name", "30", csv.field_by_name (1, "age"))
		end

	test_headers_list
			-- Test getting headers list.
		note
			testing: "covers/{SIMPLE_CSV}.headers"
		local
			csv: SIMPLE_CSV
			h: ARRAYED_LIST [STRING]
		do
			create csv.make_with_header
			csv.parse ("first,second,third%N1,2,3")
			h := csv.headers
			assert_integers_equal ("3 headers", 3, h.count)
			assert_strings_equal ("header 1", "first", h [1])
		end

	test_has_column
			-- Test column existence check.
		note
			testing: "covers/{SIMPLE_CSV}.has_column"
		local
			csv: SIMPLE_CSV
		do
			create csv.make_with_header
			csv.parse ("name,age%NJohn,30")
			assert ("has name", csv.has_column ("name"))
			assert ("has age", csv.has_column ("age"))
			assert ("no email", not csv.has_column ("email"))
		end

	test_column_index
			-- Test getting column index by name.
		note
			testing: "covers/{SIMPLE_CSV}.column_index"
		local
			csv: SIMPLE_CSV
		do
			create csv.make_with_header
			csv.parse ("a,b,c%N1,2,3")
			assert_integers_equal ("a is 1", 1, csv.column_index ("a"))
			assert_integers_equal ("b is 2", 2, csv.column_index ("b"))
			assert_integers_equal ("c is 3", 3, csv.column_index ("c"))
		end

	test_header_case_insensitive
			-- Test that header lookup is case-insensitive.
		note
			testing: "covers/{SIMPLE_CSV}.has_column"
		local
			csv: SIMPLE_CSV
		do
			create csv.make_with_header
			csv.parse ("Name,AGE%NJohn,30")
			assert ("lowercase", csv.has_column ("name"))
			assert ("uppercase", csv.has_column ("NAME"))
			assert ("mixed", csv.has_column ("Age"))
		end

feature -- Test: Row and Column Access

	test_get_row
			-- Test getting entire row.
		note
			testing: "covers/{SIMPLE_CSV}.row"
		local
			csv: SIMPLE_CSV
			r: ARRAYED_LIST [STRING]
		do
			create csv.make
			csv.parse ("a,b,c%N1,2,3%Nx,y,z")
			r := csv.row (2)
			assert_integers_equal ("3 fields", 3, r.count)
			assert_strings_equal ("field 1", "1", r [1])
			assert_strings_equal ("field 2", "2", r [2])
		end

	test_get_column
			-- Test getting entire column.
		note
			testing: "covers/{SIMPLE_CSV}.column"
		local
			csv: SIMPLE_CSV
			c: ARRAYED_LIST [STRING]
		do
			create csv.make
			csv.parse ("a,b%N1,2%N3,4")
			c := csv.column (1)
			assert_integers_equal ("3 values", 3, c.count)
			assert_strings_equal ("value 1", "a", c [1])
			assert_strings_equal ("value 2", "1", c [2])
			assert_strings_equal ("value 3", "3", c [3])
		end

	test_get_column_by_name
			-- Test getting column by name.
		note
			testing: "covers/{SIMPLE_CSV}.column_by_name"
		local
			csv: SIMPLE_CSV
			c: ARRAYED_LIST [STRING]
		do
			create csv.make_with_header
			csv.parse ("name,score%NAlice,100%NBob,95")
			c := csv.column_by_name ("score")
			assert_integers_equal ("2 values", 2, c.count)
			assert_strings_equal ("score 1", "100", c [1])
			assert_strings_equal ("score 2", "95", c [2])
		end

feature -- Test: Custom Delimiter

	test_tab_delimiter
			-- Test parsing with tab delimiter.
		note
			testing: "covers/{SIMPLE_CSV}.make_with_delimiter"
		local
			csv: SIMPLE_CSV
		do
			create csv.make_with_delimiter ('%T')
			csv.parse ("a%Tb%Tc%N1%T2%T3")
			assert_integers_equal ("2 rows", 2, csv.row_count)
			assert_strings_equal ("field", "b", csv.field (1, 2))
		end

	test_semicolon_delimiter
			-- Test parsing with semicolon delimiter.
		note
			testing: "covers/{SIMPLE_CSV}.make_with_delimiter"
		local
			csv: SIMPLE_CSV
		do
			create csv.make_with_delimiter (';')
			csv.parse ("a;b;c")
			assert_strings_equal ("field 2", "b", csv.field (1, 2))
		end

feature -- Test: Generation

	test_to_csv_simple
			-- Test generating CSV from data.
		note
			testing: "covers/{SIMPLE_CSV}.to_csv"
		local
			csv: SIMPLE_CSV
			output: STRING
		do
			create csv.make
			csv.add_data_row (<<"a", "b", "c">>)
			csv.add_data_row (<<"1", "2", "3">>)
			output := csv.to_csv
			assert ("has data", output.has_substring ("a,b,c"))
			assert ("has row 2", output.has_substring ("1,2,3"))
		end

	test_to_csv_with_quotes
			-- Test generating CSV with fields needing quotes.
		note
			testing: "covers/{SIMPLE_CSV}.to_csv"
		local
			csv: SIMPLE_CSV
			output: STRING
		do
			create csv.make
			csv.add_data_row (<<"hello,world", "test">>)
			output := csv.to_csv
			assert ("quoted", output.has_substring ("%"hello,world%""))
		end

	test_roundtrip
			-- Test parsing and regenerating produces same data.
		note
			testing: "covers/{SIMPLE_CSV}.parse", "covers/{SIMPLE_CSV}.to_csv"
		local
			csv1, csv2: SIMPLE_CSV
			original, generated: STRING
		do
			original := "name,value%NAlice,100%NBob,200"
			create csv1.make
			csv1.parse (original)
			generated := csv1.to_csv

			create csv2.make
			csv2.parse (generated)

			assert_integers_equal ("same rows", csv1.row_count, csv2.row_count)
			assert_strings_equal ("same field", csv1.field (1, 1), csv2.field (1, 1))
		end

feature -- Test: Set Headers

	test_set_headers
			-- Test setting headers programmatically.
		note
			testing: "covers/{SIMPLE_CSV}.set_headers"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.set_headers (<<"col1", "col2", "col3">>)
			csv.add_data_row (<<"a", "b", "c">>)
			assert ("has header", csv.has_header)
			assert ("has col2", csv.has_column ("col2"))
			assert_strings_equal ("by name", "b", csv.field_by_name (1, "col2"))
		end

	test_set_headers_after_parse_without_header
			-- Test setting headers after parsing data without header.
			-- Regression test: headers should be inserted, not replace first row.
		note
			testing: "covers/{SIMPLE_CSV}.set_headers"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("a,b%N1,2%N3,4")
			assert_integers_equal ("3 rows before", 3, csv.row_count)
			csv.set_headers (<<"col1", "col2">>)
			assert_integers_equal ("3 rows after", 3, csv.row_count)
			assert_strings_equal ("first data row preserved", "a", csv.field (1, 1))
			assert_strings_equal ("by name works", "1", csv.field_by_name (2, "col1"))
		end

	test_set_headers_replace_existing
			-- Test replacing existing headers.
		note
			testing: "covers/{SIMPLE_CSV}.set_headers"
		local
			csv: SIMPLE_CSV
		do
			create csv.make_with_header
			csv.parse ("old1,old2%Na,b")
			assert_integers_equal ("1 data row", 1, csv.row_count)
			csv.set_headers (<<"new1", "new2">>)
			assert_integers_equal ("still 1 data row", 1, csv.row_count)
			assert ("has new1", csv.has_column ("new1"))
			assert ("no old1", not csv.has_column ("old1"))
		end

feature -- Test: set_delimiter

	test_set_delimiter
			-- Test changing delimiter after creation.
		note
			testing: "covers/{SIMPLE_CSV}.set_delimiter"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.set_delimiter (';')
			csv.parse ("a;b;c")
			assert_integers_equal ("3 columns", 3, csv.column_count)
			assert_strings_equal ("field 2", "b", csv.field (1, 2))
		end

feature -- Test: Edge Cases

	test_crlf_line_endings
			-- Test handling Windows line endings.
		note
			testing: "covers/{SIMPLE_CSV}.parse"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("a,b%R%N1,2%R%N")
			assert_integers_equal ("2 rows", 2, csv.row_count)
		end

	test_is_empty
			-- Test is_empty check.
		note
			testing: "covers/{SIMPLE_CSV}.is_empty"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			assert ("empty initially", csv.is_empty)
			csv.parse ("a,b")
			assert ("not empty after parse", not csv.is_empty)
		end

	test_clear
			-- Test clearing data.
		note
			testing: "covers/{SIMPLE_CSV}.clear"
		local
			csv: SIMPLE_CSV
		do
			create csv.make
			csv.parse ("a,b%N1,2")
			csv.clear
			assert ("empty after clear", csv.is_empty)
		end

end
