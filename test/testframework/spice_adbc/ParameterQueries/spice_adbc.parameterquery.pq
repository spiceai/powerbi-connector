let
    conn         = Spice.Databases("127.0.0.1:50051"),
    spiceDB      = conn{[Name="spice", Kind="Database"]}[Data],
    publicSchema = spiceDB{[Name="public", Kind="Schema"]}[Data],
    testTable    = publicSchema{[Name="types_support", Kind="Table"]}[Data],
    NycTaxiGreen_Table = publicSchema{[Name="nyc_taxi_tripdata", Kind="Table"]}[Data],
    TaxiZoneLookup_Table =  publicSchema{[Name="taxi_zone_lookup", Kind="Table"]}[Data]
in
    [taxi_table = NycTaxiGreen_Table, zone_table = TaxiZoneLookup_Table]