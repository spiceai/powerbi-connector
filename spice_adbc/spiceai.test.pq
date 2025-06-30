let
    conn         = Spice.Databases("127.0.0.1:50051", "Disabled"),
    spiceDB      = conn{[Name="spice", Kind="Database"]}[Data],
    publicSchema = spiceDB{[Name="public", Kind="Schema"]}[Data],
    testTable    = publicSchema{[Name="types_support", Kind="Table"]}[Data],

    taxi_table    = publicSchema{[Name="nyc_taxi_tripdata", Kind="Table"]}[Data],
    taxi_table_schema = Table.Schema(taxi_table),

    zone_table = publicSchema{[Name="taxi_zone_lookup", Kind="Table"]}[Data],
    zone_table_schema = Table.Schema(zone_table),


    Sorted = Table.Sort(taxi_table, {"RecordID"}),
    
    // DateTimeArithmetic.query.pq (not currently supported)
    // T2 = Table.SelectColumns(Sorted, {"PULocationID","lpep_pickup_datetime"}),
    // T3 = Table.Sort(T2, {"PULocationID"}),
    // T4 = Table.AddColumn(T3, "Diff1", each [lpep_pickup_datetime] - #datetime(1999,1,5,0,0,0)),
    // T5 = Table.AddColumn(T4, "Diff2", each [lpep_pickup_datetime] - #datetime(2007,2,6,0,0,0)),
    // T6 = Table.AddColumn(T5, "Diff3", each [lpep_pickup_datetime] - #datetime(2007,9,5,0,0,0)),
    // TA = Table.FirstN(T6, 4),

    // Limit + types support
    FirstN_Test = Table.FirstN(testTable, 1),

    // Filter
    Filter_Test = Table.SelectRows(testTable, each [col_int32] > 5),

    // Subset of columns
    SelectColumns_Test = Table.SelectColumns(testTable, {"col_int32", "col_boolean"}),

    // Sorting
    Sort_Test = Table.Sort(testTable, {{"col_int32", Order.Ascending}}),

    // Multiple conditions filter
    ComplexFilter_Test = Table.SelectRows(testTable, each [col_int32] > 5 and [col_boolean] = true),

    // Aggregation
    GroupBySum_Test = Table.Group(
        testTable,
        {"col_boolean"},
        {{"SumColInt", each List.Sum([col_int32]), Int64.Type}}
    ),

    // Aggregation with count
    GroupByCount_Test = Table.Group(
        testTable,
        {"col_boolean"},
        {{"RowCount", each Table.RowCount(_), Int64.Type}}
    ),

    // Sorting + limiting (ORDER BY + LIMIT)
    SortLimit_Test = Table.FirstN(
        Table.Sort(testTable, {{"col_int32", Order.Descending}}),
        10
    ),

    // Simple calculated column
    AddColumn_Test = Table.AddColumn(testTable, "col_int_plus_1", each [col_int32] + 1, Int64.Type),

    // Filter on calculated column
    FilterAddColumn_Test = Table.SelectRows(
        Table.AddColumn(testTable, "col_int_plus_1", each [col_int32] + 1, Int64.Type),
        each [col_int_plus_1] > 10
    ),

    // Combine: group, sort, limit
    GroupSortLimit_Test = Table.FirstN(
        Table.Sort(
            Table.Group(
                testTable,
                {"col_boolean"},
                {{"SumColInt", each List.Sum([col_int32]), Int64.Type}}
            ),
            {{"SumColInt", Order.Descending}}
        ),
        5
    ),

    // // Explicit native query (raw SQL)
    NativeQuery_Test = Value.NativeQuery(
        spiceDB,
        "select * from types_support where col_int32 > 0 order by col_boolean desc limit 3",
        null,
        [
            EnableFolding = true
        ]
    ),

   // This can be improved by using Facts: https://github.com/microsoft/DataConnectors/blob/master/samples/UnitTesting/UnitTesting.query.pq#L23 
    AllTests = [
        FirstN = FirstN_Test,
        Filter = Filter_Test,
        SelectColumns = SelectColumns_Test,
        Sort = Sort_Test,
        ComplexFilter = ComplexFilter_Test,
        GroupBySum = GroupBySum_Test,
        GroupByCount = GroupByCount_Test,
        SortLimit = SortLimit_Test,
        AddColumn = AddColumn_Test,
        FilterAddColumn = FilterAddColumn_Test,
        GroupSortLimit = GroupSortLimit_Test,
        NativeQuery = NativeQuery_Test
    ]
in
    GroupSortLimit_Test