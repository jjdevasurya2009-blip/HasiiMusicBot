import ballerina/http;
import ballerina/io;
import ballerinax/mongodb;

// Read arrays from database cache
public type CacheDoc record {
    string _id;
    int[] user_ids?;
    int[] chat_ids?;
};

// Read the database URI from the .env file
function getMongoUri() returns string|error {
    string[] envLines = check io:fileReadLines(".env");
    foreach string line in envLines {
        if line.startsWith("MONGO_DB_URI=") {
            return line.substring(13).trim();
        }
    }
    return error("MONGO_DB_URI not found in .env file");
}

// Start the HTTP service on port 9090
service / on new http:Listener(9090) {

    // Keep the database connection globally
    private final mongodb:Database db;

    // Initialize the database connection when the service starts
    public function init() returns error? {
        io:println("Initializing Stats API...");
        string uri = check getMongoUri();
        
        mongodb:ConnectionConfig mongoConfig = {
            connection: uri
        };
        mongodb:Client mongoClient = check new (mongoConfig);
        self.db = check mongoClient->getDatabase("HasiiTune");
        io:println("Database connected.");
    }

    // Expose the stats endpoint
    resource function get db_stats() returns json|error {
        // Get the total counts of users and chats
        mongodb:Collection usersColl = check self.db->getCollection("users");
        int totalUsers = check usersColl->countDocuments({});

        mongodb:Collection chatsColl = check self.db->getCollection("chats");
        int totalChats = check chatsColl->countDocuments({});

        // Get the counts for sudoers and blocked users/chats
        mongodb:Collection cacheColl = check self.db->getCollection("cache");

        int sudoUsersCount = 0;
        int blockedUsersCount = 0;
        int blockedChatsCount = 0;

        // Find sudoers
        CacheDoc? sudoDoc = check cacheColl->findOne(
            filter = {"_id": "sudoers"},
            targetType = CacheDoc
        );
        if sudoDoc is CacheDoc && sudoDoc.user_ids != () {
            sudoUsersCount = (<int[]>sudoDoc.user_ids).length();
        }

        // Find blocked users
        CacheDoc? blUsersDoc = check cacheColl->findOne(
            filter = {"_id": "bl_users"},
            targetType = CacheDoc
        );
        if blUsersDoc is CacheDoc && blUsersDoc.user_ids != () {
            blockedUsersCount = (<int[]>blUsersDoc.user_ids).length();
        }

        // Find blocked chats
        CacheDoc? blChatsDoc = check cacheColl->findOne(
            filter = {"_id": "bl_chats"},
            targetType = CacheDoc
        );
        if blChatsDoc is CacheDoc && blChatsDoc.chat_ids != () {
            blockedChatsCount = (<int[]>blChatsDoc.chat_ids).length();
        }

        // Format and return the final JSON data
        json responseData = {
            "served_users": totalUsers,
            "served_chats": totalChats,
            "sudo_users": sudoUsersCount,
            "blocked_users": blockedUsersCount,
            "blocked_chats": blockedChatsCount
        };

        return responseData;
    }
}
