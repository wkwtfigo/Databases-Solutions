import json
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
        return  f"Inserted single document with ID: {result.inserted_ids}"
    
def find_operation():
    print("Documents where a coupon was used:")

    for doc in collection.find({"couponUsed": True}).limit(1):
        print(doc)

    count_coupon_used = collection.count_documents({"couponUsed": True})
    print(f"Total documents where a coupon was used: {count_coupon_used}")
    
    print("\nDocuments with storeLocation in Denver:")
    for doc in collection.find({"storeLocation": "Denver"}).limit(1):
        print(doc)

    count_denver = collection.count_documents({"storeLocation": "Denver"})
    print(f"Total documents with storeLocation in Denver: {count_denver}")

    print("\nDocuments where customer satisfaction is less than 4:")
    for doc in collection.find({"customer.satisfaction": {"$lt": 4}}).limit(1):
        print(doc)

    count_satisfaction = collection.count_documents({"customer.satisfaction": {"$lt": 4}})
    print(f"Total documents where customer satisfaction is less than 4: {count_satisfaction}")

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


if __name__ == "__main__":
    with open('Lab_11\\single_data.json', 'r') as single_file:
        single_data = json.load(single_file)

    with open('Lab_11\\multiple_data.json', 'r') as multiple_file:
        multiple_data = json.load(multiple_file)
    
    print(insert_operation(single_data))
    print(insert_operation(multiple_data))
    
    find_operation()
    delete_operation()
    update_operation()