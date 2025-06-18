
MakePQX := $(shell powershell -NoProfile -Command "Get-ChildItem -Recurse -Filter MakePQX.exe ~\.vscode\extensions | Select-Object -First 1 -ExpandProperty FullName")
PQTest := $(shell powershell -NoProfile -Command "Get-ChildItem -Recurse -Filter PQTest.exe ~\.vscode\extensions | Select-Object -First 1 -ExpandProperty FullName")
SPICE_MEZ := $(abspath ./spice_adbc/bin/AnyCPU/Debug/spice_adbc.mez)

.PHONY: tools
tools:
	code --install-extension powerquery.vscode-powerquery-sdk --force

.PHONY: build
build:
	"$(MakePQX)" compile ./spice_adbc 

.PHONY: test
test: build
	echo '{"AuthenticationKind": "Anonymous"}' | "$(PQTest)" set-credential --extension "$(SPICE_MEZ)" --queryFile "./spice_adbc/spiceai.test.pq" --prettyPrint
	"$(PQTest)" run-test --extension "$(SPICE_MEZ)" --queryFile "./spice_adbc/spiceai.test.pq" --prettyPrint
