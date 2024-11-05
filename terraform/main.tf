provider "google" {
  project = "favorable-order-440721-e7"
  region  = "nam5"
}

# Create a Pub/Sub Topic
resource "google_pubsub_topic" "my_topic" {
  name = "incoming-orders"
}

# Create a Pub/Sub Subscription
resource "google_pubsub_subscription" "my_subscription" {
  name  = "incoming-orders-Sub"
  topic = google_pubsub_topic.my_topic.id

  # Optional: You can set additional subscription settings (e.g., ack_deadline)
  ack_deadline_seconds = 30
}

# This is the default when firestore is enabled so no need to put it here
# resource "google_firestore_database" "database" {
# project     = "favorable-order-440721-e7"
# name        = "(default)"
# location_id = "nam5"
# type        = "FIRESTORE_NATIVE"
# }

resource "google_storage_bucket" "bucket" {
  name     = "order-function-code"  # Every bucket name must be globally unique
  location = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "archive" {
  name   = "function-code.zip"
  bucket = google_storage_bucket.bucket.name
  source = "function-code.zip"  # Add path to the zipped function source code
}

resource "google_cloudfunctions_function" "order_processing_function" {
  name        = "processOrder"
  runtime     = "nodejs16"  # or the version you're using
  entry_point = "processOrder"
  region      = "us-central1"

  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.my_topic.id
  }
}

terraform {
  backend "gcs" {
    bucket     = "my-terraform-state-bucket"  # Your GCS bucket name
    prefix     = "terraform/state"              # Path within the bucket
  }
}