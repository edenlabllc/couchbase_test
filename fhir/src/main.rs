use couchbase::{Cluster, GetOptions, UpsertOptions};

pub fn main() {
    // Connect to the cluster with a connection string and credentials
    let cluster = Cluster::connect("couchbase://127.0.0.1", "Administrator", "123456");
    // Open a bucket
    let bucket = cluster.bucket("travel-sample");
    // Use the default collection (needs to be used for all server 6.5 and earlier)
    let collection = bucket.default_collection();

    // Fetch a document
    match block_on(collection.get("airline_10", GetOptions::default())) {
        Ok(r) => println!("get result: {:?}", r),
        Err(e) => println!("get failed! {}", e),
    };

    // Upsert a document as JSON
    let mut content = HashMap::new();
    content.insert("Hello", "Rust!");

    match block_on(collection.upsert("foo", content, UpsertOptions::default())) {
        Ok(r) => println!("upsert result: {:?}", r),
        Err(e) => println!("upsert failed! {}", e),
    };
}
