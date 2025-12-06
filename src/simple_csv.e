note
	description: "[
		Simple CSV - Lightweight CSV parsing and generation for Eiffel.

		Supports:
		- RFC 4180 compliant CSV parsing
		- Quoted fields with embedded commas, quotes, newlines
		- Custom delimiters (comma, tab, semicolon, etc.)
		- Header row handling
		- Row and column access
		- CSV generation from data
		- UTF-8 BOM support for Excel compatibility
		- Lenient parsing mode with error collection
		- Row-by-row iteration for large files
		- Null value handling

		Usage:
			create csv.make
			csv.parse ("name,age%Njohn,30")
			name := csv.field (1, 1)  -- "name"

			-- Or with headers
			create csv.make_with_header
			csv.parse (data)
			age := csv.field_by_name (2, "age")

			-- For Excel compatibility
			excel_output := csv.to_csv_with_bom
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=Documentation", "src=../docs/index.html", "protocol=URI", "tag=documentation"
	EIS: "name=API Reference", "src=../docs/api/simple_csv.html", "protocol=URI", "tag=api"
	EIS: "name=RFC 4180", "src=https://datatracker.ietf.org/doc/html/rfc4180", "protocol=URI", "tag=specification"

class
	SIMPLE_CSV

create
	make,
	make_with_header,
	make_with_delimiter

