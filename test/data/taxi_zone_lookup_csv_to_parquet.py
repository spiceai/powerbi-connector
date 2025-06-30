import pyarrow.csv as csv
import pyarrow as pa
import pyarrow.parquet as pq
from datetime import datetime

from arrow_utils import print_parquet_schema, read_csv_with_schema, write_table_to_parquet

# CSV input path and Parquet output path
csv_path = "taxi_zone_lookup.csv"
parquet_path = "taxi_zone_lookup.parquet"

# Target schema: https://github.com/microsoft/DataConnectors/blob/master/testframework/data/PQSDKTestFrameworkDataSchema.sql
arrow_schema = pa.schema([
    ("LocationID", pa.int32()),
    ("Borough", pa.utf8()),
    ("Zone", pa.utf8()),
    ("service_zone", pa.utf8())
])

try:
    table = read_csv_with_schema(csv_path, arrow_schema)
    write_table_to_parquet(table, parquet_path)
    print_parquet_schema(parquet_path)
    
except Exception as e:
    print(f"Error during conversion: {e}")

# Keeping Table Arrow schema for future reference / troubleshooting
# Schema in Parquet file: taxi_zone_lookup.parquet
#   LocationID: int32
#   Borough: string
#   Zone: string
#   service_zone: string
