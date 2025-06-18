import pyarrow.csv as csv
import pyarrow as pa
import pyarrow.parquet as pq
from datetime import datetime

from arrow_utils import print_parquet_schema, read_csv_with_schema, write_table_to_parquet

# CSV input path and Parquet output path
csv_path = "~/spice/powerbi-connector/test/data/nyc_taxi_tripdata.csv"
parquet_path = "nyc_taxi_tripdata.parquet"

# Target schema: https://github.com/microsoft/DataConnectors/blob/master/testframework/data/PQSDKTestFrameworkDataSchema.sql
# Schema in Parquet file: nyc_taxi_tripdata.parquet
#   RecordID: int32
#   VendorID: int32
#   lpep_pickup_datetime: timestamp[ms]
#   lpep_dropoff_datetime: timestamp[ms]
#   store_and_fwd_flag: bool
#   RatecodeID: int32
#   PULocationID: int32
#   DOLocationID: int32
#   passenger_count: int32
#   trip_distance: double
#   fare_amount: double
#   extra: double
#   mta_tax: double
#   tip_amount: double
#   tolls_amount: double
#   improvement_surcharge: double
#   total_amount: double
#   payment_type: int32
#   trip_type: int32
#   congestion_surcharge: double

