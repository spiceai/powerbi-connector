section spiceai;

// Integration tests for Spice connector
shared Spice.IntegrationTests = [
    conn = Spice.Databases("127.0.0.1:50051"),
    spiceDB      = conn{[Name="spice", Kind="Database"]}[Data],	
    publicSchema = spiceDB{[Name="public", Kind="Schema"]}[Data],	
    testTable    = publicSchema{[Name="types_support", Kind="Table"]}[Data],
    // Test: Take first row
    FirstN_Test = Table.FirstN(testTable, 1),
    // Test: Filter
    Filter_Test = Table.SelectRows(testTable, each [col_int32] > 5),
    // Test: Select specific columns
    SelectColumns_Test = Table.SelectColumns(testTable, {"col_int32", "col_boolean"}),
    // Test: Sort
    Sort_Test = Table.Sort(testTable, {{"col_int32", Order.Ascending}}),
    // Test: Complex filter
    ComplexFilter_Test = Table.SelectRows(testTable, each [col_int32] > 5 and [col_boolean] = true),
    // Test: Group by and sum
    GroupBySum_Test = Table.Group(
        testTable, {"col_boolean"}, {{"SumColInt", each List.Sum([col_int32]), Int64.Type}}
    ),
    // Test: Group by and count
    GroupByCount_Test = Table.Group(testTable, {"col_boolean"}, {{"RowCount", each Table.RowCount(_), Int64.Type}}),
    // Test: Sort by descending and limit
    SortLimit_Test = Table.FirstN(Table.Sort(testTable, {{"col_int32", Order.Descending}}), 10),
    // Test: Add column
    AddColumn_Test = Table.AddColumn(testTable, "col_int_plus_1", each [col_int32] + 1, Int64.Type),
    // Test: Add column and filter
    FilterAddColumn_Test = Table.SelectRows(
        Table.AddColumn(testTable, "col_int_plus_1", each [col_int32] + 1, Int64.Type), each [col_int_plus_1] > 10
    ),
    // Test: Complex - group by, sort and limit
    GroupSortLimit_Test = Table.FirstN(
        Table.Sort(
            Table.Group(testTable, {"col_boolean"}, {{"SumColInt", each List.Sum([col_int32]), Int64.Type}}),
            {{"SumColInt", Order.Descending}}
        ),
        5
    ),
    // Test: Native query with folding enabled
    NativeQuery_Test = Value.NativeQuery(
        spiceDB,
        "select * from types_support where col_int32 > 0 order by col_boolean desc limit 3",
        null,
        [
            EnableFolding = true
        ]
    ),
    facts = {
        Fact("FirstN Test", true, Table.RowCount(FirstN_Test) = 1),
        Fact("Filter Test", true, Table.RowCount(Filter_Test) <= Table.RowCount(testTable)),
        Fact("SelectColumns Test", true, Table.ColumnCount(SelectColumns_Test) = 2),
        Fact("Sort Test", true, Table.RowCount(Sort_Test) = Table.RowCount(testTable)),
        Fact("ComplexFilter Test", true, Table.RowCount(ComplexFilter_Test) <= Table.RowCount(testTable)),
        Fact("GroupBySum Test", true, Table.RowCount(GroupBySum_Test) <= 2),
        Fact("GroupByCount Test", true, Table.RowCount(GroupByCount_Test) <= 2),
        Fact("SortLimit Test", true, Table.RowCount(SortLimit_Test) <= 10),
        Fact("AddColumn Test", true, Table.ColumnCount(AddColumn_Test) = Table.ColumnCount(testTable) + 1),
        Fact("FilterAddColumn Test", true, Table.RowCount(FilterAddColumn_Test) <= Table.RowCount(testTable)),
        Fact("GroupSortLimit Test", true, Table.RowCount(GroupSortLimit_Test) <= 5),
        Fact("NativeQuery Test", true, Table.RowCount(NativeQuery_Test) <= 3)
    },
    // Summarize all facts into a report table
    report = Facts.Summarize(facts)
][report];

