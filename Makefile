
MakePQX := $(shell powershell -NoProfile -Command "Get-ChildItem -Recurse -Filter MakePQX.exe ~\.vscode\extensions | Select-Object -First 1 -ExpandProperty FullName" | tr '\\\\' '/')
PQTest := $(shell powershell -NoProfile -Command "Get-ChildItem -Recurse -Filter PQTest.exe ~\.vscode\extensions | Select-Object -First 1 -ExpandProperty FullName" | tr '\\\\' '/')
SPICE_MEZ := $(abspath ./spice_adbc/bin/AnyCPU/Debug/spice_adbc.mez)
DATACONNECTORS_DIR := ../DataConnectors

.PHONY: tools
tools:
	code --install-extension powerquery.vscode-powerquery-sdk --force

.PHONY: build
build:
	"$(MakePQX)" compile ./spice_adbc 

.PHONY: test
test: build
	@echo '{"AuthenticationKind": "Anonymous"}' | "$(PQTest)" set-credential --extension "$(SPICE_MEZ)" --queryFile "./spice_adbc/spiceai.test.pq" --prettyPrint
	"$(PQTest)" run-test --extension "$(SPICE_MEZ)" --queryFile "./spice_adbc/spiceai.test.pq" --prettyPrint

.PHONY: test-suite
test-suite: build setup-testframework create-testframework-config
	@echo "Setting up Anonymous Authentication for test suite..."
	@echo '{"AuthenticationKind": "Anonymous"}' | "$(PQTest)" set-credential --extension "$(SPICE_MEZ)" --queryFile "./spice_adbc/spiceai.test.pq" --prettyPrint
	@cd "$(DATACONNECTORS_DIR)/testframework/tests" && \
		 echo "y" | powershell -NoProfile -ExecutionPolicy Bypass -File "RunPQSDKTestSuites.ps1"

.PHONY: setup-testframework
setup-testframework:
	@if [ ! -d "$(DATACONNECTORS_DIR)" ]; then \
		echo "Cloning DataConnectors repository..."; \
		git clone --depth 1 https://github.com/microsoft/DataConnectors.git $(DATACONNECTORS_DIR); \
	else \
		echo "DataConnectors repository already exists, skipping clone"; \
	fi

.PHONY: create-testframework-config
create-testframework-config:
	@echo "Creating RunPQSDKTestSuitesSettings.json..."
	@echo '{"PQTestExePath": "$(PQTest)", "ExtensionPath": "$(SPICE_MEZ)", "ValidateQueryFolding": false, "DetailedResults": true, "JSONResults": false}' > "$(DATACONNECTORS_DIR)/testframework/tests/RunPQSDKTestSuitesSettings.json"
	@echo "Setting up ConnectorConfigs..."
	@if [ -d "$(DATACONNECTORS_DIR)/testframework/tests/ConnectorConfigs/spice_adbc" ]; then \
		rm -rf "$(DATACONNECTORS_DIR)/testframework/tests/ConnectorConfigs/spice_adbc"; \
	fi
	@cp -r "./test/testframework/spice_adbc" "$(DATACONNECTORS_DIR)/testframework/tests/ConnectorConfigs/"
	@echo "ConnectorConfigs setup complete."
