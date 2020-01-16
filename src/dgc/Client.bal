import ballerina/crypto;
import ballerina/http;
import ballerina/log;
import ballerina/mime;

const BATCH_SIZE = 10000;

public type Client object {

    private http:Client clientEndpoint;
    private string csrfToken;
    private string cookies;

    public function __init(string collibra_url, string username, string password) returns error? {
        self.clientEndpoint = new (collibra_url + "/rest/2.0");
        json loginRequest = {
            username: username,
            password: password
        };
        var response = self.clientEndpoint->post("/auth/sessions", loginRequest);
        if (response is http:Response) {
            var msg = response.getJsonPayload();
            if (msg is json) {
                if (response.hasHeader("Set-Cookie")) {
                    self.cookies = response.getHeaders("Set-Cookie").toString();
                    self.csrfToken = msg.csrfToken.toString();
                } else {
                    return error("No cookies found in response");
                }
            } else {
                return error("No JSON Payload found in response");
            }
        } else {
            return error("Received invalid response from login API:" + response.reason());
        }
        log:printInfo("Succes fully logged into Collibra DGC");
    }

    private function createRequest() returns http:Request {
        http:Request req = new;
        req.addHeader("Authorization", "Basic " + self.csrfToken);
        req.addHeader("Cookie", self.cookies);
        return req;
    }

    # Description
    #
    # + return - Return Value Description
    public function getVersion() returns @untainted string | error {
        http:Request getAppInfo = self.createRequest();
        var response = self.clientEndpoint->get("/application/info", getAppInfo);
        if (response is http:Response) {
            var appInfo = <map<json>>response.getJsonPayload();
            return appInfo["version"].fullVersion.toString();
        } else {
            return error("Unable to retrieve version:" + response.reason());
        }
    }

    public function importObjects(Object[] importObject, string communityName) {
        byte[] hash = crypto:hashMd5(communityName.toBytes());
        string syncId = hash.toBase16();
        log:printInfo("Synchronization ID:" + syncId);
        log:printInfo("# Objects:" + importObject.length().toString());
        json[] assets = [];
        foreach Object o in importObject {
            assets.push(o.getJSON());
            if (assets.length() == BATCH_SIZE) {
                log:printInfo("# Assets:" + assets.length().toString());
                self.importBatch(assets, syncId);
                assets = [];
            }
        }
        self.importBatch(assets, syncId);
        self.finalize(syncId);
    }

    private function importBatch(json[] assets, string syncId) {
        http:Request importRequest = self.createRequest();
        mime:Entity fileBodyPart = new;
        fileBodyPart.setContentDisposition(self.getContentDispositionForFormData("file"));
        fileBodyPart.setText(assets.toJsonString());
        mime:Entity[] bodyParts = [fileBodyPart];
        importRequest.setBodyParts(bodyParts, contentType = mime:MULTIPART_FORM_DATA);
        log:printInfo("Submitting ImportJob");
        var importResponse = self.clientEndpoint->post(string `/import/synchronize/${syncId}/batch/json-job`, importRequest);
    }


    private function finalize(string syncId) {
        http:Request finalizeRequest = self.createRequest();
        log:printInfo("Finalizing ImportJob");
        var importResponse = self.clientEndpoint->post(string `/import/synchronize/${syncId}/finalize/job`, finalizeRequest);
    }

    private function getContentDispositionForFormData(string partName)
    returns (mime:ContentDisposition) {
        mime:ContentDisposition contentDisposition = new;
        contentDisposition.name = partName;
        contentDisposition.disposition = "form-data";
        return contentDisposition;
    }
};