feature {NONE} -- Initialization

	make
			-- Initialize CSV parser with default comma delimiter.
		do
			delimiter := ','
			quote_char := '"'
			has_header := False
			lenient_mode := False
			create rows.make (10)
			create header_map.make (10)
			create parse_errors.make (0)
			null_representation := Void
			iteration_index := 0
		ensure
			comma_delimiter: delimiter = ','
			default_quote: quote_char = '"'
			no_header: not has_header
			rows_empty: rows.is_empty
			header_map_empty: header_map.is_empty
			not_lenient: not lenient_mode
		end

	make_with_header
			-- Initialize CSV parser expecting first row as header.
		do
			make
			has_header := True
		ensure
			comma_delimiter: delimiter = ','
			default_quote: quote_char = '"'
			has_header_set: has_header
			rows_empty: rows.is_empty
			header_map_empty: header_map.is_empty
		end

	make_with_delimiter (a_delimiter: CHARACTER)
			-- Initialize CSV parser with custom `a_delimiter'.
		require
			valid_delimiter: a_delimiter /= '%N' and a_delimiter /= '%R'
		do
			make
			delimiter := a_delimiter
		ensure
			delimiter_set: delimiter = a_delimiter
			default_quote: quote_char = '"'
			no_header: not has_header
			rows_empty: rows.is_empty
			header_map_empty: header_map.is_empty
		end

feature -- Parsing

	parse (a_input: STRING)
			-- Parse CSV data from `a_input'.
			-- Automatically handles UTF-8 BOM if present.
		require
			input_not_void: a_input /= Void
		local
			l_row: ARRAYED_LIST [STRING]
			l_field: STRING
			i: INTEGER
			c: CHARACTER
			in_quotes: BOOLEAN
			l_input: STRING
			l_row_number: INTEGER
		do
			rows.wipe_out
			header_map.wipe_out
			parse_errors.wipe_out
			l_row_number := 1

			-- Strip BOM if present
			l_input := strip_bom (a_input)

			-- Normalize line endings
			l_input := l_input.twin
			l_input.replace_substring_all ("%R%N", "%N")
			l_input.replace_substring_all ("%R", "%N")

			create l_row.make (10)
			create l_field.make (50)
			in_quotes := False

			from
				i := 1
			invariant
				valid_index: i >= 1 and i <= l_input.count + 1
			until
				i > l_input.count
			loop
				c := l_input [i]

				if in_quotes then
					if c = quote_char then
						-- Check for escaped quote
						if i < l_input.count and then l_input [i + 1] = quote_char then
							l_field.append_character (quote_char)
							i := i + 1
						else
							in_quotes := False
						end
					else
						l_field.append_character (c)
					end
				else
					if c = quote_char then
						in_quotes := True
					elseif c = delimiter then
						l_row.extend (l_field.twin)
						l_field.wipe_out
					elseif c = '%N' then
						l_row.extend (l_field.twin)
						l_field.wipe_out
						if not l_row.is_empty then
							if lenient_mode then
								add_row_lenient (l_row, l_row_number)
							else
								add_row (l_row)
							end
							create l_row.make (10)
						end
						l_row_number := l_row_number + 1
					else
						l_field.append_character (c)
					end
				end

				i := i + 1
			variant
				l_input.count - i + 1
			end

			-- Handle last field/row
			if not l_field.is_empty or not l_row.is_empty then
				l_row.extend (l_field.twin)
				if lenient_mode then
					add_row_lenient (l_row, l_row_number)
				else
					add_row (l_row)
				end
			end

			-- Build header map if needed
			if has_header and row_count > 0 then
				build_header_map
			end
		ensure
			header_mode_unchanged: has_header = old has_header
			header_map_built: (has_header and rows.count > 0) implies header_map.count = rows.first.count
		end

	parse_file (a_path: STRING)
			-- Parse CSV data from file at `a_path'.
		require
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING
		do
			create l_file.make_with_name (a_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				create l_content.make (l_file.count)
				l_file.read_stream (l_file.count)
				l_content.append (l_file.last_string)
				l_file.close
				parse (l_content)
			end
		ensure
			header_mode_unchanged: has_header = old has_header
		end

feature -- Access

	row_count: INTEGER
			-- Number of data rows (excluding header if present).
		do
			Result := rows.count
			if has_header and Result > 0 then
				Result := Result - 1
			end
		ensure
			non_negative: Result >= 0
		end

	column_count: INTEGER
			-- Number of columns (from first row).
		do
			if rows.count > 0 then
				Result := rows.first.count
			end
		ensure
			non_negative: Result >= 0
		end

	field (a_row, a_column: INTEGER): STRING
			-- Get field at `a_row', `a_column' (1-based).
			-- Row 1 is first data row (after header if present).
		require
			valid_row: a_row >= 1 and a_row <= row_count
			valid_column: a_column >= 1 and a_column <= column_count
		local
			l_actual_row: INTEGER
		do
			l_actual_row := a_row
			if has_header then
				l_actual_row := l_actual_row + 1
			end
			Result := rows [l_actual_row] [a_column]
		ensure
			result_not_void: Result /= Void
		end

	field_by_name (a_row: INTEGER; a_column_name: STRING): STRING
			-- Get field at `a_row' by column name.
		require
			has_header: has_header
			valid_row: a_row >= 1 and a_row <= row_count
			valid_column_name: has_column (a_column_name)
		local
			l_col: INTEGER
		do
			l_col := column_index (a_column_name)
			Result := field (a_row, l_col)
		ensure
			result_not_void: Result /= Void
		end

	row (a_row: INTEGER): ARRAYED_LIST [STRING]
			-- Get all fields in `a_row' (1-based data row).
		require
			valid_row: a_row >= 1 and a_row <= row_count
		local
			l_actual_row: INTEGER
		do
			l_actual_row := a_row
			if has_header then
				l_actual_row := l_actual_row + 1
			end
			Result := rows [l_actual_row]
		ensure
			result_not_void: Result /= Void
		end

	column (a_column: INTEGER): ARRAYED_LIST [STRING]
			-- Get all values in `a_column' (1-based).
		require
			valid_column: a_column >= 1 and a_column <= column_count
		local
			i, l_start: INTEGER
		do
			create Result.make (row_count)
			l_start := 1
			if has_header then
				l_start := 2
			end
			from
				i := l_start
			invariant
				valid_index: i >= l_start and i <= rows.count + 1
				building_result: Result.count = i - l_start
			until
				i > rows.count
			loop
				if a_column <= rows [i].count then
					Result.extend (rows [i] [a_column])
				else
					Result.extend ("")
				end
				i := i + 1
			variant
				rows.count - i + 1
			end
		ensure
			result_not_void: Result /= Void
			correct_count: Result.count = row_count
		end

	column_by_name (a_column_name: STRING): ARRAYED_LIST [STRING]
			-- Get all values in column by name.
		require
			has_header: has_header
			valid_column_name: has_column (a_column_name)
		do
			Result := column (column_index (a_column_name))
		ensure
			result_not_void: Result /= Void
		end

	headers: ARRAYED_LIST [STRING]
			-- Get header row names.
		require
			has_header: has_header
		do
			if rows.count > 0 then
				Result := rows.first
			else
				create Result.make (0)
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Null Value Handling

	set_null_representation (a_null: detachable STRING)
			-- Set the string that represents null values.
			-- Pass Void to disable null handling.
		do
			null_representation := a_null
		ensure
			null_set: null_representation = a_null
		end

	null_representation: detachable STRING
			-- String that represents null values (e.g., "", "NULL", "NA").

	is_null (a_row, a_column: INTEGER): BOOLEAN
			-- Is the field at `a_row', `a_column' a null value?
		require
			valid_row: a_row >= 1 and a_row <= row_count
			valid_column: a_column >= 1 and a_column <= column_count
		local
			l_value: STRING
		do
			l_value := field (a_row, a_column)
			if attached null_representation as l_null then
				Result := l_value.same_string (l_null)
			else
				-- Without explicit null representation, empty string is null
				Result := l_value.is_empty
			end
		end

	is_null_by_name (a_row: INTEGER; a_column_name: STRING): BOOLEAN
			-- Is the field at `a_row', column named `a_column_name' a null value?
		require
			has_header: has_header
			valid_row: a_row >= 1 and a_row <= row_count
			valid_column_name: has_column (a_column_name)
		do
			Result := is_null (a_row, column_index (a_column_name))
		end

