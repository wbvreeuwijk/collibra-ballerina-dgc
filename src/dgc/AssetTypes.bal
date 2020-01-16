# 
# This defines all assettypes that make up the technical metadata 
# 


const SEPERATOR = ">";

# Assets names
const SYSTEM_ASSET = "System";
const DATABASE_ASSET = "Database";
const SCHEMA_ASSET = "Schema";
const TABLE_ASSET = "Table";
const VIEW_ASSET = "Database View";
const COLUMN_ASSET = "Column";

# Asset relationships
const SYSTEM_DATABASE_RELATION = "00000000-0000-0000-0000-000000007054:SOURCE";
const DATABASE_SCHEMA_RELATION = "00000000-0000-0000-0000-000000007024:SOURCE";
const SCHEMA_TABLE_RELATION = "00000000-0000-0000-0000-000000007043:SOURCE";
const TABLE_COLUMN_RELATION = "00000000-0000-0000-0000-000000007042:TARGET";

# Asset attributes
const TABLE_TYPE_ATTR = "Table Type";
const ORIGINAL_NAME_ATTR = "Original Name";
const DATA_TYPE_ATTR = "Data Type";
const TECH_DATA_TYPE_ATTR = "Technical Data Type";
const COLUMN_POSITION_ATTR = "Column Position";
const SIZE_ATTR = "Size";

# The System object is the top of the hierarchy
# + asset - Holds the asset representation
public type System object {
    public Asset asset;

    public function __init(string hostname, Domain domain) {
        self.asset = new (hostname, SYSTEM_ASSET, domain);
    }

};

# The Database object is part of the System
# + asset - Holds the asset representation
public type Database object {
    public Asset asset;

    public function __init(string dbname, System system) {
        self.asset = new (system.asset.name + SEPERATOR + dbname, DATABASE_ASSET, system.asset.domain);
        self.asset.addRelation(new Relation(SYSTEM_DATABASE_RELATION, system.asset));
    }

};

# The Schema object is part of the Database
# + asset - Holds the asset representation
public type Schema object {
    public Asset asset;

    public function __init(string name, Domain domain, Database database) {
        self.asset = new (database.asset.name + SEPERATOR + name, SCHEMA_ASSET, domain);
        self.asset.addRelation(new Relation(DATABASE_SCHEMA_RELATION, database.asset));
    }
};

# The Table object is part of the Schema
# + asset - Holds the asset representation
public type Table object {
    public Asset asset;

    public function __init(string name, Schema schema) {
        self.asset = new (schema.asset.name + SEPERATOR + name, TABLE_ASSET, schema.asset.domain);
        self.asset.addAttribute(new Attribute(TABLE_TYPE_ATTR, "TABLE"));
        self.asset.addRelation(new Relation(SCHEMA_TABLE_RELATION, schema.asset));
    }
};

# The View object is part of the Schema
# + asset - Holds the asset representation
public type View object {
    public Asset asset;

    public function __init(string name, Schema schema) {
        self.asset = new (schema.asset.name + SEPERATOR + name, VIEW_ASSET, schema.asset.domain);
        self.asset.addAttribute(new Attribute(TABLE_TYPE_ATTR, "VIEW"));
        self.asset.addRelation(new Relation(SCHEMA_TABLE_RELATION, schema.asset));
    }
};

# The Column object is part of the Table or View
# + asset - Holds the asset representation
public type Column object {
    public Asset asset;

    public function __init(string name, Table | View tableOrView, Schema schema) {
        self.asset = new (tableOrView.asset.name + SEPERATOR + name, COLUMN_ASSET, schema.asset.domain);
        self.asset.addRelation(new Relation(TABLE_COLUMN_RELATION, tableOrView.asset));
        self.asset.addAttribute(new Attribute(ORIGINAL_NAME_ATTR, name));
    }

    # Add the data type and technical data type attributes
    # + dataType - The Collibra data type
    # + techDataType - The Datatype as it is defined in the Datase
    public function setDataType(string dataType, string? techDataType) {
        self.asset.addAttribute(new Attribute(DATA_TYPE_ATTR, dataType));
        self.asset.addAttribute(new Attribute(TECH_DATA_TYPE_ATTR, techDataType));
    }

    # Add the column position attribute
    # + value - The position
    public function setColumnPosition(int value) {
        self.asset.addAttribute(new Attribute(COLUMN_POSITION_ATTR, value));
    }

    # Add the size attribute
    # + value - The size of the column
    public function setSize(int? value) {
        self.asset.addAttribute(new Attribute(SIZE_ATTR, value));
    }

};
