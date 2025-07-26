# Spice.ai Power BI Connector

The Spice.ai Power BI Connector is a [ADBC](https://github.com/apache/arrow-adbc)-based connector that enables Power BI users to easily connect to and visualize data from Spice.ai Enterprise and Spice Cloud Platform instances.

## Features

- Connect Power BI to Spice data sources: [Spice Cloud Platform](https://spice.ai/) and [Spice.ai Enterprise](https://spiceai.org/)
- API key authentication
- TLS encryption for secure connections

## Manual Connector Installation

### Tableau Desktop

1. Download the latest `spice_adbc.mez` file from the [releases page](https://github.com/spiceai/powerbi-connector/releases)
2. Copy to your Power BI `Custom Connectors` directory:
   - Windows: `C:\Users\[USERNAME]\Documents\Microsoft Power BI Desktop\Custom Connectors`

      ```powershell
      Invoke-WebRequest -Uri "https://github.com/spiceai/powerbi-connector/releases/latest/download/spice_adbc.mez" -OutFile "C:\Users\[USERNAME]\Documents\Microsoft Power BI Desktop\Custom Connectors\spice_adbc.mez"
      ```

3. [Enable Uncertified Connectors](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-connector-extensibility#custom-connectors) in Power BI Desktop settings and restart Power BI Desktop.

## Adding Spice as a Data Source in Power BI

1. Open Power BI Desktop.
2. Click on `Get Data` → `More...`.
3. In the dialog, select `Spice.ai` connector.

   <img width="748" alt="Spice.ai connector" src="https://github.com/user-attachments/assets/d589cfce-25c3-4697-9a7c-e63a130acd53" />

4. Click `Connect`.
5. Enter the **ADBC (Arrow Flight SQL) Endpoint**:
    - For Spice Cloud Platform:  
      `grpc+tls://flight.spiceai.io:443`  
      *(Use the region-specific address if applicable.)*
    - For on-premises/self-hosted Spice.ai:
        - Without TLS (default): `grpc://<server-ip>:50051`
        - With TLS: `grpc+tls://<server-ip>:50051`

<img width="748" alt="Spice.ai Connection Dialog" src="https://github.com/user-attachments/assets/e8365aa3-68f1-4746-916c-d0a82e80a627" />

6. Select the `Data Connectivity` mode:
    - **Import**: Data is loaded into Power BI, enabling extensive functionality but requiring periodic refreshes and sufficient local memory to accommodate the dataset.
    - **DirectQuery**: Queries are executed directly against Spice in real-time, providing fast performance even on large datasets by leveraging Spice's optimized query engine.
7. Click `OK`.
8. Select `Authentication` option:
    - **Anonymous**: Select for unauthenticated on-premises deployments.
    - **API Key**: Your Spice.ai API key for authentication (required for Spice Cloud). Follow the [guide](https://docs.spice.ai/portal/apps/api-keys) to obtain it from the Spice Cloud portal.
  
<img width="748" alt="Spice.ai Authentication" src="https://github.com/user-attachments/assets/76c550fd-489f-474c-aa50-311371ecdf5b" />

9. Click `Connect` to establish the connection.

### Creating Test Instance

Optional: To create a test Spice instance for use with the Power BI connector, follow the steps below. For additional details, refer to the [Spice.ai documentation](https://spiceai.org/docs).

#### Local Self-Hosted Spice.ai Instance

1. [Install Spice.ai OSS](https://spiceai.org/docs/installation).
2. Create a test app:

    ```powershell
    spice init taxi_trips
    cd taxi_trips
    ```

    Output:

    ```powershell
    Spice.ai OSS CLI v1.5.0
    2025/07/25 10:44:04 INFO Initialized taxi_trips/spicepod.yaml
    ```

3. Using an editor, modify `spicepod.yaml` to add the `taxi_trips` S3 dataset:

    ```yaml
    version: v1
    kind: Spicepod
    name: taxi_trips

    datasets:
      - from: s3://spiceai-public-datasets/pbi-power-query-test-suite/nyc_taxi_tripdata.parquet
        name: taxi_trips
        acceleration: 
          enabled: true
    ```

4. Run Spice. Once started, `grpc://127.0.0.1:50051` can be used as the `ADBC (Arrow Flight SQL) Endpoint` to connect. Use `Anonymous` authentication.

    ```powershell
    spice run
    ```

    Output:

    ```powershell
    2025/07/25 10:47:49 INFO Checking for latest Spice runtime release...
    2025/07/25 10:47:49 INFO Spice.ai runtime starting...
    2025-07-25T17:47:49.553039Z  INFO spiced: Starting runtime v1.5.0+models
    2025-07-25T17:47:49.555191Z  INFO runtime::init::caching: Initialized results cache; max size: 128.00 MiB, item ttl: 1s
    2025-07-25T17:47:49.555425Z  INFO runtime::init::caching: Initialized search results cache;
    2025-07-25T17:47:49.952813Z  INFO runtime::opentelemetry: Spice Runtime OpenTelemetry listening on 127.0.0.1:50052
    2025-07-25T17:47:49.952818Z  INFO runtime::flight: Spice Runtime Flight listening on 127.0.0.1:50051
    2025-07-25T17:47:49.954928Z  INFO runtime::init::dataset: Dataset taxi_trips initializing...
    2025-07-25T17:47:49.954685Z  INFO runtime::http: Spice Runtime HTTP listening on 127.0.0.1:8090
    2025-07-25T17:47:50.876966Z  INFO runtime::init::dataset: Dataset taxi_trips registered (s3://spiceai-public-datasets/pbi-power-query-test-suite/nyc_taxi_tripdata.parquet), acceleration (arrow), results cache enabled.
    2025-07-25T17:47:50.877953Z  INFO runtime::accelerated_table::refresh_task: Loading data for dataset taxi_trips
    2025-07-25T17:47:51.945597Z  INFO runtime::accelerated_table::refresh_task: Loaded 10,000 rows (1.35 MiB) for dataset taxi_trips in 1s 67ms.
    2025-07-25T17:47:52.034011Z  INFO runtime: All components are loaded. Spice runtime is ready!
    ```

#### Spice Cloud

1. Create free [Spice.ai Cloud Platform application](https://docs.spice.ai/getting-started/get-started).
1. [Configure](https://docs.spice.ai/portal/app-spicepod) and [deploy](https://docs.spice.ai/portal/app-spicepod/deployments) `taxi_trips` dataset

    ```yaml
    version: v1
    kind: Spicepod
    name: taxi_trips

    datasets:
      - from: s3://spiceai-public-datasets/pbi-power-query-test-suite/nyc_taxi_tripdata.parquet
        name: taxi_trips
        acceleration: 
          enabled: true
    ```

1. Obtain API Key: [guide](https://docs.spice.ai/portal/apps/api-keys)
1. Once configured, `grpc+tls://flight.spiceai.io:443` can be used as the `ADBC (Arrow Flight SQL) Endpoint` to connect. Provide your API key for authentication.

## Supported Data Types

The following Apache Arrow / DataFusion SQL types are supported. Other types will result in a `Unable to understand the type for column` error. Please report an issue if support for additional types is required.

| Arrow Type                                                    | DataFusion SQL Type | Power Query M Type |
|---------------------------------------------------------------|---------------------|--------------------|
| Boolean                                                       | BOOLEAN             | Logical            |
| Int16                                                         | SMALLINT            | Int16              |
| Int32                                                         | INTEGER             | Int32              |
| Int64                                                         | BIGINT              | Int64              |
| Float32                                                       | REAL                | Single             |
| Float64                                                       | DOUBLE              | Double             |
| Decimal128 / Decimal256                                       | DECIMAL             | Decimal            |
| Utf8                                                          | VARCHAR             | Text               |
| Date32 / Date64                                               | DATE                | Date               |
| Time32 / Time64                                               | TIME                | Time               |
| Timestamp                                                     | TIMESTAMP           | DateTime           |
| List / LargeList / FixedSizeList / ListView / LargeListView   | ARRAY               | Text               |
| Interval                                                      | INTERVAL            | Text               |
| Struct                                                        | STRUCT              | Text               |

## Limitations

### LargeUtf8 Data Type Is Not Supported

To work around this limitation, use [views](https://spiceai.org/docs/components/views) to manually convert `LargeUtf8` columns to `Utf8` by casting them with `::TEXT`.

**Example:**

```yaml
views:
    - name: taxi_zone_lookup
        sql: |
            SELECT
                LocationID as LocationID,
                Borough::TEXT as Borough,
                Zone::TEXT as Zone,
                service_zone::TEXT as service_zone
            FROM taxi_zone_lookup_temp;
```

### Date Time Arithmetic Operations Are Not Supported

Due to lack of support for the `timestampdiff` function in the [DataFusion query engine](https://datafusion.apache.org/user-guide/sql/scalar_functions.html), date and time arithmetic operations—such as subtracting or adding timestamps and intervals—are not supported and will result in an error similar to `Invalid function 'timestampdiff'.\nDid you mean 'to_timestamp'? (Internal; ExecuteQuery)`. For example:
(parameter) =>
let
    Sorted = Table.Sort(parameter[taxi_table], {"RecordID"}),
    T2 = Table.SelectColumns(Sorted, {"PULocationID","lpep_pickup_datetime"}),
    T3 = Table.Sort(T2, {"PULocationID"}),
    T4 = Table.AddColumn(T3, "Diff1", each [lpep_pickup_datetime] - #datetime(1999,1,5,0,0,0))
    TA = Table.FirstN(T6, 4)
in
    TA
```

```text
ADBC: InternalError [] [FlightSQL] [FlightSQL] Error during planning: Invalid function 'timestampdiff'.\nDid you mean 'to_timestamp'? (Internal; ExecuteQuery)
```

Please report an issue if support for date or time arithmetic operations is required.

## Development

### Prerequisites

- `Windows`
- `Visual Studio Code`
- `make`:
  - `choco install make` if you use Chocolatey
  - `scoop install make` if you use Scoop
  - Or download make.exe and add to PATH: <https://github.com/mbuilov/make-windows/releases>

```bash
git clone https://github.com/spiceai/powerbi-connector.git
cd powerbi-connector

# Install powerquery-sdk
make tools
```

### Build Connector

```bash
make build
```

### Run Tests

1. In a separate terminal, run the test Spice instance:

    ```bash
    cd test
    spice run
    ```

2. Run smoke tests:

    ```bash
    make test
    ```

3. Run the [Power Query SDK Test Suite](https://github.com/microsoft/DataConnectors/blob/master/testframework/tests/PQSDKTestSuites.md):

    ```bash
    make test-suite
    ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