feature -- Row Iteration

	start_iteration
			-- Start row-by-row iteration from first data row.
			-- After calling start_iteration, call next_row to advance to first row.
		do
			iteration_index := 0
		ensure
			at_start: iteration_index = 0
		end

	next_row: BOOLEAN
			-- Move to next row. Returns True if there is a next row.
		do
			iteration_index := iteration_index + 1
			Result := iteration_index <= row_count
		end

	current_row: ARRAYED_LIST [STRING]
			-- Get current row in iteration.
		require
			valid_iteration: iteration_index >= 1 and iteration_index <= row_count
		do
			Result := row (iteration_index)
		ensure
			result_not_void: Result /= Void
		end

	current_field (a_column: INTEGER): STRING
			-- Get field at `a_column' in current iteration row.
		require
			valid_iteration: iteration_index >= 1 and iteration_index <= row_count
			valid_column: a_column >= 1 and a_column <= column_count
		do
			Result := field (iteration_index, a_column)
		ensure
			result_not_void: Result /= Void
		end

	current_field_by_name (a_column_name: STRING): STRING
			-- Get field by name in current iteration row.
		require
			has_header: has_header
			valid_iteration: iteration_index >= 1 and iteration_index <= row_count
			valid_column_name: has_column (a_column_name)
		do
			Result := field_by_name (iteration_index, a_column_name)
		ensure
			result_not_void: Result /= Void
		end

	iteration_index: INTEGER
			-- Current row index in iteration (1-based data row).

feature -- Query

	has_column (a_name: STRING): BOOLEAN
			-- Does a column with `a_name' exist?
		require
			name_not_void: a_name /= Void
		do
			Result := header_map.has (a_name.as_lower)
		end

	column_index (a_name: STRING): INTEGER
			-- Get index of column named `a_name' (1-based).
		require
			name_not_void: a_name /= Void
			has_column: has_column (a_name)
		do
			Result := header_map [a_name.as_lower]
		ensure
			valid_lower_bound: Result >= 1
			valid_upper_bound: Result <= column_count
		end

	is_empty: BOOLEAN
			-- Is CSV data empty?
		do
			Result := row_count = 0
		end

feature -- Generation

	to_csv: STRING
			-- Generate CSV string from current data.
		local
			i, j: INTEGER
		do
			create Result.make (rows.count * 50)
			from
				i := 1
			invariant
				row_index_valid: i >= 1 and i <= rows.count + 1
			until
				i > rows.count
			loop
				from
					j := 1
				invariant
					col_index_valid: j >= 1 and j <= rows [i].count + 1
				until
					j > rows [i].count
				loop
					if j > 1 then
						Result.append_character (delimiter)
					end
					Result.append (escape_field (rows [i] [j]))
					j := j + 1
				variant
					rows [i].count - j + 1
				end
				Result.append_character ('%N')
				i := i + 1
			variant
				rows.count - i + 1
			end
		ensure
			result_not_void: Result /= Void
		end

	to_csv_with_bom: STRING
			-- Generate CSV string with UTF-8 BOM for Excel compatibility.
		do
			Result := Utf8_bom + to_csv
		ensure
			result_not_void: Result /= Void
			has_bom: Result.count >= 3 implies (Result [1].code = 0xEF and Result [2].code = 0xBB and Result [3].code = 0xBF)
		end

	add_data_row (a_fields: ARRAY [STRING])
			-- Add a data row.
		require
			fields_not_void: a_fields /= Void
			fields_not_empty: a_fields.count > 0
		local
			l_row: ARRAYED_LIST [STRING]
			i: INTEGER
		do
			create l_row.make (a_fields.count)
			from
				i := a_fields.lower
			invariant
				valid_index: i >= a_fields.lower and i <= a_fields.upper + 1
				building_row: l_row.count = i - a_fields.lower
			until
				i > a_fields.upper
			loop
				l_row.extend (a_fields [i])
				i := i + 1
			variant
				a_fields.upper - i + 1
			end
			rows.extend (l_row)
		ensure
			row_added: rows.count = old rows.count + 1
		end

	set_headers (a_headers: ARRAY [STRING])
			-- Set header row.
			-- If has_header is already True, replaces existing header.
			-- If has_header is False, inserts header at front preserving existing data.
		require
			headers_not_void: a_headers /= Void
			headers_not_empty: a_headers.count > 0
		local
			l_row: ARRAYED_LIST [STRING]
			i: INTEGER
		do
			create l_row.make (a_headers.count)
			from
				i := a_headers.lower
			invariant
				valid_index: i >= a_headers.lower and i <= a_headers.upper + 1
				building_row: l_row.count = i - a_headers.lower
			until
				i > a_headers.upper
			loop
				l_row.extend (a_headers [i])
				i := i + 1
			variant
				a_headers.upper - i + 1
			end
			if rows.is_empty then
				rows.extend (l_row)
			elseif has_header then
				-- Replace existing header
				rows.put_i_th (l_row, 1)
			else
				-- Insert header at front, preserving existing data
				rows.put_front (l_row)
			end
			has_header := True
			build_header_map
		ensure
			has_header_set: has_header
			header_count_matches: rows.count > 0 implies rows.first.count = a_headers.count
		end

	clear
			-- Clear all data.
		do
			rows.wipe_out
			header_map.wipe_out
			parse_errors.wipe_out
			iteration_index := 0
		ensure
			rows_empty: rows.is_empty
			header_map_empty: header_map.is_empty
			errors_cleared: parse_errors.is_empty
		end

feature -- Settings

	delimiter: CHARACTER
			-- Field delimiter (default: comma).

	quote_char: CHARACTER
			-- Quote character for escaping (default: double quote).

	has_header: BOOLEAN
			-- Does first row contain headers?

	set_delimiter (a_delimiter: CHARACTER)
			-- Set field delimiter.
		require
			valid_delimiter: a_delimiter /= '%N' and a_delimiter /= '%R'
		do
			delimiter := a_delimiter
		ensure
			delimiter_set: delimiter = a_delimiter
		end

feature -- Lenient Mode

	lenient_mode: BOOLEAN
			-- Is lenient parsing mode enabled?
			-- When True, malformed rows are skipped and errors collected.

	set_lenient_mode (a_lenient: BOOLEAN)
			-- Enable or disable lenient parsing mode.
		do
			lenient_mode := a_lenient
		ensure
			lenient_set: lenient_mode = a_lenient
		end

	parse_errors: ARRAYED_LIST [STRING]
			-- List of errors encountered during parsing (in lenient mode).

	has_parse_errors: BOOLEAN
			-- Were there any errors during parsing?
		do
			Result := not parse_errors.is_empty
		end

feature -- BOM Support

	has_bom (a_input: STRING): BOOLEAN
			-- Does `a_input' start with UTF-8 BOM?
		require
			input_not_void: a_input /= Void
		do
			Result := a_input.count >= 3 and then
					  (a_input [1].code = 0xEF and
					   a_input [2].code = 0xBB and
					   a_input [3].code = 0xBF)
		end

	strip_bom (a_input: STRING): STRING
			-- Return `a_input' with UTF-8 BOM removed if present.
		require
			input_not_void: a_input /= Void
		do
			if has_bom (a_input) then
				Result := a_input.substring (4, a_input.count)
			else
				Result := a_input
			end
		ensure
			result_not_void: Result /= Void
			bom_stripped: not has_bom (Result)
		end

feature {NONE} -- Implementation

	rows: ARRAYED_LIST [ARRAYED_LIST [STRING]]
			-- All rows including header.

	header_map: HASH_TABLE [INTEGER, STRING]
			-- Map of header names to column indices.

	add_row (a_row: ARRAYED_LIST [STRING])
			-- Add a row to the data.
		require
			row_not_void: a_row /= Void
		do
			rows.extend (a_row)
		end

	add_row_lenient (a_row: ARRAYED_LIST [STRING]; a_row_number: INTEGER)
			-- Add a row to the data in lenient mode.
			-- If row has wrong column count, log error and optionally skip.
		require
			row_not_void: a_row /= Void
			lenient: lenient_mode
		local
			l_expected: INTEGER
		do
			if rows.count > 0 then
				l_expected := rows.first.count
				if a_row.count /= l_expected then
					parse_errors.extend ("Row " + a_row_number.out + ": expected " + l_expected.out + " columns, got " + a_row.count.out)
				end
			end
			-- Still add the row (lenient mode keeps data)
			rows.extend (a_row)
		end

	build_header_map
			-- Build header name to index mapping.
		local
			i: INTEGER
		do
			header_map.wipe_out
			if rows.count > 0 then
				from
					i := 1
				invariant
					valid_index: i >= 1 and i <= rows.first.count + 1
					mapping_built: header_map.count = i - 1
				until
					i > rows.first.count
				loop
					header_map.put (i, rows.first [i].as_lower)
					i := i + 1
				variant
					rows.first.count - i + 1
				end
			end
		ensure
			map_matches_header: rows.count > 0 implies header_map.count = rows.first.count
		end

	escape_field (a_field: STRING): STRING
			-- Escape field for CSV output.
		local
			needs_quotes: BOOLEAN
		do
			needs_quotes := a_field.has (delimiter) or
						   a_field.has (quote_char) or
						   a_field.has ('%N') or
						   a_field.has ('%R')

			if needs_quotes then
				create Result.make (a_field.count + 10)
				Result.append_character (quote_char)
				across a_field as c loop
					if c.item = quote_char then
						Result.append_character (quote_char)
					end
					Result.append_character (c.item)
				end
				Result.append_character (quote_char)
			else
				Result := a_field
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Constants

	Utf8_bom: STRING
			-- UTF-8 Byte Order Mark.
		once
			create Result.make (3)
			Result.append_character ((0xEF).to_character_8)
			Result.append_character ((0xBB).to_character_8)
			Result.append_character ((0xBF).to_character_8)
		ensure
			result_not_void: Result /= Void
			correct_length: Result.count = 3
		end

invariant
	rows_exist: rows /= Void
	header_map_exists: header_map /= Void
	valid_delimiter: delimiter /= '%N' and delimiter /= '%R'
	valid_quote_char: quote_char /= '%N' and quote_char /= '%R'
	delimiter_not_quote: delimiter /= quote_char
	parse_errors_exist: parse_errors /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
