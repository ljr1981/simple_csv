<p align="center">
  <img src="https://raw.githubusercontent.com/ljr1981/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_csv

**[Documentation](https://ljr1981.github.io/simple_csv/)**

Lightweight RFC 4180 compliant CSV parsing and generation library for Eiffel.

## Features

- **RFC 4180 compliant** parsing (quoted fields, embedded commas, newlines)
- **Custom delimiters** (comma, tab, semicolon, etc.)
- **Header row** handling with column name lookup
- **Row and column** access with 1-based indexing
- **CSV generation** from data with proper escaping
- **Design by Contract** with full preconditions/postconditions

## Installation

Add to your ECF:

```xml
<library name="simple_csv" location="$SIMPLE_CSV\simple_csv.ecf"/>
```

Set environment variable:
```
SIMPLE_CSV=D:\prod\simple_csv
```

## Usage

### Basic Parsing

```eiffel
local
    csv: SIMPLE_CSV
do
    create csv.make
    csv.parse ("name,age,city%NJohn,30,NYC%NJane,25,LA")

    -- Access by row/column (1-based)
    print (csv.field (1, 1))  -- "name"
    print (csv.field (2, 2))  -- "30"
end
```

### With Header Row

```eiffel
local
    csv: SIMPLE_CSV
do
    create csv.make_with_header
    csv.parse ("name,age,city%NJohn,30,NYC%NJane,25,LA")

    -- Access by column name
    print (csv.field_by_name (1, "age"))  -- "30"
    print (csv.field_by_name (2, "name")) -- "Jane"

    -- Check column existence
    if csv.has_column ("email") then
        -- handle email column
    end
end
```

### Tab-Separated Values (TSV)

```eiffel
local
    csv: SIMPLE_CSV
do
    create csv.make_with_delimiter ('%T')
    csv.parse ("a%Tb%Tc%N1%T2%T3")
end
```

### Quoted Fields

```eiffel
-- Handles embedded commas, quotes, and newlines
csv.parse ("%"hello,world%",test")
print (csv.field (1, 1))  -- "hello,world"

-- Escaped quotes
csv.parse ("%"say %"%"hi%"%"%",test")
print (csv.field (1, 1))  -- "say "hi""
```

### Generating CSV

```eiffel
local
    csv: SIMPLE_CSV
    output: STRING
do
    create csv.make
    csv.set_headers (<<"name", "age", "city">>)
    csv.add_data_row (<<"John", "30", "NYC">>)
    csv.add_data_row (<<"Jane", "25", "LA">>)

    output := csv.to_csv
    -- "name,age,city
    --  John,30,NYC
    --  Jane,25,LA"
end
```

### Parsing Files

```eiffel
csv.parse_file ("data.csv")
```

## API Reference

### Initialization

| Feature | Description |
|---------|-------------|
| `make` | Create parser with comma delimiter |
| `make_with_header` | First row is header |
| `make_with_delimiter (char)` | Custom delimiter |

### Parsing

| Feature | Description |
|---------|-------------|
| `parse (STRING)` | Parse CSV string |
| `parse_file (STRING)` | Parse file at path |

### Access

| Feature | Description |
|---------|-------------|
| `field (row, col): STRING` | Get field (1-based) |
| `field_by_name (row, name): STRING` | Get field by column name |
| `row (n): ARRAYED_LIST[STRING]` | Get entire row |
| `column (n): ARRAYED_LIST[STRING]` | Get entire column |
| `column_by_name (name): ARRAYED_LIST[STRING]` | Get column by name |
| `headers: ARRAYED_LIST[STRING]` | Get header row |

### Query

| Feature | Description |
|---------|-------------|
| `row_count: INTEGER` | Number of data rows |
| `column_count: INTEGER` | Number of columns |
| `has_column (name): BOOLEAN` | Column exists? |
| `column_index (name): INTEGER` | Get column index |
| `is_empty: BOOLEAN` | No data? |

### Generation

| Feature | Description |
|---------|-------------|
| `to_csv: STRING` | Generate CSV string |
| `add_data_row (ARRAY[STRING])` | Add data row |
| `set_headers (ARRAY[STRING])` | Set header row |
| `clear` | Clear all data |

## Use Cases

- **Data import/export** - Universal data exchange format
- **Configuration files** - Simple key-value storage
- **Report generation** - Tabular data output
- **Log parsing** - Structured log analysis
- **Spreadsheet integration** - Excel/Sheets compatible

## Dependencies

- EiffelBase only

## License

MIT License - Copyright (c) 2024-2025, Larry Rix
