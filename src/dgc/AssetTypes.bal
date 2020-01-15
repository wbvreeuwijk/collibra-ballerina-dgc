const SEPERATOR = ">";
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

public type System object {
    public Asset asset;

    public function __init(string hostname, Domain domain) {
        self.asset = new (hostname, "System", domain);
    }

};

public type Database object {
    public Asset asset;

    public function __init(string dbname, System system) {
        self.asset = new (system.asset.name + SEPERATOR + dbname, "Database", system.asset.domain);
        self.asset.addRelation(new Relation("00000000-0000-0000-0000-000000007054:SOURCE", system.asset));
    }

};

public type Schema object {
    public Asset asset;

    public function __init(string name, Domain domain, Database database) {
        self.asset = new (database.asset.name + SEPERATOR + name, "Schema", domain);
        self.asset.addRelation(new Relation("00000000-0000-0000-0000-000000007024:SOURCE", database.asset));
    }
};

public type Table object {
    public Asset asset;

    public function __init(string name, Schema schema) {
        self.asset = new (schema.asset.name + SEPERATOR + name, "Table", schema.asset.domain);
        self.asset.addAttribute(new Attribute("Table Type", "TABLE"));
        self.asset.addRelation(new Relation("00000000-0000-0000-0000-000000007043:SOURCE", schema.asset));
    }
};

public type View object {
    public Asset asset;

    public function __init(string name, Schema schema) {
        self.asset = new (schema.asset.name + SEPERATOR + name, "Database View", schema.asset.domain);
        self.asset.addAttribute(new Attribute("Table Type", "VIEW"));
        self.asset.addRelation(new Relation("00000000-0000-0000-0000-000000007043:SOURCE", schema.asset));
    }
};

public type Column object {
    public Asset asset; 

    public function __init(string name, Table|View tableOrView, Schema schema) {
            self.asset = new (schema.asset.name + SEPERATOR + tableOrView.asset.name + SEPERATOR + name, "Column", schema.asset.domain);
            self.asset.addRelation(new Relation("00000000-0000-0000-0000-000000007042:TARGET", tableOrView.asset));
            self.asset.addAttribute(new Attribute("Original Name", name));
    }

    public function setDataType(string? value) {
        if(value != ()) {
            string? 'type = dataTypes[<string>value];
            if('type != ()) {
                self.asset.addAttribute(new Attribute("Data Type", 'type));
            } else {
                self.asset.addAttribute(new Attribute("Data Type", "N/A"));
            }
        } else {
            self.asset.addAttribute(new Attribute("Data Type", "N/A"));
        }
        self.asset.addAttribute(new Attribute("Technical Data Type", <string>value));
    }

    public function setColumnPosition(int value) {
            self.asset.addAttribute(new Attribute("Column Position", value));
    }

    public function setSize(int? value) {
            self.asset.addAttribute(new Attribute("Size", value));
    }

};
