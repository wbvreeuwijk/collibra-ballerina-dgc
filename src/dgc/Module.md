This module provides and interface to the Collibra Data Governance platform
[//]: # (above is the module summary)

# Module Overview
This module consist of three distinct components
- Assettypes: These are abstractions of assettypes related to the ingestion of technical metadata
- Client: This component takes care of connecting to the Collibra DGC API
- JdbcJsonFactory: This component connects to a database using JDBC and uses the queries in the configuration to extract metadata from the database and build a JSON object from this. 

An example implementation would look something like:
```ballerina
import dgc;
import ballerina/config;
import ballerina/log;

const DATABASE_CONF = "Database";
const COLLIBRA_CONF = "Collibra";

public function main() {
    // Setup the connection with Collibra API
    map<any> collibraConfig = config:getAsMap(COLLIBRA_CONF);
    dgc:Client dgcClient = checkpanic new (
    <string>collibraConfig["url"],
    <string>collibraConfig["user"],
    <string>collibraConfig["password"]);

    // Check connectivity by checking the version
    string dgcVersion = checkpanic dgcClient.getVersion();
    log:printInfo("Version:" + dgcVersion);

    // Create JdbcJsonFactory 
    dgc:JdbcJsonFactory jsonFactory = new(DATABASE_CONF,
        <string>collibraConfig["community"],
        <string>collibraConfig["tech_domain"],
        <string>collibraConfig["physical_domain"]);
    dgc:Object[] objList = checkpanic jsonFactory.generate(<string>collibraConfig["schema_selection"]);
    dgcClient.importObjects(objList);
}
```

A large part of the functionality of this module is configured through a configuration file `ballerina.conf`
```ballerina
[Database]
driver="sqlserver"
host=<database host>
port=1433
database=<name of database>
user=<database user>
password=<user password>
schema_query="SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME LIKE ?;"
table_query="SELECT TABLE_NAME, TABLE_TYPE FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?;"
column_query="SELECT COLUMN_NAME,ORDINAL_POSITION, DATA_TYPE, NUMERIC_PRECISION, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME= ?;"

[Collibra]
url=<url to collibra>
user=<DGC User>
password=<DGC User Password>
community="DBs Community"
tech_domain="Systems & Databases"
physical_domain="Physical Domain"
schema_selection="dbo"
```