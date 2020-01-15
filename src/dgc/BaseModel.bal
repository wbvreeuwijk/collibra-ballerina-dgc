public type Object abstract object {
    public string name;

    public function getJSON() returns json;
};

public type Community object {
    *Object;

    public function __init(string name) {
        self.name = name;
    }

    public function getJSON() returns json {
        json obj = {
            resourceType: "Community",
            identifier: {
                name: self.name
            }
        };
        return obj;
    }
};

public type Domain object {
    *Object;

    public Community community;
    private string 'type;

    public function __init(string name, string 'type, Community community) {
        self.name = name;
        self.community = community;
        self.'type = 'type;
    }

    public function getJSON() returns json {
        json obj =
        {
            "resourceType": "Domain",
            "identifier": {
                "name": self.name,
                "community": {
                    "name": self.community.name
                }
            },
            "type": {
                "name": self.'type
            }
        };
        return obj;
    }
};

public type Asset object {
    *Object;

    public Domain domain;
    private string 'type;
    map<json> attrMap = {};
    map<json> relMap = {};

    public function __init(string name, string 'type, Domain domain) {
        self.name = name;
        self.domain = domain;
        self.'type = 'type;
    }

    public function addAttribute(Attribute attr) {
        self.attrMap[attr.name] = [{
            "value": attr.value
        }];
    }

    public function addRelation(Relation rel) {
        self.relMap[rel.Id] = [
        {
            "name": rel.toAsset.name,
            "domain": {
                "name": rel.toAsset.domain.name,
                "community": {
                    "name": rel.toAsset.domain.community.name
                }
            }
        }
        ];
    }

    public function getJSON() returns json {
        map<json> obj = {
            "resourceType": "Asset",
            "identifier": {
                "name": self.name,
                "domain": {
                    "name": self.domain.name,
                    "community": {
                        "name": self.domain.community.name
                    }
                }
            },
            "type": {
                "name": self.'type
            }
        };
        obj["attributes"] = self.attrMap;
        obj["relations"] = self.relMap;
        return obj;
    }
};

public type Attribute object {
    *Object;

    public string|int? value;

    public function __init(string name, string|int? value) {
        self.name = name;
        self.value = value;
    }

    public function getJSON() returns json {
        map<json> obj = {};
        obj[self.name] = [
        {
            "value": self.value
        }
        ];
        return obj;
    }
};

public type Relation object {
    public string Id;
    public Asset toAsset;

    public function __init(string relationID, Asset toAsset) {
        self.Id = relationID;
        self.toAsset = toAsset;
    }
};
