# Spice.ai Power BI Connector

The Spice.ai Power BI Connector is a [ADBC](https://github.com/apache/arrow-adbc)-based connector that enables Power BI users to easily connect to and visualize data from Spice.ai Enterprise and Spice Cloud Platform instances.

## Features

- Connect Power BI to Spice data sources: [Spice Cloud Platform](https://spice.ai/) and [Spice.ai Enterprise](https://spiceai.org/)
- API key authentication
- TLS encryption for secure connections

## Installation

### Tableau Desktop

1. Download the latest `spice_adbc.mez` file from the [releases page](https://github.com/spiceai/powerbi-connector/releases)
2. Copy to your Power BI `Custom Connectors` directory:
   - Windows: `C:\Users\[USERNAME]\Documents\Microsoft Power BI Desktop\Custom Connectors`

      ```powershell
      Invoke-WebRequest -Uri "https://github.com/spiceai/powerbi-connector/releases/latest/download/spice_adbc.mez" -OutFile "C:\Users\[USERNAME]\Documents\Microsoft Power BI Desktop\Custom Connectors\spice_adbc.mez"
      ```

3. [Enable Uncertified Connectors](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-connector-extensibility#custom-connectors) in Power BI Desktop settings and restart Power BI Desktop.

## Limitations

### Supported Data Types

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
| Utf8 / LargeUtf8 / Utf8View                                   | VARCHAR             | Text               |
| Date32 / Date64                                               | DATE                | Date               |
| Time32 / Time64                                               | TIME                | Time               |
| Timestamp                                                     | TIMESTAMP           | DateTime           |
| List / LargeList / FixedSizeList / ListView / LargeListView   | ARRAY               | Text               |
| Interval                                                      | INTERVAL            | Text               |
| Struct                                                        | STRUCT              | Text               |

### Date Time Arithmetic Operations Are Not Supported

Date and time arithmetic operations, such as subtracting or adding timestamps and intervals, are not supported and will result in an error similar to `Invalid function 'timestampdiff'.\nDid you mean 'to_timestamp'? (Internal; ExecuteQuery)`. For example:

```text
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

### Run Smoke Tests

1. In a separate terminal, run the test Spice instance:

    ```bash
    cd test
    spice run
    ```

2. Run the tests:

    ```bash
    make test
    ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
