import pyarrow as pa
import pyarrow.csv as csv
import pyarrow.parquet as pq

def read_csv_with_schema(csv_path, schema, skip_header=True, delimiter=",", quote_char='"'):
    """
    Read a CSV file using a specified PyArrow schema.
    
    Args:
        csv_path (str): Path to the CSV file
        schema (pa.Schema): PyArrow schema to apply
        skip_header (bool): Whether to skip the header row
        delimiter (str): CSV delimiter character
        quote_char (str): CSV quote character
        
    Returns:
        pa.Table: PyArrow table with the specified schema
    """
    read_options = csv.ReadOptions(
        skip_rows=1 if skip_header else 0,
        column_names=schema.names
    )

    parse_options = csv.ParseOptions(
        delimiter=delimiter,
        quote_char=quote_char
    )

    convert_options = csv.ConvertOptions(
        column_types={field.name: field.type for field in schema},
        strings_can_be_null=True,
        auto_dict_encode=True,
        null_values=[''],
        timestamp_parsers=["%Y-%m-%d", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%H:%M:%S"]
    )

    return csv.read_csv(
        csv_path,
        read_options=read_options,
        parse_options=parse_options,
        convert_options=convert_options
    )

def write_table_to_parquet(table, parquet_path):
    """
    Write a PyArrow table to a Parquet file.
    
    Args:
        table (pa.Table): PyArrow table to write
        parquet_path (str): Output Parquet file path
        
    Returns:
        str: Path to the created Parquet file
    """
    pq.write_table(table, parquet_path)
    return parquet_path

def print_parquet_schema(parquet_path):
    """
    Print the schema of a Parquet file.
    
    Args:
        parquet_path (str): Path to the Parquet file
    """
    schema = pq.read_schema(parquet_path)
    print(f"Schema in Parquet file: {parquet_path}")
    for field in schema:
        print(f"  {field.name}: {field.type}")
    
    return schema