// Based on Microsoft Data Connectors Unit Testing example:
// https://github.com/microsoft/DataConnectors/blob/master/samples/UnitTesting/UnitTesting.query.pq
Fact = (_subject as text, _expected, _actual) as record =>
    [
        expected = try _expected,
        safeExpected = if expected[HasError] then "Expected : " & @ValueToText(expected[Error]) else expected[Value],
        actual = try _actual,
        safeActual = if actual[HasError] then "Actual : " & @ValueToText(actual[Error]) else actual[Value],
        attempt = try safeExpected = safeActual,
        result = if attempt[HasError] or not attempt[Value] then "Failure ⛔" else "Success ✓",
        resultOp = if result = "Success ✓" then " = " else " <> ",
        addendumEvalAttempt = if attempt[HasError] then @ValueToText(attempt[Error]) else "",
        addendumEvalExpected = try @ValueToText(safeExpected) otherwise "...",
        addendumEvalActual = try @ValueToText(safeActual) otherwise "...",
        fact = [
            Result = result & " " & addendumEvalAttempt,
            Notes = _subject,
            Details = " (" & addendumEvalExpected & resultOp & addendumEvalActual & ")"
        ]
    ][fact];

Facts = (_subject as text, _predicates as list) => List.Transform(_predicates, each Fact(_subject, _{0}, _{1}));

Facts.Summarize = (_facts as list) as table =>
    [
        Fact.CountSuccesses = (count, i) =>
            [
                result = try i[Result],
                sum = if result[HasError] or not Text.StartsWith(result[Value], "Success") then count else count + 1
            ][sum],
        passed = List.Accumulate(_facts, 0, Fact.CountSuccesses),
        total = List.Count(_facts),
        format = if passed = total then "All #{0} Passed !!! ✓" else "#{0} Passed ☺  #{1} Failed ☹",
        result = if passed = total then "Success" else "⛔",
        rate = Number.IntegerDivide(100 * passed, total),
        header = [
            Result = result,
            Notes = Text.Format(format, {passed, total - passed}),
            Details = Text.Format("#{0}% success rate", {rate})
        ],
        report = Table.FromRecords(List.Combine({{header}, _facts}))
    ][report];

