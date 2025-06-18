[Version = "0.1.0"]
section spiceai;

// Connector version for Spice.ai Self-Hosted instance.
[DataSource.Kind = "Spice", Publish = "Spice.Publish"]
shared Spice.Databases = Value.ReplaceType(SpiceConnectionImpl, SpiceOSSConnectionProps);

// Cloud Platform Connector is a simplified version of the self-hosted OSS version with predefined settings.
[DataSource.Kind = "SpiceCloud", Publish = "SpiceCloud.Publish"]
shared SpiceCloud.Databases = () as table => SpiceConnectionImpl("flight.spiceai.io:443", "Enabled");

SpiceOSSConnectionProps =
    let
        FunctionType = Type.ForFunction(
            [
                Parameters = [
                    server = (type text) meta [
                        Documentation.FieldCaption = "Server",
                        Documentation.FieldDescription = "Arrow Flight Endpoint of Spice.ai Server",
                        Documentation.SampleValues = {"127.0.0.1:50051"}
                    ],
                    encryption = (type text) meta [
                        Documentation.FieldCaption = Extension.LoadString("TLSCaption"),
                        Documentation.AllowedValues = {"Disabled", "Enabled"},
                        Documentation.FieldDescription = Extension.LoadString("TLSParameterDescription"),
                        Documentation.SampleValues = {"Disabled"}
                    ]
                ],
                ReturnType = type table
            ],
            2
        ),
        WithDocumentation = Value.ReplaceMetadata(FunctionType, [
            Documentation.Name = "Spice.ai Self-Hosted"
        ])
    in
        WithDocumentation;

Spice = [
    Type = "Custom",
    Authentication = [
        Key = [
            Label = "API Key",
            KeyLabel = "API Key"
        ],
        Anonymous = []
    ],
    MakeResourcePath = (server, optional encryption) =>
        if encryption <> null then
            server & ";" & encryption
        else
            server,
    ParseResourcePath = (resourcePath as text) =>
    let
        values = Text.Split(resourcePath, ";"),
        // Try to get the encryption field, or null if not present
        encryptionRaw = if List.Count(values) > 1 then Text.Trim(values{1}) else null,
        encryption = if Text.Upper(encryptionRaw) = "ENABLED" then "Enabled" else "Disabled"
    in
        { values{0}, encryption },
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

SpiceCloud = [
    Type = "Custom",
    Authentication = [
        Key = [
            Label = "API Key",
            KeyLabel = "API Key"
        ]
    ],
    MakeResourcePath = () => "SpiceCloudPlatform",
    ParseResourcePath = (resourcePath as text) => {},
    TestConnection = () => {"SpiceCloud.Databases"},
    Icons = Spice.Icons
];

SpiceCloud.Publish = [
    Beta = true,
    Category = "Database",
    SupportsDirectQuery = true,
    NativeQueryProperties = [
        navigationSteps = {[]},
        nativeQueryOptions = [
            EnableFolding = true
        ]
    ],
    ButtonText = {Extension.LoadString("CloudButtonTitle"), Extension.LoadString("CloudButtonHelp")},
    SourceImage = Spice.Icons,
    SourceTypeImage = Spice.Icons
];

GetConnectionString =
    let
        Credential = Extension.CurrentCredential()
    in
        if Credential[AuthenticationKind]? = "Key" then
            [adbc.flight.sql.authorization_header = "Bearer " & Credential[Key]]
        else
            [];

SpiceSqlGenerator = Extension.LoadExpression("SqlGenerator.pqm");
FlightSqlAdbcConfig = Extension.LoadExpression("FlightSqlAdbcConfig.pqm");

SpiceConnectionImpl = (server as text, encryption as text) as table =>
    let
        UriSchema = if Text.Upper(encryption) = "ENABLED" then "grpc+tls" else "grpc+tcp",
        ConnectionString = [Uri = UriSchema & "://" & server],
        Databases = Adbc.DataSource(
            FlightSqlAdbcConfig,
            ConnectionString,
            [
                SqlGenerator = SpiceSqlGenerator,
                CredentialConnectionString = GetConnectionString
            ]
        )
    in
        Databases;

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
