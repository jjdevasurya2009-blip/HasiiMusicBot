import ballerina/io;
import ballerinax/mongodb;

// This is the main function where the program starts running.
public function main() returns error? {
    // Print a starting message to the terminal.
    io:println("Connecting to HasiiMusicBot Database...");

    // Read the .env file to get the MongoDB URI securely
    string[] envLines = check io:fileReadLines(".env");
    string mongoUri = "";

    foreach string line in envLines {
        if line.startsWith("MONGO_DB_URI=") {
            mongoUri = line.substring(13).trim();
        }
    }

    if mongoUri == "" {
        io:println("Error: MONGO_DB_URI not found in .env file.");
        return;
    }

    // Setup the MongoDB connection configuration.
    mongodb:ConnectionConfig mongoConfig = {
        connection: mongoUri
    };

    // Create a new MongoDB client to talk to the database.
    // The 'check' keyword handles any connection errors automatically.
    mongodb:Client mongoClient = check new (mongoConfig);

    // Select the Database named "HasiiTune"
    mongodb:Database db = check mongoClient->getDatabase("HasiiTune");

    // Select the 'users' collection and count documents
    mongodb:Collection usersColl = check db->getCollection("users");
    int totalUsers = check usersColl->countDocuments({});

    // Select the 'chats' collection and count documents
    mongodb:Collection chatsColl = check db->getCollection("chats");
    int totalChats = check chatsColl->countDocuments({});

    // Print the final result in a beautiful format to the terminal screen.
    io:println("\n==============================");
    io:println("   HasiiMusicBot Statistics   ");
    io:println("==============================");
    io:println("👥 Total Users : ", totalUsers);
    io:println("💬 Total Groups: ", totalChats);
    io:println("==============================\n");

    // Always close the database connection when you are done.
    check mongoClient->close();
}
