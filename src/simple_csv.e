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

		Usage:
			create csv.make
			csv.parse ("name,age%Njohn,30")
			name := csv.field (1, 1)  -- "name"

			-- Or with headers
			create csv.make_with_header
			csv.parse (data)
			age := csv.field_by_name (2, "age")
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
			create rows.make (10)
			create header_map.make (10)
		ensure
			comma_delimiter: delimiter = ','
			default_quote: quote_char = '"'
			no_header: not has_header
			rows_empty: rows.is_empty
			header_map_empty: header_map.is_empty
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
		require
			input_not_void: a_input /= Void
		local
			l_row: ARRAYED_LIST [STRING]
			l_field: STRING
			i: INTEGER
			c: CHARACTER
			in_quotes: BOOLEAN
			l_input: STRING
		do
			rows.wipe_out
			header_map.wipe_out

			-- Normalize line endings
			l_input := a_input.twin
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
							add_row (l_row)
							create l_row.make (10)
						end
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
				add_row (l_row)
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
		ensure
			rows_empty: rows.is_empty
			header_map_empty: header_map.is_empty
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

invariant
	rows_exist: rows /= Void
	header_map_exists: header_map /= Void
	valid_delimiter: delimiter /= '%N' and delimiter /= '%R'
	valid_quote_char: quote_char /= '%N' and quote_char /= '%R'
	delimiter_not_quote: delimiter /= quote_char

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