ValueToText = (value, optional depth) =>
    let
        List.TransformAndCombine = (list, transform, separator) =>
            Text.Combine(List.Transform(list, transform), separator),
        Serialize.Binary = (x) => "#binary(" & Serialize(Binary.ToList(x)) & ") ",
        Serialize.Function = (x) =>
            _serialize_function_param_type(
                Type.FunctionParameters(Value.Type(x)), Type.FunctionRequiredParameters(Value.Type(x))
            )
                & " as "
                & _serialize_function_return_type(Value.Type(x))
                & " => (...) ",
        Serialize.List = (x) => "{" & List.TransformAndCombine(x, Serialize, ", ") & "} ",
        Serialize.Record = (x) =>
            "[ "
                & List.TransformAndCombine(
                    Record.FieldNames(x),
                    (item) => Serialize.Identifier(item) & " = " & Serialize(Record.Field(x, item)),
                    ", "
                )
                & " ] ",
        Serialize.Table = (x) =>
            "#table( type " & _serialize_table_type(Value.Type(x)) & ", " & Serialize(Table.ToRows(x)) & ") ",
        Serialize.Identifier = Expression.Identifier,
        Serialize.Type = (x) => "type " & _serialize_typename(x),
        _serialize_typename = (x, optional funtype as logical) =>
            // Optional parameter: Is this being used as part of a function signature?
            let
                isFunctionType = (x as type) =>
                    try if Type.FunctionReturn(x) is type then true else false otherwise false,
                isTableType = (x as type) => try if Type.TableSchema(x) is table then true else false otherwise false,
                isRecordType = (x as type) => try if Type.ClosedRecord(x) is type then true else false
            otherwise
                false,
                isListType = (x as type) => try if Type.ListItem(x) is type then true else false otherwise false
            in
                if funtype = null and isTableType(x) then
                    _serialize_table_type(x)
                else if funtype = null and isListType(x) then
                    "{ " & @_serialize_typename(Type.ListItem(x)) & " }"
                else if funtype = null and isFunctionType(x) then
                    "function " & _serialize_function_type(x)
                else if funtype = null and isRecordType(x) then
                    _serialize_record_type(x)
                else if x = type any then
                    "any"
                else
                    let
                        base = Type.NonNullable(x)
                    in
                        (if Type.IsNullable(x) then "nullable " else "")
                            & (
                                if base = type anynonnull then
                                    "anynonnull"
                                else if base = type binary then
                                    "binary"
                                else if base = type date then
                                    "date"
                                else if base = type datetime then
                                    "datetime"
                                else if base = type datetimezone then
                                    "datetimezone"
                                else if base = type duration then
                                    "duration"
                                else if base = type logical then
                                    "logical"
                                else if base = type none then
                                    "none"
                                else if base = type null then
                                    "null"
                                else if base = type number then
                                    "number"
                                else if base = type text then
                                    "text"
                                else if base = type time then
                                    "time"
                                else if base = type type then
                                    "type"
                                else
                                // Abstract types
                                if base = type function then
                                    "function"
                                else if base = type table then
                                    "table"
                                else if base = type record then
                                    "record"
                                else if base = type list then
                                    "list"
                                else
                                    "any /*Actually unknown type*/"
                            ),
        _serialize_table_type = (x) =>
            let
                schema = Type.TableSchema(x)
            in
                "table "
                    & (
                        if Table.IsEmpty(schema) then
                            ""
                        else
                            "["
                                & List.TransformAndCombine(
                                    Table.ToRecords(Table.Sort(schema, "Position")),
                                    each Serialize.Identifier(_[Name]) & " = " & _[Kind],
                                    ", "
                                )
                                & "] "
                    ),
        _serialize_record_type = (x) =>
            let
                flds = Type.RecordFields(x)
            in
                if Record.FieldCount(flds) = 0 then
                    "record"
                else
                    "["
                        & List.TransformAndCombine(
                            Record.FieldNames(flds),
                            (item) =>
                                Serialize.Identifier(item) & "=" & _serialize_typename(
                                    Record.Field(flds, item)[Type]
                                ),
                            ", "
                        )
                        & (if Type.IsOpenRecord(x) then ", ..." else "")
                        & "]",
        _serialize_function_type = (x) =>
            _serialize_function_param_type(Type.FunctionParameters(x), Type.FunctionRequiredParameters(x))
                & " as "
                & _serialize_function_return_type(x),
        _serialize_function_param_type = (t, n) =>
            let
                funsig = Table.ToRecords(
                    Table.TransformColumns(
                        Table.AddIndexColumn(Record.ToTable(t), "isOptional", 1), {"isOptional", (x) => x > n}
                    )
                )
            in
                "("
                    & List.TransformAndCombine(
                        funsig,
                        (item) =>
                            (if item[isOptional] then "optional " else "")
                                & Serialize.Identifier(item[Name])
                                & " as "
                                & _serialize_typename(item[Value], true),
                        ", "
                    )
                    & ")",
        _serialize_function_return_type = (x) => _serialize_typename(Type.FunctionReturn(x), true),
        Serialize = (x) as text =>
            if x is binary then
                try Serialize.Binary(x) otherwise "null /*serialize failed*/"
            else if x is date then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is datetime then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is datetimezone then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is duration then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is function then
                try Serialize.Function(x) otherwise "null /*serialize failed*/"
            else if x is list then
                try Serialize.List(x) otherwise "null /*serialize failed*/"
            else if x is logical then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is null then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is number then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is record then
                try Serialize.Record(x) otherwise "null /*serialize failed*/"
            else if x is table then
                try Serialize.Table(x) otherwise "null /*serialize failed*/"
            else if x is text then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is time then
                try Expression.Constant(x) otherwise "null /*serialize failed*/"
            else if x is type then
                try Serialize.Type(x) otherwise "null /*serialize failed*/"
            else
                "[#_unable_to_serialize_#]"
    in
        try Serialize(value) otherwise "<serialization failed>";
