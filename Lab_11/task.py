from pymongo import MongoClient

client = MongoClient("mongodb://localhost:27017/")
db = client["myDatabase"]
collection = db["supplies"]

def insert_operation(data):
    if isinstance(data, dict):
        result = collection.insert_one(data)
        return f"Inserted single document with ID: {result.inserted_id}"
    elif isinstance(data, list):
        result = collection.insert_many(data)
        return  f"Inserted single document with ID: {result.inserted_id}"
    
def find_operation():
    print("Documents where a coupon was used:")
    for doc in collection.find({"couponUsed": True}):
        print(doc)
    
    print("\nDocuments with storeLocation in Denver:")
    for doc in collection.find({"storeLocation": "Denver"}):
        print(doc)

    print("\nDocuments where customer satisfaction is less than 4:")
    for doc in collection.find({"customer.satisfaction": {"$lt": 4}}):
        print(doc)

def delete_operation():
    collection.delete_one({"_id": "5bd761dcae323e45a93ccff4"})
    collection.delete_many({"storeLocation": "Seattle"})
    print("Deletion completed.")

def update_operation():
    collection.update_one(
        {"_id": "5bd761dcae323e45a93ccff3"},
        {"$set": {"customer.satisfaction": 5}}
    )
    print("Updated customer satisfaction to 5.")