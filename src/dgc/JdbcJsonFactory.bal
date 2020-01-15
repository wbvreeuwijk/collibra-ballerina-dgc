import ballerina/config;
import ballerina/log;
import ballerinax/java.jdbc;

map<string> dataTypes = {
            'bigint: "Whole Number",
            'bit: "Whole Number",
            'decimal: "Whole Number",
            'int: "Whole Number",
            money: "Whole Number",
            numeric: "Whole Number",
            smallint: "Whole Number",
            smallmoney: "Whole Number",
            tinyint: "Whole Number",
            'float: "Decimal Number",
            real: "Decimal Number",
            date: "Date",
            datetime2: "Date Time",
            datetime: "Date Time",
            datetimeoffset: "Date Time",
            smalldatetime: "Date Time",
            time: "Time",
            char: "Text",
            text: "Text",
            varchar: "Text",
            nchar: "Text",
            ntext: "Text",
            nvarchar: "Text"
        };

# Description
#
# + SCHEMA_NAME - SCHEMA_NAME Parameter Description
type MsSQLSchemaRecord record {
    string SCHEMA_NAME;
};

# Description
#
# + TABLE_NAME - TABLE_NAME Parameter Description 
# + TABLE_TYPE - TABLE_TYPE Parameter Description
type MsSQLTable record {
    string TABLE_NAME;
    string TABLE_TYPE;
};

# Description
#
# + COLUMN_NAME - COLUMN_NAME Parameter Description 
# + ORDINAL_POSITION - ORDINAL_POSITION Parameter Description 
# + DATA_TYPE - DATA_TYPE Parameter Description 
# + NUMERIC_PRECISION - NUMERIC_PRECISION Parameter Description 
# + CHARACTER_LENGTH - CHARACTER_LENGTH Parameter Description
type MsSQLColumn record {
    string COLUMN_NAME;
    int ORDINAL_POSITION;
    string DATA_TYPE;
    int? NUMERIC_PRECISION;
    int? CHARACTER_LENGTH;
};

# Description
#
# + sqlDB - sqlDB Parameter Description 
# + databaseName - databaseName Parameter Description 
# + hostName - hostName Parameter Description 
# + objectList - objectList Parameter Description 
# + community - community Parameter Description 
# + techDomain - techDomain Parameter Description 
# + physicalDomain - physicalDomain Parameter Description 
# + schema_query - schema_query Parameter Description 
# + table_query - table_query Parameter Description 
# + column_query - column_query Parameter Description
public type JdbcJsonFactory object {

    private jdbc:Client sqlDB;
    private string databaseName;
    private string hostName;
    private Object[] objectList = [];
    private Community community;
    private Domain techDomain;
    private Domain physicalDomain;
    private string schema_query;
    private string table_query;
    private string column_query;

    public function __init(string dbConfig, string communityName, string techDomainName, string physicalDomainName) {
        map<any> databaseConfig = config:getAsMap(dbConfig);
        string host = <string>databaseConfig["host"];
        int port = <int>databaseConfig["port"];
        string database = <string>databaseConfig["database"];
        string driver = <string>databaseConfig["driver"];
        string url = string `jdbc:${driver}://${host}:${port};database=${database}`;

        log:printInfo("Setting up JDBC Connection:"+url);

        self.sqlDB = new ({
            url: url,
            username: <string>databaseConfig["user"],
            password: <string>databaseConfig["password"]
        });

        self.databaseName = database;
        self.hostName = host;
        self.community = new (communityName);
        self.techDomain = new (techDomainName, "Technology Asset Domain", self.community);
        self.physicalDomain = new (physicalDomainName, "Physical Data Dictionary", self.community);
        self.schema_query = <string>databaseConfig["schema_query"];
        self.table_query = <string>databaseConfig["table_query"];
        self.column_query = <string>databaseConfig["column_query"];
    }

    # Description
    #
    # + schemaName - schema Parameter Description 
    # + return - Return Value Description
    public function generate(string schemaName) returns @tainted error | Object[] {
        Object[] objectList = [];
        // Add main community
        objectList.push(self.community);

        // Add domains for technical assets and physical assets
        objectList.push(self.techDomain);
        objectList.push(self.physicalDomain);

        // Add the System
        System system = new (self.hostName, self.techDomain);
        objectList.push(system.asset);

        // Create database asset
        Database db = new (self.databaseName, system);
        objectList.push(db.asset);

        // First retrieve Schemas
        var DBSchemas = self.sqlDB->select(self.schema_query, MsSQLSchemaRecord, schemaName);
        if (DBSchemas is table<MsSQLSchemaRecord>) {
            foreach var dbSchema in DBSchemas {
                Schema schema = new (dbSchema.SCHEMA_NAME, self.physicalDomain, db);
                objectList.push(schema.asset);
                // Next retrieve Tables
                // Fetch the tables
                log:printInfo("Querying database for schema:"+dbSchema.SCHEMA_NAME);
                var DBTables = self.sqlDB->select(self.table_query, MsSQLTable, dbSchema.SCHEMA_NAME);
                if (DBTables is table<MsSQLTable>) {
                    foreach var dbTable in DBTables {
                        Table | View tableOrView;
                        if (dbTable.TABLE_TYPE == "VIEW") {
                            tableOrView = new View(dbTable.TABLE_NAME, schema);
                        } else {
                            tableOrView = new Table(dbTable.TABLE_NAME, schema);
                        }
                        objectList.push(tableOrView.asset);
                        // Fetch the table columns
                        log:printInfo("Querying database for table:"+dbTable.TABLE_NAME);
                        var DBColumns = self.sqlDB->select(self.column_query, MsSQLColumn, dbSchema.SCHEMA_NAME, dbTable.TABLE_NAME);
                        if (DBColumns is table<MsSQLColumn>) {
                            foreach var dbColumn in DBColumns {
                                Column column = new (dbColumn.COLUMN_NAME, tableOrView, schema);
                                string dataType = (dataTypes[<string>dbColumn.DATA_TYPE] != ()) ? <string>dataTypes[<string>dbColumn.DATA_TYPE] : "N/A" ;
                                column.setDataType(dataType,dbColumn.DATA_TYPE);
                                column.setColumnPosition(dbColumn.ORDINAL_POSITION);
                                if (dbColumn.CHARACTER_LENGTH != ()) {
                                    column.setSize(dbColumn.CHARACTER_LENGTH);
                                } else if (dbColumn.NUMERIC_PRECISION != ()) {
                                    column.setSize(dbColumn.NUMERIC_PRECISION);
                                } else {
                                    column.setSize(0);
                                }
                                objectList.push(column.asset);
                            }
                        } else {
                            return error("Column retrieval query failed:" + <string>DBColumns.detail()?.message);
                        }
                    }
                } else {
                    return error("Table retrieval query failed:" + <string>DBTables.detail()?.message);
                }
            }
        } else {
            return error("Schema retrieval query failed:" + <string>DBSchemas.detail()?.message);
        }
        return objectList;
    }
};
