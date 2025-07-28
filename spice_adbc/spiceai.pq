[Version = "1.0.0"]
section spiceai;

[DataSource.Kind = "Spice", Publish = "Spice.Publish"]
shared Spice.Databases = Value.ReplaceType(SpiceConnectionImpl, SpiceConnectionProps);

SpiceConnectionProps =
    let
        FunctionType = Type.ForFunction(
            [
                Parameters = [
                    endpoint = (type text) meta [
                        Documentation.FieldCaption = Extension.LoadString("EndpointFieldCaption"),
                        Documentation.FieldDescription = Extension.LoadString("EndpointFieldDescription"),
                        Documentation.SampleValues = {"grpc+tls://flight.spiceai.io:443", "grpc://localhost:50051"}
                    ]
                ],
                ReturnType = type table
            ],
            1
        ),
        WithDocumentation = Value.ReplaceMetadata(
            FunctionType,
            [
                Documentation.Name = Extension.LoadString("ConnectionName"),
                Documentation.LongDescription = Extension.LoadString("ConnectionLongDescription"),
                Documentation.Examples = {
                    [
                        Description = "Connect to Spice Cloud",
                        Code = "Spice.Databases(""grpc+tls://flight.spiceai.io:443"")",
                        Result = "Returns a Spice database connection entry"
                    ],
                    [
                        Description = "Connect to local instance",
                        Code = "Spice.Databases(""grpc://localhost:50051"")",
                        Result = "Returns a Spice database connection entry"
                    ]
                }
            ]
        )
    in
        WithDocumentation;

Spice = [
    Type = "Custom",
    Authentication = [
        Key = [
            Label = Extension.LoadString("ApiKeyLabel"),
            KeyLabel = Extension.LoadString("ApiKeyDescription")
        ],
        Anonymous = []
    ],
    MakeResourcePath = (endpoint) => NormalizeEndpoint(endpoint)[Normalized],
    ParseResourcePath = (resourcePath as text) => let endpoint = resourcePath in {endpoint},
    TestConnection = (resourcePath as text) => {"Spice.Databases"} & ParseResourcePath(resourcePath),
    Icons = Spice.Icons
];

Spice.Publish = [
    Beta = true,
    Category = "Database",
    SupportsDirectQuery = true,
    NativeQueryProperties = [
        navigationSteps = {[]},
        nativeQueryOptions = [
            EnableFolding = true
        ]
    ],
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    SourceImage = Spice.Icons,
    SourceTypeImage = Spice.Icons
];

Spice.Icons = Icons;

GetConnectionString =
    let
        Credential = Extension.CurrentCredential()
    in
        if Credential[AuthenticationKind]? = "Key" then
            [adbc.flight.sql.authorization_header = "Bearer " & Credential[Key]]
        else
            [];

IsKeyAuth = () as logical => let Credential = Extension.CurrentCredential() in Credential[AuthenticationKind]? = "Key";

SpiceSqlGenerator = Extension.LoadExpression("SqlGenerator.pqm");
FlightSqlAdbcConfig = Extension.LoadExpression("FlightSqlAdbcConfig.pqm");

SpiceConnectionImpl = (endpoint as text) as table =>
    let
        parsed = NormalizeEndpoint(endpoint),
        isCloud = parsed[IsCloud],
        ConnectionString = [Uri = parsed[Normalized]],
        credential = Extension.CurrentCredential(),
        authKind = credential[AuthenticationKind]?,
        result =
            if isCloud and not IsKeyAuth() then
                error Error.Record("Expression.Error", Extension.LoadString("CloudAuthError"), [
                    Endpoint = endpoint
                ])
            else
                Adbc.DataSource(
                    FlightSqlAdbcConfig,
                    ConnectionString,
                    [
                        SqlGenerator = SpiceSqlGenerator,
                        CredentialConnectionString = GetConnectionString
                    ]
                )
    in
        Diagnostics.Trace(
            TraceLevel.Information,
            [
                Name = "Spice/Connection",
                Data = [],
                SafeData = [
                    Endpoint = endpoint,
                    NormalizedEndpoint = parsed[Normalized],
                    AuthenticationKind = authKind,
                    IsCloud = isCloud
                ]
            ],
            result
        );

NormalizeEndpoint = (endpoint as text) as record =>
    let
        endpoint = Text.Trim(endpoint),
        // Split schema if present
        parts = Text.Split(endpoint, "://"),
        hasSchema = List.Count(parts) = 2,
        schema = if hasSchema then Text.Lower(parts{0}) else null,
        host = if hasSchema then parts{1} else parts{0},
        // Split host and port if present
        hostParts = Text.Split(host, ":"),
        server = hostParts{0},
        port = if List.Count(hostParts) = 2 then Number.FromText(hostParts{1}) else null,
        // Determine default schema and port
        isCloud = Text.EndsWith(Text.Lower(server), ".spiceai.io"),
        finalSchema = if schema <> null then schema else if isCloud then "grpc+tls" else "grpc",
        finalPort = if port <> null then port else if isCloud then 443 else 50051,
        normalized = finalSchema & "://" & server & ":" & Text.From(finalPort)
    in
        if not List.Contains({"grpc+tls", "grpc", "grpc+tcp"}, finalSchema) then
            error
                Error.Record(
                    "Expression.Error",
                    Text.Replace(Extension.LoadString("UnsupportedSchemaError"), "{SCHEMA}", finalSchema),
                    [
                        Schema = finalSchema
                    ]
                )
        else
            [Schema = finalSchema, Server = server, Port = finalPort, IsCloud = isCloud, Normalized = normalized];

Icons = [
    Icon16 = {
        Extension.Contents("spiceai16.png"),
        Extension.Contents("spiceai20.png"),
        Extension.Contents("spiceai24.png"),
        Extension.Contents("spiceai32.png")
    },
    Icon32 = {
        Extension.Contents("spiceai32.png"),
        Extension.Contents("spiceai40.png"),
        Extension.Contents("spiceai48.png"),
        Extension.Contents("spiceai64.png")
    }
];

Adbc.DataSource =
    try
        #shared[Adbc.DataSource]
    otherwise
        (driver, connectionString, options) =>
            error
                Error.Record("Expression.Error", "The Adbc.DataSource function is not available in this environment");
Adbc.Query =
    try
        #shared[Adbc.Query]
    otherwise
        (driver, connectionString, query) =>
            error Error.Record("Expression.Error", "The Adbc.Query function is not available in this environment");

Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

Extension.LoadExpression = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);
